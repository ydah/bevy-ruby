use crate::component::ComponentRegistry;
use crate::system::{ScheduleLabel, SystemDescriptor};
use crate::world::WorldWrapper;
use std::sync::Arc;

pub struct AppBuilder {
    registry: Arc<ComponentRegistry>,
    systems: Vec<SystemDescriptor>,
}

impl AppBuilder {
    pub fn new() -> Self {
        Self {
            registry: ComponentRegistry::new(),
            systems: Vec::new(),
        }
    }

    pub fn registry(&self) -> &Arc<ComponentRegistry> {
        &self.registry
    }

    pub fn add_system(&mut self, descriptor: SystemDescriptor) {
        self.systems.push(descriptor);
    }

    pub fn systems_for_schedule(&self, schedule: ScheduleLabel) -> Vec<&SystemDescriptor> {
        self.systems
            .iter()
            .filter(|s| s.schedule == schedule)
            .collect()
    }

    pub fn create_world(&self) -> WorldWrapper {
        WorldWrapper::with_registry(Arc::clone(&self.registry))
    }
}

impl Default for AppBuilder {
    fn default() -> Self {
        Self::new()
    }
}
