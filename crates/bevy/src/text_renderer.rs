//! Text renderer module for synchronizing Ruby text entities with Bevy.

use std::collections::HashMap;

#[cfg(feature = "rendering")]
use bevy_color::Color;
#[cfg(feature = "rendering")]
use bevy_ecs::entity::Entity;
#[cfg(feature = "rendering")]
use bevy_ecs::world::World;
#[cfg(feature = "rendering")]
use bevy_render::view::{InheritedVisibility, ViewVisibility, Visibility};
#[cfg(feature = "rendering")]
use bevy_text::{Text2d, TextColor, TextFont};
#[cfg(feature = "rendering")]
use bevy_transform::components::{GlobalTransform, Transform};

#[derive(Debug, Clone)]
pub struct TextData {
    pub content: String,
    pub font_size: f32,
    pub color_r: f32,
    pub color_g: f32,
    pub color_b: f32,
    pub color_a: f32,
}

impl Default for TextData {
    fn default() -> Self {
        Self {
            content: String::new(),
            font_size: 24.0,
            color_r: 1.0,
            color_g: 1.0,
            color_b: 1.0,
            color_a: 1.0,
        }
    }
}

#[derive(Debug, Clone)]
pub struct TextTransformData {
    pub translation_x: f32,
    pub translation_y: f32,
    pub translation_z: f32,
    pub scale_x: f32,
    pub scale_y: f32,
    pub scale_z: f32,
}

impl Default for TextTransformData {
    fn default() -> Self {
        Self {
            translation_x: 0.0,
            translation_y: 0.0,
            translation_z: 0.0,
            scale_x: 1.0,
            scale_y: 1.0,
            scale_z: 1.0,
        }
    }
}

#[derive(Debug, Clone)]
pub enum TextOperation {
    Sync {
        ruby_entity_id: u64,
        text_data: TextData,
        transform_data: TextTransformData,
    },
    Remove {
        ruby_entity_id: u64,
    },
    Clear,
}

pub struct TextSync {
    entity_map: HashMap<u64, TextEntityData>,
    pub pending_operations: Vec<TextOperation>,
}

struct TextEntityData {
    #[cfg(feature = "rendering")]
    bevy_entity: Entity,
    #[cfg(not(feature = "rendering"))]
    _phantom: (),
}

impl TextSync {
    pub fn new() -> Self {
        Self {
            entity_map: HashMap::new(),
            pending_operations: Vec::new(),
        }
    }

    pub fn sync_text_standalone(
        &mut self,
        ruby_entity_id: u64,
        text_data: &TextData,
        transform_data: &TextTransformData,
    ) {
        self.pending_operations.push(TextOperation::Sync {
            ruby_entity_id,
            text_data: text_data.clone(),
            transform_data: transform_data.clone(),
        });
    }

    pub fn remove_text_standalone(&mut self, ruby_entity_id: u64) {
        self.pending_operations
            .push(TextOperation::Remove { ruby_entity_id });
    }

    pub fn clear_standalone(&mut self) {
        self.pending_operations.push(TextOperation::Clear);
    }

    #[cfg(feature = "rendering")]
    pub fn apply_pending(&mut self, world: &mut World) {
        let ops: Vec<_> = self.pending_operations.drain(..).collect();
        for op in ops {
            match op {
                TextOperation::Sync {
                    ruby_entity_id,
                    text_data,
                    transform_data,
                } => {
                    self.sync_text(world, ruby_entity_id, &text_data, &transform_data);
                }
                TextOperation::Remove { ruby_entity_id } => {
                    self.remove_text(world, ruby_entity_id);
                }
                TextOperation::Clear => {
                    self.clear(world);
                }
            }
        }
    }

    #[cfg(not(feature = "rendering"))]
    pub fn apply_pending(&mut self, _world: &mut ()) {
        self.pending_operations.clear();
    }

    #[cfg(feature = "rendering")]
    pub fn sync_text(
        &mut self,
        world: &mut World,
        ruby_entity_id: u64,
        text_data: &TextData,
        transform_data: &TextTransformData,
    ) {
        let color = Color::srgba(
            text_data.color_r,
            text_data.color_g,
            text_data.color_b,
            text_data.color_a,
        );

        let transform = Transform {
            translation: bevy_math::Vec3::new(
                transform_data.translation_x,
                transform_data.translation_y,
                transform_data.translation_z,
            ),
            rotation: bevy_math::Quat::IDENTITY,
            scale: bevy_math::Vec3::new(
                transform_data.scale_x,
                transform_data.scale_y,
                transform_data.scale_z,
            ),
        };

        if let Some(entity_data) = self.entity_map.get(&ruby_entity_id) {
            let bevy_entity = entity_data.bevy_entity;

            if let Some(mut text) = world.get_mut::<Text2d>(bevy_entity) {
                **text = text_data.content.clone();
            }

            if let Some(mut text_color) = world.get_mut::<TextColor>(bevy_entity) {
                text_color.0 = color;
            }

            if let Some(mut font) = world.get_mut::<TextFont>(bevy_entity) {
                font.font_size = text_data.font_size;
            }

            if let Some(mut t) = world.get_mut::<Transform>(bevy_entity) {
                *t = transform;
            }
        } else {
            let bevy_entity = world
                .spawn((
                    Text2d::new(text_data.content.clone()),
                    TextFont {
                        font_size: text_data.font_size,
                        ..Default::default()
                    },
                    TextColor(color),
                    transform,
                    GlobalTransform::default(),
                    Visibility::default(),
                    InheritedVisibility::default(),
                    ViewVisibility::default(),
                ))
                .id();

            self.entity_map
                .insert(ruby_entity_id, TextEntityData { bevy_entity });
        }
    }

    #[cfg(feature = "rendering")]
    pub fn remove_text(&mut self, world: &mut World, ruby_entity_id: u64) {
        if let Some(entity_data) = self.entity_map.remove(&ruby_entity_id) {
            world.despawn(entity_data.bevy_entity);
        }
    }

    #[cfg(feature = "rendering")]
    pub fn clear(&mut self, world: &mut World) {
        for (_, entity_data) in self.entity_map.drain() {
            world.despawn(entity_data.bevy_entity);
        }
    }

    pub fn len(&self) -> usize {
        self.entity_map.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entity_map.is_empty()
    }

    #[cfg(not(feature = "rendering"))]
    pub fn sync_text(
        &mut self,
        _world: &mut (),
        _ruby_entity_id: u64,
        _text_data: &TextData,
        _transform_data: &TextTransformData,
    ) {
    }

    #[cfg(not(feature = "rendering"))]
    pub fn remove_text(&mut self, _world: &mut (), _ruby_entity_id: u64) {}

    #[cfg(not(feature = "rendering"))]
    pub fn clear(&mut self, _world: &mut ()) {}
}

impl Default for TextSync {
    fn default() -> Self {
        Self::new()
    }
}
