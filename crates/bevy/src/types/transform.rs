use bevy_math::{Quat, Vec3};
use bevy_transform::components::Transform;
use crate::types::math::{RubyQuat, RubyVec3};

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RubyTransform(pub Transform);

impl RubyTransform {
    pub fn new() -> Self {
        Self(Transform::IDENTITY)
    }

    pub fn from_translation(translation: RubyVec3) -> Self {
        Self(Transform::from_translation(translation.inner()))
    }

    pub fn from_xyz(x: f32, y: f32, z: f32) -> Self {
        Self(Transform::from_xyz(x, y, z))
    }

    pub fn from_rotation(rotation: RubyQuat) -> Self {
        Self(Transform::from_rotation(rotation.inner()))
    }

    pub fn from_scale(scale: RubyVec3) -> Self {
        Self(Transform::from_scale(scale.inner()))
    }

    pub fn from_translation_rotation(translation: RubyVec3, rotation: RubyQuat) -> Self {
        Self(Transform {
            translation: translation.inner(),
            rotation: rotation.inner(),
            scale: Vec3::ONE,
        })
    }

    pub fn from_translation_rotation_scale(
        translation: RubyVec3,
        rotation: RubyQuat,
        scale: RubyVec3,
    ) -> Self {
        Self(Transform {
            translation: translation.inner(),
            rotation: rotation.inner(),
            scale: scale.inner(),
        })
    }

    pub fn identity() -> Self {
        Self(Transform::IDENTITY)
    }

    pub fn translation(&self) -> RubyVec3 {
        RubyVec3::from(self.0.translation)
    }

    pub fn rotation(&self) -> RubyQuat {
        RubyQuat::from(self.0.rotation)
    }

    pub fn scale(&self) -> RubyVec3 {
        RubyVec3::from(self.0.scale)
    }

    pub fn set_translation(&mut self, translation: RubyVec3) {
        self.0.translation = translation.inner();
    }

    pub fn set_rotation(&mut self, rotation: RubyQuat) {
        self.0.rotation = rotation.inner();
    }

    pub fn set_scale(&mut self, scale: RubyVec3) {
        self.0.scale = scale.inner();
    }

    pub fn translate(&mut self, delta: RubyVec3) {
        self.0.translation += delta.inner();
    }

    pub fn rotate(&mut self, rotation: RubyQuat) {
        self.0.rotation = rotation.inner() * self.0.rotation;
    }

    pub fn rotate_x(&mut self, angle: f32) {
        self.0.rotate_x(angle);
    }

    pub fn rotate_y(&mut self, angle: f32) {
        self.0.rotate_y(angle);
    }

    pub fn rotate_z(&mut self, angle: f32) {
        self.0.rotate_z(angle);
    }

    pub fn rotate_local_x(&mut self, angle: f32) {
        self.0.rotate_local_x(angle);
    }

    pub fn rotate_local_y(&mut self, angle: f32) {
        self.0.rotate_local_y(angle);
    }

    pub fn rotate_local_z(&mut self, angle: f32) {
        self.0.rotate_local_z(angle);
    }

    pub fn look_at(&mut self, target: RubyVec3, up: RubyVec3) {
        self.0.look_at(target.inner(), up.inner());
    }

    pub fn forward(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.forward())
    }

    pub fn back(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.back())
    }

    pub fn left(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.left())
    }

    pub fn right(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.right())
    }

    pub fn up(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.up())
    }

    pub fn down(&self) -> RubyVec3 {
        RubyVec3::from(*self.0.down())
    }

    pub fn mul(&self, other: &RubyTransform) -> Self {
        Self(self.0 * other.0)
    }

    pub fn transform_point(&self, point: RubyVec3) -> RubyVec3 {
        RubyVec3::from(self.0.transform_point(point.inner()))
    }

    pub fn inner(&self) -> Transform {
        self.0
    }
}

impl Default for RubyTransform {
    fn default() -> Self {
        Self::new()
    }
}

impl From<Transform> for RubyTransform {
    fn from(t: Transform) -> Self {
        Self(t)
    }
}

impl From<RubyTransform> for Transform {
    fn from(t: RubyTransform) -> Self {
        t.0
    }
}
