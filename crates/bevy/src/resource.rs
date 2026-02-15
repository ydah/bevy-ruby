use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct ResourceWrapper {
    name: String,
    data: HashMap<String, Vec<u8>>,
}

impl ResourceWrapper {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            data: HashMap::new(),
        }
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn set(&mut self, key: &str, value: Vec<u8>) {
        self.data.insert(key.to_string(), value);
    }

    pub fn get(&self, key: &str) -> Option<&Vec<u8>> {
        self.data.get(key)
    }
}
