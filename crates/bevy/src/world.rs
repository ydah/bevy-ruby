use crate::component::ComponentRegistry;
use crate::entity::EntityWrapper;
use crate::error::BevyRubyError;
use crate::types::{DynamicComponent, DynamicComponents};
use bevy_ecs::world::World;
use std::cell::RefCell;
use std::sync::Arc;

pub struct WorldWrapper {
    world: RefCell<World>,
    registry: Arc<ComponentRegistry>,
}

impl WorldWrapper {
    pub fn new() -> Self {
        Self {
            world: RefCell::new(World::new()),
            registry: ComponentRegistry::new(),
        }
    }

    pub fn with_registry(registry: Arc<ComponentRegistry>) -> Self {
        Self {
            world: RefCell::new(World::new()),
            registry,
        }
    }

    pub fn spawn(&self) -> EntityWrapper {
        let entity = self.world.borrow_mut().spawn_empty().id();
        EntityWrapper::new(entity)
    }

    pub fn spawn_with_component(&self, component: DynamicComponent) -> EntityWrapper {
        let mut components = DynamicComponents::new();
        components.add(component);
        let entity = self.world.borrow_mut().spawn(components).id();
        EntityWrapper::new(entity)
    }

    pub fn spawn_with_components(&self, component_list: Vec<DynamicComponent>) -> EntityWrapper {
        let mut components = DynamicComponents::new();
        for component in component_list {
            components.add(component);
        }
        let entity = self.world.borrow_mut().spawn(components).id();
        EntityWrapper::new(entity)
    }

    pub fn despawn(&self, entity: EntityWrapper) -> Result<(), BevyRubyError> {
        let mut world = self.world.borrow_mut();
        if world.get_entity(entity.inner()).is_ok() {
            world.despawn(entity.inner());
            Ok(())
        } else {
            Err(BevyRubyError::EntityNotFound(entity.inner()))
        }
    }

    pub fn entity_exists(&self, entity: EntityWrapper) -> bool {
        self.world.borrow().get_entity(entity.inner()).is_ok()
    }

    pub fn insert_component(
        &self,
        entity: EntityWrapper,
        component: DynamicComponent,
    ) -> Result<(), BevyRubyError> {
        let mut world = self.world.borrow_mut();
        match world.get_entity_mut(entity.inner()) {
            Ok(mut entity_mut) => {
                if let Some(mut components) = entity_mut.get_mut::<DynamicComponents>() {
                    components.add(component);
                } else {
                    let mut components = DynamicComponents::new();
                    components.add(component);
                    entity_mut.insert(components);
                }
                Ok(())
            }
            Err(_) => Err(BevyRubyError::EntityNotFound(entity.inner())),
        }
    }

    pub fn get_component(
        &self,
        entity: EntityWrapper,
        type_name: &str,
    ) -> Result<DynamicComponent, BevyRubyError> {
        let world = self.world.borrow();
        match world.get_entity(entity.inner()) {
            Ok(entity_ref) => {
                if let Some(components) = entity_ref.get::<DynamicComponents>() {
                    components.get(type_name).cloned().ok_or_else(|| {
                        BevyRubyError::ComponentNotFound {
                            entity: entity.inner(),
                            component: type_name.to_string(),
                        }
                    })
                } else {
                    Err(BevyRubyError::ComponentNotFound {
                        entity: entity.inner(),
                        component: type_name.to_string(),
                    })
                }
            }
            Err(_) => Err(BevyRubyError::EntityNotFound(entity.inner())),
        }
    }

    pub fn has_component(&self, entity: EntityWrapper, type_name: &str) -> bool {
        let world = self.world.borrow();
        match world.get_entity(entity.inner()) {
            Ok(entity_ref) => {
                if let Some(components) = entity_ref.get::<DynamicComponents>() {
                    components.has(type_name)
                } else {
                    false
                }
            }
            Err(_) => false,
        }
    }

    pub fn query_entities_with(&self, type_names: &[&str]) -> Vec<EntityWrapper> {
        let world = self.world.borrow();
        let mut result = Vec::new();

        for entity in world.iter_entities() {
            if let Some(components) = entity.get::<DynamicComponents>() {
                if components.has_all(type_names) {
                    result.push(EntityWrapper::new(entity.id()));
                }
            }
        }

        result
    }

    pub fn registry(&self) -> &Arc<ComponentRegistry> {
        &self.registry
    }

    pub fn with_world<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&World) -> R,
    {
        f(&self.world.borrow())
    }

    pub fn with_world_mut<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&mut World) -> R,
    {
        f(&mut self.world.borrow_mut())
    }
}

impl Default for WorldWrapper {
    fn default() -> Self {
        Self::new()
    }
}
