//! RenderApp module for managing the Bevy rendering application.

#[cfg(feature = "rendering")]
use bevy_a11y::AccessibilityPlugin;
#[cfg(feature = "rendering")]
use bevy_app::{App, AppExit, Startup, Update};
#[cfg(feature = "rendering")]
use bevy_asset::AssetPlugin;
#[cfg(feature = "rendering")]
use bevy_core::{FrameCountPlugin, Name, TaskPoolPlugin, TypeRegistrationPlugin};
#[cfg(feature = "rendering")]
use bevy_core_pipeline::CorePipelinePlugin;
#[cfg(feature = "rendering")]
use bevy_core_pipeline::core_2d::Camera2d;
#[cfg(feature = "rendering")]
use bevy_ecs::event::{EventReader, EventWriter};
#[cfg(feature = "rendering")]
use bevy_ecs::system::{Commands, Res};
#[cfg(feature = "rendering")]
use bevy_ecs::world::World;
#[cfg(feature = "rendering")]
use bevy_hierarchy::HierarchyPlugin;
#[cfg(feature = "rendering")]
use bevy_input::gamepad::{
    Gamepad, GamepadAxis, GamepadButton, GamepadRumbleIntensity, GamepadRumbleRequest,
};
#[cfg(feature = "rendering")]
use bevy_input::keyboard::KeyCode;
#[cfg(feature = "rendering")]
use bevy_input::mouse::MouseButton;
#[cfg(feature = "rendering")]
use bevy_input::{ButtonInput, InputPlugin};
#[cfg(feature = "rendering")]
use bevy_log::LogPlugin;
#[cfg(feature = "rendering")]
use bevy_picking::{
    DefaultPickingPlugins,
    events::{Click, Down, Out, Over, Pointer, Up},
    pointer::{PointerButton, PointerId},
};
#[cfg(feature = "rendering")]
use bevy_render::RenderPlugin;
#[cfg(feature = "rendering")]
use bevy_render::camera::Camera;
#[cfg(feature = "rendering")]
use bevy_render::prelude::ImagePlugin;
#[cfg(feature = "rendering")]
use bevy_sprite::SpritePlugin;
#[cfg(feature = "rendering")]
use bevy_text::TextPlugin;
#[cfg(feature = "rendering")]
use bevy_time::TimePlugin;
#[cfg(feature = "rendering")]
use bevy_transform::TransformPlugin;
#[cfg(feature = "rendering")]
use bevy_transform::components::Transform;
#[cfg(feature = "rendering")]
use bevy_window::{Window, WindowPlugin};
#[cfg(feature = "rendering")]
use bevy_winit::{WakeUp, WinitPlugin};
#[cfg(feature = "rendering")]
use std::sync::Arc;
#[cfg(feature = "rendering")]
use std::sync::Mutex;

/// Window configuration for the render application.
#[derive(Debug, Clone)]
pub struct WindowConfig {
    pub title: String,
    pub width: f32,
    pub height: f32,
    pub resizable: bool,
}

impl Default for WindowConfig {
    fn default() -> Self {
        Self {
            title: "Bevy Ruby".to_string(),
            width: 800.0,
            height: 600.0,
            resizable: true,
        }
    }
}

use crate::{DefaultSpriteTexture, InputState, MeshSync, SpriteSync, TextSync};

#[cfg(feature = "rendering")]
type UpdateCallback = Arc<Mutex<Option<Box<dyn FnMut(&mut RubyBridgeState) + Send>>>>;

#[cfg(feature = "rendering")]
#[derive(bevy_ecs::system::Resource)]
pub struct RubyBridge {
    pub callback: UpdateCallback,
    pub state: Arc<Mutex<RubyBridgeState>>,
}

#[cfg(feature = "rendering")]
pub struct RubyBridgeState {
    pub input_state: InputState,
    pub sprite_sync: SpriteSync,
    pub text_sync: TextSync,
    pub mesh_sync: MeshSync,
    pub pending_gamepad_rumble: Vec<GamepadRumbleCommand>,
    pub picking_events: Vec<PickingEventData>,
    pub should_exit: bool,
    pub world_access: Option<*mut World>,
    pub camera_position: (f32, f32, f32),
    pub camera_scale: f32,
    pub camera_dirty: bool,
}

#[cfg(feature = "rendering")]
#[derive(Debug, Clone, Copy)]
pub struct GamepadRumbleCommand {
    pub gamepad_id: u64,
    pub strong_motor: f32,
    pub weak_motor: f32,
    pub duration_secs: f32,
    pub stop: bool,
}

#[cfg(feature = "rendering")]
#[derive(Debug, Clone)]
pub struct PickingEventData {
    pub kind: String,
    pub target_id: u64,
    pub pointer_id: String,
    pub pointer_position: (f32, f32),
    pub button: Option<String>,
    pub camera_id: Option<u64>,
    pub depth: Option<f32>,
    pub hit_position: Option<(f32, f32, f32)>,
    pub hit_normal: Option<(f32, f32, f32)>,
}

#[cfg(feature = "rendering")]
unsafe impl Send for RubyBridgeState {}
#[cfg(feature = "rendering")]
unsafe impl Sync for RubyBridgeState {}

#[cfg(feature = "rendering")]
impl Default for RubyBridgeState {
    fn default() -> Self {
        Self {
            input_state: InputState::new(),
            sprite_sync: SpriteSync::new(),
            text_sync: TextSync::new(),
            mesh_sync: MeshSync::new(),
            pending_gamepad_rumble: Vec::new(),
            picking_events: Vec::new(),
            should_exit: false,
            world_access: None,
            camera_position: (0.0, 0.0, 0.0),
            camera_scale: 1.0,
            camera_dirty: false,
        }
    }
}

#[cfg(feature = "rendering")]
fn spawn_camera_2d_system(mut commands: Commands) {
    commands.spawn((Camera::default(), Camera2d::default(), Transform::default()));
}

#[cfg(feature = "rendering")]
fn setup_default_sprite_texture_system(world: &mut World) {
    DefaultSpriteTexture::insert_into_world(world);
}

#[cfg(feature = "rendering")]
fn ruby_bridge_system(
    bridge: Res<RubyBridge>,
    keyboard: Res<ButtonInput<KeyCode>>,
    mouse_buttons: Res<ButtonInput<MouseButton>>,
    windows: bevy_ecs::system::Query<&Window>,
    gamepad_query: bevy_ecs::system::Query<(bevy_ecs::entity::Entity, Option<&Name>, &Gamepad)>,
    mut over_events: EventReader<Pointer<Over>>,
    mut out_events: EventReader<Pointer<Out>>,
    mut down_events: EventReader<Pointer<Down>>,
    mut up_events: EventReader<Pointer<Up>>,
    mut click_events: EventReader<Pointer<Click>>,
    mut gamepad_rumble_requests: EventWriter<GamepadRumbleRequest>,
    mut exit_writer: EventWriter<AppExit>,
) {
    let mut state = bridge.state.lock().unwrap();

    state.input_state.clear();

    for key in keyboard.get_pressed() {
        if let Some(key_name) = keycode_to_string(*key) {
            state.input_state.set_pressed(&key_name);
        }
    }

    for key in keyboard.get_just_pressed() {
        if let Some(key_name) = keycode_to_string(*key) {
            state.input_state.set_just_pressed(&key_name);
        }
    }

    for key in keyboard.get_just_released() {
        if let Some(key_name) = keycode_to_string(*key) {
            state.input_state.set_just_released(&key_name);
        }
    }

    if mouse_buttons.pressed(MouseButton::Left) {
        state.input_state.set_mouse_pressed("LEFT");
    }
    if mouse_buttons.pressed(MouseButton::Right) {
        state.input_state.set_mouse_pressed("RIGHT");
    }
    if mouse_buttons.pressed(MouseButton::Middle) {
        state.input_state.set_mouse_pressed("MIDDLE");
    }

    if mouse_buttons.just_pressed(MouseButton::Left) {
        state.input_state.set_mouse_just_pressed("LEFT");
    }
    if mouse_buttons.just_pressed(MouseButton::Right) {
        state.input_state.set_mouse_just_pressed("RIGHT");
    }
    if mouse_buttons.just_pressed(MouseButton::Middle) {
        state.input_state.set_mouse_just_pressed("MIDDLE");
    }

    for (entity, maybe_name, gamepad) in gamepad_query.iter() {
        let id = entity.to_bits();
        let gamepad_name = maybe_name
            .map(|name| name.as_str().to_string())
            .unwrap_or_else(|| format!("Gamepad {}", id));

        state.input_state.set_gamepad_connected(id, &gamepad_name);

        for button in gamepad.get_pressed() {
            let button_name = gamepad_button_to_string(*button);
            state
                .input_state
                .set_gamepad_button_pressed(id, &button_name);
        }

        for button in gamepad.get_just_pressed() {
            let button_name = gamepad_button_to_string(*button);
            state
                .input_state
                .set_gamepad_button_just_pressed(id, &button_name);
        }

        for button in gamepad.get_just_released() {
            let button_name = gamepad_button_to_string(*button);
            state
                .input_state
                .set_gamepad_button_just_released(id, &button_name);
        }

        for axis in GamepadAxis::all() {
            let axis_name = gamepad_axis_to_string(axis);
            let axis_value = gamepad.get(axis).unwrap_or(0.0);
            state
                .input_state
                .set_gamepad_axis(id, &axis_name, axis_value);
        }
    }

    if let Ok(window) = windows.get_single() {
        if let Some(pos) = window.cursor_position() {
            let center_x = window.width() / 2.0;
            let center_y = window.height() / 2.0;
            state.input_state.mouse_position = (pos.x - center_x, center_y - pos.y);
        }
    }

    state.picking_events.clear();

    for event in over_events.read() {
        let hit = &event.event.hit;
        state.picking_events.push(PickingEventData {
            kind: "over".to_string(),
            target_id: event.target.to_bits(),
            pointer_id: pointer_id_to_string(event.pointer_id),
            pointer_position: (
                event.pointer_location.position.x,
                event.pointer_location.position.y,
            ),
            button: None,
            camera_id: Some(hit.camera.to_bits()),
            depth: Some(hit.depth),
            hit_position: hit
                .position
                .map(|position| (position.x, position.y, position.z)),
            hit_normal: hit.normal.map(|normal| (normal.x, normal.y, normal.z)),
        });
    }

    for event in out_events.read() {
        let hit = &event.event.hit;
        state.picking_events.push(PickingEventData {
            kind: "out".to_string(),
            target_id: event.target.to_bits(),
            pointer_id: pointer_id_to_string(event.pointer_id),
            pointer_position: (
                event.pointer_location.position.x,
                event.pointer_location.position.y,
            ),
            button: None,
            camera_id: Some(hit.camera.to_bits()),
            depth: Some(hit.depth),
            hit_position: hit
                .position
                .map(|position| (position.x, position.y, position.z)),
            hit_normal: hit.normal.map(|normal| (normal.x, normal.y, normal.z)),
        });
    }

    for event in down_events.read() {
        let hit = &event.event.hit;
        state.picking_events.push(PickingEventData {
            kind: "down".to_string(),
            target_id: event.target.to_bits(),
            pointer_id: pointer_id_to_string(event.pointer_id),
            pointer_position: (
                event.pointer_location.position.x,
                event.pointer_location.position.y,
            ),
            button: Some(pointer_button_to_string(event.event.button).to_string()),
            camera_id: Some(hit.camera.to_bits()),
            depth: Some(hit.depth),
            hit_position: hit
                .position
                .map(|position| (position.x, position.y, position.z)),
            hit_normal: hit.normal.map(|normal| (normal.x, normal.y, normal.z)),
        });
    }

    for event in up_events.read() {
        let hit = &event.event.hit;
        state.picking_events.push(PickingEventData {
            kind: "up".to_string(),
            target_id: event.target.to_bits(),
            pointer_id: pointer_id_to_string(event.pointer_id),
            pointer_position: (
                event.pointer_location.position.x,
                event.pointer_location.position.y,
            ),
            button: Some(pointer_button_to_string(event.event.button).to_string()),
            camera_id: Some(hit.camera.to_bits()),
            depth: Some(hit.depth),
            hit_position: hit
                .position
                .map(|position| (position.x, position.y, position.z)),
            hit_normal: hit.normal.map(|normal| (normal.x, normal.y, normal.z)),
        });
    }

    for event in click_events.read() {
        let hit = &event.event.hit;
        state.picking_events.push(PickingEventData {
            kind: "click".to_string(),
            target_id: event.target.to_bits(),
            pointer_id: pointer_id_to_string(event.pointer_id),
            pointer_position: (
                event.pointer_location.position.x,
                event.pointer_location.position.y,
            ),
            button: Some(pointer_button_to_string(event.event.button).to_string()),
            camera_id: Some(hit.camera.to_bits()),
            depth: Some(hit.depth),
            hit_position: hit
                .position
                .map(|position| (position.x, position.y, position.z)),
            hit_normal: hit.normal.map(|normal| (normal.x, normal.y, normal.z)),
        });
    }

    drop(state);

    if let Ok(mut callback) = bridge.callback.lock() {
        if let Some(ref mut cb) = *callback {
            let mut state = bridge.state.lock().unwrap();
            cb(&mut state);
        }
    }

    let mut state = bridge.state.lock().unwrap();
    for command in state.pending_gamepad_rumble.drain(..) {
        let gamepad = bevy_ecs::entity::Entity::from_bits(command.gamepad_id);
        if command.stop || (command.strong_motor <= 0.0 && command.weak_motor <= 0.0) {
            gamepad_rumble_requests.send(GamepadRumbleRequest::Stop { gamepad });
            continue;
        }

        gamepad_rumble_requests.send(GamepadRumbleRequest::Add {
            gamepad,
            intensity: GamepadRumbleIntensity {
                strong_motor: command.strong_motor.clamp(0.0, 1.0),
                weak_motor: command.weak_motor.clamp(0.0, 1.0),
            },
            duration: std::time::Duration::from_secs_f32(command.duration_secs.max(0.0)),
        });
    }

    if state.should_exit {
        exit_writer.send(AppExit::Success);
    }
}

#[cfg(feature = "rendering")]
fn sprite_sync_system(world: &mut World) {
    let state_arc = {
        let bridge = world.resource::<RubyBridge>();
        bridge.state.clone()
    };

    let mut state = state_arc.lock().unwrap();
    state.sprite_sync.apply_pending(world);
}

#[cfg(feature = "rendering")]
fn text_sync_system(world: &mut World) {
    let state_arc = {
        let bridge = world.resource::<RubyBridge>();
        bridge.state.clone()
    };

    let mut state = state_arc.lock().unwrap();
    state.text_sync.apply_pending(world);
}

#[cfg(feature = "rendering")]
fn mesh_sync_system(world: &mut World) {
    let state_arc = {
        let bridge = world.resource::<RubyBridge>();
        bridge.state.clone()
    };

    let mut state = state_arc.lock().unwrap();
    state.mesh_sync.apply_pending(world);
}

#[cfg(feature = "rendering")]
fn camera_sync_system(
    bridge: Res<RubyBridge>,
    mut query: bevy_ecs::system::Query<&mut Transform, bevy_ecs::query::With<Camera2d>>,
) {
    let mut state = bridge.state.lock().unwrap();
    if !state.camera_dirty {
        return;
    }

    for mut transform in query.iter_mut() {
        transform.translation.x = state.camera_position.0;
        transform.translation.y = state.camera_position.1;
        transform.translation.z = state.camera_position.2;
        transform.scale.x = state.camera_scale;
        transform.scale.y = state.camera_scale;
    }

    state.camera_dirty = false;
}

#[cfg(feature = "rendering")]
fn keycode_to_string(key: KeyCode) -> Option<String> {
    match key {
        KeyCode::KeyA => Some("A".to_string()),
        KeyCode::KeyB => Some("B".to_string()),
        KeyCode::KeyC => Some("C".to_string()),
        KeyCode::KeyD => Some("D".to_string()),
        KeyCode::KeyE => Some("E".to_string()),
        KeyCode::KeyF => Some("F".to_string()),
        KeyCode::KeyG => Some("G".to_string()),
        KeyCode::KeyH => Some("H".to_string()),
        KeyCode::KeyI => Some("I".to_string()),
        KeyCode::KeyJ => Some("J".to_string()),
        KeyCode::KeyK => Some("K".to_string()),
        KeyCode::KeyL => Some("L".to_string()),
        KeyCode::KeyM => Some("M".to_string()),
        KeyCode::KeyN => Some("N".to_string()),
        KeyCode::KeyO => Some("O".to_string()),
        KeyCode::KeyP => Some("P".to_string()),
        KeyCode::KeyQ => Some("Q".to_string()),
        KeyCode::KeyR => Some("R".to_string()),
        KeyCode::KeyS => Some("S".to_string()),
        KeyCode::KeyT => Some("T".to_string()),
        KeyCode::KeyU => Some("U".to_string()),
        KeyCode::KeyV => Some("V".to_string()),
        KeyCode::KeyW => Some("W".to_string()),
        KeyCode::KeyX => Some("X".to_string()),
        KeyCode::KeyY => Some("Y".to_string()),
        KeyCode::KeyZ => Some("Z".to_string()),
        KeyCode::Digit0 => Some("0".to_string()),
        KeyCode::Digit1 => Some("1".to_string()),
        KeyCode::Digit2 => Some("2".to_string()),
        KeyCode::Digit3 => Some("3".to_string()),
        KeyCode::Digit4 => Some("4".to_string()),
        KeyCode::Digit5 => Some("5".to_string()),
        KeyCode::Digit6 => Some("6".to_string()),
        KeyCode::Digit7 => Some("7".to_string()),
        KeyCode::Digit8 => Some("8".to_string()),
        KeyCode::Digit9 => Some("9".to_string()),
        KeyCode::Space => Some("SPACE".to_string()),
        KeyCode::Enter => Some("ENTER".to_string()),
        KeyCode::Escape => Some("ESCAPE".to_string()),
        KeyCode::ArrowUp => Some("UP".to_string()),
        KeyCode::ArrowDown => Some("DOWN".to_string()),
        KeyCode::ArrowLeft => Some("LEFT".to_string()),
        KeyCode::ArrowRight => Some("RIGHT".to_string()),
        KeyCode::ShiftLeft | KeyCode::ShiftRight => Some("SHIFT".to_string()),
        KeyCode::ControlLeft | KeyCode::ControlRight => Some("CONTROL".to_string()),
        KeyCode::AltLeft | KeyCode::AltRight => Some("ALT".to_string()),
        KeyCode::Tab => Some("TAB".to_string()),
        KeyCode::Backspace => Some("BACKSPACE".to_string()),
        _ => None,
    }
}

#[cfg(feature = "rendering")]
fn gamepad_button_to_string(button: GamepadButton) -> String {
    match button {
        GamepadButton::South => "South".to_string(),
        GamepadButton::East => "East".to_string(),
        GamepadButton::North => "North".to_string(),
        GamepadButton::West => "West".to_string(),
        GamepadButton::C => "C".to_string(),
        GamepadButton::Z => "Z".to_string(),
        GamepadButton::LeftTrigger => "LeftTrigger".to_string(),
        GamepadButton::LeftTrigger2 => "LeftTrigger2".to_string(),
        GamepadButton::RightTrigger => "RightTrigger".to_string(),
        GamepadButton::RightTrigger2 => "RightTrigger2".to_string(),
        GamepadButton::Select => "Select".to_string(),
        GamepadButton::Start => "Start".to_string(),
        GamepadButton::Mode => "Mode".to_string(),
        GamepadButton::LeftThumb => "LeftThumb".to_string(),
        GamepadButton::RightThumb => "RightThumb".to_string(),
        GamepadButton::DPadUp => "DPadUp".to_string(),
        GamepadButton::DPadDown => "DPadDown".to_string(),
        GamepadButton::DPadLeft => "DPadLeft".to_string(),
        GamepadButton::DPadRight => "DPadRight".to_string(),
        GamepadButton::Other(id) => format!("Other({})", id),
    }
}

#[cfg(feature = "rendering")]
fn gamepad_axis_to_string(axis: GamepadAxis) -> String {
    match axis {
        GamepadAxis::LeftStickX => "LeftStickX".to_string(),
        GamepadAxis::LeftStickY => "LeftStickY".to_string(),
        GamepadAxis::LeftZ => "LeftZ".to_string(),
        GamepadAxis::RightStickX => "RightStickX".to_string(),
        GamepadAxis::RightStickY => "RightStickY".to_string(),
        GamepadAxis::RightZ => "RightZ".to_string(),
        GamepadAxis::Other(id) => format!("Other({})", id),
    }
}

#[cfg(feature = "rendering")]
fn pointer_id_to_string(pointer_id: PointerId) -> String {
    match pointer_id {
        PointerId::Mouse => "Mouse".to_string(),
        PointerId::Touch(id) => format!("Touch({})", id),
        PointerId::Custom(id) => format!("Custom({})", id),
    }
}

#[cfg(feature = "rendering")]
fn pointer_button_to_string(button: PointerButton) -> &'static str {
    match button {
        PointerButton::Primary => "Primary",
        PointerButton::Secondary => "Secondary",
        PointerButton::Middle => "Middle",
    }
}

#[cfg(feature = "rendering")]
pub struct RenderApp {
    app: App,
    bridge: Arc<Mutex<RubyBridgeState>>,
    callback: UpdateCallback,
}

#[cfg(feature = "rendering")]
impl RenderApp {
    pub fn new(config: WindowConfig) -> Self {
        let mut app = App::new();

        app.add_plugins((
            LogPlugin::default(),
            TaskPoolPlugin::default(),
            TypeRegistrationPlugin::default(),
            FrameCountPlugin::default(),
            TimePlugin::default(),
            TransformPlugin::default(),
            HierarchyPlugin::default(),
            InputPlugin::default(),
        ));

        app.add_plugins((
            WindowPlugin {
                primary_window: Some(Window {
                    title: config.title,
                    resolution: (config.width, config.height).into(),
                    resizable: config.resizable,
                    ..Default::default()
                }),
                ..Default::default()
            },
            AccessibilityPlugin,
            AssetPlugin::default(),
            WinitPlugin::<WakeUp>::default(),
        ));

        app.add_plugins((
            RenderPlugin::default(),
            ImagePlugin::default(),
            CorePipelinePlugin::default(),
            DefaultPickingPlugins,
            SpritePlugin::default(),
            TextPlugin::default(),
            bevy_prototype_lyon::prelude::ShapePlugin,
        ));

        let bridge_state = Arc::new(Mutex::new(RubyBridgeState::default()));
        let callback: UpdateCallback = Arc::new(Mutex::new(None));

        let bridge = RubyBridge {
            callback: callback.clone(),
            state: bridge_state.clone(),
        };

        app.insert_resource(bridge);
        app.add_systems(Startup, spawn_camera_2d_system);
        app.add_systems(Startup, setup_default_sprite_texture_system);
        app.add_systems(Update, ruby_bridge_system);
        app.add_systems(Update, sprite_sync_system);
        app.add_systems(Update, text_sync_system);
        app.add_systems(Update, mesh_sync_system);
        app.add_systems(Update, camera_sync_system);

        Self {
            app,
            bridge: bridge_state,
            callback,
        }
    }

    pub fn set_callback<F>(&mut self, callback: F)
    where
        F: FnMut(&mut RubyBridgeState) + Send + 'static,
    {
        let mut cb = self.callback.lock().unwrap();
        *cb = Some(Box::new(callback));
    }

    pub fn run(&mut self) {
        self.app.run();
    }

    pub fn bridge_state(&self) -> Arc<Mutex<RubyBridgeState>> {
        self.bridge.clone()
    }

    pub fn should_exit(&self) -> bool {
        self.bridge.lock().map(|s| s.should_exit).unwrap_or(false)
    }

    pub fn is_initialized(&self) -> bool {
        true
    }
}

#[cfg(not(feature = "rendering"))]
pub struct RenderApp;

#[cfg(not(feature = "rendering"))]
impl RenderApp {
    pub fn new(_config: WindowConfig) -> Self {
        Self
    }

    pub fn run(&mut self) {}

    pub fn should_exit(&self) -> bool {
        false
    }

    pub fn is_initialized(&self) -> bool {
        false
    }
}
