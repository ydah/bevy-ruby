use bevy_math::{Quat, Vec2, Vec3};

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RubyVec2(pub Vec2);

impl RubyVec2 {
    pub fn new(x: f32, y: f32) -> Self {
        Self(Vec2::new(x, y))
    }

    pub fn zero() -> Self {
        Self(Vec2::ZERO)
    }

    pub fn one() -> Self {
        Self(Vec2::ONE)
    }

    pub fn x(&self) -> f32 {
        self.0.x
    }

    pub fn y(&self) -> f32 {
        self.0.y
    }

    pub fn set_x(&mut self, x: f32) {
        self.0.x = x;
    }

    pub fn set_y(&mut self, y: f32) {
        self.0.y = y;
    }

    pub fn length(&self) -> f32 {
        self.0.length()
    }

    pub fn length_squared(&self) -> f32 {
        self.0.length_squared()
    }

    pub fn normalize(&self) -> Self {
        Self(self.0.normalize())
    }

    pub fn dot(&self, other: &RubyVec2) -> f32 {
        self.0.dot(other.0)
    }

    pub fn add(&self, other: &RubyVec2) -> Self {
        Self(self.0 + other.0)
    }

    pub fn sub(&self, other: &RubyVec2) -> Self {
        Self(self.0 - other.0)
    }

    pub fn mul(&self, scalar: f32) -> Self {
        Self(self.0 * scalar)
    }

    pub fn div(&self, scalar: f32) -> Self {
        Self(self.0 / scalar)
    }

    pub fn distance(&self, other: &RubyVec2) -> f32 {
        self.0.distance(other.0)
    }

    pub fn inner(&self) -> Vec2 {
        self.0
    }
}

impl From<Vec2> for RubyVec2 {
    fn from(v: Vec2) -> Self {
        Self(v)
    }
}

impl From<RubyVec2> for Vec2 {
    fn from(v: RubyVec2) -> Self {
        v.0
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RubyVec3(pub Vec3);

impl RubyVec3 {
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self(Vec3::new(x, y, z))
    }

    pub fn zero() -> Self {
        Self(Vec3::ZERO)
    }

    pub fn one() -> Self {
        Self(Vec3::ONE)
    }

    pub fn x(&self) -> f32 {
        self.0.x
    }

    pub fn y(&self) -> f32 {
        self.0.y
    }

    pub fn z(&self) -> f32 {
        self.0.z
    }

    pub fn set_x(&mut self, x: f32) {
        self.0.x = x;
    }

    pub fn set_y(&mut self, y: f32) {
        self.0.y = y;
    }

    pub fn set_z(&mut self, z: f32) {
        self.0.z = z;
    }

    pub fn length(&self) -> f32 {
        self.0.length()
    }

    pub fn length_squared(&self) -> f32 {
        self.0.length_squared()
    }

    pub fn normalize(&self) -> Self {
        Self(self.0.normalize())
    }

    pub fn dot(&self, other: &RubyVec3) -> f32 {
        self.0.dot(other.0)
    }

    pub fn cross(&self, other: &RubyVec3) -> Self {
        Self(self.0.cross(other.0))
    }

    pub fn add(&self, other: &RubyVec3) -> Self {
        Self(self.0 + other.0)
    }

    pub fn sub(&self, other: &RubyVec3) -> Self {
        Self(self.0 - other.0)
    }

    pub fn mul(&self, scalar: f32) -> Self {
        Self(self.0 * scalar)
    }

    pub fn div(&self, scalar: f32) -> Self {
        Self(self.0 / scalar)
    }

    pub fn distance(&self, other: &RubyVec3) -> f32 {
        self.0.distance(other.0)
    }

    pub fn inner(&self) -> Vec3 {
        self.0
    }
}

impl From<Vec3> for RubyVec3 {
    fn from(v: Vec3) -> Self {
        Self(v)
    }
}

impl From<RubyVec3> for Vec3 {
    fn from(v: RubyVec3) -> Self {
        v.0
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RubyQuat(pub Quat);

impl RubyQuat {
    pub fn identity() -> Self {
        Self(Quat::IDENTITY)
    }

    pub fn from_axis_angle(axis: &RubyVec3, angle: f32) -> Self {
        Self(Quat::from_axis_angle(axis.0, angle))
    }

    pub fn from_euler(x: f32, y: f32, z: f32) -> Self {
        Self(Quat::from_euler(bevy_math::EulerRot::XYZ, x, y, z))
    }

    pub fn from_rotation_x(angle: f32) -> Self {
        Self(Quat::from_rotation_x(angle))
    }

    pub fn from_rotation_y(angle: f32) -> Self {
        Self(Quat::from_rotation_y(angle))
    }

    pub fn from_rotation_z(angle: f32) -> Self {
        Self(Quat::from_rotation_z(angle))
    }

    pub fn x(&self) -> f32 {
        self.0.x
    }

    pub fn y(&self) -> f32 {
        self.0.y
    }

    pub fn z(&self) -> f32 {
        self.0.z
    }

    pub fn w(&self) -> f32 {
        self.0.w
    }

    pub fn normalize(&self) -> Self {
        Self(self.0.normalize())
    }

    pub fn inverse(&self) -> Self {
        Self(self.0.inverse())
    }

    pub fn mul(&self, other: &RubyQuat) -> Self {
        Self(self.0 * other.0)
    }

    pub fn mul_vec3(&self, v: &RubyVec3) -> RubyVec3 {
        RubyVec3(self.0 * v.0)
    }

    pub fn inner(&self) -> Quat {
        self.0
    }
}

impl From<Quat> for RubyQuat {
    fn from(q: Quat) -> Self {
        Self(q)
    }
}

impl From<RubyQuat> for Quat {
    fn from(q: RubyQuat) -> Self {
        q.0
    }
}
