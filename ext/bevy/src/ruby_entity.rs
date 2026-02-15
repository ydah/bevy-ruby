use bevy_ruby::EntityWrapper;
use magnus::{method, prelude::*, Error, RModule, Ruby};

#[magnus::wrap(class = "Bevy::Entity", free_immediately, size)]
pub struct RubyEntity {
    inner: EntityWrapper,
}

impl RubyEntity {
    pub fn new(entity: EntityWrapper) -> Self {
        Self { inner: entity }
    }

    pub fn inner(&self) -> EntityWrapper {
        self.inner
    }

    fn id(&self) -> u64 {
        self.inner.id()
    }
}

impl PartialEq for RubyEntity {
    fn eq(&self, other: &Self) -> bool {
        self.inner == other.inner
    }
}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let class = module.define_class("Entity", ruby.class_object())?;
    class.define_method("id", method!(RubyEntity::id, 0))?;
    Ok(())
}
