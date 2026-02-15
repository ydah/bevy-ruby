//! Ruby bindings for the RenderApp and input handling.

use bevy_ruby::{
    GamepadRumbleCommand, InputState, MeshData, MeshSync, MeshTransformData, PickingEventData,
    RenderApp, ShapeType, SpriteData, SpriteSync, TextData, TextSync, TextTransformData,
    TransformData, WindowConfig,
};
use magnus::{
    Error, RArray, RHash, Ruby, TryConvert, Value, block::Proc, function, method, prelude::*,
};
use std::cell::RefCell;

struct RenderState {
    render_app: RenderApp,
    sprite_sync: SpriteSync,
}

thread_local! {
    static RENDER_STATE: RefCell<Option<RenderState>> = const { RefCell::new(None) };
    static RUBY_CALLBACK: RefCell<Option<Proc>> = const { RefCell::new(None) };
    static SHARED_INPUT: RefCell<InputState> = RefCell::new(InputState::new());
    static SHOULD_STOP: RefCell<bool> = const { RefCell::new(false) };
    static PENDING_SPRITES: RefCell<SpriteSync> = RefCell::new(SpriteSync::new());
    static PENDING_TEXTS: RefCell<TextSync> = RefCell::new(TextSync::new());
    static PENDING_MESHES: RefCell<MeshSync> = RefCell::new(MeshSync::new());
    static CAMERA_POSITION: RefCell<(f32, f32, f32)> = RefCell::new((0.0, 0.0, 0.0));
    static CAMERA_SCALE: RefCell<f32> = RefCell::new(1.0);
    static CAMERA_DIRTY: RefCell<bool> = const { RefCell::new(false) };
    static PENDING_GAMEPAD_RUMBLE: RefCell<Vec<GamepadRumbleCommand>> = const { RefCell::new(Vec::new()) };
    static SHARED_PICKING_EVENTS: RefCell<Vec<PickingEventData>> = const { RefCell::new(Vec::new()) };
}

#[magnus::wrap(class = "Bevy::RenderApp", free_immediately, size)]
pub struct RubyRenderApp {
    _marker: (),
}

impl RubyRenderApp {
    fn new(args: &[Value]) -> Result<Self, Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");

        let config = if args.is_empty() {
            WindowConfig::default()
        } else {
            let hash: RHash = TryConvert::try_convert(args[0])?;
            let title: Option<String> = get_hash_value(&ruby, &hash, "title")?;
            let width: Option<f64> = get_hash_value(&ruby, &hash, "width")?;
            let height: Option<f64> = get_hash_value(&ruby, &hash, "height")?;
            let resizable: Option<bool> = get_hash_value(&ruby, &hash, "resizable")?;

            WindowConfig {
                title: title.unwrap_or_else(|| "Bevy Ruby".to_string()),
                width: width.unwrap_or(800.0) as f32,
                height: height.unwrap_or(600.0) as f32,
                resizable: resizable.unwrap_or(true),
            }
        };

        RENDER_STATE.with(|state| {
            let mut state = state.borrow_mut();
            if state.is_some() {
                return Err(Error::new(
                    ruby.exception_runtime_error(),
                    "RenderApp already exists. Only one instance is allowed.",
                ));
            }
            *state = Some(RenderState {
                render_app: RenderApp::new(config),
                sprite_sync: SpriteSync::new(),
            });
            Ok(())
        })?;

        Ok(Self { _marker: () })
    }

    fn initialize(&self) -> Result<(), Error> {
        Ok(())
    }

    fn run_with_block(&self) -> Result<(), Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");

        if !ruby.block_given() {
            return Err(Error::new(
                ruby.exception_arg_error(),
                "run requires a block",
            ));
        }

        let proc = ruby.block_proc()?;
        RUBY_CALLBACK.with(|cb| {
            *cb.borrow_mut() = Some(proc);
        });

        RENDER_STATE.with(|state| {
            let mut state = state.borrow_mut();
            if let Some(ref mut s) = *state {
                #[cfg(feature = "rendering")]
                {
                    s.render_app.set_callback(move |bridge_state| {
                        SHARED_INPUT.with(|input| {
                            *input.borrow_mut() = bridge_state.input_state.clone();
                        });
                        SHARED_PICKING_EVENTS.with(|events| {
                            *events.borrow_mut() = bridge_state.picking_events.clone();
                        });

                        RUBY_CALLBACK.with(|cb| {
                            if let Some(ref proc) = *cb.borrow() {
                                let _ = proc.call::<_, Value>(());
                            }
                        });

                        PENDING_SPRITES.with(|sprites| {
                            let mut pending = sprites.borrow_mut();
                            for op in pending.pending_operations.drain(..) {
                                bridge_state.sprite_sync.pending_operations.push(op);
                            }
                        });

                        PENDING_TEXTS.with(|texts| {
                            let mut pending = texts.borrow_mut();
                            for op in pending.pending_operations.drain(..) {
                                bridge_state.text_sync.pending_operations.push(op);
                            }
                        });

                        PENDING_MESHES.with(|meshes| {
                            let mut pending = meshes.borrow_mut();
                            for op in pending.pending_operations.drain(..) {
                                bridge_state.mesh_sync.pending_operations.push(op);
                            }
                        });

                        PENDING_GAMEPAD_RUMBLE.with(|rumbles| {
                            let mut pending = rumbles.borrow_mut();
                            for command in pending.drain(..) {
                                bridge_state.pending_gamepad_rumble.push(command);
                            }
                        });

                        let camera_dirty = CAMERA_DIRTY.with(|d| {
                            let dirty = *d.borrow();
                            *d.borrow_mut() = false;
                            dirty
                        });
                        if camera_dirty {
                            bridge_state.camera_position = CAMERA_POSITION.with(|p| *p.borrow());
                            bridge_state.camera_scale = CAMERA_SCALE.with(|s| *s.borrow());
                            bridge_state.camera_dirty = true;
                        }

                        let should_stop = SHOULD_STOP.with(|s| *s.borrow());
                        if should_stop {
                            bridge_state.should_exit = true;
                        }
                    });

                    s.render_app.run();
                }
            }
        });

        RUBY_CALLBACK.with(|cb| {
            *cb.borrow_mut() = None;
        });

        RENDER_STATE.with(|state| {
            *state.borrow_mut() = None;
        });

        Ok(())
    }

    fn stop(&self) -> Result<(), Error> {
        SHOULD_STOP.with(|s| {
            *s.borrow_mut() = true;
        });
        Ok(())
    }

    fn should_close(&self) -> bool {
        RENDER_STATE.with(|state| {
            let state = state.borrow();
            if let Some(ref s) = *state {
                s.render_app.should_exit()
            } else {
                true
            }
        })
    }

    fn key_pressed(&self, key: String) -> bool {
        SHARED_INPUT.with(|input| input.borrow().key_pressed(&key))
    }

    fn key_just_pressed(&self, key: String) -> bool {
        SHARED_INPUT.with(|input| input.borrow().key_just_pressed(&key))
    }

    fn key_just_released(&self, key: String) -> bool {
        SHARED_INPUT.with(|input| input.borrow().key_just_released(&key))
    }

    fn mouse_button_pressed(&self, button: String) -> bool {
        SHARED_INPUT.with(|input| input.borrow().mouse_button_pressed(&button))
    }

    fn mouse_button_just_pressed(&self, button: String) -> bool {
        SHARED_INPUT.with(|input| input.borrow().mouse_button_just_pressed(&button))
    }

    fn mouse_position(&self) -> RArray {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let (x, y) = SHARED_INPUT.with(|input| input.borrow().mouse_position);
        let array = ruby.ary_new_capa(2);
        let _ = array.push(x);
        let _ = array.push(y);
        array
    }

    fn mouse_delta(&self) -> RArray {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let (dx, dy) = SHARED_INPUT.with(|input| input.borrow().mouse_delta);
        let array = ruby.ary_new_capa(2);
        let _ = array.push(dx);
        let _ = array.push(dy);
        array
    }

    fn pressed_keys(&self) -> RArray {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let keys = SHARED_INPUT.with(|input| input.borrow().get_pressed_keys());
        let array = ruby.ary_new_capa(keys.len());
        for key in keys {
            let _ = array.push(key);
        }
        array
    }

    fn gamepads_state(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let mut states = SHARED_INPUT.with(|input| input.borrow().gamepad_states());
        states.sort_by_key(|state| state.id);

        let id_sym = ruby.to_symbol("id");
        let name_sym = ruby.to_symbol("name");
        let buttons_pressed_sym = ruby.to_symbol("buttons_pressed");
        let buttons_just_pressed_sym = ruby.to_symbol("buttons_just_pressed");
        let buttons_just_released_sym = ruby.to_symbol("buttons_just_released");
        let axes_sym = ruby.to_symbol("axes");

        let result = ruby.ary_new_capa(states.len());

        for state in states {
            let hash = ruby.hash_new();
            hash.aset(id_sym, state.id)?;
            hash.aset(name_sym, state.name)?;

            let mut buttons_pressed: Vec<_> = state.buttons_pressed.into_iter().collect();
            buttons_pressed.sort();
            let buttons_pressed_array = ruby.ary_new_capa(buttons_pressed.len());
            for button in buttons_pressed {
                buttons_pressed_array.push(button)?;
            }
            hash.aset(buttons_pressed_sym, buttons_pressed_array)?;

            let mut buttons_just_pressed: Vec<_> = state.buttons_just_pressed.into_iter().collect();
            buttons_just_pressed.sort();
            let buttons_just_pressed_array = ruby.ary_new_capa(buttons_just_pressed.len());
            for button in buttons_just_pressed {
                buttons_just_pressed_array.push(button)?;
            }
            hash.aset(buttons_just_pressed_sym, buttons_just_pressed_array)?;

            let mut buttons_just_released: Vec<_> =
                state.buttons_just_released.into_iter().collect();
            buttons_just_released.sort();
            let buttons_just_released_array = ruby.ary_new_capa(buttons_just_released.len());
            for button in buttons_just_released {
                buttons_just_released_array.push(button)?;
            }
            hash.aset(buttons_just_released_sym, buttons_just_released_array)?;

            let axes_hash = ruby.hash_new();
            let mut axes_entries: Vec<_> = state.axes.into_iter().collect();
            axes_entries.sort_by(|left, right| left.0.cmp(&right.0));
            for (axis, value) in axes_entries {
                axes_hash.aset(axis, value as f64)?;
            }
            hash.aset(axes_sym, axes_hash)?;

            result.push(hash)?;
        }

        Ok(result)
    }

    fn sync_sprite(
        &self,
        ruby_entity_id: u64,
        sprite_hash: RHash,
        transform_hash: RHash,
    ) -> Result<(), Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let sprite_data = parse_sprite_data(&ruby, &sprite_hash)?;
        let transform_data = parse_transform_data(&ruby, &transform_hash)?;

        PENDING_SPRITES.with(|sprites| {
            sprites.borrow_mut().sync_sprite_standalone(
                ruby_entity_id,
                &sprite_data,
                &transform_data,
            );
        });

        Ok(())
    }

    fn remove_sprite(&self, ruby_entity_id: u64) -> Result<(), Error> {
        PENDING_SPRITES.with(|sprites| {
            sprites
                .borrow_mut()
                .remove_sprite_standalone(ruby_entity_id);
        });

        Ok(())
    }

    fn clear_sprites(&self) -> Result<(), Error> {
        PENDING_SPRITES.with(|sprites| {
            sprites.borrow_mut().clear_standalone();
        });

        Ok(())
    }

    fn sync_text(
        &self,
        ruby_entity_id: u64,
        text_hash: RHash,
        transform_hash: RHash,
    ) -> Result<(), Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let text_data = parse_text_data(&ruby, &text_hash)?;
        let transform_data = parse_text_transform_data(&ruby, &transform_hash)?;

        PENDING_TEXTS.with(|texts| {
            texts
                .borrow_mut()
                .sync_text_standalone(ruby_entity_id, &text_data, &transform_data);
        });

        Ok(())
    }

    fn remove_text(&self, ruby_entity_id: u64) -> Result<(), Error> {
        PENDING_TEXTS.with(|texts| {
            texts.borrow_mut().remove_text_standalone(ruby_entity_id);
        });

        Ok(())
    }

    fn clear_texts(&self) -> Result<(), Error> {
        PENDING_TEXTS.with(|texts| {
            texts.borrow_mut().clear_standalone();
        });

        Ok(())
    }

    fn sync_mesh(
        &self,
        ruby_entity_id: u64,
        mesh_hash: RHash,
        transform_hash: RHash,
    ) -> Result<(), Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let mesh_data = parse_mesh_data(&ruby, &mesh_hash)?;
        let transform_data = parse_mesh_transform_data(&ruby, &transform_hash)?;

        PENDING_MESHES.with(|meshes| {
            meshes
                .borrow_mut()
                .sync_mesh_standalone(ruby_entity_id, &mesh_data, &transform_data);
        });

        Ok(())
    }

    fn remove_mesh(&self, ruby_entity_id: u64) -> Result<(), Error> {
        PENDING_MESHES.with(|meshes| {
            meshes.borrow_mut().remove_mesh_standalone(ruby_entity_id);
        });

        Ok(())
    }

    fn clear_meshes(&self) -> Result<(), Error> {
        PENDING_MESHES.with(|meshes| {
            meshes.borrow_mut().clear_standalone();
        });

        Ok(())
    }

    fn is_initialized(&self) -> bool {
        RENDER_STATE.with(|state| state.borrow().is_some())
    }

    fn set_camera_position(&self, x: f64, y: f64, z: f64) -> Result<(), Error> {
        CAMERA_POSITION.with(|p| {
            *p.borrow_mut() = (x as f32, y as f32, z as f32);
        });
        CAMERA_DIRTY.with(|d| {
            *d.borrow_mut() = true;
        });
        Ok(())
    }

    fn get_camera_position(&self) -> RArray {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let (x, y, z) = CAMERA_POSITION.with(|p| *p.borrow());
        let array = ruby.ary_new_capa(3);
        let _ = array.push(x as f64);
        let _ = array.push(y as f64);
        let _ = array.push(z as f64);
        array
    }

    fn set_camera_scale(&self, scale: f64) -> Result<(), Error> {
        CAMERA_SCALE.with(|s| {
            *s.borrow_mut() = scale as f32;
        });
        CAMERA_DIRTY.with(|d| {
            *d.borrow_mut() = true;
        });
        Ok(())
    }

    fn get_camera_scale(&self) -> f64 {
        CAMERA_SCALE.with(|s| *s.borrow()) as f64
    }

    fn queue_gamepad_rumble(
        &self,
        gamepad_id: u64,
        strong_motor: f64,
        weak_motor: f64,
        duration_secs: f64,
    ) -> Result<(), Error> {
        let stop = strong_motor <= 0.0 && weak_motor <= 0.0;
        let command = GamepadRumbleCommand {
            gamepad_id,
            strong_motor: strong_motor as f32,
            weak_motor: weak_motor as f32,
            duration_secs: duration_secs as f32,
            stop,
        };

        PENDING_GAMEPAD_RUMBLE.with(|rumbles| {
            rumbles.borrow_mut().push(command);
        });
        Ok(())
    }

    fn drain_picking_events(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().expect("Ruby runtime not available");
        let kind_sym = ruby.to_symbol("kind");
        let target_id_sym = ruby.to_symbol("target_id");
        let pointer_id_sym = ruby.to_symbol("pointer_id");
        let position_sym = ruby.to_symbol("position");
        let button_sym = ruby.to_symbol("button");
        let camera_id_sym = ruby.to_symbol("camera_id");
        let depth_sym = ruby.to_symbol("depth");
        let hit_position_sym = ruby.to_symbol("hit_position");
        let hit_normal_sym = ruby.to_symbol("hit_normal");

        let events = SHARED_PICKING_EVENTS.with(|picking_events| {
            let mut picking_events = picking_events.borrow_mut();
            picking_events.drain(..).collect::<Vec<_>>()
        });

        let result = ruby.ary_new_capa(events.len());

        for event in events {
            let hash = ruby.hash_new();
            hash.aset(kind_sym, event.kind)?;
            hash.aset(target_id_sym, event.target_id)?;
            hash.aset(pointer_id_sym, event.pointer_id)?;

            let position = ruby.ary_new_capa(2);
            position.push(event.pointer_position.0 as f64)?;
            position.push(event.pointer_position.1 as f64)?;
            hash.aset(position_sym, position)?;

            if let Some(button) = event.button {
                hash.aset(button_sym, button)?;
            }

            if let Some(camera_id) = event.camera_id {
                hash.aset(camera_id_sym, camera_id)?;
            }

            if let Some(depth) = event.depth {
                hash.aset(depth_sym, depth as f64)?;
            }

            if let Some((x, y, z)) = event.hit_position {
                let hit_position = ruby.ary_new_capa(3);
                hit_position.push(x as f64)?;
                hit_position.push(y as f64)?;
                hit_position.push(z as f64)?;
                hash.aset(hit_position_sym, hit_position)?;
            }

            if let Some((x, y, z)) = event.hit_normal {
                let hit_normal = ruby.ary_new_capa(3);
                hit_normal.push(x as f64)?;
                hit_normal.push(y as f64)?;
                hit_normal.push(z as f64)?;
                hash.aset(hit_normal_sym, hit_normal)?;
            }

            result.push(hash)?;
        }

        Ok(result)
    }
}

fn get_hash_value<T: TryConvert>(ruby: &Ruby, hash: &RHash, key: &str) -> Result<Option<T>, Error> {
    let sym = ruby.to_symbol(key);
    match hash.get(sym) {
        Some(val) => {
            if val.is_nil() {
                Ok(None)
            } else {
                Ok(Some(TryConvert::try_convert(val)?))
            }
        }
        None => Ok(None),
    }
}

fn parse_sprite_data(ruby: &Ruby, hash: &RHash) -> Result<SpriteData, Error> {
    let color_r: Option<f64> = get_hash_value(ruby, hash, "color_r")?;
    let color_g: Option<f64> = get_hash_value(ruby, hash, "color_g")?;
    let color_b: Option<f64> = get_hash_value(ruby, hash, "color_b")?;
    let color_a: Option<f64> = get_hash_value(ruby, hash, "color_a")?;
    let flip_x: Option<bool> = get_hash_value(ruby, hash, "flip_x")?;
    let flip_y: Option<bool> = get_hash_value(ruby, hash, "flip_y")?;
    let anchor_x: Option<f64> = get_hash_value(ruby, hash, "anchor_x")?;
    let anchor_y: Option<f64> = get_hash_value(ruby, hash, "anchor_y")?;
    let custom_size_x: Option<f64> = get_hash_value(ruby, hash, "custom_size_x")?;
    let custom_size_y: Option<f64> = get_hash_value(ruby, hash, "custom_size_y")?;

    let has_custom_size = custom_size_x.is_some() || custom_size_y.is_some();

    Ok(SpriteData {
        color_r: color_r.unwrap_or(1.0) as f32,
        color_g: color_g.unwrap_or(1.0) as f32,
        color_b: color_b.unwrap_or(1.0) as f32,
        color_a: color_a.unwrap_or(1.0) as f32,
        flip_x: flip_x.unwrap_or(false),
        flip_y: flip_y.unwrap_or(false),
        anchor_x: anchor_x.unwrap_or(0.5) as f32,
        anchor_y: anchor_y.unwrap_or(0.5) as f32,
        has_custom_size,
        custom_size_x: custom_size_x.unwrap_or(0.0) as f32,
        custom_size_y: custom_size_y.unwrap_or(0.0) as f32,
    })
}

fn parse_transform_data(ruby: &Ruby, hash: &RHash) -> Result<TransformData, Error> {
    let x: Option<f64> = get_hash_value(ruby, hash, "x")?;
    let y: Option<f64> = get_hash_value(ruby, hash, "y")?;
    let z: Option<f64> = get_hash_value(ruby, hash, "z")?;
    let rotation: Option<f64> = get_hash_value(ruby, hash, "rotation")?;
    let scale_x: Option<f64> = get_hash_value(ruby, hash, "scale_x")?;
    let scale_y: Option<f64> = get_hash_value(ruby, hash, "scale_y")?;
    let scale_z: Option<f64> = get_hash_value(ruby, hash, "scale_z")?;

    let angle = rotation.unwrap_or(0.0) as f32;
    let half_angle = angle / 2.0;
    let (sin_half, cos_half) = half_angle.sin_cos();

    Ok(TransformData {
        translation_x: x.unwrap_or(0.0) as f32,
        translation_y: y.unwrap_or(0.0) as f32,
        translation_z: z.unwrap_or(0.0) as f32,
        rotation_x: 0.0,
        rotation_y: 0.0,
        rotation_z: sin_half,
        rotation_w: cos_half,
        scale_x: scale_x.unwrap_or(1.0) as f32,
        scale_y: scale_y.unwrap_or(1.0) as f32,
        scale_z: scale_z.unwrap_or(1.0) as f32,
    })
}

fn parse_text_data(ruby: &Ruby, hash: &RHash) -> Result<TextData, Error> {
    let content: Option<String> = get_hash_value(ruby, hash, "content")?;
    let font_size: Option<f64> = get_hash_value(ruby, hash, "font_size")?;
    let color_r: Option<f64> = get_hash_value(ruby, hash, "color_r")?;
    let color_g: Option<f64> = get_hash_value(ruby, hash, "color_g")?;
    let color_b: Option<f64> = get_hash_value(ruby, hash, "color_b")?;
    let color_a: Option<f64> = get_hash_value(ruby, hash, "color_a")?;

    Ok(TextData {
        content: content.unwrap_or_default(),
        font_size: font_size.unwrap_or(24.0) as f32,
        color_r: color_r.unwrap_or(1.0) as f32,
        color_g: color_g.unwrap_or(1.0) as f32,
        color_b: color_b.unwrap_or(1.0) as f32,
        color_a: color_a.unwrap_or(1.0) as f32,
    })
}

fn parse_text_transform_data(ruby: &Ruby, hash: &RHash) -> Result<TextTransformData, Error> {
    let x: Option<f64> = get_hash_value(ruby, hash, "x")?;
    let y: Option<f64> = get_hash_value(ruby, hash, "y")?;
    let z: Option<f64> = get_hash_value(ruby, hash, "z")?;
    let scale_x: Option<f64> = get_hash_value(ruby, hash, "scale_x")?;
    let scale_y: Option<f64> = get_hash_value(ruby, hash, "scale_y")?;
    let scale_z: Option<f64> = get_hash_value(ruby, hash, "scale_z")?;

    Ok(TextTransformData {
        translation_x: x.unwrap_or(0.0) as f32,
        translation_y: y.unwrap_or(0.0) as f32,
        translation_z: z.unwrap_or(0.0) as f32,
        scale_x: scale_x.unwrap_or(1.0) as f32,
        scale_y: scale_y.unwrap_or(1.0) as f32,
        scale_z: scale_z.unwrap_or(1.0) as f32,
    })
}

fn parse_mesh_data(ruby: &Ruby, hash: &RHash) -> Result<MeshData, Error> {
    let shape_type_val: Option<i64> = get_hash_value(ruby, hash, "shape_type")?;
    let shape_type = match shape_type_val.unwrap_or(0) {
        0 => ShapeType::Rectangle,
        1 => ShapeType::Circle,
        2 => ShapeType::RegularPolygon,
        3 => ShapeType::Line,
        4 => ShapeType::Ellipse,
        _ => ShapeType::Rectangle,
    };

    let color_r: Option<f64> = get_hash_value(ruby, hash, "color_r")?;
    let color_g: Option<f64> = get_hash_value(ruby, hash, "color_g")?;
    let color_b: Option<f64> = get_hash_value(ruby, hash, "color_b")?;
    let color_a: Option<f64> = get_hash_value(ruby, hash, "color_a")?;
    let width: Option<f64> = get_hash_value(ruby, hash, "width")?;
    let height: Option<f64> = get_hash_value(ruby, hash, "height")?;
    let radius: Option<f64> = get_hash_value(ruby, hash, "radius")?;
    let sides: Option<i64> = get_hash_value(ruby, hash, "sides")?;
    let line_start_x: Option<f64> = get_hash_value(ruby, hash, "line_start_x")?;
    let line_start_y: Option<f64> = get_hash_value(ruby, hash, "line_start_y")?;
    let line_end_x: Option<f64> = get_hash_value(ruby, hash, "line_end_x")?;
    let line_end_y: Option<f64> = get_hash_value(ruby, hash, "line_end_y")?;
    let thickness: Option<f64> = get_hash_value(ruby, hash, "thickness")?;
    let fill: Option<bool> = get_hash_value(ruby, hash, "fill")?;

    Ok(MeshData {
        shape_type,
        color_r: color_r.unwrap_or(1.0) as f32,
        color_g: color_g.unwrap_or(1.0) as f32,
        color_b: color_b.unwrap_or(1.0) as f32,
        color_a: color_a.unwrap_or(1.0) as f32,
        width: width.unwrap_or(100.0) as f32,
        height: height.unwrap_or(100.0) as f32,
        radius: radius.unwrap_or(50.0) as f32,
        sides: sides.unwrap_or(6) as u32,
        line_start_x: line_start_x.unwrap_or(0.0) as f32,
        line_start_y: line_start_y.unwrap_or(0.0) as f32,
        line_end_x: line_end_x.unwrap_or(100.0) as f32,
        line_end_y: line_end_y.unwrap_or(0.0) as f32,
        thickness: thickness.unwrap_or(2.0) as f32,
        fill: fill.unwrap_or(true),
    })
}

fn parse_mesh_transform_data(ruby: &Ruby, hash: &RHash) -> Result<MeshTransformData, Error> {
    let x: Option<f64> = get_hash_value(ruby, hash, "x")?;
    let y: Option<f64> = get_hash_value(ruby, hash, "y")?;
    let z: Option<f64> = get_hash_value(ruby, hash, "z")?;
    let rotation: Option<f64> = get_hash_value(ruby, hash, "rotation")?;
    let scale_x: Option<f64> = get_hash_value(ruby, hash, "scale_x")?;
    let scale_y: Option<f64> = get_hash_value(ruby, hash, "scale_y")?;
    let scale_z: Option<f64> = get_hash_value(ruby, hash, "scale_z")?;

    let angle = rotation.unwrap_or(0.0) as f32;
    let half_angle = angle / 2.0;
    let (sin_half, cos_half) = half_angle.sin_cos();

    Ok(MeshTransformData {
        translation_x: x.unwrap_or(0.0) as f32,
        translation_y: y.unwrap_or(0.0) as f32,
        translation_z: z.unwrap_or(0.0) as f32,
        rotation_x: 0.0,
        rotation_y: 0.0,
        rotation_z: sin_half,
        rotation_w: cos_half,
        scale_x: scale_x.unwrap_or(1.0) as f32,
        scale_y: scale_y.unwrap_or(1.0) as f32,
        scale_z: scale_z.unwrap_or(1.0) as f32,
    })
}

pub fn define(ruby: &Ruby, module: &magnus::RModule) -> Result<(), Error> {
    let class = module.define_class("RenderApp", ruby.class_object())?;

    class.define_singleton_method("new", function!(RubyRenderApp::new, -1))?;
    class.define_method("initialize!", method!(RubyRenderApp::initialize, 0))?;
    class.define_method("run", method!(RubyRenderApp::run_with_block, 0))?;
    class.define_method("stop!", method!(RubyRenderApp::stop, 0))?;
    class.define_method("should_close?", method!(RubyRenderApp::should_close, 0))?;
    class.define_method("initialized?", method!(RubyRenderApp::is_initialized, 0))?;

    class.define_method("key_pressed?", method!(RubyRenderApp::key_pressed, 1))?;
    class.define_method(
        "key_just_pressed?",
        method!(RubyRenderApp::key_just_pressed, 1),
    )?;
    class.define_method(
        "key_just_released?",
        method!(RubyRenderApp::key_just_released, 1),
    )?;
    class.define_method(
        "mouse_button_pressed?",
        method!(RubyRenderApp::mouse_button_pressed, 1),
    )?;
    class.define_method(
        "mouse_button_just_pressed?",
        method!(RubyRenderApp::mouse_button_just_pressed, 1),
    )?;
    class.define_method("mouse_position", method!(RubyRenderApp::mouse_position, 0))?;
    class.define_method("mouse_delta", method!(RubyRenderApp::mouse_delta, 0))?;
    class.define_method("pressed_keys", method!(RubyRenderApp::pressed_keys, 0))?;
    class.define_method("gamepads_state", method!(RubyRenderApp::gamepads_state, 0))?;

    class.define_method("sync_sprite", method!(RubyRenderApp::sync_sprite, 3))?;
    class.define_method("remove_sprite", method!(RubyRenderApp::remove_sprite, 1))?;
    class.define_method("clear_sprites", method!(RubyRenderApp::clear_sprites, 0))?;

    class.define_method("sync_text", method!(RubyRenderApp::sync_text, 3))?;
    class.define_method("remove_text", method!(RubyRenderApp::remove_text, 1))?;
    class.define_method("clear_texts", method!(RubyRenderApp::clear_texts, 0))?;

    class.define_method("sync_mesh", method!(RubyRenderApp::sync_mesh, 3))?;
    class.define_method("remove_mesh", method!(RubyRenderApp::remove_mesh, 1))?;
    class.define_method("clear_meshes", method!(RubyRenderApp::clear_meshes, 0))?;

    class.define_method(
        "set_camera_position",
        method!(RubyRenderApp::set_camera_position, 3),
    )?;
    class.define_method(
        "camera_position",
        method!(RubyRenderApp::get_camera_position, 0),
    )?;
    class.define_method(
        "set_camera_scale",
        method!(RubyRenderApp::set_camera_scale, 1),
    )?;
    class.define_method("camera_scale", method!(RubyRenderApp::get_camera_scale, 0))?;
    class.define_method(
        "queue_gamepad_rumble",
        method!(RubyRenderApp::queue_gamepad_rumble, 4),
    )?;
    class.define_method(
        "drain_picking_events",
        method!(RubyRenderApp::drain_picking_events, 0),
    )?;

    Ok(())
}
