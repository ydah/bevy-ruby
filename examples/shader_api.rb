# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Shader & Post-Processing Demo',
    width: 1000.0,
    height: 700.0
  }
)

bloom = Bevy::Bloom.new(
  intensity: 0.3,
  threshold: 0.8,
  soft_threshold: 0.5,
  composite_mode: :additive
)

vignette = Bevy::Vignette.new(
  intensity: 0.4,
  radius: 0.6,
  smoothness: 0.3,
  color: Bevy::Color.black
)

color_grading = Bevy::ColorGrading.new(
  exposure: 0.0,
  gamma: 1.0,
  saturation: 1.0,
  contrast: 1.0
)

chromatic_aberration = Bevy::ChromaticAberration.new(
  intensity: 0.0,
  max_samples: 8
)

effects = {
  bloom: { enabled: true, effect: bloom },
  vignette: { enabled: false, effect: vignette },
  color_grading: { enabled: false, effect: color_grading },
  chromatic: { enabled: false, effect: chromatic_aberration }
}

current_effect = :bloom
status_entity = nil

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1100.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Shader & Post-Processing Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  [-200, -100, 0, 100, 200].each_with_index do |x, i|
    hue = i * 0.2
    color = Bevy::Color.from_hsv(hue * 360, 0.8, 1.0)
    ctx.spawn(
      Bevy::Transform.from_xyz(x.to_f, 150.0, 1.0),
      Bevy::Mesh::Circle.new(radius: 40.0, color: color)
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(-300.0, 0.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 100.0, height: 100.0, color: Bevy::Color.from_hex('#FF6B6B'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-150.0, 0.0, 1.0),
    Bevy::Mesh::RegularPolygon.new(radius: 50.0, sides: 6, color: Bevy::Color.from_hex('#4ECDC4'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, 1.0),
    Bevy::Mesh::Circle.new(radius: 50.0, color: Bevy::Color.from_hex('#FFE66D'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(150.0, 0.0, 1.0),
    Bevy::Mesh::RegularPolygon.new(radius: 50.0, sides: 3, color: Bevy::Color.from_hex('#95E1D3'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(300.0, 0.0, 1.0),
    Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: Bevy::Color.from_hex('#F38181'))
  )

  5.times do |i|
    x = -200.0 + i * 100.0
    ctx.spawn(
      Bevy::Transform.from_xyz(x, -150.0, 1.0),
      Bevy::Mesh::Circle.new(radius: 25.0, color: Bevy::Color.from_hex('#FFFFFF'))
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[1-4] Switch Effect  [UP/DOWN] Adjust  [SPACE] Toggle', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -280.0, 0.0),
    Bevy::Text2d.new('Current: Bloom (Intensity: 0.3)', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    current_effect = :bloom
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    current_effect = :vignette
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    current_effect = :color_grading
  elsif ctx.key_just_pressed?('KEY4') || ctx.key_just_pressed?('4')
    current_effect = :chromatic
  end

  if ctx.key_just_pressed?('SPACE')
    effects[current_effect][:enabled] = !effects[current_effect][:enabled]
  end

  adjust_speed = 0.5 * delta
  case current_effect
  when :bloom
    if ctx.key_pressed?('UP')
      bloom.intensity = [bloom.intensity + adjust_speed, 1.0].min
    elsif ctx.key_pressed?('DOWN')
      bloom.intensity = [bloom.intensity - adjust_speed, 0.0].max
    end
  when :vignette
    if ctx.key_pressed?('UP')
      vignette.intensity = [vignette.intensity + adjust_speed, 1.0].min
    elsif ctx.key_pressed?('DOWN')
      vignette.intensity = [vignette.intensity - adjust_speed, 0.0].max
    end
  when :color_grading
    if ctx.key_pressed?('UP')
      color_grading.saturation = [color_grading.saturation + adjust_speed, 2.0].min
    elsif ctx.key_pressed?('DOWN')
      color_grading.saturation = [color_grading.saturation - adjust_speed, 0.0].max
    end
  when :chromatic
    if ctx.key_pressed?('UP')
      chromatic_aberration.intensity = [chromatic_aberration.intensity + adjust_speed * 0.1, 0.1].min
    elsif ctx.key_pressed?('DOWN')
      chromatic_aberration.intensity = [chromatic_aberration.intensity - adjust_speed * 0.1, 0.0].max
    end
  end

  status_text = case current_effect
                when :bloom
                  "Bloom (Intensity: #{bloom.intensity.round(2)}) - #{effects[:bloom][:enabled] ? 'ON' : 'OFF'}"
                when :vignette
                  "Vignette (Intensity: #{vignette.intensity.round(2)}) - #{effects[:vignette][:enabled] ? 'ON' : 'OFF'}"
                when :color_grading
                  "Color Grading (Saturation: #{color_grading.saturation.round(2)}) - #{effects[:color_grading][:enabled] ? 'ON' : 'OFF'}"
                when :chromatic
                  "Chromatic Aberration (Intensity: #{chromatic_aberration.intensity.round(3)}) - #{effects[:chromatic][:enabled] ? 'ON' : 'OFF'}"
                end

  if status_entity
    new_text = Bevy::Text2d.new("Current: #{status_text}", font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Shader & Post-Processing Demo'
puts ''
puts 'Controls:'
puts '  [1] Bloom effect'
puts '  [2] Vignette effect'
puts '  [3] Color Grading'
puts '  [4] Chromatic Aberration'
puts '  [UP/DOWN] Adjust intensity'
puts '  [SPACE] Toggle effect on/off'
puts '  [ESC] Exit'

app.run
