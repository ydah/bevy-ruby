# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Audio Effects System Demo',
    width: 900.0,
    height: 700.0
  }
)

reverb = Bevy::Reverb.new(room_size: 0.7, damping: 0.5, wet_level: 0.4, dry_level: 0.6)
delay = Bevy::Delay.new(delay_time: 0.25, feedback: 0.4, wet_level: 0.5)
lpf = Bevy::LowPassFilter.new(cutoff: 2000.0, resonance: 0.707)
compressor = Bevy::Compressor.new(threshold: -18.0, ratio: 4.0, attack: 0.005, release: 0.1)
chorus = Bevy::Chorus.new(rate: 1.5, depth: 0.02, delay: 0.03, feedback: 0.25)
distortion = Bevy::Distortion.new(drive: 0.5, range: 1000.0, blend: 0.6)

effects = [
  { name: 'Reverb', effect: reverb, param: :room_size, range: [0.0, 1.0], color: '#E74C3C' },
  { name: 'Delay', effect: delay, param: :delay_time, range: [0.0, 1.0], color: '#3498DB' },
  { name: 'Low Pass', effect: lpf, param: :cutoff, range: [100.0, 10000.0], color: '#2ECC71' },
  { name: 'Compressor', effect: compressor, param: :threshold, range: [-60.0, 0.0], color: '#F39C12' },
  { name: 'Chorus', effect: chorus, param: :rate, range: [0.1, 5.0], color: '#9B59B6' },
  { name: 'Distortion', effect: distortion, param: :drive, range: [0.0, 1.0], color: '#E91E63' }
]

current_effect_index = 0
waveform_points = []
time_elapsed = 0.0

status_entity = nil
bar_entities = {}

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Audio Effects System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[UP/DOWN] Select Effect  [LEFT/RIGHT] Adjust Parameter  [SPACE] Toggle', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  effects.each_with_index do |eff, i|
    y = 180.0 - i * 70.0
    ctx.spawn(
      Bevy::Transform.from_xyz(-380.0, y, 0.0),
      Bevy::Text2d.new(eff[:name], font_size: 14.0, color: Bevy::Color.from_hex(eff[:color]))
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -250.0, 0.0),
    Bevy::Text2d.new('Waveform Visualization', font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Current: Reverb | Room Size: 0.70', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if ctx.key_just_pressed?('UP')
    current_effect_index = (current_effect_index - 1) % effects.size
  elsif ctx.key_just_pressed?('DOWN')
    current_effect_index = (current_effect_index + 1) % effects.size
  end

  current = effects[current_effect_index]
  adjust_speed = delta * (current[:range][1] - current[:range][0]) * 0.3

  if ctx.key_pressed?('LEFT')
    value = current[:effect].send(current[:param])
    new_value = [value - adjust_speed, current[:range][0]].max
    current[:effect].send("#{current[:param]}=", new_value)
  elsif ctx.key_pressed?('RIGHT')
    value = current[:effect].send(current[:param])
    new_value = [value + adjust_speed, current[:range][1]].min
    current[:effect].send("#{current[:param]}=", new_value)
  end

  if ctx.key_just_pressed?('SPACE')
    current[:effect].enabled = !current[:effect].enabled
  end

  bar_entities.each { |_, e| ctx.world.despawn(e) if e }
  bar_entities.clear

  effects.each_with_index do |eff, i|
    y = 180.0 - i * 70.0
    value = eff[:effect].send(eff[:param])
    normalized = (value - eff[:range][0]) / (eff[:range][1] - eff[:range][0])
    bar_width = normalized * 300.0

    alpha = eff[:effect].enabled ? 1.0 : 0.3
    color = Bevy::Color.from_hex(eff[:color])
    bar_color = Bevy::Color.rgba(color.r, color.g, color.b, alpha)

    bg_entity = ctx.spawn(
      Bevy::Transform.from_xyz(0.0, y, 0.0),
      Bevy::Mesh::Rectangle.new(width: 300.0, height: 30.0, color: Bevy::Color.from_hex('#333344'))
    )
    bar_entities["bg_#{i}"] = bg_entity

    bar_entity = ctx.spawn(
      Bevy::Transform.from_xyz(-150.0 + bar_width / 2.0, y, 1.0),
      Bevy::Mesh::Rectangle.new(width: [bar_width, 1.0].max, height: 26.0, color: bar_color)
    )
    bar_entities["bar_#{i}"] = bar_entity

    if i == current_effect_index
      selector = ctx.spawn(
        Bevy::Transform.from_xyz(-320.0, y, 2.0),
        Bevy::Mesh::RegularPolygon.new(radius: 10.0, sides: 3, color: Bevy::Color.white)
      )
      bar_entities[:selector] = selector
    end
  end

  waveform_points.clear
  50.times do |i|
    t = time_elapsed + i * 0.05
    base_wave = Math.sin(t * 5.0) * 50.0

    processed = base_wave
    processed *= (1.0 + reverb.room_size * 0.5) if reverb.enabled
    processed *= (1.0 - lpf.cutoff / 20000.0 * 0.3) if lpf.enabled
    processed *= (1.0 + distortion.drive * 0.5) if distortion.enabled

    x = -200.0 + i * 8.0
    y = -180.0 + processed * 0.8
    waveform_points << { x: x, y: y }
  end

  waveform_points.each_with_index do |point, i|
    wave_entity = ctx.spawn(
      Bevy::Transform.from_xyz(point[:x], point[:y], 1.0),
      Bevy::Mesh::Circle.new(radius: 4.0, color: Bevy::Color.from_hex('#00FF88'))
    )
    bar_entities["wave_#{i}"] = wave_entity
  end

  if status_entity
    current = effects[current_effect_index]
    value = current[:effect].send(current[:param])
    enabled_text = current[:effect].enabled ? 'ON' : 'OFF'
    param_name = current[:param].to_s.split('_').map(&:capitalize).join(' ')
    status_text = "Current: #{current[:name]} | #{param_name}: #{value.round(2)} [#{enabled_text}]"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Audio Effects System Demo'
puts ''
puts 'Effects available:'
puts '  - Reverb (room size)'
puts '  - Delay (delay time)'
puts '  - Low Pass Filter (cutoff frequency)'
puts '  - Compressor (threshold)'
puts '  - Chorus (rate)'
puts '  - Distortion (drive)'
puts ''
puts 'Controls:'
puts '  [UP/DOWN] Select effect'
puts '  [LEFT/RIGHT] Adjust parameter'
puts '  [SPACE] Toggle effect on/off'
puts '  [ESC] Exit'

app.run
