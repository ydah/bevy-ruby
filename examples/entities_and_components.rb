# frozen_string_literal: true

# Basic Example: Entities and Components
# This example shows how to create entities with components and display them visually.
# Multiple entities with different colors move across the screen.

require 'bevy'

# Define custom components using ComponentDSL
class Velocity < Bevy::ComponentDSL
  attribute :dx, Float, default: 0.0
  attribute :dy, Float, default: 0.0
end

class Name < Bevy::ComponentDSL
  attribute :value, String, default: 'Unknown'
end

# Create an app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Entities and Components',
    width: 800.0,
    height: 600.0
  }
)

# Spawn entities with components
app.add_startup_system do |ctx|
  # Player - cyan square
  ctx.spawn(
    Name.new(value: 'Player'),
    Velocity.new(dx: 100.0, dy: 50.0),
    Bevy::Transform.from_xyz(-200.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  # Enemy 1 - red square
  ctx.spawn(
    Name.new(value: 'Enemy 1'),
    Velocity.new(dx: -80.0, dy: 60.0),
    Bevy::Transform.from_xyz(200.0, 100.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(40.0, 40.0)
    )
  )

  # Enemy 2 - orange square
  ctx.spawn(
    Name.new(value: 'Enemy 2'),
    Velocity.new(dx: 60.0, dy: -90.0),
    Bevy::Transform.from_xyz(0.0, -150.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E67E22'),
      custom_size: Bevy::Vec2.new(35.0, 35.0)
    )
  )

  # Collectible - yellow square
  ctx.spawn(
    Name.new(value: 'Coin'),
    Velocity.new(dx: 0.0, dy: 120.0),
    Bevy::Transform.from_xyz(-100.0, 200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#F1C40F'),
      custom_size: Bevy::Vec2.new(25.0, 25.0)
    )
  )
end

# Movement system - move all entities with Velocity
app.add_update_system do |ctx|
  ctx.world.each(Velocity, Bevy::Transform) do |entity, vel, transform|
    new_x = transform.translation.x + vel.dx * ctx.delta
    new_y = transform.translation.y + vel.dy * ctx.delta

    # Bounce off screen edges
    if new_x.abs > 350.0
      vel.dx = -vel.dx
      new_x = new_x.clamp(-350.0, 350.0)
      ctx.world.insert_component(entity, vel)
    end

    if new_y.abs > 250.0
      vel.dy = -vel.dy
      new_y = new_y.clamp(-250.0, 250.0)
      ctx.world.insert_component(entity, vel)
    end

    new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Entities and Components Demo - Press ESC to exit'
puts 'Watch the colored squares bounce around!'
app.run
