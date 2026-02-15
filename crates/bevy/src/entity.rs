use bevy_ecs::entity::Entity;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct EntityWrapper(pub Entity);

impl EntityWrapper {
    pub fn new(entity: Entity) -> Self {
        Self(entity)
    }

    pub fn id(&self) -> u64 {
        self.0.to_bits()
    }

    pub fn inner(&self) -> Entity {
        self.0
    }
}

impl From<Entity> for EntityWrapper {
    fn from(entity: Entity) -> Self {
        Self(entity)
    }
}

impl From<EntityWrapper> for Entity {
    fn from(wrapper: EntityWrapper) -> Self {
        wrapper.0
    }
}
