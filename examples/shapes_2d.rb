# frozen_string_literal: true

# 2D Shapes Example
# Demonstrates drawing various 2D shapes using sprites.
# Shapes rotate and pulse to show animation capabilities.

require 'bevy'

class Shape < Bevy::ComponentDSL
  attribute :shape_type, String, default: 'square'
  attribute :rotation_speed, Float, default: 1.0
  attribute :pulse_speed, Float, default: 2.0
  attribute :base_size, Float, default: 50.0
end

SHAPE_CONFIGS = [
  { type: 'square', color: '#E74C3C', x: -250.0, y: 100.0, size: 60.0, rot_speed: 1.0 },
  { type: 'rectangle', color: '#3498DB', x: -100.0, y: 100.0, size: 50.0, rot_speed: -0.5 },
  { type: 'diamond', color: '#2ECC71', x: 50.0, y: 100.0, size: 55.0, rot_speed: 2.0 },
  { type: 'tall', color: '#9B59B6', x: 200.0, y: 100.0, size: 40.0, rot_speed: -1.5 },
  { type: 'wide', color: '#F39C12', x: -175.0, y: -100.0, size: 45.0, rot_speed: 0.8 },
  { type: 'small', color: '#1ABC9C', x: 0.0, y: -100.0, size: 30.0, rot_speed: 3.0 },
  { type: 'large', color: '#E91E63', x: 175.0, y: -100.0, size: 80.0, rot_speed: -0.3 }
].freeze

def shape_dimensions(shape_type, base_size)
  case shape_type
  when 'square'
    [base_size, base_size]
  when 'rectangle'
    [base_size * 1.5, base_size]
  when 'diamond'
    [base_size, base_size]
  when 'tall'
    [base_size, base_size * 2]
  when 'wide'
    [base_size * 2.5, base_size * 0.6]
  when 'small'
    [base_size, base_size]
  when 'large'
    [base_size, base_size]
  else
    [base_size, base_size]
  end
end

app = Bevy::App.new(
  render: true,
  window: {
    title: '2D Shapes - Rotating and Pulsing',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  SHAPE_CONFIGS.each do |config|
    width, height = shape_dimensions(config[:type], config[:size])

    initial_rotation = config[:type] == 'diamond' ? Math::PI / 4 : 0.0

    ctx.spawn(
      Shape.new(
        shape_type: config[:type],
        rotation_speed: config[:rot_speed],
        pulse_speed: rand(1.5..3.0),
        base_size: config[:size]
      ),
      Bevy::Transform.new(
        translation: Bevy::Vec3.new(config[:x], config[:y], 0.0),
        rotation: Bevy::Quat.from_rotation_z(initial_rotation),
        scale: Bevy::Vec3.one
      ),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(config[:color]),
        custom_size: Bevy::Vec2.new(width, height)
      )
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.rgba(0.2, 0.2, 0.3, 0.5),
      custom_size: Bevy::Vec2.new(700.0, 350.0)
    )
  )
end

app.add_update_system do |ctx|
  ctx.delta
  elapsed = ctx.elapsed

  ctx.world.each(Shape, Bevy::Transform) do |entity, shape, transform|
    base_rotation = shape.shape_type == 'diamond' ? Math::PI / 4 : 0.0
    new_rotation = base_rotation + elapsed * shape.rotation_speed

    pulse = 1.0 + Math.sin(elapsed * shape.pulse_speed) * 0.15
    new_scale = Bevy::Vec3.new(pulse, pulse, 1.0)

    new_transform = Bevy::Transform.new(
      translation: transform.translation,
      rotation: Bevy::Quat.from_rotation_z(new_rotation),
      scale: new_scale
    )

    ctx.world.insert_component(entity, new_transform)
  end
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(Shape, Bevy::Sprite) do |entity, shape, sprite|
    hue_shift = Math.sin(elapsed * 0.5 + shape.rotation_speed) * 0.1
    base_color = sprite.color

    r = (base_color.r + hue_shift).clamp(0.0, 1.0)
    g = (base_color.g + hue_shift * 0.5).clamp(0.0, 1.0)
    b = (base_color.b - hue_shift * 0.3).clamp(0.0, 1.0)

    new_sprite = sprite.with_color(Bevy::Color.rgba(r, g, b, 1.0))
    ctx.world.insert_component(entity, new_sprite)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts '2D Shapes Example'
puts 'Watch the shapes rotate and pulse!'
puts 'Press ESC to exit'
app.run
