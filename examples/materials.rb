# frozen_string_literal: true

require 'bevy'

class MaterialSample < Bevy::ComponentDSL
  attribute :name, String, default: ''
  attribute :row, Integer, default: 0
end

class RotatingShape < Bevy::ComponentDSL
  attribute :speed, Float, default: 1.0
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Materials Demo - ColorMaterial, StandardMaterial, BlendMode',
    width: 1000.0,
    height: 700.0
  }
)

app.add_startup_system do |ctx|
  start_x = -350.0
  spacing = 140.0

  row1_y = 200.0
  ctx.spawn(
    MaterialSample.new(name: 'Red', row: 1),
    Bevy::Transform.from_xyz(start_x, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(1.0, 0.0, 0.0, 1.0))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Green', row: 1),
    Bevy::Transform.from_xyz(start_x + spacing, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(0.0, 1.0, 0.0, 1.0))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Blue', row: 1),
    Bevy::Transform.from_xyz(start_x + spacing * 2, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(0.0, 0.0, 1.0, 1.0))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Yellow', row: 1),
    Bevy::Transform.from_xyz(start_x + spacing * 3, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(1.0, 1.0, 0.0, 1.0))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Cyan', row: 1),
    Bevy::Transform.from_xyz(start_x + spacing * 4, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(0.0, 1.0, 1.0, 1.0))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Magenta', row: 1),
    Bevy::Transform.from_xyz(start_x + spacing * 5, row1_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.new(1.0, 0.0, 1.0, 1.0))
  )

  row2_y = 50.0
  ctx.spawn(
    MaterialSample.new(name: 'Trans50', row: 2),
    Bevy::Transform.from_xyz(start_x, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(1.0, 0.0, 0.0, 0.5))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Trans30', row: 2),
    Bevy::Transform.from_xyz(start_x + spacing, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(0.0, 1.0, 0.0, 0.3))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Trans70', row: 2),
    Bevy::Transform.from_xyz(start_x + spacing * 2, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(0.0, 0.0, 1.0, 0.7))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Trans20', row: 2),
    Bevy::Transform.from_xyz(start_x + spacing * 3, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(1.0, 1.0, 0.0, 0.2))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Trans80', row: 2),
    Bevy::Transform.from_xyz(start_x + spacing * 4, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(1.0, 0.5, 0.0, 0.8))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Trans10', row: 2),
    Bevy::Transform.from_xyz(start_x + spacing * 5, row2_y, 0.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.new(0.5, 0.0, 1.0, 0.1))
  )

  row3_y = -100.0
  ctx.spawn(
    MaterialSample.new(name: 'Hex1', row: 3),
    RotatingShape.new(speed: 0.5),
    Bevy::Transform.from_xyz(start_x, row3_y, 0.0),
    Bevy::Mesh::Hexagon.new(radius: 50.0, color: Bevy::Color.from_hex('#E74C3C'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Hex2', row: 3),
    RotatingShape.new(speed: -0.7),
    Bevy::Transform.from_xyz(start_x + spacing, row3_y, 0.0),
    Bevy::Mesh::Hexagon.new(radius: 50.0, color: Bevy::Color.from_hex('#3498DB'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Hex3', row: 3),
    RotatingShape.new(speed: 1.0),
    Bevy::Transform.from_xyz(start_x + spacing * 2, row3_y, 0.0),
    Bevy::Mesh::Hexagon.new(radius: 50.0, color: Bevy::Color.from_hex('#2ECC71'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Tri1', row: 3),
    RotatingShape.new(speed: -0.3),
    Bevy::Transform.from_xyz(start_x + spacing * 3, row3_y, 0.0),
    Bevy::Mesh::Triangle.new(radius: 50.0, color: Bevy::Color.from_hex('#F39C12'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Tri2', row: 3),
    RotatingShape.new(speed: 0.8),
    Bevy::Transform.from_xyz(start_x + spacing * 4, row3_y, 0.0),
    Bevy::Mesh::Triangle.new(radius: 50.0, color: Bevy::Color.from_hex('#9B59B6'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Oct', row: 3),
    RotatingShape.new(speed: -0.5),
    Bevy::Transform.from_xyz(start_x + spacing * 5, row3_y, 0.0),
    Bevy::Mesh::RegularPolygon.new(radius: 50.0, sides: 8, color: Bevy::Color.from_hex('#1ABC9C'))
  )

  row4_y = -250.0
  ctx.spawn(
    MaterialSample.new(name: 'Ellipse1', row: 4),
    RotatingShape.new(speed: 0.3),
    Bevy::Transform.from_xyz(start_x + spacing, row4_y, 0.0),
    Bevy::Mesh::Ellipse.new(width: 120.0, height: 60.0, color: Bevy::Color.from_hex('#E91E63'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Ellipse2', row: 4),
    RotatingShape.new(speed: -0.4),
    Bevy::Transform.from_xyz(start_x + spacing * 3, row4_y, 0.0),
    Bevy::Mesh::Ellipse.new(width: 80.0, height: 100.0, color: Bevy::Color.from_hex('#00BCD4'))
  )
  ctx.spawn(
    MaterialSample.new(name: 'Ellipse3', row: 4),
    RotatingShape.new(speed: 0.6),
    Bevy::Transform.from_xyz(start_x + spacing * 5, row4_y, 0.0),
    Bevy::Mesh::Ellipse.new(width: 100.0, height: 40.0, color: Bevy::Color.from_hex('#CDDC39'))
  )
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(RotatingShape, Bevy::Transform) do |entity, rotating, transform|
    rotation = elapsed * rotating.speed
    new_transform = Bevy::Transform.new(
      translation: transform.translation,
      rotation: Bevy::Quat.from_rotation_z(rotation),
      scale: Bevy::Vec3.new(1.0, 1.0, 1.0)
    )
    ctx.world.insert_component(entity, new_transform)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Materials Demo'
puts ''
puts 'Displaying various materials and colors:'
puts '  Row 1: Basic colors (Red, Green, Blue, Yellow, Cyan, Magenta)'
puts '  Row 2: Transparent circles (various alpha values)'
puts '  Row 3: Rotating hexagons and triangles with hex colors'
puts '  Row 4: Rotating ellipses'
puts ''
puts 'Press ESC to exit'

app.run
