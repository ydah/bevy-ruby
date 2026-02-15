use bevy_ruby::{RubyQuat, RubyVec2, RubyVec3};
use magnus::{function, method, prelude::*, Error, RArray, RModule, Ruby};
use std::cell::RefCell;

#[magnus::wrap(class = "Bevy::Vec2", free_immediately, size)]
pub struct MagnusVec2 {
    inner: RefCell<RubyVec2>,
}

impl MagnusVec2 {
    fn new(x: f64, y: f64) -> Self {
        Self {
            inner: RefCell::new(RubyVec2::new(x as f32, y as f32)),
        }
    }

    fn zero() -> Self {
        Self {
            inner: RefCell::new(RubyVec2::zero()),
        }
    }

    fn one() -> Self {
        Self {
            inner: RefCell::new(RubyVec2::one()),
        }
    }

    fn x(&self) -> f64 {
        self.inner.borrow().x() as f64
    }

    fn y(&self) -> f64 {
        self.inner.borrow().y() as f64
    }

    fn set_x(&self, x: f64) {
        self.inner.borrow_mut().set_x(x as f32);
    }

    fn set_y(&self, y: f64) {
        self.inner.borrow_mut().set_y(y as f32);
    }

    fn length(&self) -> f64 {
        self.inner.borrow().length() as f64
    }

    fn length_squared(&self) -> f64 {
        self.inner.borrow().length_squared() as f64
    }

    fn normalize(&self) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().normalize()),
        }
    }

    fn dot(&self, other: &MagnusVec2) -> f64 {
        self.inner.borrow().dot(&other.inner.borrow()) as f64
    }

    fn add(&self, other: &MagnusVec2) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().add(&other.inner.borrow())),
        }
    }

    fn sub(&self, other: &MagnusVec2) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().sub(&other.inner.borrow())),
        }
    }

    fn mul(&self, scalar: f64) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().mul(scalar as f32)),
        }
    }

    fn div(&self, scalar: f64) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().div(scalar as f32)),
        }
    }

    fn distance(&self, other: &MagnusVec2) -> f64 {
        self.inner.borrow().distance(&other.inner.borrow()) as f64
    }

    fn to_a(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().unwrap();
        let arr = ruby.ary_new();
        let v = self.inner.borrow();
        arr.push(v.x() as f64)?;
        arr.push(v.y() as f64)?;
        Ok(arr)
    }

    pub fn inner(&self) -> RubyVec2 {
        *self.inner.borrow()
    }
}

unsafe impl Send for MagnusVec2 {}

#[magnus::wrap(class = "Bevy::Vec3", free_immediately, size)]
pub struct MagnusVec3 {
    inner: RefCell<RubyVec3>,
}

impl MagnusVec3 {
    fn new(x: f64, y: f64, z: f64) -> Self {
        Self {
            inner: RefCell::new(RubyVec3::new(x as f32, y as f32, z as f32)),
        }
    }

    fn zero() -> Self {
        Self {
            inner: RefCell::new(RubyVec3::zero()),
        }
    }

    fn one() -> Self {
        Self {
            inner: RefCell::new(RubyVec3::one()),
        }
    }

    fn x(&self) -> f64 {
        self.inner.borrow().x() as f64
    }

    fn y(&self) -> f64 {
        self.inner.borrow().y() as f64
    }

    fn z(&self) -> f64 {
        self.inner.borrow().z() as f64
    }

    fn set_x(&self, x: f64) {
        self.inner.borrow_mut().set_x(x as f32);
    }

    fn set_y(&self, y: f64) {
        self.inner.borrow_mut().set_y(y as f32);
    }

    fn set_z(&self, z: f64) {
        self.inner.borrow_mut().set_z(z as f32);
    }

    fn length(&self) -> f64 {
        self.inner.borrow().length() as f64
    }

    fn length_squared(&self) -> f64 {
        self.inner.borrow().length_squared() as f64
    }

    fn normalize(&self) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().normalize()),
        }
    }

    fn dot(&self, other: &MagnusVec3) -> f64 {
        self.inner.borrow().dot(&other.inner.borrow()) as f64
    }

    fn cross(&self, other: &MagnusVec3) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().cross(&other.inner.borrow())),
        }
    }

    fn add(&self, other: &MagnusVec3) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().add(&other.inner.borrow())),
        }
    }

    fn sub(&self, other: &MagnusVec3) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().sub(&other.inner.borrow())),
        }
    }

    fn mul(&self, scalar: f64) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().mul(scalar as f32)),
        }
    }

    fn div(&self, scalar: f64) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().div(scalar as f32)),
        }
    }

    fn distance(&self, other: &MagnusVec3) -> f64 {
        self.inner.borrow().distance(&other.inner.borrow()) as f64
    }

    fn to_a(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().unwrap();
        let arr = ruby.ary_new();
        let v = self.inner.borrow();
        arr.push(v.x() as f64)?;
        arr.push(v.y() as f64)?;
        arr.push(v.z() as f64)?;
        Ok(arr)
    }

    pub fn inner(&self) -> RubyVec3 {
        *self.inner.borrow()
    }
}

unsafe impl Send for MagnusVec3 {}

#[magnus::wrap(class = "Bevy::Quat", free_immediately, size)]
pub struct MagnusQuat {
    inner: RefCell<RubyQuat>,
}

impl MagnusQuat {
    fn identity() -> Self {
        Self {
            inner: RefCell::new(RubyQuat::identity()),
        }
    }

    fn from_axis_angle(axis: &MagnusVec3, angle: f64) -> Self {
        Self {
            inner: RefCell::new(RubyQuat::from_axis_angle(&axis.inner(), angle as f32)),
        }
    }

    fn from_euler(x: f64, y: f64, z: f64) -> Self {
        Self {
            inner: RefCell::new(RubyQuat::from_euler(x as f32, y as f32, z as f32)),
        }
    }

    fn from_rotation_x(angle: f64) -> Self {
        Self {
            inner: RefCell::new(RubyQuat::from_rotation_x(angle as f32)),
        }
    }

    fn from_rotation_y(angle: f64) -> Self {
        Self {
            inner: RefCell::new(RubyQuat::from_rotation_y(angle as f32)),
        }
    }

    fn from_rotation_z(angle: f64) -> Self {
        Self {
            inner: RefCell::new(RubyQuat::from_rotation_z(angle as f32)),
        }
    }

    fn x(&self) -> f64 {
        self.inner.borrow().x() as f64
    }

    fn y(&self) -> f64 {
        self.inner.borrow().y() as f64
    }

    fn z(&self) -> f64 {
        self.inner.borrow().z() as f64
    }

    fn w(&self) -> f64 {
        self.inner.borrow().w() as f64
    }

    fn normalize(&self) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().normalize()),
        }
    }

    fn inverse(&self) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().inverse()),
        }
    }

    fn mul_quat(&self, other: &MagnusQuat) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().mul(&other.inner.borrow())),
        }
    }

    fn mul_vec3(&self, v: &MagnusVec3) -> MagnusVec3 {
        MagnusVec3 {
            inner: RefCell::new(self.inner.borrow().mul_vec3(&v.inner())),
        }
    }

    fn to_a(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().unwrap();
        let arr = ruby.ary_new();
        let q = self.inner.borrow();
        arr.push(q.x() as f64)?;
        arr.push(q.y() as f64)?;
        arr.push(q.z() as f64)?;
        arr.push(q.w() as f64)?;
        Ok(arr)
    }

    pub fn inner(&self) -> RubyQuat {
        *self.inner.borrow()
    }
}

unsafe impl Send for MagnusQuat {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let vec2_class = module.define_class("Vec2", ruby.class_object())?;
    vec2_class.define_singleton_method("new", function!(MagnusVec2::new, 2))?;
    vec2_class.define_singleton_method("zero", function!(MagnusVec2::zero, 0))?;
    vec2_class.define_singleton_method("one", function!(MagnusVec2::one, 0))?;
    vec2_class.define_method("x", method!(MagnusVec2::x, 0))?;
    vec2_class.define_method("y", method!(MagnusVec2::y, 0))?;
    vec2_class.define_method("x=", method!(MagnusVec2::set_x, 1))?;
    vec2_class.define_method("y=", method!(MagnusVec2::set_y, 1))?;
    vec2_class.define_method("length", method!(MagnusVec2::length, 0))?;
    vec2_class.define_method("length_squared", method!(MagnusVec2::length_squared, 0))?;
    vec2_class.define_method("normalize", method!(MagnusVec2::normalize, 0))?;
    vec2_class.define_method("dot", method!(MagnusVec2::dot, 1))?;
    vec2_class.define_method("+", method!(MagnusVec2::add, 1))?;
    vec2_class.define_method("-", method!(MagnusVec2::sub, 1))?;
    vec2_class.define_method("*", method!(MagnusVec2::mul, 1))?;
    vec2_class.define_method("/", method!(MagnusVec2::div, 1))?;
    vec2_class.define_method("distance", method!(MagnusVec2::distance, 1))?;
    vec2_class.define_method("to_a", method!(MagnusVec2::to_a, 0))?;

    let vec3_class = module.define_class("Vec3", ruby.class_object())?;
    vec3_class.define_singleton_method("new", function!(MagnusVec3::new, 3))?;
    vec3_class.define_singleton_method("zero", function!(MagnusVec3::zero, 0))?;
    vec3_class.define_singleton_method("one", function!(MagnusVec3::one, 0))?;
    vec3_class.define_method("x", method!(MagnusVec3::x, 0))?;
    vec3_class.define_method("y", method!(MagnusVec3::y, 0))?;
    vec3_class.define_method("z", method!(MagnusVec3::z, 0))?;
    vec3_class.define_method("x=", method!(MagnusVec3::set_x, 1))?;
    vec3_class.define_method("y=", method!(MagnusVec3::set_y, 1))?;
    vec3_class.define_method("z=", method!(MagnusVec3::set_z, 1))?;
    vec3_class.define_method("length", method!(MagnusVec3::length, 0))?;
    vec3_class.define_method("length_squared", method!(MagnusVec3::length_squared, 0))?;
    vec3_class.define_method("normalize", method!(MagnusVec3::normalize, 0))?;
    vec3_class.define_method("dot", method!(MagnusVec3::dot, 1))?;
    vec3_class.define_method("cross", method!(MagnusVec3::cross, 1))?;
    vec3_class.define_method("+", method!(MagnusVec3::add, 1))?;
    vec3_class.define_method("-", method!(MagnusVec3::sub, 1))?;
    vec3_class.define_method("*", method!(MagnusVec3::mul, 1))?;
    vec3_class.define_method("/", method!(MagnusVec3::div, 1))?;
    vec3_class.define_method("distance", method!(MagnusVec3::distance, 1))?;
    vec3_class.define_method("to_a", method!(MagnusVec3::to_a, 0))?;

    let quat_class = module.define_class("Quat", ruby.class_object())?;
    quat_class.define_singleton_method("identity", function!(MagnusQuat::identity, 0))?;
    quat_class.define_singleton_method("from_axis_angle", function!(MagnusQuat::from_axis_angle, 2))?;
    quat_class.define_singleton_method("from_euler", function!(MagnusQuat::from_euler, 3))?;
    quat_class.define_singleton_method("from_rotation_x", function!(MagnusQuat::from_rotation_x, 1))?;
    quat_class.define_singleton_method("from_rotation_y", function!(MagnusQuat::from_rotation_y, 1))?;
    quat_class.define_singleton_method("from_rotation_z", function!(MagnusQuat::from_rotation_z, 1))?;
    quat_class.define_method("x", method!(MagnusQuat::x, 0))?;
    quat_class.define_method("y", method!(MagnusQuat::y, 0))?;
    quat_class.define_method("z", method!(MagnusQuat::z, 0))?;
    quat_class.define_method("w", method!(MagnusQuat::w, 0))?;
    quat_class.define_method("normalize", method!(MagnusQuat::normalize, 0))?;
    quat_class.define_method("inverse", method!(MagnusQuat::inverse, 0))?;
    quat_class.define_method("*", method!(MagnusQuat::mul_quat, 1))?;
    quat_class.define_method("mul_vec3", method!(MagnusQuat::mul_vec3, 1))?;
    quat_class.define_method("to_a", method!(MagnusQuat::to_a, 0))?;

    Ok(())
}
