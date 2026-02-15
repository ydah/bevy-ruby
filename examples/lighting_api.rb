# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Lighting System Demo',
    width: 900.0,
    height: 700.0
  }
)

point_light = Bevy::PointLight.new(
  color: Bevy::Color.rgba(1.0, 0.9, 0.7, 1.0),
  intensity: 1000.0,
  range: 200.0,
  shadows_enabled: true
)

directional_light = Bevy::DirectionalLight.new(
  color: Bevy::Color.rgba(1.0, 0.95, 0.9, 1.0),
  illuminance: 50_000.0,
  shadows_enabled: true
)

spot_light = Bevy::SpotLight.new(
  color: Bevy::Color.rgba(0.5, 0.8, 1.0, 1.0),
  intensity: 1500.0,
  range: 150.0,
  inner_angle: Math::PI / 8.0,
  outer_angle: Math::PI / 4.0
)

ambient_light = Bevy::AmbientLight.new(
  color: Bevy::Color.rgba(0.2, 0.2, 0.3, 1.0),
  brightness: 0.1
)

current_light = :point
light_types = [:point, :directional, :spot, :ambient]
light_labels = {
  point: 'Point Light',
  directional: 'Directional Light',
  spot: 'Spot Light',
  ambient: 'Ambient Light'
}

light_entity = nil
light_indicator_entity = nil
status_entity = nil
time_elapsed = 0.0
light_position = Bevy::Vec3.new(0.0, 100.0, 0.0)

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#0a0a15'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Lighting System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  [-300, -150, 0, 150, 300].each do |x|
    ctx.spawn(
      Bevy::Transform.from_xyz(x.to_f, -100.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: Bevy::Color.from_hex('#333344'))
    )
  end

  [-225, -75, 75, 225].each do |x|
    ctx.spawn(
      Bevy::Transform.from_xyz(x.to_f, -200.0, 0.0),
      Bevy::Mesh::Circle.new(radius: 35.0, color: Bevy::Color.from_hex('#444455'))
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 50.0, 0.0),
    Bevy::Mesh::RegularPolygon.new(radius: 60.0, sides: 6, color: Bevy::Color.from_hex('#555566'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[1-4] Switch Light  [Arrow Keys] Move  [+/-] Intensity', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Current: Point Light | Intensity: 1000', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )

  light_indicator_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 100.0, 5.0),
    Bevy::Mesh::Circle.new(radius: 15.0, color: Bevy::Color.from_hex('#FFDD44'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    current_light = :point
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    current_light = :directional
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    current_light = :spot
  elsif ctx.key_just_pressed?('KEY4') || ctx.key_just_pressed?('4')
    current_light = :ambient
  end

  move_speed = 150.0 * delta
  if ctx.key_pressed?('LEFT')
    light_position = Bevy::Vec3.new(light_position.x - move_speed, light_position.y, light_position.z)
  elsif ctx.key_pressed?('RIGHT')
    light_position = Bevy::Vec3.new(light_position.x + move_speed, light_position.y, light_position.z)
  end
  if ctx.key_pressed?('UP')
    light_position = Bevy::Vec3.new(light_position.x, light_position.y + move_speed, light_position.z)
  elsif ctx.key_pressed?('DOWN')
    light_position = Bevy::Vec3.new(light_position.x, light_position.y - move_speed, light_position.z)
  end

  light_position = Bevy::Vec3.new(
    [[light_position.x, -400.0].max, 400.0].min,
    [[light_position.y, -250.0].max, 250.0].min,
    light_position.z
  )

  intensity_change = 100.0 * delta
  case current_light
  when :point
    if ctx.key_pressed?('EQUALS') || ctx.key_pressed?('PLUS')
      point_light.intensity = [point_light.intensity + intensity_change * 10, 5000.0].min
    elsif ctx.key_pressed?('MINUS')
      point_light.intensity = [point_light.intensity - intensity_change * 10, 100.0].max
    end
  when :directional
    if ctx.key_pressed?('EQUALS') || ctx.key_pressed?('PLUS')
      directional_light.illuminance = [directional_light.illuminance + intensity_change * 1000, 200_000.0].min
    elsif ctx.key_pressed?('MINUS')
      directional_light.illuminance = [directional_light.illuminance - intensity_change * 1000, 10_000.0].max
    end
  when :spot
    if ctx.key_pressed?('EQUALS') || ctx.key_pressed?('PLUS')
      spot_light.intensity = [spot_light.intensity + intensity_change * 10, 5000.0].min
    elsif ctx.key_pressed?('MINUS')
      spot_light.intensity = [spot_light.intensity - intensity_change * 10, 100.0].max
    end
  when :ambient
    if ctx.key_pressed?('EQUALS') || ctx.key_pressed?('PLUS')
      ambient_light.brightness = [ambient_light.brightness + intensity_change * 0.01, 1.0].min
    elsif ctx.key_pressed?('MINUS')
      ambient_light.brightness = [ambient_light.brightness - intensity_change * 0.01, 0.0].max
    end
  end

  light_color = case current_light
                when :point then point_light.color
                when :directional then directional_light.color
                when :spot then spot_light.color
                when :ambient then ambient_light.color
                end

  intensity_text = case current_light
                   when :point then point_light.intensity.round.to_s
                   when :directional then "#{(directional_light.illuminance / 1000).round}k lux"
                   when :spot then spot_light.intensity.round.to_s
                   when :ambient then (ambient_light.brightness * 100).round.to_s + '%'
                   end

  if light_indicator_entity
    indicator_color = Bevy::Color.rgba(light_color.r, light_color.g, light_color.b, 0.8)
    pulse = (Math.sin(time_elapsed * 3.0) + 1.0) / 2.0 * 5.0 + 15.0
    new_mesh = Bevy::Mesh::Circle.new(radius: pulse, color: indicator_color)
    ctx.world.insert_component(light_indicator_entity, new_mesh)
    ctx.world.insert_component(light_indicator_entity, Bevy::Transform.from_xyz(light_position.x, light_position.y, 5.0))
  end

  if status_entity
    status_text = "Current: #{light_labels[current_light]} | Intensity: #{intensity_text}"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Lighting System Demo'
puts ''
puts 'Light Types:'
puts '  [1] Point Light - Omnidirectional light source'
puts '  [2] Directional Light - Sun-like parallel rays'
puts '  [3] Spot Light - Focused cone of light'
puts '  [4] Ambient Light - Global fill light'
puts ''
puts 'Controls:'
puts '  [Arrow Keys] Move light position'
puts '  [+/-] Adjust intensity'
puts '  [ESC] Exit'

app.run
