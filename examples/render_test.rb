# frozen_string_literal: true

# Simple Rendering Test
# Tests basic rendering functionality with a moving sprite

require 'bevy'

# Moving box component
class MovingBox < Bevy::ComponentDSL
  attribute :speed, Float, default: 100.0
  attribute :direction, Float, default: 1.0
end

# Create app with rendering enabled
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Bevy Ruby - Render Test',
    width: 800.0,
    height: 600.0
  }
)

# Spawn a moving sprite on startup
app.add_startup_system do |ctx|
  ctx.spawn(
    MovingBox.new(speed: 200.0),
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  # Spawn a static reference sprite
  ctx.spawn(
    Bevy::Transform.from_xyz(200.0, 100.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(30.0, 30.0)
    )
  )
end

# Update system - move the box back and forth
app.add_update_system do |ctx|
  ctx.world.each(MovingBox, Bevy::Transform) do |entity, box, transform|
    new_x = transform.translation.x + box.speed * box.direction * ctx.delta

    # Bounce at edges
    if new_x > 300.0
      box.direction = -1.0
      new_x = 300.0
    elsif new_x < -300.0
      box.direction = 1.0
      new_x = -300.0
    end

    new_pos = Bevy::Vec3.new(new_x, transform.translation.y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
    ctx.world.insert_component(entity, box)
  end
end

# Input handling - press ESC to exit
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Starting render test...'
puts 'Press ESC to exit'
app.run
puts 'Done!'
