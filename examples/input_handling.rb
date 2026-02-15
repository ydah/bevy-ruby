# frozen_string_literal: true

# Basic Example: Input Handling
# This example demonstrates keyboard and mouse input with visual feedback.
# Control a player sprite with WASD/Arrow keys.

require 'bevy'

# Player component
class Player < Bevy::ComponentDSL
  attribute :speed, Float, default: 300.0
end

# Create an app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Input Handling - WASD/Arrows to move, ESC to exit',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  # Player sprite - controllable with keyboard
  ctx.spawn(
    Player.new(speed: 300.0),
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  # Reference markers at screen edges
  markers = [
    { x: 0.0, y: 250.0, color: '#FFFFFF' },   # Top
    { x: 0.0, y: -250.0, color: '#FFFFFF' },  # Bottom
    { x: -350.0, y: 0.0, color: '#FFFFFF' },  # Left
    { x: 350.0, y: 0.0, color: '#FFFFFF' }    # Right
  ]

  markers.each do |m|
    ctx.spawn(
      Bevy::Transform.from_xyz(m[:x], m[:y], -1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(m[:color]).with_alpha(0.3),
        custom_size: Bevy::Vec2.new(20.0, 20.0)
      )
    )
  end
end

# Player movement system
app.add_update_system do |ctx|
  ctx.world.each(Player, Bevy::Transform) do |entity, player, transform|
    dx = 0.0
    dy = 0.0

    # WASD keys
    dy += 1.0 if ctx.key_pressed?('W')
    dy -= 1.0 if ctx.key_pressed?('S')
    dx -= 1.0 if ctx.key_pressed?('A')
    dx += 1.0 if ctx.key_pressed?('D')

    # Arrow keys
    dy += 1.0 if ctx.key_pressed?('UP')
    dy -= 1.0 if ctx.key_pressed?('DOWN')
    dx -= 1.0 if ctx.key_pressed?('LEFT')
    dx += 1.0 if ctx.key_pressed?('RIGHT')

    # Normalize diagonal movement
    if dx != 0.0 && dy != 0.0
      length = Math.sqrt(dx * dx + dy * dy)
      dx /= length
      dy /= length
    end

    # Apply movement
    new_x = transform.translation.x + dx * player.speed * ctx.delta
    new_y = transform.translation.y + dy * player.speed * ctx.delta

    # Clamp to screen bounds
    new_x = new_x.clamp(-350.0, 350.0)
    new_y = new_y.clamp(-250.0, 250.0)

    new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Input Handling Demo'
puts 'Controls:'
puts '  WASD or Arrow keys - Move the player'
puts '  ESC - Exit'
app.run
