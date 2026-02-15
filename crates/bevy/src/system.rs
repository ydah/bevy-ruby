use crate::error::BevyRubyError;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ScheduleLabel {
    Startup,
    Update,
    FixedUpdate,
    PostUpdate,
}

impl ScheduleLabel {
    pub fn from_str(s: &str) -> Result<Self, BevyRubyError> {
        match s.to_lowercase().as_str() {
            "startup" => Ok(ScheduleLabel::Startup),
            "update" => Ok(ScheduleLabel::Update),
            "fixed_update" | "fixedupdate" => Ok(ScheduleLabel::FixedUpdate),
            "post_update" | "postupdate" => Ok(ScheduleLabel::PostUpdate),
            _ => Err(BevyRubyError::SystemError(format!(
                "Unknown schedule: {}",
                s
            ))),
        }
    }
}

#[derive(Clone)]
pub struct SystemDescriptor {
    pub schedule: ScheduleLabel,
    pub param_types: Vec<String>,
}

impl SystemDescriptor {
    pub fn new(schedule: ScheduleLabel) -> Self {
        Self {
            schedule,
            param_types: Vec::new(),
        }
    }

    pub fn with_param(mut self, param_type: &str) -> Self {
        self.param_types.push(param_type.to_string());
        self
    }
}
