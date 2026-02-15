# frozen_string_literal: true

require 'bevy'

class GamepadPlayer < Bevy::ComponentDSL
  attribute :gamepad_id, Integer, default: 0
  attribute :speed, Float, default: 300.0
end

class StickIndicator < Bevy::ComponentDSL
  attribute :stick, String, default: 'left'
end

class TriggerIndicator < Bevy::ComponentDSL
  attribute :side, String, default: 'left'
end

class RumbleState < Bevy::ResourceDSL
  attribute :active, :boolean, default: false
  attribute :timer, Float, default: 0.0
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Gamepad Demo - Input, DeadZone, Rumble',
    width: 900.0,
    height: 700.0
  }
)

gamepad = Bevy::GamepadInput.new(0)
dead_zone = Bevy::DeadZone.new(inner: 0.1, outer: 0.95)
rumble_state = { active: false, timer: 0.0 }

app.add_startup_system do |ctx|
  ctx.spawn(
    GamepadPlayer.new(gamepad_id: 0),
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 50.0, height: 50.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  ctx.spawn(
    StickIndicator.new(stick: 'left'),
    Bevy::Transform.from_xyz(-300.0, -250.0, 0.0),
    Bevy::Mesh::Circle.new(radius: 80.0, color: Bevy::Color.from_hex('#2C3E50'))
  )
  ctx.spawn(
    StickIndicator.new(stick: 'left_dot'),
    Bevy::Transform.from_xyz(-300.0, -250.0, 1.0),
    Bevy::Mesh::Circle.new(radius: 15.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    StickIndicator.new(stick: 'right'),
    Bevy::Transform.from_xyz(300.0, -250.0, 0.0),
    Bevy::Mesh::Circle.new(radius: 80.0, color: Bevy::Color.from_hex('#2C3E50'))
  )
  ctx.spawn(
    StickIndicator.new(stick: 'right_dot'),
    Bevy::Transform.from_xyz(300.0, -250.0, 1.0),
    Bevy::Mesh::Circle.new(radius: 15.0, color: Bevy::Color.from_hex('#2ECC71'))
  )

  ctx.spawn(
    TriggerIndicator.new(side: 'left'),
    Bevy::Transform.from_xyz(-350.0, 280.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 60.0, height: 20.0, color: Bevy::Color.from_hex('#34495E'))
  )
  ctx.spawn(
    TriggerIndicator.new(side: 'right'),
    Bevy::Transform.from_xyz(350.0, 280.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 60.0, height: 20.0, color: Bevy::Color.from_hex('#34495E'))
  )

  button_colors = {
    'A' => Bevy::Color.from_hex('#2ECC71'),
    'B' => Bevy::Color.from_hex('#E74C3C'),
    'X' => Bevy::Color.from_hex('#3498DB'),
    'Y' => Bevy::Color.from_hex('#F1C40F')
  }

  button_positions = { 'A' => 0, 'B' => 1, 'X' => 2, 'Y' => 3 }
  button_positions.each do |name, idx|
    ctx.spawn(
      Bevy::Transform.from_xyz(-150.0 + idx * 100.0, 280.0, 0.0),
      Bevy::Mesh::Circle.new(radius: 25.0, color: button_colors[name])
    )
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta

  left_x = ctx.key_pressed?('A') ? -1.0 : (ctx.key_pressed?('D') ? 1.0 : 0.0)
  left_y = ctx.key_pressed?('W') ? 1.0 : (ctx.key_pressed?('S') ? -1.0 : 0.0)
  right_x = ctx.key_pressed?('LEFT') ? -1.0 : (ctx.key_pressed?('RIGHT') ? 1.0 : 0.0)
  right_y = ctx.key_pressed?('UP') ? 1.0 : (ctx.key_pressed?('DOWN') ? -1.0 : 0.0)

  gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_X, left_x)
  gamepad.set_axis(Bevy::GamepadAxis::LEFT_STICK_Y, left_y)
  gamepad.set_axis(Bevy::GamepadAxis::RIGHT_STICK_X, right_x)
  gamepad.set_axis(Bevy::GamepadAxis::RIGHT_STICK_Y, right_y)

  left_trigger = ctx.key_pressed?('Q') ? 1.0 : 0.0
  right_trigger = ctx.key_pressed?('E') ? 1.0 : 0.0
  gamepad.set_axis(Bevy::GamepadAxis::LEFT_TRIGGER, left_trigger)
  gamepad.set_axis(Bevy::GamepadAxis::RIGHT_TRIGGER, right_trigger)

  ctx.key_just_pressed?('SPACE') ? gamepad.press(Bevy::GamepadButton::SOUTH) : gamepad.release(Bevy::GamepadButton::SOUTH)

  ctx.world.each(GamepadPlayer, Bevy::Transform) do |entity, player, transform|
    raw_x = gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)
    raw_y = gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_Y)

    dx = dead_zone.apply(raw_x.abs) * (raw_x.negative? ? -1.0 : 1.0)
    dy = dead_zone.apply(raw_y.abs) * (raw_y.negative? ? -1.0 : 1.0)

    new_x = transform.translation.x + dx * player.speed * delta
    new_y = transform.translation.y + dy * player.speed * delta

    new_x = [[-350.0, new_x].max, 350.0].min
    new_y = [[-200.0, new_y].max, 200.0].min

    new_transform = Bevy::Transform.from_xyz(new_x, new_y, 0.0)
    ctx.world.insert_component(entity, new_transform)
  end
end

app.add_update_system do |ctx|
  left_x = gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)
  left_y = gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_Y)
  right_x = gamepad.axis_raw(Bevy::GamepadAxis::RIGHT_STICK_X)
  right_y = gamepad.axis_raw(Bevy::GamepadAxis::RIGHT_STICK_Y)

  ctx.world.each(StickIndicator, Bevy::Transform) do |entity, indicator, transform|
    case indicator.stick
    when 'left_dot'
      new_x = -300.0 + left_x * 60.0
      new_y = -250.0 + left_y * 60.0
      new_transform = Bevy::Transform.from_xyz(new_x, new_y, 1.0)
      ctx.world.insert_component(entity, new_transform)
    when 'right_dot'
      new_x = 300.0 + right_x * 60.0
      new_y = -250.0 + right_y * 60.0
      new_transform = Bevy::Transform.from_xyz(new_x, new_y, 1.0)
      ctx.world.insert_component(entity, new_transform)
    end
  end

  left_trigger = gamepad.axis_raw(Bevy::GamepadAxis::LEFT_TRIGGER)
  right_trigger = gamepad.axis_raw(Bevy::GamepadAxis::RIGHT_TRIGGER)

  ctx.world.each(TriggerIndicator, Bevy::Transform) do |entity, indicator, transform|
    if indicator.side == 'left'
      height = 20.0 + left_trigger * 80.0
      new_transform = Bevy::Transform.from_xyz(-350.0, 280.0 + height / 2 - 10.0, 0.0)
      ctx.world.insert_component(entity, new_transform)
    elsif indicator.side == 'right'
      height = 20.0 + right_trigger * 80.0
      new_transform = Bevy::Transform.from_xyz(350.0, 280.0 + height / 2 - 10.0, 0.0)
      ctx.world.insert_component(entity, new_transform)
    end
  end
end

app.add_update_system do |ctx|
  if ctx.key_just_pressed?('R')
    rumble = Bevy::RumbleRequest.new(strong: 0.8, weak: 0.3, duration: 0.5)
    rumble_state[:active] = true
    rumble_state[:timer] = rumble.duration
    puts "Rumble triggered! (simulated)"
  end

  if rumble_state[:active]
    rumble_state[:timer] -= ctx.delta
    rumble_state[:active] = false if rumble_state[:timer] <= 0
  end

  gamepad.clear_just_pressed

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Gamepad Demo'
puts ''
puts 'Controls (simulating gamepad with keyboard):'
puts '  WASD       - Left stick'
puts '  Arrow keys - Right stick'
puts '  Q/E        - Left/Right triggers'
puts '  SPACE      - A button'
puts '  R          - Trigger rumble (simulated)'
puts '  ESC        - Exit'
puts ''
puts 'Features:'
puts '  - GamepadInput with simulated stick/button input'
puts '  - DeadZone applied to movement'
puts '  - Visual stick and trigger indicators'
puts '  - RumbleRequest (simulated)'

app.run
