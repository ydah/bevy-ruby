//! Sprite renderer module for synchronizing Ruby sprites with Bevy.

use std::collections::HashMap;

#[cfg(feature = "rendering")]
use bevy_asset::{Assets, Handle};
#[cfg(feature = "rendering")]
use bevy_color::Color;
#[cfg(feature = "rendering")]
use bevy_ecs::entity::Entity;
#[cfg(feature = "rendering")]
use bevy_ecs::system::Resource;
#[cfg(feature = "rendering")]
use bevy_ecs::world::World;
#[cfg(feature = "rendering")]
use bevy_image::Image;
#[cfg(feature = "rendering")]
use bevy_math::Vec2;
#[cfg(feature = "rendering")]
use bevy_sprite::Sprite;
#[cfg(feature = "rendering")]
use bevy_transform::components::Transform;

/// Sprite data received from Ruby.
#[derive(Debug, Clone)]
pub struct SpriteData {
    pub color_r: f32,
    pub color_g: f32,
    pub color_b: f32,
    pub color_a: f32,
    pub flip_x: bool,
    pub flip_y: bool,
    pub anchor_x: f32,
    pub anchor_y: f32,
    pub has_custom_size: bool,
    pub custom_size_x: f32,
    pub custom_size_y: f32,
}

impl Default for SpriteData {
    fn default() -> Self {
        Self {
            color_r: 1.0,
            color_g: 1.0,
            color_b: 1.0,
            color_a: 1.0,
            flip_x: false,
            flip_y: false,
            anchor_x: 0.5,
            anchor_y: 0.5,
            has_custom_size: false,
            custom_size_x: 0.0,
            custom_size_y: 0.0,
        }
    }
}

/// Transform data received from Ruby.
#[derive(Debug, Clone)]
pub struct TransformData {
    pub translation_x: f32,
    pub translation_y: f32,
    pub translation_z: f32,
    pub rotation_x: f32,
    pub rotation_y: f32,
    pub rotation_z: f32,
    pub rotation_w: f32,
    pub scale_x: f32,
    pub scale_y: f32,
    pub scale_z: f32,
}

impl Default for TransformData {
    fn default() -> Self {
        Self {
            translation_x: 0.0,
            translation_y: 0.0,
            translation_z: 0.0,
            rotation_x: 0.0,
            rotation_y: 0.0,
            rotation_z: 0.0,
            rotation_w: 1.0,
            scale_x: 1.0,
            scale_y: 1.0,
            scale_z: 1.0,
        }
    }
}

/// Pending sprite operation.
#[derive(Debug, Clone)]
pub enum SpriteOperation {
    Sync {
        ruby_entity_id: u64,
        sprite_data: SpriteData,
        transform_data: TransformData,
    },
    Remove {
        ruby_entity_id: u64,
    },
    Clear,
}

/// Resource to hold the default white texture for sprites.
#[cfg(feature = "rendering")]
#[derive(Resource)]
pub struct DefaultSpriteTexture {
    pub handle: Handle<Image>,
}

#[cfg(feature = "rendering")]
impl DefaultSpriteTexture {
    pub fn create_1x1_white_image() -> Image {
        use bevy_image::Image;
        use bevy_render::render_asset::RenderAssetUsages;
        use bevy_render::render_resource::{Extent3d, TextureDimension, TextureFormat};

        Image::new(
            Extent3d {
                width: 1,
                height: 1,
                depth_or_array_layers: 1,
            },
            TextureDimension::D2,
            vec![255, 255, 255, 255],
            TextureFormat::Rgba8UnormSrgb,
            RenderAssetUsages::RENDER_WORLD | RenderAssetUsages::MAIN_WORLD,
        )
    }

    pub fn insert_into_world(world: &mut World) {
        let image = Self::create_1x1_white_image();
        let handle = {
            let mut images = world.resource_mut::<Assets<Image>>();
            images.add(image)
        };
        world.insert_resource(DefaultSpriteTexture { handle });
    }
}

/// Manages the synchronization of Ruby sprites to Bevy entities.
pub struct SpriteSync {
    /// Maps Ruby entity IDs to Bevy render entities.
    entity_map: HashMap<u64, EntityData>,
    /// Pending operations to apply on next update.
    pub pending_operations: Vec<SpriteOperation>,
}

struct EntityData {
    #[cfg(feature = "rendering")]
    bevy_entity: Entity,
    #[cfg(not(feature = "rendering"))]
    _phantom: (),
}

impl SpriteSync {
    /// Creates a new SpriteSync instance.
    pub fn new() -> Self {
        Self {
            entity_map: HashMap::new(),
            pending_operations: Vec::new(),
        }
    }

    /// Queues a sprite sync operation (standalone, no World needed).
    pub fn sync_sprite_standalone(
        &mut self,
        ruby_entity_id: u64,
        sprite_data: &SpriteData,
        transform_data: &TransformData,
    ) {
        self.pending_operations.push(SpriteOperation::Sync {
            ruby_entity_id,
            sprite_data: sprite_data.clone(),
            transform_data: transform_data.clone(),
        });
    }

    /// Queues a sprite removal (standalone, no World needed).
    pub fn remove_sprite_standalone(&mut self, ruby_entity_id: u64) {
        self.pending_operations.push(SpriteOperation::Remove { ruby_entity_id });
    }

    /// Queues clearing all sprites (standalone, no World needed).
    pub fn clear_standalone(&mut self) {
        self.pending_operations.push(SpriteOperation::Clear);
    }

    /// Applies all pending operations to the World.
    #[cfg(feature = "rendering")]
    pub fn apply_pending(&mut self, world: &mut World) {
        let ops: Vec<_> = self.pending_operations.drain(..).collect();
        for op in ops {
            match op {
                SpriteOperation::Sync {
                    ruby_entity_id,
                    sprite_data,
                    transform_data,
                } => {
                    self.sync_sprite(world, ruby_entity_id, &sprite_data, &transform_data);
                }
                SpriteOperation::Remove { ruby_entity_id } => {
                    self.remove_sprite(world, ruby_entity_id);
                }
                SpriteOperation::Clear => {
                    self.clear(world);
                }
            }
        }
    }

    #[cfg(not(feature = "rendering"))]
    pub fn apply_pending(&mut self, _world: &mut ()) {
        self.pending_operations.clear();
    }

    /// Synchronizes a Ruby sprite to Bevy.
    #[cfg(feature = "rendering")]
    pub fn sync_sprite(
        &mut self,
        world: &mut World,
        ruby_entity_id: u64,
        sprite_data: &SpriteData,
        transform_data: &TransformData,
    ) {
        let color = Color::srgba(
            sprite_data.color_r,
            sprite_data.color_g,
            sprite_data.color_b,
            sprite_data.color_a,
        );

        let custom_size = if sprite_data.has_custom_size {
            Some(Vec2::new(
                sprite_data.custom_size_x,
                sprite_data.custom_size_y,
            ))
        } else {
            None
        };

        let transform = Transform {
            translation: bevy_math::Vec3::new(
                transform_data.translation_x,
                transform_data.translation_y,
                transform_data.translation_z,
            ),
            rotation: bevy_math::Quat::from_xyzw(
                transform_data.rotation_x,
                transform_data.rotation_y,
                transform_data.rotation_z,
                transform_data.rotation_w,
            ),
            scale: bevy_math::Vec3::new(
                transform_data.scale_x,
                transform_data.scale_y,
                transform_data.scale_z,
            ),
        };

        if let Some(entity_data) = self.entity_map.get(&ruby_entity_id) {
            // Update existing Bevy entity
            let bevy_entity = entity_data.bevy_entity;

            if let Some(mut sprite) = world.get_mut::<Sprite>(bevy_entity) {
                sprite.color = color;
                sprite.custom_size = custom_size;
                sprite.flip_x = sprite_data.flip_x;
                sprite.flip_y = sprite_data.flip_y;
            }

            if let Some(mut t) = world.get_mut::<Transform>(bevy_entity) {
                *t = transform;
            }
        } else {
            // Spawn new Bevy render entity with default white texture
            let texture_handle = world
                .get_resource::<DefaultSpriteTexture>()
                .map(|t| t.handle.clone());

            let bevy_entity = world
                .spawn((
                    Sprite {
                        color,
                        custom_size,
                        flip_x: sprite_data.flip_x,
                        flip_y: sprite_data.flip_y,
                        image: texture_handle.clone().unwrap_or_default(),
                        ..Default::default()
                    },
                    transform,
                ))
                .id();

            self.entity_map.insert(
                ruby_entity_id,
                EntityData { bevy_entity },
            );
        }
    }

    /// Removes a sprite from Bevy.
    #[cfg(feature = "rendering")]
    pub fn remove_sprite(&mut self, world: &mut World, ruby_entity_id: u64) {
        if let Some(entity_data) = self.entity_map.remove(&ruby_entity_id) {
            world.despawn(entity_data.bevy_entity);
        }
    }

    /// Clears all sprites and removes them from Bevy.
    #[cfg(feature = "rendering")]
    pub fn clear(&mut self, world: &mut World) {
        for (_, entity_data) in self.entity_map.drain() {
            world.despawn(entity_data.bevy_entity);
        }
    }

    /// Returns the number of synced sprites.
    pub fn len(&self) -> usize {
        self.entity_map.len()
    }

    /// Returns true if no sprites are synced.
    pub fn is_empty(&self) -> bool {
        self.entity_map.is_empty()
    }

    /// Returns all Ruby entity IDs that are currently synced.
    pub fn synced_entities(&self) -> Vec<u64> {
        self.entity_map.keys().copied().collect()
    }

    // No-op implementations for non-rendering builds
    #[cfg(not(feature = "rendering"))]
    pub fn sync_sprite(
        &mut self,
        _world: &mut (),
        _ruby_entity_id: u64,
        _sprite_data: &SpriteData,
        _transform_data: &TransformData,
    ) {
    }

    #[cfg(not(feature = "rendering"))]
    pub fn remove_sprite(&mut self, _world: &mut (), _ruby_entity_id: u64) {}

    #[cfg(not(feature = "rendering"))]
    pub fn clear(&mut self, _world: &mut ()) {}
}

impl Default for SpriteSync {
    fn default() -> Self {
        Self::new()
    }
}
