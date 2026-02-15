# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Scene System Demo',
    width: 900.0,
    height: 700.0
  }
)

scenes = {
  forest: {
    name: 'Forest Scene',
    color: '#1a3a1a',
    entities: [
      { type: :rect, x: 0.0, y: -180.0, w: 800.0, h: 100.0, color: '#2d5a2d' },
      { type: :circle, x: -200.0, y: 50.0, r: 80.0, color: '#1a5a1a' },
      { type: :circle, x: -180.0, y: 80.0, r: 60.0, color: '#2a6a2a' },
      { type: :circle, x: 100.0, y: 30.0, r: 100.0, color: '#1a5a1a' },
      { type: :circle, x: 130.0, y: 70.0, r: 70.0, color: '#2a6a2a' },
      { type: :rect, x: -200.0, y: -60.0, w: 20.0, h: 120.0, color: '#5a3a1a' },
      { type: :rect, x: 100.0, y: -70.0, w: 25.0, h: 140.0, color: '#5a3a1a' }
    ]
  },
  desert: {
    name: 'Desert Scene',
    color: '#3a2a1a',
    entities: [
      { type: :rect, x: 0.0, y: -180.0, w: 800.0, h: 100.0, color: '#d4a84a' },
      { type: :polygon, x: -150.0, y: 0.0, r: 120.0, sides: 3, color: '#c4984a' },
      { type: :polygon, x: 100.0, y: -20.0, r: 80.0, sides: 3, color: '#b4884a' },
      { type: :circle, x: 300.0, y: 150.0, r: 40.0, color: '#FFD700' },
      { type: :circle, x: -280.0, y: 50.0, r: 15.0, color: '#2a8a2a' }
    ]
  },
  ocean: {
    name: 'Ocean Scene',
    color: '#1a2a3a',
    entities: [
      { type: :rect, x: 0.0, y: -100.0, w: 800.0, h: 260.0, color: '#2a5a8a' },
      { type: :rect, x: 0.0, y: 100.0, w: 800.0, h: 140.0, color: '#4a8aba' },
      { type: :circle, x: 200.0, y: 180.0, r: 50.0, color: '#FFD700' },
      { type: :polygon, x: -100.0, y: -50.0, r: 40.0, sides: 3, color: '#aaaaaa' },
      { type: :polygon, x: 150.0, y: -80.0, r: 30.0, sides: 3, color: '#bbbbbb' },
      { type: :circle, x: -200.0, y: -120.0, r: 25.0, color: '#3a7aaa' }
    ]
  },
  space: {
    name: 'Space Scene',
    color: '#0a0a1a',
    entities: [
      { type: :circle, x: -200.0, y: 100.0, r: 80.0, color: '#5a5aaa' },
      { type: :circle, x: 150.0, y: -50.0, r: 60.0, color: '#8a5a4a' },
      { type: :circle, x: 100.0, y: 150.0, r: 30.0, color: '#aaaaaa' }
    ]
  }
}

scene_keys = scenes.keys
current_scene_index = 0
scene_entities = []
stars = []
status_entity = nil
transition_progress = 1.0
transitioning = false
time_elapsed = 0.0

50.times do
  stars << {
    x: rand(-400.0..400.0),
    y: rand(-250.0..280.0),
    size: rand(1.0..3.0),
    twinkle_offset: rand(0.0..Math::PI * 2)
  }
end

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Scene System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[LEFT/RIGHT] Switch Scene  [R] Reload  [S] Save (simulated)', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Current: Forest Scene', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if !transitioning
    if ctx.key_just_pressed?('LEFT')
      current_scene_index = (current_scene_index - 1) % scene_keys.size
      transitioning = true
      transition_progress = 0.0
    elsif ctx.key_just_pressed?('RIGHT')
      current_scene_index = (current_scene_index + 1) % scene_keys.size
      transitioning = true
      transition_progress = 0.0
    end
  end

  if ctx.key_just_pressed?('R')
    transitioning = true
    transition_progress = 0.0
  end

  if transitioning
    transition_progress += delta * 2.0
    if transition_progress >= 1.0
      transition_progress = 1.0
      transitioning = false
    end
  end

  scene_entities.each { |e| ctx.world.despawn(e) }
  scene_entities.clear

  current_key = scene_keys[current_scene_index]
  scene = scenes[current_key]

  bg_alpha = transitioning ? transition_progress : 1.0
  bg_color = Bevy::Color.from_hex(scene[:color])
  bg_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(
      width: 1000.0,
      height: 800.0,
      color: Bevy::Color.rgba(bg_color.r, bg_color.g, bg_color.b, bg_alpha)
    )
  )
  scene_entities << bg_entity

  if current_key == :space
    stars.each_with_index do |star, i|
      twinkle = (Math.sin(time_elapsed * 2.0 + star[:twinkle_offset]) + 1.0) / 2.0
      alpha = 0.3 + twinkle * 0.7
      star_entity = ctx.spawn(
        Bevy::Transform.from_xyz(star[:x], star[:y], -5.0),
        Bevy::Mesh::Circle.new(radius: star[:size], color: Bevy::Color.rgba(1.0, 1.0, 1.0, alpha))
      )
      scene_entities << star_entity
    end
  end

  scene[:entities].each_with_index do |ent, i|
    entity_alpha = transitioning ? [[transition_progress * 2.0, 1.0].min, 0.0].max : 1.0
    base_color = Bevy::Color.from_hex(ent[:color])
    color = Bevy::Color.rgba(base_color.r, base_color.g, base_color.b, entity_alpha)

    spawn_y = ent[:y]
    if transitioning
      spawn_y = ent[:y] - 50.0 + 50.0 * transition_progress
    end

    entity = case ent[:type]
             when :rect
               ctx.spawn(
                 Bevy::Transform.from_xyz(ent[:x], spawn_y, i.to_f * 0.1),
                 Bevy::Mesh::Rectangle.new(width: ent[:w], height: ent[:h], color: color)
               )
             when :circle
               ctx.spawn(
                 Bevy::Transform.from_xyz(ent[:x], spawn_y, i.to_f * 0.1),
                 Bevy::Mesh::Circle.new(radius: ent[:r], color: color)
               )
             when :polygon
               ctx.spawn(
                 Bevy::Transform.from_xyz(ent[:x], spawn_y, i.to_f * 0.1),
                 Bevy::Mesh::RegularPolygon.new(radius: ent[:r], sides: ent[:sides], color: color)
               )
             end
    scene_entities << entity if entity
  end

  if status_entity
    status_text = "Current: #{scene[:name]} | Entities: #{scene[:entities].size}"
    status_text += ' [Loading...]' if transitioning
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Scene System Demo'
puts ''
puts 'Available Scenes:'
puts '  - Forest Scene'
puts '  - Desert Scene'
puts '  - Ocean Scene'
puts '  - Space Scene'
puts ''
puts 'Controls:'
puts '  [LEFT/RIGHT] Switch between scenes'
puts '  [R] Reload current scene'
puts '  [S] Save scene (simulated)'
puts '  [ESC] Exit'

app.run
