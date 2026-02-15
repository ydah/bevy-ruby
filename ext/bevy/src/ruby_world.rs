use bevy_ruby::WorldWrapper;
use magnus::{function, method, prelude::*, Error, RArray, RModule, Ruby};
use std::cell::RefCell;

use crate::ruby_component::RubyComponent;
use crate::ruby_entity::RubyEntity;

#[magnus::wrap(class = "Bevy::World", free_immediately, size)]
pub struct RubyWorld {
    inner: RefCell<WorldWrapper>,
}

impl RubyWorld {
    pub fn new() -> Self {
        Self {
            inner: RefCell::new(WorldWrapper::new()),
        }
    }

    pub fn from_wrapper(wrapper: WorldWrapper) -> Self {
        Self {
            inner: RefCell::new(wrapper),
        }
    }

    fn spawn(&self) -> RubyEntity {
        let entity = self.inner.borrow().spawn();
        RubyEntity::new(entity)
    }

    fn spawn_with(&self, components: RArray) -> Result<RubyEntity, Error> {
        let mut component_list = Vec::new();

        for item in components.into_iter() {
            let component = <&RubyComponent>::try_convert(item)?;
            component_list.push(component.inner());
        }

        let entity = self.inner.borrow().spawn_with_components(component_list);
        Ok(RubyEntity::new(entity))
    }

    fn entity_exists(&self, entity: &RubyEntity) -> bool {
        self.inner.borrow().entity_exists(entity.inner())
    }

    fn despawn(&self, entity: &RubyEntity) -> Result<(), Error> {
        self.inner
            .borrow()
            .despawn(entity.inner())
            .map_err(|e| Error::new(Ruby::get().unwrap().exception_runtime_error(), e.to_string()))
    }

    fn insert(&self, entity: &RubyEntity, component: &RubyComponent) -> Result<(), Error> {
        self.inner
            .borrow()
            .insert_component(entity.inner(), component.inner())
            .map_err(|e| Error::new(Ruby::get().unwrap().exception_runtime_error(), e.to_string()))
    }

    fn get(&self, entity: &RubyEntity, type_name: String) -> Result<RubyComponent, Error> {
        self.inner
            .borrow()
            .get_component(entity.inner(), &type_name)
            .map(RubyComponent::from_dynamic)
            .map_err(|e| Error::new(Ruby::get().unwrap().exception_runtime_error(), e.to_string()))
    }

    fn has_component(&self, entity: &RubyEntity, type_name: String) -> bool {
        self.inner.borrow().has_component(entity.inner(), &type_name)
    }

    fn query(&self, type_names: RArray) -> Result<RArray, Error> {
        let ruby = Ruby::get().unwrap();
        let mut names: Vec<String> = Vec::new();

        for item in type_names.into_iter() {
            names.push(String::try_convert(item)?);
        }

        let name_refs: Vec<&str> = names.iter().map(|s| s.as_str()).collect();
        let entities = self.inner.borrow().query_entities_with(&name_refs);

        let result = ruby.ary_new();
        for entity in entities {
            result.push(RubyEntity::new(entity))?;
        }

        Ok(result)
    }
}

unsafe impl Send for RubyWorld {}

pub fn define(ruby: &Ruby, module: &RModule) -> Result<(), Error> {
    let class = module.define_class("World", ruby.class_object())?;
    class.define_singleton_method("new", function!(RubyWorld::new, 0))?;
    class.define_method("spawn", method!(RubyWorld::spawn, 0))?;
    class.define_method("spawn_with", method!(RubyWorld::spawn_with, 1))?;
    class.define_method("entity_exists?", method!(RubyWorld::entity_exists, 1))?;
    class.define_method("despawn_native", method!(RubyWorld::despawn, 1))?;
    class.define_method("insert", method!(RubyWorld::insert, 2))?;
    class.define_method("get", method!(RubyWorld::get, 2))?;
    class.define_method("has_component?", method!(RubyWorld::has_component, 2))?;
    class.define_method("query", method!(RubyWorld::query, 1))?;
    Ok(())
}
