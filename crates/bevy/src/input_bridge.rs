//! Input bridge module for converting Bevy input to Ruby-compatible format.

use std::collections::{HashMap, HashSet};

#[cfg(feature = "rendering")]
use bevy_ecs::world::World;
#[cfg(feature = "rendering")]
use bevy_input::{ButtonInput, keyboard::KeyCode, mouse::MouseButton};
#[cfg(feature = "rendering")]
use bevy_window::{PrimaryWindow, Window};

/// Holds the current input state for Ruby.
#[derive(Debug, Default, Clone)]
pub struct InputState {
    pub keys_pressed: HashSet<String>,
    pub keys_just_pressed: HashSet<String>,
    pub keys_just_released: HashSet<String>,
    pub mouse_buttons_pressed: HashSet<String>,
    pub mouse_buttons_just_pressed: HashSet<String>,
    pub mouse_position: (f32, f32),
    pub mouse_delta: (f32, f32),
    pub gamepads: HashMap<u64, GamepadInputState>,
}

#[derive(Debug, Default, Clone)]
pub struct GamepadInputState {
    pub id: u64,
    pub name: String,
    pub buttons_pressed: HashSet<String>,
    pub buttons_just_pressed: HashSet<String>,
    pub buttons_just_released: HashSet<String>,
    pub axes: HashMap<String, f32>,
}

impl InputState {
    /// Creates a new empty input state.
    pub fn new() -> Self {
        Self::default()
    }

    /// Updates the input state from Bevy's world.
    #[cfg(feature = "rendering")]
    pub fn update_from_bevy(&mut self, world: &mut World) {
        self.update_keyboard(world);
        self.update_mouse(world);
        self.update_cursor_position(world);
    }

    #[cfg(feature = "rendering")]
    fn update_keyboard(&mut self, world: &World) {
        if let Some(keyboard) = world.get_resource::<ButtonInput<KeyCode>>() {
            self.keys_pressed.clear();
            self.keys_just_pressed.clear();
            self.keys_just_released.clear();

            for key in keyboard.get_pressed() {
                self.keys_pressed.insert(keycode_to_string(*key));
            }
            for key in keyboard.get_just_pressed() {
                self.keys_just_pressed.insert(keycode_to_string(*key));
            }
            for key in keyboard.get_just_released() {
                self.keys_just_released.insert(keycode_to_string(*key));
            }
        }
    }

    #[cfg(feature = "rendering")]
    fn update_mouse(&mut self, world: &World) {
        if let Some(mouse) = world.get_resource::<ButtonInput<MouseButton>>() {
            self.mouse_buttons_pressed.clear();
            self.mouse_buttons_just_pressed.clear();

            for button in mouse.get_pressed() {
                self.mouse_buttons_pressed
                    .insert(mouse_button_to_string(*button));
            }
            for button in mouse.get_just_pressed() {
                self.mouse_buttons_just_pressed
                    .insert(mouse_button_to_string(*button));
            }
        }
    }

    #[cfg(feature = "rendering")]
    fn update_cursor_position(&mut self, world: &mut World) {
        // Query for primary window to get cursor position
        let mut query = world.query_filtered::<&Window, bevy_ecs::query::With<PrimaryWindow>>();
        if let Some(window) = query.iter(world).next() {
            if let Some(pos) = window.cursor_position() {
                let old_pos = self.mouse_position;
                self.mouse_position = (pos.x, pos.y);
                self.mouse_delta = (pos.x - old_pos.0, pos.y - old_pos.1);
            }
        }
    }

    /// Checks if a key is currently pressed.
    pub fn key_pressed(&self, key: &str) -> bool {
        self.keys_pressed.contains(key)
    }

    /// Checks if a key was just pressed this frame.
    pub fn key_just_pressed(&self, key: &str) -> bool {
        self.keys_just_pressed.contains(key)
    }

    /// Checks if a key was just released this frame.
    pub fn key_just_released(&self, key: &str) -> bool {
        self.keys_just_released.contains(key)
    }

    /// Checks if a mouse button is currently pressed.
    pub fn mouse_button_pressed(&self, button: &str) -> bool {
        self.mouse_buttons_pressed.contains(button)
    }

    /// Checks if a mouse button was just pressed this frame.
    pub fn mouse_button_just_pressed(&self, button: &str) -> bool {
        self.mouse_buttons_just_pressed.contains(button)
    }

    /// Returns all currently pressed keys.
    pub fn get_pressed_keys(&self) -> Vec<String> {
        self.keys_pressed.iter().cloned().collect()
    }

    /// Returns all gamepad states currently known for this frame.
    pub fn gamepad_states(&self) -> Vec<GamepadInputState> {
        self.gamepads.values().cloned().collect()
    }

    /// Clears all input state for a new frame.
    pub fn clear(&mut self) {
        self.keys_pressed.clear();
        self.keys_just_pressed.clear();
        self.keys_just_released.clear();
        self.mouse_buttons_pressed.clear();
        self.mouse_buttons_just_pressed.clear();
        self.gamepads.clear();
    }

    /// Sets a key as pressed.
    pub fn set_pressed(&mut self, key: &str) {
        self.keys_pressed.insert(key.to_string());
    }

    /// Sets a key as just pressed.
    pub fn set_just_pressed(&mut self, key: &str) {
        self.keys_just_pressed.insert(key.to_string());
    }

    /// Sets a key as just released.
    pub fn set_just_released(&mut self, key: &str) {
        self.keys_just_released.insert(key.to_string());
    }

    /// Sets a mouse button as pressed.
    pub fn set_mouse_pressed(&mut self, button: &str) {
        self.mouse_buttons_pressed.insert(button.to_string());
    }

    /// Sets a mouse button as just pressed.
    pub fn set_mouse_just_pressed(&mut self, button: &str) {
        self.mouse_buttons_just_pressed.insert(button.to_string());
    }

    /// Ensures a gamepad slot exists for this frame and updates its display name.
    pub fn set_gamepad_connected(&mut self, id: u64, name: &str) {
        let state = self
            .gamepads
            .entry(id)
            .or_insert_with(|| GamepadInputState {
                id,
                ..Default::default()
            });
        state.name = name.to_string();
    }

    /// Marks a gamepad button as currently pressed.
    pub fn set_gamepad_button_pressed(&mut self, id: u64, button: &str) {
        let state = self
            .gamepads
            .entry(id)
            .or_insert_with(|| GamepadInputState {
                id,
                ..Default::default()
            });
        state.buttons_pressed.insert(button.to_string());
    }

    /// Marks a gamepad button as just pressed.
    pub fn set_gamepad_button_just_pressed(&mut self, id: u64, button: &str) {
        let state = self
            .gamepads
            .entry(id)
            .or_insert_with(|| GamepadInputState {
                id,
                ..Default::default()
            });
        state.buttons_just_pressed.insert(button.to_string());
    }

    /// Marks a gamepad button as just released.
    pub fn set_gamepad_button_just_released(&mut self, id: u64, button: &str) {
        let state = self
            .gamepads
            .entry(id)
            .or_insert_with(|| GamepadInputState {
                id,
                ..Default::default()
            });
        state.buttons_just_released.insert(button.to_string());
    }

    /// Sets a gamepad axis value.
    pub fn set_gamepad_axis(&mut self, id: u64, axis: &str, value: f32) {
        let state = self
            .gamepads
            .entry(id)
            .or_insert_with(|| GamepadInputState {
                id,
                ..Default::default()
            });
        state.axes.insert(axis.to_string(), value);
    }
}

/// Converts a Bevy KeyCode to a Ruby-compatible string.
#[cfg(feature = "rendering")]
fn keycode_to_string(key: KeyCode) -> String {
    match key {
        KeyCode::KeyA => "A".to_string(),
        KeyCode::KeyB => "B".to_string(),
        KeyCode::KeyC => "C".to_string(),
        KeyCode::KeyD => "D".to_string(),
        KeyCode::KeyE => "E".to_string(),
        KeyCode::KeyF => "F".to_string(),
        KeyCode::KeyG => "G".to_string(),
        KeyCode::KeyH => "H".to_string(),
        KeyCode::KeyI => "I".to_string(),
        KeyCode::KeyJ => "J".to_string(),
        KeyCode::KeyK => "K".to_string(),
        KeyCode::KeyL => "L".to_string(),
        KeyCode::KeyM => "M".to_string(),
        KeyCode::KeyN => "N".to_string(),
        KeyCode::KeyO => "O".to_string(),
        KeyCode::KeyP => "P".to_string(),
        KeyCode::KeyQ => "Q".to_string(),
        KeyCode::KeyR => "R".to_string(),
        KeyCode::KeyS => "S".to_string(),
        KeyCode::KeyT => "T".to_string(),
        KeyCode::KeyU => "U".to_string(),
        KeyCode::KeyV => "V".to_string(),
        KeyCode::KeyW => "W".to_string(),
        KeyCode::KeyX => "X".to_string(),
        KeyCode::KeyY => "Y".to_string(),
        KeyCode::KeyZ => "Z".to_string(),
        KeyCode::Digit0 => "0".to_string(),
        KeyCode::Digit1 => "1".to_string(),
        KeyCode::Digit2 => "2".to_string(),
        KeyCode::Digit3 => "3".to_string(),
        KeyCode::Digit4 => "4".to_string(),
        KeyCode::Digit5 => "5".to_string(),
        KeyCode::Digit6 => "6".to_string(),
        KeyCode::Digit7 => "7".to_string(),
        KeyCode::Digit8 => "8".to_string(),
        KeyCode::Digit9 => "9".to_string(),
        KeyCode::ArrowUp => "UP".to_string(),
        KeyCode::ArrowDown => "DOWN".to_string(),
        KeyCode::ArrowLeft => "LEFT".to_string(),
        KeyCode::ArrowRight => "RIGHT".to_string(),
        KeyCode::Space => "SPACE".to_string(),
        KeyCode::Enter => "ENTER".to_string(),
        KeyCode::Escape => "ESCAPE".to_string(),
        KeyCode::Tab => "TAB".to_string(),
        KeyCode::Backspace => "BACKSPACE".to_string(),
        KeyCode::Delete => "DELETE".to_string(),
        KeyCode::ShiftLeft => "SHIFT_LEFT".to_string(),
        KeyCode::ShiftRight => "SHIFT_RIGHT".to_string(),
        KeyCode::ControlLeft => "CONTROL_LEFT".to_string(),
        KeyCode::ControlRight => "CONTROL_RIGHT".to_string(),
        KeyCode::AltLeft => "ALT_LEFT".to_string(),
        KeyCode::AltRight => "ALT_RIGHT".to_string(),
        _ => format!("{:?}", key),
    }
}

/// Converts a Bevy MouseButton to a Ruby-compatible string.
#[cfg(feature = "rendering")]
fn mouse_button_to_string(button: MouseButton) -> String {
    match button {
        MouseButton::Left => "LEFT".to_string(),
        MouseButton::Right => "RIGHT".to_string(),
        MouseButton::Middle => "MIDDLE".to_string(),
        MouseButton::Back => "BACK".to_string(),
        MouseButton::Forward => "FORWARD".to_string(),
        MouseButton::Other(id) => format!("OTHER_{}", id),
    }
}
