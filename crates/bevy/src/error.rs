use bevy_ecs::entity::Entity;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum BevyRubyError {
    #[error("Entity {0:?} not found")]
    EntityNotFound(Entity),

    #[error("Component '{component}' not found on entity {entity:?}")]
    ComponentNotFound { entity: Entity, component: String },

    #[error("Component '{0}' already exists")]
    ComponentAlreadyExists(String),

    #[error("Resource '{0}' not found")]
    ResourceNotFound(String),

    #[error("Resource '{0}' already exists")]
    ResourceAlreadyExists(String),

    #[error("Component '{0}' is not registered")]
    ComponentNotRegistered(String),

    #[error("Invalid type conversion: expected {expected}, got {actual}")]
    InvalidType { expected: String, actual: String },

    #[error("System error: {0}")]
    SystemError(String),

    #[error("World is not available")]
    WorldNotAvailable,
}
