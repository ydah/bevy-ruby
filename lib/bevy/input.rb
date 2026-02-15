# frozen_string_literal: true

module Bevy
  module KeyCode
    A = 'A'
    B = 'B'
    C = 'C'
    D = 'D'
    E = 'E'
    F = 'F'
    G = 'G'
    H = 'H'
    I = 'I'
    J = 'J'
    K = 'K'
    L = 'L'
    M = 'M'
    N = 'N'
    O = 'O'
    P = 'P'
    Q = 'Q'
    R = 'R'
    S = 'S'
    T = 'T'
    U = 'U'
    V = 'V'
    W = 'W'
    X = 'X'
    Y = 'Y'
    Z = 'Z'

    KEY_0 = 'Key0'
    KEY_1 = 'Key1'
    KEY_2 = 'Key2'
    KEY_3 = 'Key3'
    KEY_4 = 'Key4'
    KEY_5 = 'Key5'
    KEY_6 = 'Key6'
    KEY_7 = 'Key7'
    KEY_8 = 'Key8'
    KEY_9 = 'Key9'

    ESCAPE = 'Escape'
    ENTER = 'Enter'
    SPACE = 'Space'
    BACKSPACE = 'Backspace'
    TAB = 'Tab'

    LEFT = 'ArrowLeft'
    RIGHT = 'ArrowRight'
    UP = 'ArrowUp'
    DOWN = 'ArrowDown'

    LEFT_SHIFT = 'ShiftLeft'
    RIGHT_SHIFT = 'ShiftRight'
    LEFT_CONTROL = 'ControlLeft'
    RIGHT_CONTROL = 'ControlRight'
    LEFT_ALT = 'AltLeft'
    RIGHT_ALT = 'AltRight'

    F1 = 'F1'
    F2 = 'F2'
    F3 = 'F3'
    F4 = 'F4'
    F5 = 'F5'
    F6 = 'F6'
    F7 = 'F7'
    F8 = 'F8'
    F9 = 'F9'
    F10 = 'F10'
    F11 = 'F11'
    F12 = 'F12'
  end

  module MouseButton
    LEFT = 'Left'
    RIGHT = 'Right'
    MIDDLE = 'Middle'
  end

  class KeyboardInput
    def initialize
      @pressed = {}
      @just_pressed = {}
      @just_released = {}
      @last_frame_pressed = {}
    end

    def press(key)
      @just_pressed[key] = true unless @pressed[key]
      @pressed[key] = true
    end

    def release(key)
      @just_released[key] = true if @pressed[key]
      @pressed.delete(key)
    end

    def pressed?(key)
      @pressed[key] == true
    end

    def just_pressed?(key)
      @just_pressed[key] == true
    end

    def just_released?(key)
      @just_released[key] == true
    end

    def was_pressed_last_frame?(key)
      @last_frame_pressed[key] == true
    end

    def set_just_pressed(key)
      @just_pressed[key] = true
    end

    def end_frame
      @last_frame_pressed = @pressed.dup
    end

    def clear_just_pressed
      @just_pressed.clear
      @just_released.clear
    end

    def pressed_keys
      @pressed.keys
    end

    def any_pressed?
      !@pressed.empty?
    end

    def reset
      @last_frame_pressed = @pressed.dup
      @pressed.clear
      @just_pressed.clear
      @just_released.clear
    end
  end

  class MouseInput
    attr_reader :position, :delta, :scroll_delta

    def initialize
      @pressed = {}
      @just_pressed = {}
      @just_released = {}
      @position = Vec2.zero
      @delta = Vec2.zero
      @scroll_delta = Vec2.zero
    end

    def press(button)
      @just_pressed[button] = true unless @pressed[button]
      @pressed[button] = true
    end

    def release(button)
      @just_released[button] = true if @pressed[button]
      @pressed.delete(button)
    end

    def pressed?(button)
      @pressed[button] == true
    end

    def just_pressed?(button)
      @just_pressed[button] == true
    end

    def just_released?(button)
      @just_released[button] == true
    end

    def set_position(x, y)
      old_x = @position.x
      old_y = @position.y
      @position = Vec2.new(x, y)
      @delta = Vec2.new(x - old_x, y - old_y)
    end

    def set_scroll(x, y)
      @scroll_delta = Vec2.new(x, y)
    end

    def clear_just_pressed
      @just_pressed.clear
      @just_released.clear
      @delta = Vec2.zero
      @scroll_delta = Vec2.zero
    end

    def reset
      @pressed.clear
      @just_pressed.clear
      @just_released.clear
      @position = Vec2.zero
      @delta = Vec2.zero
      @scroll_delta = Vec2.zero
    end
  end

  module GamepadButton
    SOUTH = 'South'
    EAST = 'East'
    NORTH = 'North'
    WEST = 'West'
    LEFT_TRIGGER = 'LeftTrigger'
    LEFT_TRIGGER2 = 'LeftTrigger2'
    RIGHT_TRIGGER = 'RightTrigger'
    RIGHT_TRIGGER2 = 'RightTrigger2'
    SELECT = 'Select'
    START = 'Start'
    MODE = 'Mode'
    LEFT_THUMB = 'LeftThumb'
    RIGHT_THUMB = 'RightThumb'
    DPAD_UP = 'DPadUp'
    DPAD_DOWN = 'DPadDown'
    DPAD_LEFT = 'DPadLeft'
    DPAD_RIGHT = 'DPadRight'
  end

  module GamepadAxis
    LEFT_STICK_X = 'LeftStickX'
    LEFT_STICK_Y = 'LeftStickY'
    RIGHT_STICK_X = 'RightStickX'
    RIGHT_STICK_Y = 'RightStickY'
    LEFT_TRIGGER = 'LeftZ'
    RIGHT_TRIGGER = 'RightZ'
  end

  class DeadZone
    attr_reader :inner, :outer

    def initialize(inner: 0.1, outer: 0.95)
      @inner = inner.clamp(0.0, 1.0)
      @outer = outer.clamp(0.0, 1.0)
    end

    def apply(value)
      abs_value = value.abs
      return 0.0 if abs_value < @inner
      return value / value.abs if abs_value > @outer

      normalized = (abs_value - @inner) / (@outer - @inner)
      normalized * (value / value.abs)
    end

    def apply_vec2(vec)
      len = Math.sqrt(vec.x * vec.x + vec.y * vec.y)
      return Vec2.zero if len < @inner
      return vec.normalize if len > @outer

      normalized_len = (len - @inner) / (@outer - @inner)
      normalized = vec.normalize
      Vec2.new(normalized.x * normalized_len, normalized.y * normalized_len)
    end
  end

  class RumbleRequest
    attr_reader :strong_magnitude, :weak_magnitude, :duration

    def initialize(strong: 0.0, weak: 0.0, duration: 0.0)
      @strong_magnitude = strong.clamp(0.0, 1.0)
      @weak_magnitude = weak.clamp(0.0, 1.0)
      @duration = [duration, 0.0].max
    end

    def self.strong(magnitude, duration)
      new(strong: magnitude, weak: 0.0, duration: duration)
    end

    def self.weak(magnitude, duration)
      new(strong: 0.0, weak: magnitude, duration: duration)
    end

    def self.both(magnitude, duration)
      new(strong: magnitude, weak: magnitude, duration: duration)
    end
  end

  class GamepadInput
    attr_reader :id, :name
    attr_accessor :stick_dead_zone

    def initialize(id = 0, name: nil)
      @id = id
      @name = name || "Gamepad #{id}"
      @pressed = {}
      @just_pressed = {}
      @just_released = {}
      @button_values = {}
      @axes = {}
      @axis_dead_zones = {}
      @stick_dead_zone = DeadZone.new
      @pending_rumble = nil
    end

    def press(button)
      @just_pressed[button] = true unless @pressed[button]
      @pressed[button] = true
      @button_values[button] = 1.0
    end

    def release(button)
      @just_released[button] = true if @pressed[button]
      @pressed.delete(button)
      @button_values[button] = 0.0
    end

    def set_button_value(button, value)
      was_pressed = @pressed[button]
      @button_values[button] = value
      @pressed[button] = value > 0.5
      if !was_pressed && @pressed[button]
        @just_pressed[button] = true
      elsif was_pressed && !@pressed[button]
        @just_released[button] = true
      end
    end

    def button_value(button)
      @button_values[button] || 0.0
    end

    def known_buttons
      @button_values.keys
    end

    def pressed?(button)
      @pressed[button] == true
    end

    def just_pressed?(button)
      @just_pressed[button] == true
    end

    def just_released?(button)
      @just_released[button] == true
    end

    def set_axis_dead_zone(axis, dead_zone)
      @axis_dead_zones[axis] = dead_zone
    end

    def set_axis(axis, value)
      @axes[axis] = value.clamp(-1.0, 1.0)
    end

    def axis_raw(axis)
      @axes[axis] || 0.0
    end

    def known_axes
      @axes.keys
    end

    def axis(axis)
      raw = axis_raw(axis)
      dead_zone = @axis_dead_zones[axis] || DeadZone.new
      dead_zone.apply(raw)
    end

    def left_stick_raw
      Vec2.new(
        axis_raw(GamepadAxis::LEFT_STICK_X),
        axis_raw(GamepadAxis::LEFT_STICK_Y)
      )
    end

    def left_stick
      @stick_dead_zone.apply_vec2(left_stick_raw)
    end

    def right_stick_raw
      Vec2.new(
        axis_raw(GamepadAxis::RIGHT_STICK_X),
        axis_raw(GamepadAxis::RIGHT_STICK_Y)
      )
    end

    def right_stick
      @stick_dead_zone.apply_vec2(right_stick_raw)
    end

    def left_trigger
      [axis(GamepadAxis::LEFT_TRIGGER), 0.0].max
    end

    def right_trigger
      [axis(GamepadAxis::RIGHT_TRIGGER), 0.0].max
    end

    def rumble(request)
      @pending_rumble = request
    end

    def rumble_strong(magnitude, duration)
      @pending_rumble = RumbleRequest.strong(magnitude, duration)
    end

    def rumble_weak(magnitude, duration)
      @pending_rumble = RumbleRequest.weak(magnitude, duration)
    end

    def rumble_both(magnitude, duration)
      @pending_rumble = RumbleRequest.both(magnitude, duration)
    end

    def stop_rumble
      @pending_rumble = RumbleRequest.new
    end

    def pending_rumble
      @pending_rumble
    end

    def clear_pending_rumble
      @pending_rumble = nil
    end

    def clear_just_pressed
      @just_pressed.clear
      @just_released.clear
    end

    def reset
      @pressed.clear
      @just_pressed.clear
      @just_released.clear
      @button_values.clear
      @axes.clear
      @pending_rumble = nil
    end
  end

  class Gamepads
    attr_accessor :default_dead_zone

    def initialize
      @gamepads = {}
      @default_dead_zone = DeadZone.new
    end

    def connect(id, name: nil)
      gamepad = GamepadInput.new(id, name: name)
      gamepad.stick_dead_zone = @default_dead_zone
      @gamepads[id] = gamepad
    end

    def disconnect(id)
      @gamepads.delete(id)
    end

    def connected?(id)
      @gamepads.key?(id)
    end

    def get(id)
      @gamepads[id]
    end

    def [](id)
      @gamepads[id]
    end

    def connected_ids
      @gamepads.keys
    end

    def count
      @gamepads.size
    end

    def any?
      !@gamepads.empty?
    end

    def first
      @gamepads.values.first
    end

    def each(&block)
      @gamepads.values.each(&block)
    end

    def any_pressed?(button)
      @gamepads.values.any? { |gp| gp.pressed?(button) }
    end

    def any_just_pressed?(button)
      @gamepads.values.any? { |gp| gp.just_pressed?(button) }
    end

    def any_just_released?(button)
      @gamepads.values.any? { |gp| gp.just_released?(button) }
    end

    def clear_just_pressed
      @gamepads.each_value(&:clear_just_pressed)
    end

    def clear_pending_rumbles
      @gamepads.each_value(&:clear_pending_rumble)
    end

    def reset_all
      @gamepads.each_value(&:reset)
    end
  end
end
