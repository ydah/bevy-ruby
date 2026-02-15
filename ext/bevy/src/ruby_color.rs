use bevy_ruby::RubyColor;
use magnus::{function, method, prelude::*, Error, RArray, RModule, Ruby};
use std::cell::RefCell;

#[magnus::wrap(class = "Bevy::Color", free_immediately, size)]
pub struct MagnusColor {
    inner: RefCell<RubyColor>,
}

impl MagnusColor {
    fn new(r: f64, g: f64, b: f64, a: f64) -> Self {
        Self {
            inner: RefCell::new(RubyColor::new(r as f32, g as f32, b as f32, a as f32)),
        }
    }

    fn rgb(r: f64, g: f64, b: f64) -> Self {
        Self {
            inner: RefCell::new(RubyColor::rgb(r as f32, g as f32, b as f32)),
        }
    }

    fn rgba(r: f64, g: f64, b: f64, a: f64) -> Self {
        Self {
            inner: RefCell::new(RubyColor::rgba(r as f32, g as f32, b as f32, a as f32)),
        }
    }

    fn from_hex(hex: String) -> Result<Self, Error> {
        RubyColor::from_hex(&hex)
            .map(|c| Self {
                inner: RefCell::new(c),
            })
            .ok_or_else(|| Error::new(magnus::exception::arg_error(), "Invalid hex color"))
    }

    fn white() -> Self {
        Self {
            inner: RefCell::new(RubyColor::white()),
        }
    }

    fn black() -> Self {
        Self {
            inner: RefCell::new(RubyColor::black()),
        }
    }

    fn red() -> Self {
        Self {
            inner: RefCell::new(RubyColor::red()),
        }
    }

    fn green() -> Self {
        Self {
            inner: RefCell::new(RubyColor::green()),
        }
    }

    fn blue() -> Self {
        Self {
            inner: RefCell::new(RubyColor::blue()),
        }
    }

    fn transparent() -> Self {
        Self {
            inner: RefCell::new(RubyColor::transparent()),
        }
    }

    fn r(&self) -> f64 {
        self.inner.borrow().r() as f64
    }

    fn g(&self) -> f64 {
        self.inner.borrow().g() as f64
    }

    fn b(&self) -> f64 {
        self.inner.borrow().b() as f64
    }

    fn a(&self) -> f64 {
        self.inner.borrow().a() as f64
    }

    fn set_r(&self, r: f64) {
        self.inner.borrow_mut().set_r(r as f32);
    }

    fn set_g(&self, g: f64) {
        self.inner.borrow_mut().set_g(g as f32);
    }

    fn set_b(&self, b: f64) {
        self.inner.borrow_mut().set_b(b as f32);
    }

    fn set_a(&self, a: f64) {
        self.inner.borrow_mut().set_a(a as f32);
    }

    fn with_alpha(&self, alpha: f64) -> Self {
        Self {
            inner: RefCell::new(self.inner.borrow().with_alpha(alpha as f32)),
        }
    }

    fn to_a(&self) -> Result<RArray, Error> {
        let ruby = Ruby::get().unwrap();
        let arr = ruby.ary_new();
        let c = self.inner.borrow();
        arr.push(c.r() as f64)?;
        arr.push(c.g() as f64)?;
        arr.push(c.b() as f64)?;
        arr.push(c.a() as f64)?;
        Ok(arr)
    }
}

unsafe impl Send for MagnusColor {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let color_class = module.define_class("Color", ruby.class_object())?;
    color_class.define_singleton_method("new", function!(MagnusColor::new, 4))?;
    color_class.define_singleton_method("rgb", function!(MagnusColor::rgb, 3))?;
    color_class.define_singleton_method("rgba", function!(MagnusColor::rgba, 4))?;
    color_class.define_singleton_method("from_hex", function!(MagnusColor::from_hex, 1))?;
    color_class.define_singleton_method("white", function!(MagnusColor::white, 0))?;
    color_class.define_singleton_method("black", function!(MagnusColor::black, 0))?;
    color_class.define_singleton_method("red", function!(MagnusColor::red, 0))?;
    color_class.define_singleton_method("green", function!(MagnusColor::green, 0))?;
    color_class.define_singleton_method("blue", function!(MagnusColor::blue, 0))?;
    color_class.define_singleton_method("transparent", function!(MagnusColor::transparent, 0))?;
    color_class.define_method("r", method!(MagnusColor::r, 0))?;
    color_class.define_method("g", method!(MagnusColor::g, 0))?;
    color_class.define_method("b", method!(MagnusColor::b, 0))?;
    color_class.define_method("a", method!(MagnusColor::a, 0))?;
    color_class.define_method("r=", method!(MagnusColor::set_r, 1))?;
    color_class.define_method("g=", method!(MagnusColor::set_g, 1))?;
    color_class.define_method("b=", method!(MagnusColor::set_b, 1))?;
    color_class.define_method("a=", method!(MagnusColor::set_a, 1))?;
    color_class.define_method("with_alpha", method!(MagnusColor::with_alpha, 1))?;
    color_class.define_method("to_a", method!(MagnusColor::to_a, 0))?;

    Ok(())
}
