use bevy_ecs::component::Component;
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq)]
pub enum DynamicValue {
    Nil,
    Boolean(bool),
    Integer(i64),
    Float(f64),
    String(String),
    Symbol(String),
    Array(Vec<DynamicValue>),
    Hash(HashMap<String, DynamicValue>),
}

impl DynamicValue {
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            DynamicValue::Boolean(v) => Some(*v),
            _ => None,
        }
    }

    pub fn as_i64(&self) -> Option<i64> {
        match self {
            DynamicValue::Integer(v) => Some(*v),
            _ => None,
        }
    }

    pub fn as_f64(&self) -> Option<f64> {
        match self {
            DynamicValue::Float(v) => Some(*v),
            DynamicValue::Integer(v) => Some(*v as f64),
            _ => None,
        }
    }

    pub fn as_str(&self) -> Option<&str> {
        match self {
            DynamicValue::String(v) => Some(v),
            DynamicValue::Symbol(v) => Some(v),
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct DynamicComponent {
    pub type_name: String,
    pub data: HashMap<String, DynamicValue>,
}

impl DynamicComponent {
    pub fn new(type_name: &str) -> Self {
        Self {
            type_name: type_name.to_string(),
            data: HashMap::new(),
        }
    }

    pub fn with_field(mut self, name: &str, value: DynamicValue) -> Self {
        self.data.insert(name.to_string(), value);
        self
    }

    pub fn set(&mut self, name: &str, value: DynamicValue) {
        self.data.insert(name.to_string(), value);
    }

    pub fn get(&self, name: &str) -> Option<&DynamicValue> {
        self.data.get(name)
    }

    pub fn type_name(&self) -> &str {
        &self.type_name
    }
}

#[derive(Debug, Clone, Component, Default)]
pub struct DynamicComponents {
    components: Vec<DynamicComponent>,
}

impl DynamicComponents {
    pub fn new() -> Self {
        Self {
            components: Vec::new(),
        }
    }

    pub fn add(&mut self, component: DynamicComponent) {
        let type_name = component.type_name.clone();
        self.components.retain(|c| c.type_name != type_name);
        self.components.push(component);
    }

    pub fn get(&self, type_name: &str) -> Option<&DynamicComponent> {
        self.components.iter().find(|c| c.type_name == type_name)
    }

    pub fn get_mut(&mut self, type_name: &str) -> Option<&mut DynamicComponent> {
        self.components
            .iter_mut()
            .find(|c| c.type_name == type_name)
    }

    pub fn has(&self, type_name: &str) -> bool {
        self.components.iter().any(|c| c.type_name == type_name)
    }

    pub fn has_all(&self, type_names: &[&str]) -> bool {
        type_names.iter().all(|name| self.has(name))
    }

    pub fn remove(&mut self, type_name: &str) -> Option<DynamicComponent> {
        let pos = self
            .components
            .iter()
            .position(|c| c.type_name == type_name)?;
        Some(self.components.remove(pos))
    }

    pub fn iter(&self) -> impl Iterator<Item = &DynamicComponent> {
        self.components.iter()
    }

    pub fn type_names(&self) -> Vec<&str> {
        self.components.iter().map(|c| c.type_name.as_str()).collect()
    }
}
