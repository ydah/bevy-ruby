# frozen_string_literal: true

require 'bevy'

class Player < Bevy::ComponentDSL
  attribute :speed, Float, default: 200.0
end

class GridPoint < Bevy::ComponentDSL
  attribute :base_x, Float, default: 0.0
  attribute :base_y, Float, default: 0.0
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Camera Effects Demo - SmoothFollow, Shake, Zoom',
    width: 900.0,
    height: 700.0
  }
)

smooth_follow = Bevy::SmoothFollow.new(smoothness: 5.0, offset: Bevy::Vec3.new(0.0, 0.0, 0.0))
camera_shake = Bevy::CameraShake.new
camera_zoom = Bevy::CameraZoom.new(initial: 1.0, min: 0.5, max: 2.0)
camera_bounds = Bevy::CameraBounds.new(min_x: -300.0, max_x: 300.0, min_y: -200.0, max_y: 200.0)

app.add_startup_system do |ctx|
  ctx.spawn(
    Player.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 40.0, height: 40.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  grid_color = Bevy::Color.from_hex('#34495E')
  (-8..8).each do |x|
    (-6..6).each do |y|
      next if x.zero? && y.zero?

      ctx.spawn(
        GridPoint.new(base_x: x * 80.0, base_y: y * 80.0),
        Bevy::Transform.from_xyz(x * 80.0, y * 80.0, 0.0),
        Bevy::Mesh::Rectangle.new(width: 15.0, height: 15.0, color: grid_color)
      )
    end
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Mesh::Rectangle.new(width: 1600.0, height: 1200.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  ctx.world.each(Player, Bevy::Transform) do |entity, player, transform|
    dx = 0.0
    dy = 0.0
    dx -= 1.0 if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')
    dx += 1.0 if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')
    dy += 1.0 if ctx.key_pressed?('W') || ctx.key_pressed?('UP')
    dy -= 1.0 if ctx.key_pressed?('S') || ctx.key_pressed?('DOWN')

    new_x = transform.translation.x + dx * player.speed * delta
    new_y = transform.translation.y + dy * player.speed * delta

    new_transform = Bevy::Transform.from_xyz(new_x, new_y, 1.0)
    ctx.world.insert_component(entity, new_transform)

    target_pos = Bevy::Vec3.new(new_x, new_y, 0.0)
    smooth_follow.follow(target_pos)
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta

  current_pos = ctx.camera_position
  new_pos = smooth_follow.lerp_position(current_pos, delta)

  shake_offset = camera_shake.update(delta)
  shaken_pos = Bevy::Vec3.new(
    new_pos.x + shake_offset.x,
    new_pos.y + shake_offset.y,
    new_pos.z
  )

  bounded_pos = camera_bounds.clamp(shaken_pos)

  ctx.set_camera_position(bounded_pos)
  ctx.set_camera_zoom(camera_zoom.current)
end

app.add_update_system do |ctx|
  camera_shake.trigger(25.0, 0.4) if ctx.key_just_pressed?('SPACE')
  camera_zoom.zoom_in(0.1) if ctx.key_just_pressed?('Q')
  camera_zoom.zoom_out(0.1) if ctx.key_just_pressed?('E')
  camera_zoom.set(1.0) if ctx.key_just_pressed?('R')

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Camera Effects Demo'
puts ''
puts 'Controls:'
puts '  WASD/Arrows - Move player (blue square)'
puts '  SPACE       - Trigger camera shake'
puts '  Q/E         - Zoom in/out'
puts '  R           - Reset zoom'
puts '  ESC         - Exit'
puts ''
puts 'Features:'
puts '  - SmoothFollow: Camera smoothly follows the player'
puts '  - CameraShake: Press SPACE for screen shake effect'
puts '  - CameraZoom: Q/E to zoom the camera'
puts '  - CameraBounds: Camera stays within defined boundaries'

app.run
