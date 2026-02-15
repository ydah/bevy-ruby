# frozen_string_literal: true

RSpec.describe Bevy::KeyCode do
  it 'defines common key codes' do
    expect(Bevy::KeyCode::A).to eq('A')
    expect(Bevy::KeyCode::SPACE).to eq('Space')
    expect(Bevy::KeyCode::ESCAPE).to eq('Escape')
    expect(Bevy::KeyCode::LEFT).to eq('ArrowLeft')
    expect(Bevy::KeyCode::F1).to eq('F1')
  end
end

RSpec.describe Bevy::KeyboardInput do
  let(:keyboard) { described_class.new }

  describe '#press' do
    it 'marks a key as pressed' do
      keyboard.press(Bevy::KeyCode::A)
      expect(keyboard.pressed?(Bevy::KeyCode::A)).to be true
    end

    it 'marks a key as just pressed on first press' do
      keyboard.press(Bevy::KeyCode::A)
      expect(keyboard.just_pressed?(Bevy::KeyCode::A)).to be true
    end

    it 'does not mark as just pressed on subsequent frames' do
      keyboard.press(Bevy::KeyCode::A)
      keyboard.clear_just_pressed
      keyboard.press(Bevy::KeyCode::A)
      expect(keyboard.just_pressed?(Bevy::KeyCode::A)).to be false
      expect(keyboard.pressed?(Bevy::KeyCode::A)).to be true
    end
  end

  describe '#release' do
    it 'marks a key as released' do
      keyboard.press(Bevy::KeyCode::A)
      keyboard.release(Bevy::KeyCode::A)
      expect(keyboard.pressed?(Bevy::KeyCode::A)).to be false
    end

    it 'marks a key as just released' do
      keyboard.press(Bevy::KeyCode::A)
      keyboard.release(Bevy::KeyCode::A)
      expect(keyboard.just_released?(Bevy::KeyCode::A)).to be true
    end
  end

  describe '#pressed_keys' do
    it 'returns all pressed keys' do
      keyboard.press(Bevy::KeyCode::A)
      keyboard.press(Bevy::KeyCode::W)
      expect(keyboard.pressed_keys).to contain_exactly(Bevy::KeyCode::A, Bevy::KeyCode::W)
    end
  end

  describe '#any_pressed?' do
    it 'returns false when no keys are pressed' do
      expect(keyboard.any_pressed?).to be false
    end

    it 'returns true when at least one key is pressed' do
      keyboard.press(Bevy::KeyCode::SPACE)
      expect(keyboard.any_pressed?).to be true
    end
  end

  describe '#reset' do
    it 'clears all state' do
      keyboard.press(Bevy::KeyCode::A)
      keyboard.reset
      expect(keyboard.pressed?(Bevy::KeyCode::A)).to be false
      expect(keyboard.just_pressed?(Bevy::KeyCode::A)).to be false
      expect(keyboard.pressed_keys).to be_empty
    end
  end
end

RSpec.describe Bevy::MouseButton do
  it 'defines mouse buttons' do
    expect(Bevy::MouseButton::LEFT).to eq('Left')
    expect(Bevy::MouseButton::RIGHT).to eq('Right')
    expect(Bevy::MouseButton::MIDDLE).to eq('Middle')
  end
end

RSpec.describe Bevy::MouseInput do
  let(:mouse) { described_class.new }

  describe '#press and #release' do
    it 'tracks button state' do
      mouse.press(Bevy::MouseButton::LEFT)
      expect(mouse.pressed?(Bevy::MouseButton::LEFT)).to be true
      expect(mouse.just_pressed?(Bevy::MouseButton::LEFT)).to be true

      mouse.release(Bevy::MouseButton::LEFT)
      expect(mouse.pressed?(Bevy::MouseButton::LEFT)).to be false
      expect(mouse.just_released?(Bevy::MouseButton::LEFT)).to be true
    end
  end

  describe '#set_position' do
    it 'updates position and calculates delta' do
      mouse.set_position(100.0, 200.0)
      expect(mouse.position.x).to eq(100.0)
      expect(mouse.position.y).to eq(200.0)

      mouse.set_position(110.0, 195.0)
      expect(mouse.delta.x).to eq(10.0)
      expect(mouse.delta.y).to eq(-5.0)
    end
  end

  describe '#set_scroll' do
    it 'updates scroll delta' do
      mouse.set_scroll(0.0, 3.0)
      expect(mouse.scroll_delta.x).to eq(0.0)
      expect(mouse.scroll_delta.y).to eq(3.0)
    end
  end

  describe '#clear_just_pressed' do
    it 'clears just pressed state and deltas' do
      mouse.press(Bevy::MouseButton::LEFT)
      mouse.set_position(100.0, 100.0)
      mouse.set_scroll(0.0, 1.0)

      mouse.clear_just_pressed

      expect(mouse.just_pressed?(Bevy::MouseButton::LEFT)).to be false
      expect(mouse.delta.x).to eq(0.0)
      expect(mouse.scroll_delta.y).to eq(0.0)
    end
  end

  describe '#reset' do
    it 'clears all state' do
      mouse.press(Bevy::MouseButton::LEFT)
      mouse.set_position(100.0, 100.0)
      mouse.reset

      expect(mouse.pressed?(Bevy::MouseButton::LEFT)).to be false
      expect(mouse.position.x).to eq(0.0)
    end
  end
end

RSpec.describe Bevy::DeadZone do
  describe '.new' do
    it 'creates with default values' do
      dz = described_class.new
      expect(dz.inner).to eq(0.1)
      expect(dz.outer).to eq(0.95)
    end

    it 'creates with custom values' do
      dz = described_class.new(inner: 0.2, outer: 0.9)
      expect(dz.inner).to eq(0.2)
      expect(dz.outer).to eq(0.9)
    end

    it 'clamps values to 0..1' do
      dz = described_class.new(inner: -0.5, outer: 1.5)
      expect(dz.inner).to eq(0.0)
      expect(dz.outer).to eq(1.0)
    end
  end

  describe '#apply' do
    it 'returns 0 for values within inner dead zone' do
      dz = described_class.new(inner: 0.1)
      expect(dz.apply(0.05)).to eq(0.0)
      expect(dz.apply(-0.05)).to eq(0.0)
    end

    it 'returns 1 or -1 for values beyond outer dead zone' do
      dz = described_class.new(outer: 0.9)
      expect(dz.apply(0.95)).to eq(1.0)
      expect(dz.apply(-0.95)).to eq(-1.0)
    end

    it 'normalizes values between inner and outer' do
      dz = described_class.new(inner: 0.1, outer: 1.0)
      result = dz.apply(0.55)
      expect(result).to be > 0.0
      expect(result).to be < 1.0
    end
  end

  describe '#apply_vec2' do
    it 'applies dead zone to Vec2' do
      dz = described_class.new(inner: 0.1)
      vec = Bevy::Vec2.new(0.05, 0.05)
      result = dz.apply_vec2(vec)
      expect(result.x).to eq(0.0)
      expect(result.y).to eq(0.0)
    end
  end
end

RSpec.describe Bevy::RumbleRequest do
  describe '.new' do
    it 'creates with default values' do
      rr = described_class.new
      expect(rr.strong_magnitude).to eq(0.0)
      expect(rr.weak_magnitude).to eq(0.0)
      expect(rr.duration).to eq(0.0)
    end

    it 'creates with custom values' do
      rr = described_class.new(strong: 0.8, weak: 0.5, duration: 0.5)
      expect(rr.strong_magnitude).to eq(0.8)
      expect(rr.weak_magnitude).to eq(0.5)
      expect(rr.duration).to eq(0.5)
    end

    it 'clamps magnitude to 0..1' do
      rr = described_class.new(strong: 1.5, weak: -0.5, duration: 1.0)
      expect(rr.strong_magnitude).to eq(1.0)
      expect(rr.weak_magnitude).to eq(0.0)
    end
  end

  describe '.strong' do
    it 'creates strong-only rumble' do
      rr = described_class.strong(0.7, 0.3)
      expect(rr.strong_magnitude).to eq(0.7)
      expect(rr.weak_magnitude).to eq(0.0)
      expect(rr.duration).to eq(0.3)
    end
  end

  describe '.weak' do
    it 'creates weak-only rumble' do
      rr = described_class.weak(0.5, 0.2)
      expect(rr.strong_magnitude).to eq(0.0)
      expect(rr.weak_magnitude).to eq(0.5)
      expect(rr.duration).to eq(0.2)
    end
  end

  describe '.both' do
    it 'creates rumble with both motors' do
      rr = described_class.both(0.6, 0.4)
      expect(rr.strong_magnitude).to eq(0.6)
      expect(rr.weak_magnitude).to eq(0.6)
      expect(rr.duration).to eq(0.4)
    end
  end
end

RSpec.describe Bevy::GamepadButton do
  it 'defines gamepad buttons' do
    expect(Bevy::GamepadButton::SOUTH).to eq('South')
    expect(Bevy::GamepadButton::DPAD_UP).to eq('DPadUp')
    expect(Bevy::GamepadButton::START).to eq('Start')
  end
end

RSpec.describe Bevy::GamepadAxis do
  it 'defines gamepad axes' do
    expect(Bevy::GamepadAxis::LEFT_STICK_X).to eq('LeftStickX')
    expect(Bevy::GamepadAxis::RIGHT_TRIGGER).to eq('RightZ')
  end
end

RSpec.describe Bevy::GamepadInput do
  let(:gamepad) { described_class.new(0) }

  describe '#initialize' do
    it 'stores the gamepad id' do
      expect(gamepad.id).to eq(0)
    end
  end

  describe '#press and #release' do
    it 'tracks button state' do
      gamepad.press(Bevy::GamepadButton::SOUTH)
      expect(gamepad.pressed?(Bevy::GamepadButton::SOUTH)).to be true
      expect(gamepad.just_pressed?(Bevy::GamepadButton::SOUTH)).to be true

      gamepad.release(Bevy::GamepadButton::SOUTH)
      expect(gamepad.pressed?(Bevy::GamepadButton::SOUTH)).to be false
      expect(gamepad.just_released?(Bevy::GamepadButton::SOUTH)).to be true
    end
  end

  describe '#set_axis and #axis' do
    it 'tracks axis values' do
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 0.75)
      expect(gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)).to eq(0.75)
    end

    it 'clamps axis values to -1..1' do
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 1.5)
      expect(gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)).to eq(1.0)

      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, -1.5)
      expect(gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)).to eq(-1.0)
    end

    it 'returns 0.0 for unset axes' do
      expect(gamepad.axis(Bevy::GamepadAxis::RIGHT_STICK_X)).to eq(0.0)
    end
  end

  describe '#left_stick_raw' do
    it 'returns a Vec2 of left stick axes without dead zone' do
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 0.5)
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_Y, -0.3)
      stick = gamepad.left_stick_raw
      expect(stick.x).to be_within(0.001).of(0.5)
      expect(stick.y).to be_within(0.001).of(-0.3)
    end
  end

  describe '#right_stick_raw' do
    it 'returns a Vec2 of right stick axes without dead zone' do
      gamepad.set_axis(Bevy::GamepadAxis::RIGHT_STICK_X, -0.2)
      gamepad.set_axis(Bevy::GamepadAxis::RIGHT_STICK_Y, 0.8)
      stick = gamepad.right_stick_raw
      expect(stick.x).to be_within(0.001).of(-0.2)
      expect(stick.y).to be_within(0.001).of(0.8)
    end
  end

  describe '#reset' do
    it 'clears all state' do
      gamepad.press(Bevy::GamepadButton::SOUTH)
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 0.5)
      gamepad.reset

      expect(gamepad.pressed?(Bevy::GamepadButton::SOUTH)).to be false
      expect(gamepad.axis(Bevy::GamepadAxis::LEFT_STICK_X)).to eq(0.0)
    end
  end

  describe '#name' do
    it 'has a default name' do
      expect(gamepad.name).to eq('Gamepad 0')
    end

    it 'accepts custom name' do
      gp = described_class.new(1, name: 'Xbox Controller')
      expect(gp.name).to eq('Xbox Controller')
    end
  end

  describe '#stick_dead_zone' do
    it 'has a default dead zone' do
      expect(gamepad.stick_dead_zone).to be_a(Bevy::DeadZone)
    end

    it 'applies dead zone to left_stick' do
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 0.05)
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_Y, 0.05)
      stick = gamepad.left_stick
      expect(stick.x).to eq(0.0)
      expect(stick.y).to eq(0.0)
    end
  end

  describe '#rumble' do
    it 'sets pending rumble request' do
      request = Bevy::RumbleRequest.new(strong: 0.5, weak: 0.3, duration: 0.2)
      gamepad.rumble(request)
      expect(gamepad.pending_rumble).to eq(request)
    end
  end

  describe '#rumble_strong' do
    it 'creates strong rumble request' do
      gamepad.rumble_strong(0.8, 0.5)
      rr = gamepad.pending_rumble
      expect(rr.strong_magnitude).to eq(0.8)
      expect(rr.weak_magnitude).to eq(0.0)
    end
  end

  describe '#rumble_both' do
    it 'creates rumble with both motors' do
      gamepad.rumble_both(0.6, 0.3)
      rr = gamepad.pending_rumble
      expect(rr.strong_magnitude).to eq(0.6)
      expect(rr.weak_magnitude).to eq(0.6)
    end
  end

  describe '#stop_rumble' do
    it 'creates zero-magnitude rumble request' do
      gamepad.rumble_strong(1.0, 1.0)
      gamepad.stop_rumble
      rr = gamepad.pending_rumble
      expect(rr.strong_magnitude).to eq(0.0)
      expect(rr.weak_magnitude).to eq(0.0)
    end
  end

  describe '#left_trigger and #right_trigger' do
    it 'returns trigger values' do
      gamepad.set_axis(Bevy::GamepadAxis::LEFT_TRIGGER, 0.7)
      gamepad.set_axis(Bevy::GamepadAxis::RIGHT_TRIGGER, 0.3)
      expect(gamepad.left_trigger).to be >= 0.0
      expect(gamepad.right_trigger).to be >= 0.0
    end
  end
end

RSpec.describe Bevy::Gamepads do
  let(:gamepads) { described_class.new }

  describe '#connect' do
    it 'creates a new gamepad' do
      gamepads.connect(0)
      expect(gamepads.connected?(0)).to be true
      expect(gamepads.get(0)).to be_a(Bevy::GamepadInput)
    end
  end

  describe '#disconnect' do
    it 'removes a gamepad' do
      gamepads.connect(0)
      gamepads.disconnect(0)
      expect(gamepads.connected?(0)).to be false
    end
  end

  describe '#[]' do
    it 'accesses gamepad by id' do
      gamepads.connect(0)
      expect(gamepads[0]).to be_a(Bevy::GamepadInput)
    end
  end

  describe '#connected_ids' do
    it 'returns all connected gamepad ids' do
      gamepads.connect(0)
      gamepads.connect(1)
      expect(gamepads.connected_ids).to contain_exactly(0, 1)
    end
  end

  describe '#each' do
    it 'iterates over all connected gamepads' do
      gamepads.connect(0)
      gamepads.connect(1)
      ids = []
      gamepads.each { |g| ids << g.id }
      expect(ids).to contain_exactly(0, 1)
    end
  end

  describe '#clear_just_pressed' do
    it 'clears just pressed state for all gamepads' do
      gamepads.connect(0)
      gamepads[0].press(Bevy::GamepadButton::SOUTH)

      gamepads.clear_just_pressed

      expect(gamepads[0].just_pressed?(Bevy::GamepadButton::SOUTH)).to be false
      expect(gamepads[0].pressed?(Bevy::GamepadButton::SOUTH)).to be true
    end
  end
end
