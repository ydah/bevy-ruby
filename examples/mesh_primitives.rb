# frozen_string_literal: true

# Shapes Demo
# Demonstrates the Mesh module for creating 2D primitives with actual shapes.
# Shows rectangles, circles, lines, and polygons rendered as real shapes (not sprites).

require 'bevy'

class ShapeMarker < Bevy::ComponentDSL
  attribute :shape_type, String, default: ''
  attribute :angle, Float, default: 0.0
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Mesh Shapes Demo - 2D Primitives',
    width: 900.0,
    height: 700.0
  }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    ShapeMarker.new(shape_type: 'rectangle'),
    Bevy::Transform.from_xyz(-300.0, 200.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 120.0, height: 80.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'circle'),
    Bevy::Transform.from_xyz(-100.0, 200.0, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'triangle'),
    Bevy::Transform.from_xyz(100.0, 200.0, 0.0),
    Bevy::Mesh::Triangle.new(radius: 50.0, color: Bevy::Color.from_hex('#2ECC71'))
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'hexagon'),
    Bevy::Transform.from_xyz(300.0, 200.0, 0.0),
    Bevy::Mesh::Hexagon.new(radius: 50.0, color: Bevy::Color.from_hex('#9B59B6'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-250.0, 0.0, 0.0),
    Bevy::Mesh::Line.new(
      start_point: Bevy::Vec2.new(-100.0, 0.0),
      end_point: Bevy::Vec2.new(100.0, 0.0),
      thickness: 5.0,
      color: Bevy::Color.from_hex('#F39C12')
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Mesh::Line.new(
      start_point: Bevy::Vec2.new(-50.0, -50.0),
      end_point: Bevy::Vec2.new(50.0, 50.0),
      thickness: 8.0,
      color: Bevy::Color.from_hex('#1ABC9C')
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(250.0, 0.0, 0.0),
    Bevy::Mesh::Line.new(
      start_point: Bevy::Vec2.new(-100.0, 50.0),
      end_point: Bevy::Vec2.new(100.0, -50.0),
      thickness: 3.0,
      color: Bevy::Color.from_hex('#E91E63')
    )
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'pentagon'),
    Bevy::Transform.from_xyz(-250.0, -180.0, 0.0),
    Bevy::Mesh::RegularPolygon.new(radius: 60.0, sides: 5, color: Bevy::Color.from_hex('#FF5722'))
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'octagon'),
    Bevy::Transform.from_xyz(0.0, -180.0, 0.0),
    Bevy::Mesh::RegularPolygon.new(radius: 55.0, sides: 8, color: Bevy::Color.from_hex('#00BCD4'))
  )

  ctx.spawn(
    ShapeMarker.new(shape_type: 'ellipse'),
    Bevy::Transform.from_xyz(250.0, -180.0, 0.0),
    Bevy::Mesh::Ellipse.new(width: 100.0, height: 60.0, color: Bevy::Color.from_hex('#CDDC39'))
  )
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(ShapeMarker, Bevy::Transform) do |entity, marker, transform|
    speed = case marker.shape_type
            when 'rectangle' then 1.0
            when 'circle' then 0.0
            when 'triangle' then 2.0
            when 'hexagon' then -1.5
            when 'pentagon' then 1.2
            when 'octagon' then -0.8
            when 'ellipse' then 0.5
            else 0.0
            end

    rotation = elapsed * speed
    pulse = 1.0 + Math.sin(elapsed * 2.0 + marker.shape_type.hash) * 0.1

    new_transform = Bevy::Transform.new(
      translation: transform.translation,
      rotation: Bevy::Quat.from_rotation_z(rotation),
      scale: Bevy::Vec3.new(pulse, pulse, 1.0)
    )

    ctx.world.insert_component(entity, new_transform)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Mesh Shapes Demo'
puts ''
puts 'Shapes displayed (using Bevy::Mesh - actual shape rendering):'
puts '  Row 1: Rectangle, Circle, Triangle, Hexagon'
puts '  Row 2: Lines (horizontal, diagonal, sloped)'
puts '  Row 3: Pentagon, Octagon, Ellipse'
puts ''
puts 'Features:'
puts '  - Mesh::Rectangle, Circle, Triangle, Hexagon'
puts '  - Mesh::Line for line segments'
puts '  - Mesh::RegularPolygon for n-sided shapes'
puts '  - Mesh::Ellipse for ellipses'
puts '  - Rotation and pulsing animations'
puts ''
puts 'Press ESC to exit'
app.run
