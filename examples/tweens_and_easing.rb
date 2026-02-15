# frozen_string_literal: true

require 'bevy'

class AnimatedSprite < Bevy::ComponentDSL
  attribute :name, String, default: ''
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Animation Demo - Tweens, Easing, Keyframes',
    width: 900.0,
    height: 700.0
  }
)

bounce_tween = Bevy::Tween.new(
  from: Bevy::Vec3.new(-300.0, 200.0, 1.0),
  to: Bevy::Vec3.new(300.0, 200.0, 1.0),
  duration: 2.0,
  easing: :ease_out_bounce,
  repeat_mode: :loop
)

elastic_tween = Bevy::Tween.new(
  from: Bevy::Vec3.new(-300.0, 50.0, 1.0),
  to: Bevy::Vec3.new(300.0, 50.0, 1.0),
  duration: 2.0,
  easing: :ease_out_elastic,
  repeat_mode: :loop
)

scale_tween = Bevy::Tween.new(
  from: 20.0,
  to: 60.0,
  duration: 1.0,
  easing: :ease_in_out_sine,
  repeat_mode: :ping_pong
)

color_clip = Bevy::AnimationClip.new('color_cycle', repeat_mode: :loop)
color_track = color_clip.add_track(:color)
color_track.add_keyframe(0.0, Bevy::Color.from_hex('#E74C3C'))
color_track.add_keyframe(1.0, Bevy::Color.from_hex('#F39C12'), easing: :ease_in_out_quad)
color_track.add_keyframe(2.0, Bevy::Color.from_hex('#2ECC71'), easing: :ease_in_out_quad)
color_track.add_keyframe(3.0, Bevy::Color.from_hex('#3498DB'), easing: :ease_in_out_quad)
color_track.add_keyframe(4.0, Bevy::Color.from_hex('#9B59B6'), easing: :ease_in_out_quad)
color_track.add_keyframe(5.0, Bevy::Color.from_hex('#E74C3C'), easing: :ease_in_out_quad)

color_player = Bevy::AnimationPlayer.new
color_player.add_clip(color_clip)
color_player.play('color_cycle')

orbit_clip = Bevy::AnimationClip.new('orbit', repeat_mode: :loop)
x_track = orbit_clip.add_track(:x)
y_track = orbit_clip.add_track(:y)

steps = 60
radius = 100.0
(0..steps).each do |i|
  t = i.to_f / steps
  angle = t * 2.0 * Math::PI
  x_track.add_keyframe(t * 3.0, Math.cos(angle) * radius)
  y_track.add_keyframe(t * 3.0, Math.sin(angle) * radius * 0.5)
end

orbit_player = Bevy::AnimationPlayer.new
orbit_player.add_clip(orbit_clip)
orbit_player.play('orbit')

easing_demos = [
  { name: 'Linear', easing: :linear, y: 100 },
  { name: 'Ease In Quad', easing: :ease_in_quad, y: 60 },
  { name: 'Ease Out Quad', easing: :ease_out_quad, y: 20 },
  { name: 'Ease In Out Cubic', easing: :ease_in_out_cubic, y: -20 },
  { name: 'Ease Out Back', easing: :ease_out_back, y: -60 },
  { name: 'Ease Out Bounce', easing: :ease_out_bounce, y: -100 }
]

easing_tweens = easing_demos.map do |demo|
  Bevy::Tween.new(
    from: -350.0,
    to: -150.0,
    duration: 2.0,
    easing: demo[:easing],
    repeat_mode: :loop
  )
end

entities = {}

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Animation Demo', font_size: 32.0, color: Bevy::Color.white)
  )

  entities[:bounce] = ctx.spawn(
    AnimatedSprite.new(name: 'bounce'),
    Bevy::Transform.from_xyz(-300.0, 200.0, 1.0),
    Bevy::Mesh::Circle.new(radius: 25.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 200.0, 0.0),
    Bevy::Text2d.new('Bounce:', font_size: 14.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )

  entities[:elastic] = ctx.spawn(
    AnimatedSprite.new(name: 'elastic'),
    Bevy::Transform.from_xyz(-300.0, 50.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 40.0, height: 40.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 50.0, 0.0),
    Bevy::Text2d.new('Elastic:', font_size: 14.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )

  entities[:scale] = ctx.spawn(
    AnimatedSprite.new(name: 'scale'),
    Bevy::Transform.from_xyz(0.0, -100.0, 1.0),
    Bevy::Mesh::Circle.new(radius: 30.0, color: Bevy::Color.from_hex('#2ECC71'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-100.0, -100.0, 0.0),
    Bevy::Text2d.new('Scale:', font_size: 14.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )

  entities[:color] = ctx.spawn(
    AnimatedSprite.new(name: 'color'),
    Bevy::Transform.from_xyz(200.0, -100.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(120.0, -100.0, 0.0),
    Bevy::Text2d.new('Color:', font_size: 14.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )

  entities[:orbit] = ctx.spawn(
    AnimatedSprite.new(name: 'orbit'),
    Bevy::Transform.from_xyz(0.0, -250.0, 1.0),
    Bevy::Mesh::RegularPolygon.new(radius: 15.0, sides: 6, color: Bevy::Color.from_hex('#F39C12'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -250.0, 0.0),
    Bevy::Mesh::Circle.new(radius: 3.0, color: Bevy::Color.from_hex('#7F8C8D'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-100.0, -250.0, 0.0),
    Bevy::Text2d.new('Orbit:', font_size: 14.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  bounce_tween.update(delta)
  elastic_tween.update(delta)
  scale_tween.update(delta)
  color_player.update(delta)
  orbit_player.update(delta)
  easing_tweens.each { |t| t.update(delta) }

  if entities[:bounce]
    pos = bounce_tween.current_value
    entity = entities[:bounce]
    new_transform = Bevy::Transform.from_xyz(pos.x, pos.y, pos.z)
    ctx.world.insert_component(entity, new_transform)
  end

  if entities[:elastic]
    pos = elastic_tween.current_value
    entity = entities[:elastic]
    new_transform = Bevy::Transform.from_xyz(pos.x, pos.y, pos.z)
    ctx.world.insert_component(entity, new_transform)
  end

  if entities[:scale]
    radius = scale_tween.current_value
    entity = entities[:scale]
    new_mesh = Bevy::Mesh::Circle.new(radius: radius, color: Bevy::Color.from_hex('#2ECC71'))
    ctx.world.mesh_components[entity.id] ||= {}
    ctx.world.mesh_components[entity.id][new_mesh.type_name] = new_mesh
  end

  if entities[:color]
    color = color_player.sample_property(:color)
    if color
      entity = entities[:color]
      new_mesh = Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: color)
      ctx.world.mesh_components[entity.id] ||= {}
      ctx.world.mesh_components[entity.id][new_mesh.type_name] = new_mesh
    end
  end

  if entities[:orbit]
    x = orbit_player.sample_property(:x) || 0.0
    y = orbit_player.sample_property(:y) || 0.0
    entity = entities[:orbit]
    new_transform = Bevy::Transform.from_xyz(x, -250.0 + y, 1.0)
    ctx.world.insert_component(entity, new_transform)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Animation Demo'
puts ''
puts 'Animations shown:'
puts '  - Bounce easing (circle moving horizontally)'
puts '  - Elastic easing (rectangle moving horizontally)'
puts '  - Scale animation (pulsing circle)'
puts '  - Color keyframe animation (color-changing rectangle)'
puts '  - Orbit animation (hexagon orbiting)'
puts ''
puts 'Press ESC to exit'

app.run
