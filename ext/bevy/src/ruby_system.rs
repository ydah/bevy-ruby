use bevy_ruby::system::{ScheduleLabel, SystemDescriptor};
use magnus::{function, method, prelude::*, Error, RModule, Ruby, Symbol};
use std::cell::RefCell;

#[magnus::wrap(class = "Bevy::SystemDescriptor", free_immediately, size)]
pub struct RubySystemDescriptor {
    inner: RefCell<SystemDescriptor>,
}

impl RubySystemDescriptor {
    fn new(schedule: Symbol) -> Result<Self, Error> {
        let ruby = Ruby::get().unwrap();
        let schedule_str = schedule.name().map_err(|e| {
            Error::new(ruby.exception_runtime_error(), format!("Invalid schedule symbol: {}", e))
        })?;
        let label = ScheduleLabel::from_str(&schedule_str).map_err(|e| {
            Error::new(ruby.exception_runtime_error(), e.to_string())
        })?;
        Ok(Self {
            inner: RefCell::new(SystemDescriptor::new(label)),
        })
    }

    fn with_param(&self, param_type: String) -> Self {
        let inner = self.inner.borrow();
        let new_descriptor = inner.clone().with_param(&param_type);
        Self {
            inner: RefCell::new(new_descriptor),
        }
    }

    fn schedule(&self) -> String {
        let inner = self.inner.borrow();
        match inner.schedule {
            ScheduleLabel::Startup => "startup".to_string(),
            ScheduleLabel::Update => "update".to_string(),
            ScheduleLabel::FixedUpdate => "fixed_update".to_string(),
            ScheduleLabel::PostUpdate => "post_update".to_string(),
        }
    }

    fn param_types(&self) -> Vec<String> {
        self.inner.borrow().param_types.clone()
    }

    #[allow(dead_code)]
    pub fn inner(&self) -> SystemDescriptor {
        self.inner.borrow().clone()
    }
}

unsafe impl Send for RubySystemDescriptor {}

#[magnus::wrap(class = "Bevy::ScheduleLabel", free_immediately, size)]
pub struct RubyScheduleLabel {
    inner: ScheduleLabel,
}

impl RubyScheduleLabel {
    fn startup() -> Self {
        Self { inner: ScheduleLabel::Startup }
    }

    fn update() -> Self {
        Self { inner: ScheduleLabel::Update }
    }

    fn fixed_update() -> Self {
        Self { inner: ScheduleLabel::FixedUpdate }
    }

    fn post_update() -> Self {
        Self { inner: ScheduleLabel::PostUpdate }
    }

    fn from_string(s: String) -> Result<Self, Error> {
        let ruby = Ruby::get().unwrap();
        let label = ScheduleLabel::from_str(&s).map_err(|e| {
            Error::new(ruby.exception_runtime_error(), e.to_string())
        })?;
        Ok(Self { inner: label })
    }

    fn to_s(&self) -> String {
        match self.inner {
            ScheduleLabel::Startup => "startup".to_string(),
            ScheduleLabel::Update => "update".to_string(),
            ScheduleLabel::FixedUpdate => "fixed_update".to_string(),
            ScheduleLabel::PostUpdate => "post_update".to_string(),
        }
    }

    fn eq(&self, other: &RubyScheduleLabel) -> bool {
        self.inner == other.inner
    }

    #[allow(dead_code)]
    pub fn inner(&self) -> ScheduleLabel {
        self.inner
    }
}

unsafe impl Send for RubyScheduleLabel {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let descriptor_class = module.define_class("SystemDescriptor", ruby.class_object())?;
    descriptor_class.define_singleton_method("new", function!(RubySystemDescriptor::new, 1))?;
    descriptor_class.define_method("with_param", method!(RubySystemDescriptor::with_param, 1))?;
    descriptor_class.define_method("schedule", method!(RubySystemDescriptor::schedule, 0))?;
    descriptor_class.define_method("param_types", method!(RubySystemDescriptor::param_types, 0))?;

    let label_class = module.define_class("ScheduleLabel", ruby.class_object())?;
    label_class.define_singleton_method("startup", function!(RubyScheduleLabel::startup, 0))?;
    label_class.define_singleton_method("update", function!(RubyScheduleLabel::update, 0))?;
    label_class.define_singleton_method("fixed_update", function!(RubyScheduleLabel::fixed_update, 0))?;
    label_class.define_singleton_method("post_update", function!(RubyScheduleLabel::post_update, 0))?;
    label_class.define_singleton_method("from_string", function!(RubyScheduleLabel::from_string, 1))?;
    label_class.define_method("to_s", method!(RubyScheduleLabel::to_s, 0))?;
    label_class.define_method("==", method!(RubyScheduleLabel::eq, 1))?;

    Ok(())
}
