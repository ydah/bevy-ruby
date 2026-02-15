use bevy_ruby::{AppBuilder, WorldWrapper};
use bevy_ruby::system::ScheduleLabel;
use magnus::{function, method, prelude::*, Error, RModule, Ruby, Symbol};
use std::cell::RefCell;
use std::sync::Arc;

use crate::ruby_world::RubyWorld;

#[magnus::wrap(class = "Bevy::AppBuilder", free_immediately, size)]
pub struct RubyAppBuilder {
    inner: RefCell<AppBuilder>,
}

impl RubyAppBuilder {
    fn new() -> Self {
        Self {
            inner: RefCell::new(AppBuilder::new()),
        }
    }

    fn add_system(&self, schedule: Symbol, _param_types: Vec<String>) -> Result<(), Error> {
        let ruby = Ruby::get().unwrap();
        let schedule_str = schedule.name().map_err(|e| {
            Error::new(ruby.exception_runtime_error(), format!("Invalid schedule symbol: {}", e))
        })?;
        let label = ScheduleLabel::from_str(&schedule_str).map_err(|e| {
            Error::new(ruby.exception_runtime_error(), e.to_string())
        })?;
        let descriptor = bevy_ruby::system::SystemDescriptor::new(label);
        self.inner.borrow_mut().add_system(descriptor);
        Ok(())
    }

    fn systems_for_schedule(&self, schedule: Symbol) -> Result<usize, Error> {
        let ruby = Ruby::get().unwrap();
        let schedule_str = schedule.name().map_err(|e| {
            Error::new(ruby.exception_runtime_error(), format!("Invalid schedule symbol: {}", e))
        })?;
        let label = ScheduleLabel::from_str(&schedule_str).map_err(|e| {
            Error::new(ruby.exception_runtime_error(), e.to_string())
        })?;
        Ok(self.inner.borrow().systems_for_schedule(label).len())
    }

    fn create_world(&self) -> RubyWorld {
        RubyWorld::from_wrapper(self.inner.borrow().create_world())
    }

    #[allow(dead_code)]
    pub fn inner(&self) -> std::cell::Ref<'_, AppBuilder> {
        self.inner.borrow()
    }
}

unsafe impl Send for RubyAppBuilder {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let class = module.define_class("AppBuilder", ruby.class_object())?;
    class.define_singleton_method("new", function!(RubyAppBuilder::new, 0))?;
    class.define_method("add_system", method!(RubyAppBuilder::add_system, 2))?;
    class.define_method("systems_for_schedule", method!(RubyAppBuilder::systems_for_schedule, 1))?;
    class.define_method("create_world", method!(RubyAppBuilder::create_world, 0))?;

    Ok(())
}
