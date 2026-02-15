# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Gizmos System Demo',
    width: 900.0,
    height: 700.0
  }
)

gizmos = Bevy::Gizmos.new
gizmo_config = Bevy::GizmoConfig.new(enabled: true, line_width: 2.0, depth_test: true)

current_mode = :shapes
modes = [:shapes, :grid, :transform, :debug]
mode_labels = {
  shapes: 'Basic Shapes',
  grid: 'Grid & Lines',
  transform: 'Transform Gizmo',
  debug: 'Debug Visualization'
}

transform_gizmo = Bevy::TransformGizmo.new(enabled: true, mode: Bevy::TransformGizmo::TRANSLATE)
target_position = Bevy::Vec3.new(0.0, 0.0, 0.0)
target_rotation = 0.0
target_scale = 1.0

time_elapsed = 0.0
gizmo_entities = {}
status_entity = nil

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Gizmos System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[1-4] Switch Mode  [T/R/S] Transform Mode  [Arrow Keys] Move', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Mode: Basic Shapes | Gizmos: ON', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    current_mode = :shapes
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    current_mode = :grid
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    current_mode = :transform
  elsif ctx.key_just_pressed?('KEY4') || ctx.key_just_pressed?('4')
    current_mode = :debug
  end

  transform_gizmo.translate_mode if ctx.key_just_pressed?('T')
  transform_gizmo.rotate_mode if ctx.key_just_pressed?('R')
  transform_gizmo.scale_mode if ctx.key_just_pressed?('S')

  gizmo_config.enabled = !gizmo_config.enabled if ctx.key_just_pressed?('G')

  move_speed = 100.0 * delta
  if ctx.key_pressed?('LEFT')
    target_position = Bevy::Vec3.new(target_position.x - move_speed, target_position.y, 0.0)
  elsif ctx.key_pressed?('RIGHT')
    target_position = Bevy::Vec3.new(target_position.x + move_speed, target_position.y, 0.0)
  end
  if ctx.key_pressed?('UP')
    target_position = Bevy::Vec3.new(target_position.x, target_position.y + move_speed, 0.0)
  elsif ctx.key_pressed?('DOWN')
    target_position = Bevy::Vec3.new(target_position.x, target_position.y - move_speed, 0.0)
  end

  gizmo_entities.each { |_, e| ctx.world.despawn(e) if e }
  gizmo_entities.clear

  return unless gizmo_config.enabled

  case current_mode
  when :shapes
    ctx.spawn(
      Bevy::Transform.from_xyz(-200.0, 100.0, 1.0),
      Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.from_hex('#E74C3C'))
    )

    ctx.spawn(
      Bevy::Transform.from_xyz(0.0, 100.0, 1.0),
      Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: Bevy::Color.from_hex('#3498DB'))
    )

    ctx.spawn(
      Bevy::Transform.from_xyz(200.0, 100.0, 1.0),
      Bevy::Mesh::RegularPolygon.new(radius: 50.0, sides: 6, color: Bevy::Color.from_hex('#2ECC71'))
    )

    pulse = (Math.sin(time_elapsed * 2.0) + 1.0) / 2.0 * 30.0 + 30.0
    ctx.spawn(
      Bevy::Transform.from_xyz(-200.0, -50.0, 1.0),
      Bevy::Mesh::Circle.new(radius: pulse, color: Bevy::Color.from_hex('#F39C12'))
    )

    ctx.spawn(
      Bevy::Transform.from_xyz(0.0, -50.0, 1.0),
      Bevy::Mesh::RegularPolygon.new(radius: 40.0, sides: 3, color: Bevy::Color.from_hex('#9B59B6'))
    )

    ctx.spawn(
      Bevy::Transform.from_xyz(200.0, -50.0, 1.0),
      Bevy::Mesh::RegularPolygon.new(radius: 45.0, sides: 8, color: Bevy::Color.from_hex('#1ABC9C'))
    )

  when :grid
    (-4..4).each do |i|
      x = i * 80.0
      ctx.spawn(
        Bevy::Transform.from_xyz(x, 0.0, 0.5),
        Bevy::Mesh::Rectangle.new(width: 2.0, height: 400.0, color: Bevy::Color.from_hex('#333344'))
      )
    end

    (-2..2).each do |i|
      y = i * 80.0
      ctx.spawn(
        Bevy::Transform.from_xyz(0.0, y, 0.5),
        Bevy::Mesh::Rectangle.new(width: 640.0, height: 2.0, color: Bevy::Color.from_hex('#333344'))
      )
    end

    ctx.spawn(
      Bevy::Transform.from_xyz(0.0, 0.0, 1.0),
      Bevy::Mesh::Rectangle.new(width: 640.0, height: 3.0, color: Bevy::Color.from_hex('#E74C3C'))
    )
    ctx.spawn(
      Bevy::Transform.from_xyz(0.0, 0.0, 1.0),
      Bevy::Mesh::Rectangle.new(width: 3.0, height: 400.0, color: Bevy::Color.from_hex('#2ECC71'))
    )

    ctx.spawn(
      Bevy::Transform.from_xyz(300.0, 0.0, 2.0),
      Bevy::Text2d.new('X', font_size: 16.0, color: Bevy::Color.from_hex('#E74C3C'))
    )
    ctx.spawn(
      Bevy::Transform.from_xyz(0.0, 180.0, 2.0),
      Bevy::Text2d.new('Y', font_size: 16.0, color: Bevy::Color.from_hex('#2ECC71'))
    )

  when :transform
    ctx.spawn(
      Bevy::Transform.from_xyz(target_position.x, target_position.y, 1.0),
      Bevy::Mesh::Rectangle.new(width: 60.0 * target_scale, height: 60.0 * target_scale, color: Bevy::Color.from_hex('#FFD700'))
    )

    axis_length = 80.0
    case transform_gizmo.mode
    when Bevy::TransformGizmo::TRANSLATE
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x + axis_length / 2.0, target_position.y, 2.0),
        Bevy::Mesh::Rectangle.new(width: axis_length, height: 4.0, color: Bevy::Color.from_hex('#E74C3C'))
      )
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x, target_position.y + axis_length / 2.0, 2.0),
        Bevy::Mesh::Rectangle.new(width: 4.0, height: axis_length, color: Bevy::Color.from_hex('#2ECC71'))
      )
    when Bevy::TransformGizmo::ROTATE
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x, target_position.y, 2.0),
        Bevy::Mesh::Circle.new(radius: 60.0, color: Bevy::Color.from_hex('#3498DB'))
      )
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x, target_position.y, 3.0),
        Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.from_hex('#1a1a2e'))
      )
    when Bevy::TransformGizmo::SCALE
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x + 50.0, target_position.y, 2.0),
        Bevy::Mesh::Rectangle.new(width: 15.0, height: 15.0, color: Bevy::Color.from_hex('#E74C3C'))
      )
      ctx.spawn(
        Bevy::Transform.from_xyz(target_position.x, target_position.y + 50.0, 2.0),
        Bevy::Mesh::Rectangle.new(width: 15.0, height: 15.0, color: Bevy::Color.from_hex('#2ECC71'))
      )
    end

    mode_text = ctx.spawn(
      Bevy::Transform.from_xyz(target_position.x, target_position.y - 80.0, 3.0),
      Bevy::Text2d.new("[#{transform_gizmo.mode}]", font_size: 12.0, color: Bevy::Color.white)
    )
    gizmo_entities[:mode_text] = mode_text

  when :debug
    5.times do |i|
      x = -200.0 + i * 100.0
      y = Math.sin(time_elapsed * 2.0 + i * 0.5) * 80.0
      ctx.spawn(
        Bevy::Transform.from_xyz(x, y, 1.0),
        Bevy::Mesh::Circle.new(radius: 20.0, color: Bevy::Color.from_hex('#E74C3C'))
      )

      ctx.spawn(
        Bevy::Transform.from_xyz(x, y - 40.0, 0.5),
        Bevy::Mesh::Rectangle.new(width: 2.0, height: 30.0, color: Bevy::Color.from_hex('#FFFF00'))
      )

      speed_indicator = (Math.cos(time_elapsed * 2.0 + i * 0.5).abs * 30.0).round
      text_entity = ctx.spawn(
        Bevy::Transform.from_xyz(x, y + 35.0, 2.0),
        Bevy::Text2d.new("v:#{speed_indicator}", font_size: 10.0, color: Bevy::Color.from_hex('#88FF88'))
      )
      gizmo_entities["debug_text_#{i}"] = text_entity
    end
  end

  if status_entity
    gizmo_status = gizmo_config.enabled ? 'ON' : 'OFF'
    status_text = "Mode: #{mode_labels[current_mode]} | Gizmos: #{gizmo_status}"
    if current_mode == :transform
      status_text += " | Transform: #{transform_gizmo.mode}"
    end
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Gizmos System Demo'
puts ''
puts 'Modes:'
puts '  [1] Basic Shapes - Circle, Rectangle, Polygon'
puts '  [2] Grid & Lines - Coordinate system'
puts '  [3] Transform Gizmo - Move/Rotate/Scale handles'
puts '  [4] Debug Visualization - Motion tracking'
puts ''
puts 'Controls:'
puts '  [T] Translate mode  [R] Rotate mode  [S] Scale mode'
puts '  [G] Toggle gizmos on/off'
puts '  [Arrow Keys] Move target (in transform mode)'
puts '  [ESC] Exit'

app.run
