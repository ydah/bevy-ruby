use std::any::TypeId;
use std::collections::HashMap;
use crate::types::DynamicValue;

#[derive(Debug, Clone)]
pub struct Event {
    pub type_name: String,
    pub data: HashMap<String, DynamicValue>,
}

impl Event {
    pub fn new(type_name: &str) -> Self {
        Self {
            type_name: type_name.to_string(),
            data: HashMap::new(),
        }
    }

    pub fn with_data(type_name: &str, data: HashMap<String, DynamicValue>) -> Self {
        Self {
            type_name: type_name.to_string(),
            data,
        }
    }

    pub fn set(&mut self, key: &str, value: DynamicValue) {
        self.data.insert(key.to_string(), value);
    }

    pub fn get(&self, key: &str) -> Option<&DynamicValue> {
        self.data.get(key)
    }

    pub fn type_name(&self) -> &str {
        &self.type_name
    }
}

pub struct EventQueue {
    events: Vec<Event>,
    read_index: usize,
}

impl EventQueue {
    pub fn new() -> Self {
        Self {
            events: Vec::new(),
            read_index: 0,
        }
    }

    pub fn send(&mut self, event: Event) {
        self.events.push(event);
    }

    pub fn read(&mut self) -> impl Iterator<Item = &Event> {
        let start = self.read_index;
        self.read_index = self.events.len();
        self.events[start..].iter()
    }

    pub fn clear(&mut self) {
        self.events.clear();
        self.read_index = 0;
    }

    pub fn len(&self) -> usize {
        self.events.len()
    }

    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    pub fn unread_count(&self) -> usize {
        self.events.len().saturating_sub(self.read_index)
    }
}

impl Default for EventQueue {
    fn default() -> Self {
        Self::new()
    }
}

pub struct Events {
    queues: HashMap<String, EventQueue>,
    type_ids: HashMap<TypeId, String>,
}

impl Events {
    pub fn new() -> Self {
        Self {
            queues: HashMap::new(),
            type_ids: HashMap::new(),
        }
    }

    pub fn register(&mut self, type_name: &str) {
        if !self.queues.contains_key(type_name) {
            self.queues.insert(type_name.to_string(), EventQueue::new());
        }
    }

    pub fn register_with_type_id(&mut self, type_name: &str, type_id: TypeId) {
        self.register(type_name);
        self.type_ids.insert(type_id, type_name.to_string());
    }

    pub fn send(&mut self, event: Event) {
        let type_name = event.type_name.clone();
        if let Some(queue) = self.queues.get_mut(&type_name) {
            queue.send(event);
        }
    }

    pub fn read(&mut self, type_name: &str) -> Option<impl Iterator<Item = &Event>> {
        self.queues.get_mut(type_name).map(|q| q.read())
    }

    pub fn clear(&mut self, type_name: &str) {
        if let Some(queue) = self.queues.get_mut(type_name) {
            queue.clear();
        }
    }

    pub fn clear_all(&mut self) {
        for queue in self.queues.values_mut() {
            queue.clear();
        }
    }

    pub fn get_queue(&self, type_name: &str) -> Option<&EventQueue> {
        self.queues.get(type_name)
    }

    pub fn get_queue_mut(&mut self, type_name: &str) -> Option<&mut EventQueue> {
        self.queues.get_mut(type_name)
    }

    pub fn is_registered(&self, type_name: &str) -> bool {
        self.queues.contains_key(type_name)
    }
}

impl Default for Events {
    fn default() -> Self {
        Self::new()
    }
}

pub struct EventReader<'a> {
    queue: &'a mut EventQueue,
}

impl<'a> EventReader<'a> {
    pub fn new(queue: &'a mut EventQueue) -> Self {
        Self { queue }
    }

    pub fn read(&mut self) -> impl Iterator<Item = &Event> {
        self.queue.read()
    }

    pub fn is_empty(&self) -> bool {
        self.queue.unread_count() == 0
    }

    pub fn len(&self) -> usize {
        self.queue.unread_count()
    }
}

pub struct EventWriter<'a> {
    queue: &'a mut EventQueue,
}

impl<'a> EventWriter<'a> {
    pub fn new(queue: &'a mut EventQueue) -> Self {
        Self { queue }
    }

    pub fn send(&mut self, event: Event) {
        self.queue.send(event);
    }

    pub fn send_default(&mut self, type_name: &str) {
        self.queue.send(Event::new(type_name));
    }
}
