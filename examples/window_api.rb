# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Window System Demo',
    width: 900.0,
    height: 700.0
  }
)

window_config = {
  title: 'Window System Demo',
  width: 900.0,
  height: 700.0,
  mode: :windowed,
  resizable: true,
  decorations: true,
  cursor_visible: true,
  cursor_grab: :none,
  vsync: true
}

modes = [:windowed, :borderless, :fullscreen]
grab_modes = [:none, :confined, :locked]
current_mode_index = 0
current_grab_index = 0

window_events = []
entity_cache = {}
status_entity = nil
time_elapsed = 0.0

simulated_monitors = [
  { name: 'Primary Display', width: 1920, height: 1080, refresh: 60, scale: 1.0 },
  { name: 'Secondary Display', width: 2560, height: 1440, refresh: 144, scale: 1.5 },
  { name: 'External Monitor', width: 3840, height: 2160, refresh: 60, scale: 2.0 }
]

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Window System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[M] Window Mode  [C] Cursor Grab  [V] VSync  [D] Decorations', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Mode: Windowed | Cursor: Visible | VSync: ON', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if ctx.key_just_pressed?('M')
    current_mode_index = (current_mode_index + 1) % modes.size
    window_config[:mode] = modes[current_mode_index]
    window_events << { type: 'Mode Changed', value: modes[current_mode_index].to_s, time: time_elapsed }
  end

  if ctx.key_just_pressed?('C')
    current_grab_index = (current_grab_index + 1) % grab_modes.size
    window_config[:cursor_grab] = grab_modes[current_grab_index]
    window_events << { type: 'Cursor Grab', value: grab_modes[current_grab_index].to_s, time: time_elapsed }
  end

  if ctx.key_just_pressed?('V')
    window_config[:vsync] = !window_config[:vsync]
    window_events << { type: 'VSync', value: window_config[:vsync] ? 'ON' : 'OFF', time: time_elapsed }
  end

  if ctx.key_just_pressed?('D')
    window_config[:decorations] = !window_config[:decorations]
    window_events << { type: 'Decorations', value: window_config[:decorations] ? 'ON' : 'OFF', time: time_elapsed }
  end

  if ctx.key_just_pressed?('H')
    window_config[:cursor_visible] = !window_config[:cursor_visible]
    window_events << { type: 'Cursor', value: window_config[:cursor_visible] ? 'Visible' : 'Hidden', time: time_elapsed }
  end

  window_events.reject! { |e| time_elapsed - e[:time] > 5.0 }

  entity_cache.each { |_, e| ctx.world.despawn(e) if e }
  entity_cache.clear

  config_y = 180.0
  config_items = [
    { label: 'Title', value: window_config[:title] },
    { label: 'Size', value: "#{window_config[:width].to_i}x#{window_config[:height].to_i}" },
    { label: 'Mode', value: window_config[:mode].to_s.capitalize },
    { label: 'Resizable', value: window_config[:resizable] ? 'Yes' : 'No' },
    { label: 'Decorations', value: window_config[:decorations] ? 'Yes' : 'No' },
    { label: 'Cursor Visible', value: window_config[:cursor_visible] ? 'Yes' : 'No' },
    { label: 'Cursor Grab', value: window_config[:cursor_grab].to_s.capitalize },
    { label: 'VSync', value: window_config[:vsync] ? 'ON' : 'OFF' }
  ]

  header_entity = ctx.spawn(
    Bevy::Transform.from_xyz(-280.0, config_y + 30.0, 0.0),
    Bevy::Text2d.new('Window Configuration:', font_size: 16.0, color: Bevy::Color.white)
  )
  entity_cache[:header] = header_entity

  config_items.each_with_index do |item, i|
    y = config_y - i * 25.0
    label_entity = ctx.spawn(
      Bevy::Transform.from_xyz(-280.0, y, 0.0),
      Bevy::Text2d.new("#{item[:label]}:", font_size: 12.0, color: Bevy::Color.from_hex('#888888'))
    )
    entity_cache["label_#{i}"] = label_entity

    value_entity = ctx.spawn(
      Bevy::Transform.from_xyz(-150.0, y, 0.0),
      Bevy::Text2d.new(item[:value], font_size: 12.0, color: Bevy::Color.from_hex('#2ECC71'))
    )
    entity_cache["value_#{i}"] = value_entity
  end

  monitor_header = ctx.spawn(
    Bevy::Transform.from_xyz(150.0, config_y + 30.0, 0.0),
    Bevy::Text2d.new('Available Monitors:', font_size: 16.0, color: Bevy::Color.white)
  )
  entity_cache[:monitor_header] = monitor_header

  simulated_monitors.each_with_index do |monitor, i|
    y = config_y - i * 60.0

    name_entity = ctx.spawn(
      Bevy::Transform.from_xyz(150.0, y, 0.0),
      Bevy::Text2d.new(monitor[:name], font_size: 12.0, color: Bevy::Color.from_hex('#3498DB'))
    )
    entity_cache["monitor_name_#{i}"] = name_entity

    details = "#{monitor[:width]}x#{monitor[:height]} @ #{monitor[:refresh]}Hz (#{monitor[:scale]}x)"
    details_entity = ctx.spawn(
      Bevy::Transform.from_xyz(150.0, y - 18.0, 0.0),
      Bevy::Text2d.new(details, font_size: 10.0, color: Bevy::Color.from_hex('#666666'))
    )
    entity_cache["monitor_details_#{i}"] = details_entity
  end

  preview_x = 0.0
  preview_y = -100.0
  preview_scale = 0.15

  preview_width = window_config[:width] * preview_scale
  preview_height = window_config[:height] * preview_scale

  if window_config[:decorations]
    titlebar = ctx.spawn(
      Bevy::Transform.from_xyz(preview_x, preview_y + preview_height / 2.0 + 10.0, 1.0),
      Bevy::Mesh::Rectangle.new(width: preview_width, height: 20.0, color: Bevy::Color.from_hex('#333344'))
    )
    entity_cache[:titlebar] = titlebar

    close_btn = ctx.spawn(
      Bevy::Transform.from_xyz(preview_x + preview_width / 2.0 - 15.0, preview_y + preview_height / 2.0 + 10.0, 2.0),
      Bevy::Mesh::Circle.new(radius: 5.0, color: Bevy::Color.from_hex('#E74C3C'))
    )
    entity_cache[:close_btn] = close_btn
  end

  mode_color = case window_config[:mode]
               when :windowed then '#2a4a6a'
               when :borderless then '#4a2a6a'
               when :fullscreen then '#2a6a4a'
               end

  preview_entity = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: preview_width, height: preview_height, color: Bevy::Color.from_hex(mode_color))
  )
  entity_cache[:preview] = preview_entity

  preview_label = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y, 1.0),
    Bevy::Text2d.new('Window Preview', font_size: 10.0, color: Bevy::Color.white)
  )
  entity_cache[:preview_label] = preview_label

  if window_events.any?
    events_header = ctx.spawn(
      Bevy::Transform.from_xyz(-280.0, -180.0, 0.0),
      Bevy::Text2d.new('Recent Events:', font_size: 12.0, color: Bevy::Color.white)
    )
    entity_cache[:events_header] = events_header

    window_events.last(4).each_with_index do |event, i|
      y = -200.0 - i * 18.0
      age = time_elapsed - event[:time]
      alpha = [[1.0 - age / 5.0, 1.0].min, 0.0].max
      event_text = "#{event[:type]}: #{event[:value]}"
      event_entity = ctx.spawn(
        Bevy::Transform.from_xyz(-280.0, y, 0.0),
        Bevy::Text2d.new(event_text, font_size: 10.0, color: Bevy::Color.rgba(0.7, 0.9, 0.7, alpha))
      )
      entity_cache["event_#{i}"] = event_entity
    end
  end

  if status_entity
    cursor_status = window_config[:cursor_visible] ? 'Visible' : 'Hidden'
    vsync_status = window_config[:vsync] ? 'ON' : 'OFF'
    status_text = "Mode: #{window_config[:mode].to_s.capitalize} | Cursor: #{cursor_status} | VSync: #{vsync_status}"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Window System Demo'
puts ''
puts 'Window Configuration Options:'
puts '  [M] Cycle window mode (Windowed/Borderless/Fullscreen)'
puts '  [C] Cycle cursor grab mode (None/Confined/Locked)'
puts '  [V] Toggle VSync'
puts '  [D] Toggle window decorations'
puts '  [H] Toggle cursor visibility'
puts ''
puts 'Press ESC to exit'

app.run
