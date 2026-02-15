use bevy_ecs::component::ComponentId;
use parking_lot::RwLock;
use std::any::TypeId;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct AttributeDescriptor {
    pub name: String,
    pub attr_type: AttributeType,
    pub default_value: Option<Vec<u8>>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AttributeType {
    Integer,
    Float,
    Boolean,
    String,
    Vec2,
    Vec3,
    Quat,
    Entity,
}

#[derive(Debug, Clone)]
pub struct ComponentMetadata {
    pub name: String,
    pub attributes: Vec<AttributeDescriptor>,
}

#[derive(Debug, Clone)]
pub struct ComponentData {
    pub metadata: ComponentMetadata,
    pub data: HashMap<String, Vec<u8>>,
}

impl ComponentData {
    pub fn new(name: &str) -> Self {
        Self {
            metadata: ComponentMetadata {
                name: name.to_string(),
                attributes: Vec::new(),
            },
            data: HashMap::new(),
        }
    }

    pub fn with_attribute(mut self, name: &str, attr_type: AttributeType) -> Self {
        self.metadata.attributes.push(AttributeDescriptor {
            name: name.to_string(),
            attr_type,
            default_value: None,
        });
        self
    }

    pub fn set_data(&mut self, name: &str, data: Vec<u8>) {
        self.data.insert(name.to_string(), data);
    }

    pub fn get_data(&self, name: &str) -> Option<&Vec<u8>> {
        self.data.get(name)
    }
}

pub struct ComponentRegistry {
    name_to_id: RwLock<HashMap<String, ComponentId>>,
    id_to_metadata: RwLock<HashMap<ComponentId, ComponentMetadata>>,
    #[allow(dead_code)]
    type_to_id: RwLock<HashMap<TypeId, ComponentId>>,
}

impl ComponentRegistry {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            name_to_id: RwLock::new(HashMap::new()),
            id_to_metadata: RwLock::new(HashMap::new()),
            type_to_id: RwLock::new(HashMap::new()),
        })
    }

    pub fn register(&self, name: &str, component_id: ComponentId, metadata: ComponentMetadata) {
        self.name_to_id
            .write()
            .insert(name.to_string(), component_id);
        self.id_to_metadata.write().insert(component_id, metadata);
    }

    pub fn get_id(&self, name: &str) -> Option<ComponentId> {
        self.name_to_id.read().get(name).copied()
    }

    pub fn get_metadata(&self, id: ComponentId) -> Option<ComponentMetadata> {
        self.id_to_metadata.read().get(&id).cloned()
    }

    pub fn is_registered(&self, name: &str) -> bool {
        self.name_to_id.read().contains_key(name)
    }
}

impl Default for ComponentRegistry {
    fn default() -> Self {
        Self {
            name_to_id: RwLock::new(HashMap::new()),
            id_to_metadata: RwLock::new(HashMap::new()),
            type_to_id: RwLock::new(HashMap::new()),
        }
    }
}
