# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Animation System Demo',
    width: 900.0,
    height: 700.0
  }
)

class AnimatedObject
  attr_accessor :tween, :position, :color, :size, :label

  def initialize(label:, tween:, initial_pos:, color:, size: 30.0)
    @label = label
    @tween = tween
    @position = initial_pos
    @color = color
    @size = size
  end

  def update(delta)
    @tween.update(delta)
  end
end

easings = [
  { name: 'Linear', easing: :linear, color: '#E74C3C' },
  { name: 'Ease In Quad', easing: :ease_in_quad, color: '#3498DB' },
  { name: 'Ease Out Quad', easing: :ease_out_quad, color: '#2ECC71' },
  { name: 'Ease In Out Cubic', easing: :ease_in_out_cubic, color: '#F39C12' },
  { name: 'Ease Out Back', easing: :ease_out_back, color: '#9B59B6' },
  { name: 'Ease Out Bounce', easing: :ease_out_bounce, color: '#1ABC9C' },
  { name: 'Ease Out Elastic', easing: :ease_out_elastic, color: '#E91E63' }
]

animated_objects = easings.map.with_index do |config, i|
  y = 180.0 - i * 60.0
  tween = Bevy::Tween.new(
    from: -300.0,
    to: 300.0,
    duration: 2.0,
    easing: config[:easing],
    repeat_mode: :loop
  )
  AnimatedObject.new(
    label: config[:name],
    tween: tween,
    initial_pos: Bevy::Vec3.new(-300.0, y, 0.0),
    color: Bevy::Color.from_hex(config[:color]),
    size: 25.0
  )
end

scale_tween = Bevy::Tween.new(
  from: 20.0,
  to: 50.0,
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

object_entities = {}
scale_entity = nil
color_entity = nil
paused = false

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Animation System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[SPACE] Pause/Resume  [R] Reset  [ESC] Exit', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  animated_objects.each_with_index do |obj, i|
    y = 180.0 - i * 60.0
    ctx.spawn(
      Bevy::Transform.from_xyz(-400.0, y, 0.0),
      Bevy::Text2d.new(obj.label, font_size: 12.0, color: obj.color)
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -220.0, 0.0),
    Bevy::Text2d.new('Scale Animation', font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Color Keyframe Animation', font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  if ctx.key_just_pressed?('SPACE')
    paused = !paused
  end

  if ctx.key_just_pressed?('R')
    animated_objects.each { |obj| obj.tween.reset }
    scale_tween.reset
    color_player.seek(0.0)
  end

  unless paused
    animated_objects.each { |obj| obj.update(delta) }
    scale_tween.update(delta)
    color_player.update(delta)
  end

  object_entities.each { |_, e| ctx.world.despawn(e) if e }
  object_entities.clear

  animated_objects.each_with_index do |obj, i|
    y = 180.0 - i * 60.0
    x = obj.tween.current_value
    entity = ctx.spawn(
      Bevy::Transform.from_xyz(x, y, 1.0),
      Bevy::Mesh::Circle.new(radius: obj.size, color: obj.color)
    )
    object_entities[i] = entity
  end

  scale_radius = scale_tween.current_value
  scale_entity = ctx.spawn(
    Bevy::Transform.from_xyz(-150.0, -260.0, 1.0),
    Bevy::Mesh::Circle.new(radius: scale_radius, color: Bevy::Color.from_hex('#FFD700'))
  )
  object_entities[:scale] = scale_entity

  current_color = color_player.sample_property(:color) || Bevy::Color.from_hex('#E74C3C')
  color_entity = ctx.spawn(
    Bevy::Transform.from_xyz(150.0, -260.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: current_color)
  )
  object_entities[:color] = color_entity

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Animation System Demo'
puts ''
puts 'Easing functions visualized:'
puts '  - Linear, Quad, Cubic, Back, Bounce, Elastic'
puts ''
puts 'Additional animations:'
puts '  - Scale animation (pulsing circle)'
puts '  - Color keyframe animation (rainbow rectangle)'
puts ''
puts 'Controls:'
puts '  [SPACE] Pause/Resume'
puts '  [R] Reset all animations'
puts '  [ESC] Exit'

app.run
