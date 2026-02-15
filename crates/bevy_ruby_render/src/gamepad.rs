use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GamepadButton {
    South,
    East,
    North,
    West,
    LeftTrigger,
    LeftTrigger2,
    RightTrigger,
    RightTrigger2,
    Select,
    Start,
    Mode,
    LeftThumb,
    RightThumb,
    DPadUp,
    DPadDown,
    DPadLeft,
    DPadRight,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GamepadAxisType {
    LeftStickX,
    LeftStickY,
    RightStickX,
    RightStickY,
    LeftTrigger,
    RightTrigger,
}

#[derive(Debug, Clone, Copy)]
pub struct DeadZone {
    pub inner: f32,
    pub outer: f32,
}

impl Default for DeadZone {
    fn default() -> Self {
        Self {
            inner: 0.1,
            outer: 0.95,
        }
    }
}

impl DeadZone {
    pub fn new(inner: f32, outer: f32) -> Self {
        Self {
            inner: inner.clamp(0.0, 1.0),
            outer: outer.clamp(0.0, 1.0),
        }
    }

    pub fn apply(&self, value: f32) -> f32 {
        let abs_value = value.abs();
        if abs_value < self.inner {
            0.0
        } else if abs_value > self.outer {
            value.signum()
        } else {
            let normalized = (abs_value - self.inner) / (self.outer - self.inner);
            normalized * value.signum()
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct RumbleRequest {
    pub strong_magnitude: f32,
    pub weak_magnitude: f32,
    pub duration_secs: f32,
}

impl RumbleRequest {
    pub fn new(strong: f32, weak: f32, duration: f32) -> Self {
        Self {
            strong_magnitude: strong.clamp(0.0, 1.0),
            weak_magnitude: weak.clamp(0.0, 1.0),
            duration_secs: duration.max(0.0),
        }
    }

    pub fn strong(magnitude: f32, duration: f32) -> Self {
        Self::new(magnitude, 0.0, duration)
    }

    pub fn weak(magnitude: f32, duration: f32) -> Self {
        Self::new(0.0, magnitude, duration)
    }

    pub fn both(magnitude: f32, duration: f32) -> Self {
        Self::new(magnitude, magnitude, duration)
    }
}

#[derive(Debug, Clone, Copy)]
pub struct Vec2 {
    pub x: f32,
    pub y: f32,
}

impl Vec2 {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }

    pub fn zero() -> Self {
        Self { x: 0.0, y: 0.0 }
    }

    pub fn length(&self) -> f32 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    pub fn normalized(&self) -> Self {
        let len = self.length();
        if len > 0.0 {
            Self {
                x: self.x / len,
                y: self.y / len,
            }
        } else {
            Self::zero()
        }
    }

    pub fn apply_deadzone(&self, deadzone: &DeadZone) -> Self {
        let len = self.length();
        if len < deadzone.inner {
            Self::zero()
        } else if len > deadzone.outer {
            self.normalized()
        } else {
            let normalized_len = (len - deadzone.inner) / (deadzone.outer - deadzone.inner);
            let normalized = self.normalized();
            Self {
                x: normalized.x * normalized_len,
                y: normalized.y * normalized_len,
            }
        }
    }
}

#[derive(Debug, Clone)]
pub struct GamepadState {
    pub id: u32,
    pub name: String,
    pub connected: bool,
    buttons: HashMap<GamepadButton, ButtonState>,
    axes: HashMap<GamepadAxisType, f32>,
    dead_zones: HashMap<GamepadAxisType, DeadZone>,
    stick_dead_zone: DeadZone,
    pub pending_rumble: Option<RumbleRequest>,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct ButtonState {
    pub pressed: bool,
    pub just_pressed: bool,
    pub just_released: bool,
    pub value: f32,
}

impl GamepadState {
    pub fn new(id: u32) -> Self {
        Self {
            id,
            name: format!("Gamepad {}", id),
            connected: true,
            buttons: HashMap::new(),
            axes: HashMap::new(),
            dead_zones: HashMap::new(),
            stick_dead_zone: DeadZone::default(),
            pending_rumble: None,
        }
    }

    pub fn with_name(mut self, name: String) -> Self {
        self.name = name;
        self
    }

    pub fn set_stick_dead_zone(&mut self, dead_zone: DeadZone) {
        self.stick_dead_zone = dead_zone;
    }

    pub fn set_axis_dead_zone(&mut self, axis: GamepadAxisType, dead_zone: DeadZone) {
        self.dead_zones.insert(axis, dead_zone);
    }

    pub fn press(&mut self, button: GamepadButton) {
        let state = self.buttons.entry(button).or_default();
        if !state.pressed {
            state.just_pressed = true;
        }
        state.pressed = true;
        state.value = 1.0;
    }

    pub fn release(&mut self, button: GamepadButton) {
        if let Some(state) = self.buttons.get_mut(&button) {
            if state.pressed {
                state.just_released = true;
            }
            state.pressed = false;
            state.value = 0.0;
        }
    }

    pub fn set_button_value(&mut self, button: GamepadButton, value: f32) {
        let state = self.buttons.entry(button).or_default();
        let was_pressed = state.pressed;
        state.value = value;
        state.pressed = value > 0.5;
        if !was_pressed && state.pressed {
            state.just_pressed = true;
        } else if was_pressed && !state.pressed {
            state.just_released = true;
        }
    }

    pub fn pressed(&self, button: GamepadButton) -> bool {
        self.buttons
            .get(&button)
            .is_some_and(|state| state.pressed)
    }

    pub fn just_pressed(&self, button: GamepadButton) -> bool {
        self.buttons
            .get(&button)
            .is_some_and(|state| state.just_pressed)
    }

    pub fn just_released(&self, button: GamepadButton) -> bool {
        self.buttons
            .get(&button)
            .is_some_and(|state| state.just_released)
    }

    pub fn button_value(&self, button: GamepadButton) -> f32 {
        self.buttons.get(&button).map_or(0.0, |state| state.value)
    }

    pub fn set_axis(&mut self, axis: GamepadAxisType, value: f32) {
        self.axes.insert(axis, value.clamp(-1.0, 1.0));
    }

    pub fn axis_raw(&self, axis: GamepadAxisType) -> f32 {
        self.axes.get(&axis).copied().unwrap_or(0.0)
    }

    pub fn axis(&self, axis: GamepadAxisType) -> f32 {
        let raw = self.axis_raw(axis);
        let default_dead_zone = DeadZone::default();
        let dead_zone = self.dead_zones.get(&axis).unwrap_or(&default_dead_zone);
        dead_zone.apply(raw)
    }

    pub fn left_stick_raw(&self) -> Vec2 {
        Vec2::new(
            self.axis_raw(GamepadAxisType::LeftStickX),
            self.axis_raw(GamepadAxisType::LeftStickY),
        )
    }

    pub fn left_stick(&self) -> Vec2 {
        self.left_stick_raw().apply_deadzone(&self.stick_dead_zone)
    }

    pub fn right_stick_raw(&self) -> Vec2 {
        Vec2::new(
            self.axis_raw(GamepadAxisType::RightStickX),
            self.axis_raw(GamepadAxisType::RightStickY),
        )
    }

    pub fn right_stick(&self) -> Vec2 {
        self.right_stick_raw().apply_deadzone(&self.stick_dead_zone)
    }

    pub fn left_trigger(&self) -> f32 {
        self.axis(GamepadAxisType::LeftTrigger).max(0.0)
    }

    pub fn right_trigger(&self) -> f32 {
        self.axis(GamepadAxisType::RightTrigger).max(0.0)
    }

    pub fn rumble(&mut self, request: RumbleRequest) {
        self.pending_rumble = Some(request);
    }

    pub fn stop_rumble(&mut self) {
        self.pending_rumble = Some(RumbleRequest::new(0.0, 0.0, 0.0));
    }

    pub fn clear_frame_state(&mut self) {
        for state in self.buttons.values_mut() {
            state.just_pressed = false;
            state.just_released = false;
        }
        self.pending_rumble = None;
    }

    pub fn reset(&mut self) {
        self.buttons.clear();
        self.axes.clear();
        self.pending_rumble = None;
    }
}

#[derive(Debug, Clone, Default)]
pub struct GamepadManager {
    gamepads: HashMap<u32, GamepadState>,
    default_stick_dead_zone: DeadZone,
}

impl GamepadManager {
    pub fn new() -> Self {
        Self {
            gamepads: HashMap::new(),
            default_stick_dead_zone: DeadZone::default(),
        }
    }

    pub fn set_default_dead_zone(&mut self, dead_zone: DeadZone) {
        self.default_stick_dead_zone = dead_zone;
    }

    pub fn connect(&mut self, id: u32) -> &mut GamepadState {
        let mut state = GamepadState::new(id);
        state.set_stick_dead_zone(self.default_stick_dead_zone);
        self.gamepads.entry(id).or_insert(state)
    }

    pub fn connect_with_name(&mut self, id: u32, name: String) -> &mut GamepadState {
        let mut state = GamepadState::new(id).with_name(name);
        state.set_stick_dead_zone(self.default_stick_dead_zone);
        self.gamepads.entry(id).or_insert(state)
    }

    pub fn disconnect(&mut self, id: u32) -> Option<GamepadState> {
        self.gamepads.remove(&id)
    }

    pub fn is_connected(&self, id: u32) -> bool {
        self.gamepads.contains_key(&id)
    }

    pub fn get(&self, id: u32) -> Option<&GamepadState> {
        self.gamepads.get(&id)
    }

    pub fn get_mut(&mut self, id: u32) -> Option<&mut GamepadState> {
        self.gamepads.get_mut(&id)
    }

    pub fn connected_ids(&self) -> Vec<u32> {
        self.gamepads.keys().copied().collect()
    }

    pub fn count(&self) -> usize {
        self.gamepads.len()
    }

    pub fn iter(&self) -> impl Iterator<Item = &GamepadState> {
        self.gamepads.values()
    }

    pub fn iter_mut(&mut self) -> impl Iterator<Item = &mut GamepadState> {
        self.gamepads.values_mut()
    }

    pub fn clear_frame_state(&mut self) {
        for gamepad in self.gamepads.values_mut() {
            gamepad.clear_frame_state();
        }
    }

    pub fn any_pressed(&self, button: GamepadButton) -> bool {
        self.gamepads.values().any(|gp| gp.pressed(button))
    }

    pub fn any_just_pressed(&self, button: GamepadButton) -> bool {
        self.gamepads.values().any(|gp| gp.just_pressed(button))
    }

    pub fn first(&self) -> Option<&GamepadState> {
        self.gamepads.values().next()
    }

    pub fn first_mut(&mut self) -> Option<&mut GamepadState> {
        self.gamepads.values_mut().next()
    }
}
