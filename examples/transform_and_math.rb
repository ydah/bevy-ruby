# frozen_string_literal: true

# Basic Example: Transform and Math
# This example demonstrates Transform, Vec2, Vec3, and Quat usage visually.
# Shows rotating and scaling sprites in real-time.

require 'bevy'

# Component to track rotation speed
class Rotator < Bevy::ComponentDSL
  attribute :speed, Float, default: 1.0
end

# Component to track scale pulsing
class Pulser < Bevy::ComponentDSL
  attribute :speed, Float, default: 2.0
  attribute :min_scale, Float, default: 0.5
  attribute :max_scale, Float, default: 1.5
  attribute :time, Float, default: 0.0
end

# Component for orbiting
class Orbiter < Bevy::ComponentDSL
  attribute :radius, Float, default: 100.0
  attribute :speed, Float, default: 1.0
  attribute :angle, Float, default: 0.0
end

# Create an app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Transform and Math Demo',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  # Center reference - static white square
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.white.with_alpha(0.3),
      custom_size: Bevy::Vec2.new(20.0, 20.0)
    )
  )

  # Rotating square (cyan)
  ctx.spawn(
    Rotator.new(speed: 2.0),
    Bevy::Transform.from_xyz(-200.0, 100.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(60.0, 60.0)
    )
  )

  # Pulsing square (red)
  ctx.spawn(
    Pulser.new(speed: 3.0, min_scale: 0.5, max_scale: 1.5),
    Bevy::Transform.from_xyz(200.0, 100.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  # Orbiting squares (multiple colors)
  colors = ['#3498DB', '#2ECC71', '#F1C40F', '#9B59B6']
  4.times do |i|
    ctx.spawn(
      Orbiter.new(
        radius: 120.0,
        speed: 1.5,
        angle: i * Math::PI / 2
      ),
      Bevy::Transform.from_xyz(0.0, -100.0, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(colors[i]),
        custom_size: Bevy::Vec2.new(30.0, 30.0)
      )
    )
  end
end

# Rotation system
app.add_update_system do |ctx|
  ctx.world.each(Rotator, Bevy::Transform) do |entity, rotator, transform|
    # Rotate around Z axis
    new_transform = transform.rotate_z(rotator.speed * ctx.delta)
    ctx.world.insert_component(entity, new_transform)
  end
end

# Pulsing scale system
app.add_update_system do |ctx|
  ctx.world.each(Pulser, Bevy::Transform) do |entity, pulser, transform|
    pulser.time += ctx.delta
    ctx.world.insert_component(entity, pulser)

    # Calculate scale using sine wave
    t = (Math.sin(pulser.time * pulser.speed) + 1.0) / 2.0
    scale = pulser.min_scale + t * (pulser.max_scale - pulser.min_scale)

    new_scale = Bevy::Vec3.new(scale, scale, 1.0)
    ctx.world.insert_component(entity, transform.with_scale(new_scale))
  end
end

# Orbiting system
app.add_update_system do |ctx|
  ctx.world.each(Orbiter, Bevy::Transform) do |entity, orbiter, transform|
    orbiter.angle += orbiter.speed * ctx.delta
    ctx.world.insert_component(entity, orbiter)

    # Calculate position on circle
    x = Math.cos(orbiter.angle) * orbiter.radius
    y = Math.sin(orbiter.angle) * orbiter.radius - 100.0 # Offset to center

    new_pos = Bevy::Vec3.new(x, y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Transform and Math Demo - Press ESC to exit'
puts 'Watch: rotating square, pulsing square, and orbiting squares!'
app.run
