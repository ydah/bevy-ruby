use bevy_ecs::component::ComponentId;

#[derive(Debug, Clone)]
pub enum QueryFilter {
    With(ComponentId),
    Without(ComponentId),
    Changed(ComponentId),
    Added(ComponentId),
}

#[derive(Clone)]
pub struct QueryBuilder {
    fetch: Vec<String>,
    filters: Vec<QueryFilter>,
}

impl QueryBuilder {
    pub fn new() -> Self {
        Self {
            fetch: Vec::new(),
            filters: Vec::new(),
        }
    }

    pub fn fetch(mut self, component_name: &str) -> Self {
        self.fetch.push(component_name.to_string());
        self
    }

    pub fn filter_with(mut self, component_id: ComponentId) -> Self {
        self.filters.push(QueryFilter::With(component_id));
        self
    }

    pub fn filter_without(mut self, component_id: ComponentId) -> Self {
        self.filters.push(QueryFilter::Without(component_id));
        self
    }

    pub fn fetch_components(&self) -> &[String] {
        &self.fetch
    }

    pub fn filters(&self) -> &[QueryFilter] {
        &self.filters
    }
}

impl Default for QueryBuilder {
    fn default() -> Self {
        Self::new()
    }
}
