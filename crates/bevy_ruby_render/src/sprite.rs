use bevy_color::Color;
use bevy_ecs::entity::Entity;
use bevy_ecs::world::World;
use bevy_math::Vec2;
use bevy_sprite::Sprite;
use bevy_transform::components::Transform;
use std::collections::HashMap;

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

impl SpriteData {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.color_r = r;
        self.color_g = g;
        self.color_b = b;
        self.color_a = a;
        self
    }

    pub fn with_size(mut self, width: f32, height: f32) -> Self {
        self.has_custom_size = true;
        self.custom_size_x = width;
        self.custom_size_y = height;
        self
    }

    pub fn with_flip(mut self, flip_x: bool, flip_y: bool) -> Self {
        self.flip_x = flip_x;
        self.flip_y = flip_y;
        self
    }

    pub fn to_bevy_color(&self) -> Color {
        Color::srgba(self.color_r, self.color_g, self.color_b, self.color_a)
    }

    pub fn custom_size(&self) -> Option<Vec2> {
        if self.has_custom_size {
            Some(Vec2::new(self.custom_size_x, self.custom_size_y))
        } else {
            None
        }
    }
}

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

impl TransformData {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_xyz(x: f32, y: f32, z: f32) -> Self {
        Self {
            translation_x: x,
            translation_y: y,
            translation_z: z,
            ..Default::default()
        }
    }

    pub fn to_bevy_transform(&self) -> Transform {
        Transform {
            translation: bevy_math::Vec3::new(
                self.translation_x,
                self.translation_y,
                self.translation_z,
            ),
            rotation: bevy_math::Quat::from_xyzw(
                self.rotation_x,
                self.rotation_y,
                self.rotation_z,
                self.rotation_w,
            ),
            scale: bevy_math::Vec3::new(self.scale_x, self.scale_y, self.scale_z),
        }
    }
}

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

struct EntityData {
    bevy_entity: Entity,
}

pub struct SpriteSync {
    entity_map: HashMap<u64, EntityData>,
    pub pending_operations: Vec<SpriteOperation>,
}

impl SpriteSync {
    pub fn new() -> Self {
        Self {
            entity_map: HashMap::new(),
            pending_operations: Vec::new(),
        }
    }

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

    pub fn remove_sprite_standalone(&mut self, ruby_entity_id: u64) {
        self.pending_operations
            .push(SpriteOperation::Remove { ruby_entity_id });
    }

    pub fn clear_standalone(&mut self) {
        self.pending_operations.push(SpriteOperation::Clear);
    }

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

    pub fn sync_sprite(
        &mut self,
        world: &mut World,
        ruby_entity_id: u64,
        sprite_data: &SpriteData,
        transform_data: &TransformData,
    ) {
        let color = sprite_data.to_bevy_color();
        let custom_size = sprite_data.custom_size();
        let transform = transform_data.to_bevy_transform();

        if let Some(entity_data) = self.entity_map.get(&ruby_entity_id) {
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
            let bevy_entity = world
                .spawn((
                    Sprite {
                        color,
                        custom_size,
                        flip_x: sprite_data.flip_x,
                        flip_y: sprite_data.flip_y,
                        ..Default::default()
                    },
                    transform,
                ))
                .id();

            self.entity_map
                .insert(ruby_entity_id, EntityData { bevy_entity });
        }
    }

    pub fn remove_sprite(&mut self, world: &mut World, ruby_entity_id: u64) {
        if let Some(entity_data) = self.entity_map.remove(&ruby_entity_id) {
            world.despawn(entity_data.bevy_entity);
        }
    }

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

    pub fn synced_entities(&self) -> Vec<u64> {
        self.entity_map.keys().copied().collect()
    }
}

impl Default for SpriteSync {
    fn default() -> Self {
        Self::new()
    }
}
