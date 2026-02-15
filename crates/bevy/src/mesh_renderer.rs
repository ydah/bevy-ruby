use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ShapeType {
    Rectangle,
    Circle,
    RegularPolygon,
    Line,
    Ellipse,
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
    #[cfg(feature = "rendering")]
    bevy_entity: bevy_ecs::entity::Entity,
    #[cfg(not(feature = "rendering"))]
    _phantom: (),
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
        self.pending_operations.push(MeshOperation::Remove { ruby_entity_id });
    }

    pub fn clear_standalone(&mut self) {
        self.pending_operations.push(MeshOperation::Clear);
    }

    #[cfg(feature = "rendering")]
    pub fn apply_pending(&mut self, world: &mut bevy_ecs::world::World) {
        use bevy_color::Color;
        use bevy_math::Vec3;
        use bevy_prototype_lyon::prelude::*;
        use bevy_render::view::Visibility;
        use bevy_transform::components::Transform;

        let ops: Vec<_> = self.pending_operations.drain(..).collect();
        for op in ops {
            match op {
                MeshOperation::Sync {
                    ruby_entity_id,
                    mesh_data,
                    transform_data,
                } => {
                    let color = Color::srgba(
                        mesh_data.color_r,
                        mesh_data.color_g,
                        mesh_data.color_b,
                        mesh_data.color_a,
                    );

                    let transform = Transform {
                        translation: Vec3::new(
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
                        scale: Vec3::new(
                            transform_data.scale_x,
                            transform_data.scale_y,
                            transform_data.scale_z,
                        ),
                    };

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
                                    extents: bevy_math::Vec2::new(mesh_data.width, mesh_data.height),
                                    origin: RectangleOrigin::Center,
                                    ..Default::default()
                                };
                                world.spawn((
                                    ShapeBundle {
                                        path: GeometryBuilder::build_as(&shape),
                                        transform,
                                        visibility: Visibility::Visible,
                                        ..Default::default()
                                    },
                                    draw_mode.0,
                                    draw_mode.1,
                                )).id()
                            }
                            ShapeType::Circle => {
                                let shape = shapes::Circle {
                                    radius: mesh_data.radius,
                                    center: bevy_math::Vec2::ZERO,
                                };
                                world.spawn((
                                    ShapeBundle {
                                        path: GeometryBuilder::build_as(&shape),
                                        transform,
                                        visibility: Visibility::Visible,
                                        ..Default::default()
                                    },
                                    draw_mode.0,
                                    draw_mode.1,
                                )).id()
                            }
                            ShapeType::RegularPolygon => {
                                let shape = shapes::RegularPolygon {
                                    sides: mesh_data.sides as usize,
                                    feature: RegularPolygonFeature::Radius(mesh_data.radius),
                                    ..Default::default()
                                };
                                world.spawn((
                                    ShapeBundle {
                                        path: GeometryBuilder::build_as(&shape),
                                        transform,
                                        visibility: Visibility::Visible,
                                        ..Default::default()
                                    },
                                    draw_mode.0,
                                    draw_mode.1,
                                )).id()
                            }
                            ShapeType::Line => {
                                let shape = shapes::Line(
                                    bevy_math::Vec2::new(mesh_data.line_start_x, mesh_data.line_start_y),
                                    bevy_math::Vec2::new(mesh_data.line_end_x, mesh_data.line_end_y),
                                );
                                world.spawn((
                                    ShapeBundle {
                                        path: GeometryBuilder::build_as(&shape),
                                        transform,
                                        visibility: Visibility::Visible,
                                        ..Default::default()
                                    },
                                    Stroke::new(color, mesh_data.thickness),
                                )).id()
                            }
                            ShapeType::Ellipse => {
                                let shape = shapes::Ellipse {
                                    radii: bevy_math::Vec2::new(mesh_data.width / 2.0, mesh_data.height / 2.0),
                                    center: bevy_math::Vec2::ZERO,
                                };
                                world.spawn((
                                    ShapeBundle {
                                        path: GeometryBuilder::build_as(&shape),
                                        transform,
                                        visibility: Visibility::Visible,
                                        ..Default::default()
                                    },
                                    draw_mode.0,
                                    draw_mode.1,
                                )).id()
                            }
                        };

                        self.entity_map.insert(ruby_entity_id, EntityData { bevy_entity });
                    }
                }
                MeshOperation::Remove { ruby_entity_id } => {
                    if let Some(entity_data) = self.entity_map.remove(&ruby_entity_id) {
                        world.despawn(entity_data.bevy_entity);
                    }
                }
                MeshOperation::Clear => {
                    for (_, entity_data) in self.entity_map.drain() {
                        world.despawn(entity_data.bevy_entity);
                    }
                }
            }
        }
    }

    #[cfg(not(feature = "rendering"))]
    pub fn apply_pending(&mut self, _world: &mut ()) {
        self.pending_operations.clear();
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
