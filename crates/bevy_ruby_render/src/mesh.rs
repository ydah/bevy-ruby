use bevy_color::Color;
use bevy_ecs::entity::Entity;
use bevy_ecs::world::World;
use bevy_math::{Vec2, Vec3};
use bevy_prototype_lyon::prelude::*;
use bevy_render::view::Visibility;
use bevy_transform::components::Transform;
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ShapeType {
    Rectangle,
    Circle,
    RegularPolygon,
    Line,
    Ellipse,
    Triangle,
}

#[derive(Debug, Clone)]
pub struct MeshData {
    pub shape_type: ShapeType,
    pub color_r: f32,
    pub color_g: f32,
    pub color_b: f32,
    pub color_a: f32,
    pub width: f32,
    pub height: f32,
    pub radius: f32,
    pub sides: u32,
    pub line_start_x: f32,
    pub line_start_y: f32,
    pub line_end_x: f32,
    pub line_end_y: f32,
    pub thickness: f32,
    pub fill: bool,
}

impl Default for MeshData {
    fn default() -> Self {
        Self {
            shape_type: ShapeType::Rectangle,
            color_r: 1.0,
            color_g: 1.0,
            color_b: 1.0,
            color_a: 1.0,
            width: 100.0,
            height: 100.0,
            radius: 50.0,
            sides: 6,
            line_start_x: 0.0,
            line_start_y: 0.0,
            line_end_x: 100.0,
            line_end_y: 0.0,
            thickness: 2.0,
            fill: true,
        }
    }
}

impl MeshData {
    pub fn rectangle(width: f32, height: f32) -> Self {
        Self {
            shape_type: ShapeType::Rectangle,
            width,
            height,
            ..Default::default()
        }
    }

    pub fn circle(radius: f32) -> Self {
        Self {
            shape_type: ShapeType::Circle,
            radius,
            ..Default::default()
        }
    }

    pub fn regular_polygon(radius: f32, sides: u32) -> Self {
        Self {
            shape_type: ShapeType::RegularPolygon,
            radius,
            sides,
            ..Default::default()
        }
    }

    pub fn line(start: Vec2, end: Vec2, thickness: f32) -> Self {
        Self {
            shape_type: ShapeType::Line,
            line_start_x: start.x,
            line_start_y: start.y,
            line_end_x: end.x,
            line_end_y: end.y,
            thickness,
            ..Default::default()
        }
    }

    pub fn ellipse(width: f32, height: f32) -> Self {
        Self {
            shape_type: ShapeType::Ellipse,
            width,
            height,
            ..Default::default()
        }
    }

    pub fn with_color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.color_r = r;
        self.color_g = g;
        self.color_b = b;
        self.color_a = a;
        self
    }

    pub fn with_fill(mut self, fill: bool) -> Self {
        self.fill = fill;
        self
    }

    pub fn to_bevy_color(&self) -> Color {
        Color::srgba(self.color_r, self.color_g, self.color_b, self.color_a)
    }
}

#[derive(Debug, Clone)]
pub struct MeshTransformData {
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

impl Default for MeshTransformData {
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

impl MeshTransformData {
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
            translation: Vec3::new(
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
            scale: Vec3::new(self.scale_x, self.scale_y, self.scale_z),
        }
    }
}

#[derive(Debug, Clone)]
pub enum MeshOperation {
    Sync {
        ruby_entity_id: u64,
        mesh_data: MeshData,
        transform_data: MeshTransformData,
    },
    Remove {
        ruby_entity_id: u64,
    },
    Clear,
}

struct EntityData {
    bevy_entity: Entity,
}

pub struct MeshSync {
    entity_map: HashMap<u64, EntityData>,
    pub pending_operations: Vec<MeshOperation>,
}

impl MeshSync {
    pub fn new() -> Self {
        Self {
            entity_map: HashMap::new(),
            pending_operations: Vec::new(),
        }
    }

    pub fn sync_mesh_standalone(
        &mut self,
        ruby_entity_id: u64,
        mesh_data: &MeshData,
        transform_data: &MeshTransformData,
    ) {
        self.pending_operations.push(MeshOperation::Sync {
            ruby_entity_id,
            mesh_data: mesh_data.clone(),
            transform_data: transform_data.clone(),
        });
    }

    pub fn remove_mesh_standalone(&mut self, ruby_entity_id: u64) {
        self.pending_operations
            .push(MeshOperation::Remove { ruby_entity_id });
    }

    pub fn clear_standalone(&mut self) {
        self.pending_operations.push(MeshOperation::Clear);
    }

    pub fn apply_pending(&mut self, world: &mut World) {
        let ops: Vec<_> = self.pending_operations.drain(..).collect();
        for op in ops {
            match op {
                MeshOperation::Sync {
                    ruby_entity_id,
                    mesh_data,
                    transform_data,
                } => {
                    self.sync_mesh(world, ruby_entity_id, &mesh_data, &transform_data);
                }
                MeshOperation::Remove { ruby_entity_id } => {
                    self.remove_mesh(world, ruby_entity_id);
                }
                MeshOperation::Clear => {
                    self.clear(world);
                }
            }
        }
    }

    pub fn sync_mesh(
        &mut self,
        world: &mut World,
        ruby_entity_id: u64,
        mesh_data: &MeshData,
        transform_data: &MeshTransformData,
    ) {
        let color = mesh_data.to_bevy_color();
        let transform = transform_data.to_bevy_transform();

        if let Some(entity_data) = self.entity_map.get(&ruby_entity_id) {
            let bevy_entity = entity_data.bevy_entity;
            if let Some(mut t) = world.get_mut::<Transform>(bevy_entity) {
                *t = transform;
            }
            if let Some(mut fill) = world.get_mut::<Fill>(bevy_entity) {
                fill.color = color;
            }
            if let Some(mut stroke) = world.get_mut::<Stroke>(bevy_entity) {
                stroke.color = color;
            }
        } else {
            let transparent = Color::srgba(0.0, 0.0, 0.0, 0.0);
            let draw_mode = if mesh_data.fill {
                (
                    Fill::color(color),
                    Stroke::new(color, mesh_data.thickness),
                )
            } else {
                (
                    Fill::color(transparent),
                    Stroke::new(color, mesh_data.thickness),
                )
            };

            let bevy_entity = match mesh_data.shape_type {
                ShapeType::Rectangle => {
                    let shape = shapes::Rectangle {
                        extents: Vec2::new(mesh_data.width, mesh_data.height),
                        origin: RectangleOrigin::Center,
                        ..Default::default()
                    };
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            draw_mode.0,
                            draw_mode.1,
                        ))
                        .id()
                }
                ShapeType::Circle => {
                    let shape = shapes::Circle {
                        radius: mesh_data.radius,
                        center: Vec2::ZERO,
                    };
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            draw_mode.0,
                            draw_mode.1,
                        ))
                        .id()
                }
                ShapeType::RegularPolygon => {
                    let shape = shapes::RegularPolygon {
                        sides: mesh_data.sides as usize,
                        feature: RegularPolygonFeature::Radius(mesh_data.radius),
                        ..Default::default()
                    };
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            draw_mode.0,
                            draw_mode.1,
                        ))
                        .id()
                }
                ShapeType::Triangle => {
                    let shape = shapes::RegularPolygon {
                        sides: 3,
                        feature: RegularPolygonFeature::Radius(mesh_data.radius),
                        ..Default::default()
                    };
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            draw_mode.0,
                            draw_mode.1,
                        ))
                        .id()
                }
                ShapeType::Line => {
                    let shape = shapes::Line(
                        Vec2::new(mesh_data.line_start_x, mesh_data.line_start_y),
                        Vec2::new(mesh_data.line_end_x, mesh_data.line_end_y),
                    );
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            Stroke::new(color, mesh_data.thickness),
                        ))
                        .id()
                }
                ShapeType::Ellipse => {
                    let shape = shapes::Ellipse {
                        radii: Vec2::new(mesh_data.width / 2.0, mesh_data.height / 2.0),
                        center: Vec2::ZERO,
                    };
                    world
                        .spawn((
                            ShapeBundle {
                                path: GeometryBuilder::build_as(&shape),
                                transform,
                                visibility: Visibility::Visible,
                                ..Default::default()
                            },
                            draw_mode.0,
                            draw_mode.1,
                        ))
                        .id()
                }
            };

            self.entity_map
                .insert(ruby_entity_id, EntityData { bevy_entity });
        }
    }

    pub fn remove_mesh(&mut self, world: &mut World, ruby_entity_id: u64) {
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

impl Default for MeshSync {
    fn default() -> Self {
        Self::new()
    }
}

pub struct MeshBuilder {
    mesh_data: MeshData,
    transform_data: MeshTransformData,
}

impl MeshBuilder {
    pub fn new(shape_type: ShapeType) -> Self {
        Self {
            mesh_data: MeshData {
                shape_type,
                ..Default::default()
            },
            transform_data: MeshTransformData::default(),
        }
    }

    pub fn rectangle(width: f32, height: f32) -> Self {
        Self {
            mesh_data: MeshData::rectangle(width, height),
            transform_data: MeshTransformData::default(),
        }
    }

    pub fn circle(radius: f32) -> Self {
        Self {
            mesh_data: MeshData::circle(radius),
            transform_data: MeshTransformData::default(),
        }
    }

    pub fn color(mut self, r: f32, g: f32, b: f32, a: f32) -> Self {
        self.mesh_data = self.mesh_data.with_color(r, g, b, a);
        self
    }

    pub fn fill(mut self, fill: bool) -> Self {
        self.mesh_data = self.mesh_data.with_fill(fill);
        self
    }

    pub fn position(mut self, x: f32, y: f32, z: f32) -> Self {
        self.transform_data = MeshTransformData::from_xyz(x, y, z);
        self
    }

    pub fn build(self) -> (MeshData, MeshTransformData) {
        (self.mesh_data, self.transform_data)
    }
}
