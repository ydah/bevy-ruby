use crate::system::ScheduleLabel;
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SystemSet {
    PreUpdate,
    Update,
    PostUpdate,
    First,
    Last,
    Custom(u32),
}

impl Default for SystemSet {
    fn default() -> Self {
        SystemSet::Update
    }
}

#[derive(Debug, Clone)]
pub struct SystemOrdering {
    pub before: Vec<String>,
    pub after: Vec<String>,
}

impl SystemOrdering {
    pub fn new() -> Self {
        Self {
            before: Vec::new(),
            after: Vec::new(),
        }
    }

    pub fn before(mut self, system_name: &str) -> Self {
        self.before.push(system_name.to_string());
        self
    }

    pub fn after(mut self, system_name: &str) -> Self {
        self.after.push(system_name.to_string());
        self
    }
}

impl Default for SystemOrdering {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone)]
pub struct ScheduleConfig {
    pub set: SystemSet,
    pub ordering: SystemOrdering,
    pub run_if: Option<String>,
}

impl ScheduleConfig {
    pub fn new() -> Self {
        Self {
            set: SystemSet::default(),
            ordering: SystemOrdering::new(),
            run_if: None,
        }
    }

    pub fn in_set(mut self, set: SystemSet) -> Self {
        self.set = set;
        self
    }

    pub fn before(mut self, system_name: &str) -> Self {
        self.ordering = self.ordering.before(system_name);
        self
    }

    pub fn after(mut self, system_name: &str) -> Self {
        self.ordering = self.ordering.after(system_name);
        self
    }

    pub fn run_if(mut self, condition: &str) -> Self {
        self.run_if = Some(condition.to_string());
        self
    }
}

impl Default for ScheduleConfig {
    fn default() -> Self {
        Self::new()
    }
}

pub struct Schedule {
    label: ScheduleLabel,
    systems: Vec<(String, ScheduleConfig)>,
    set_order: Vec<SystemSet>,
}

impl Schedule {
    pub fn new(label: ScheduleLabel) -> Self {
        Self {
            label,
            systems: Vec::new(),
            set_order: vec![
                SystemSet::First,
                SystemSet::PreUpdate,
                SystemSet::Update,
                SystemSet::PostUpdate,
                SystemSet::Last,
            ],
        }
    }

    pub fn label(&self) -> ScheduleLabel {
        self.label
    }

    pub fn add_system(&mut self, name: &str, config: ScheduleConfig) {
        self.systems.push((name.to_string(), config));
    }

    pub fn systems(&self) -> &[(String, ScheduleConfig)] {
        &self.systems
    }

    pub fn systems_in_order(&self) -> Vec<&str> {
        let mut by_set: HashMap<SystemSet, Vec<&str>> = HashMap::new();

        for (name, config) in &self.systems {
            by_set.entry(config.set).or_default().push(name.as_str());
        }

        let mut result = Vec::new();
        for set in &self.set_order {
            if let Some(systems) = by_set.get(set) {
                result.extend(systems.iter().copied());
            }
        }

        for (name, config) in &self.systems {
            if let SystemSet::Custom(_) = config.set {
                if !result.contains(&name.as_str()) {
                    result.push(name.as_str());
                }
            }
        }

        result
    }
}

pub struct Schedules {
    schedules: HashMap<ScheduleLabel, Schedule>,
}

impl Schedules {
    pub fn new() -> Self {
        let mut schedules = HashMap::new();
        schedules.insert(ScheduleLabel::Startup, Schedule::new(ScheduleLabel::Startup));
        schedules.insert(ScheduleLabel::Update, Schedule::new(ScheduleLabel::Update));
        schedules.insert(ScheduleLabel::FixedUpdate, Schedule::new(ScheduleLabel::FixedUpdate));
        schedules.insert(ScheduleLabel::PostUpdate, Schedule::new(ScheduleLabel::PostUpdate));
        Self { schedules }
    }

    pub fn get(&self, label: ScheduleLabel) -> Option<&Schedule> {
        self.schedules.get(&label)
    }

    pub fn get_mut(&mut self, label: ScheduleLabel) -> Option<&mut Schedule> {
        self.schedules.get_mut(&label)
    }

    pub fn add_system(&mut self, label: ScheduleLabel, name: &str, config: ScheduleConfig) {
        if let Some(schedule) = self.schedules.get_mut(&label) {
            schedule.add_system(name, config);
        }
    }
}

impl Default for Schedules {
    fn default() -> Self {
        Self::new()
    }
}
