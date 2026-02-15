# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Diagnostics System Demo',
    width: 900.0,
    height: 700.0
  }
)

fps_diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS', max_history: 60, suffix: ' fps')
frame_time_diagnostic = Bevy::Diagnostic.new(id: 'frame_time', name: 'Frame Time', max_history: 60, suffix: ' ms')
entity_diagnostic = Bevy::Diagnostic.new(id: 'entities', name: 'Entities', max_history: 60)
memory_diagnostic = Bevy::Diagnostic.new(id: 'memory', name: 'Memory', max_history: 60, suffix: ' MB')

store = Bevy::DiagnosticsStore.new
store.add(fps_diagnostic)
store.add(frame_time_diagnostic)
store.add(entity_diagnostic)
store.add(memory_diagnostic)

spawned_entities = []
last_frame_time = Time.now
frame_count = 0
entity_cache = {}
show_graphs = { fps: true, frame_time: true, entities: true, memory: true }

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Diagnostics System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[SPACE] Spawn Entities  [C] Clear Entities  [1-4] Toggle Graph', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-350.0, 220.0, 0.0),
    Bevy::Text2d.new('Real-time Diagnostics:', font_size: 16.0, color: Bevy::Color.white)
  )
end

app.add_update_system do |ctx|
  current_time = Time.now
  frame_time = (current_time - last_frame_time) * 1000.0
  last_frame_time = current_time
  frame_count += 1

  fps = frame_time > 0 ? 1000.0 / frame_time : 60.0

  fps_diagnostic.add_measurement(fps)
  frame_time_diagnostic.add_measurement(frame_time)
  entity_diagnostic.add_measurement(spawned_entities.size.to_f)
  memory_diagnostic.add_measurement(50.0 + spawned_entities.size * 0.1 + rand(0.0..5.0))

  if ctx.key_just_pressed?('SPACE')
    10.times do
      x = rand(-350.0..350.0)
      y = rand(-150.0..100.0)
      color = Bevy::Color.from_hex(['#E74C3C', '#3498DB', '#2ECC71', '#F39C12', '#9B59B6'].sample)
      entity = ctx.spawn(
        Bevy::Transform.from_xyz(x, y, 1.0),
        Bevy::Mesh::Circle.new(radius: rand(5.0..15.0), color: color)
      )
      spawned_entities << entity
    end
  end

  if ctx.key_just_pressed?('C')
    spawned_entities.each { |e| ctx.world.despawn(e) }
    spawned_entities.clear
  end

  show_graphs[:fps] = !show_graphs[:fps] if ctx.key_just_pressed?('1')
  show_graphs[:frame_time] = !show_graphs[:frame_time] if ctx.key_just_pressed?('2')
  show_graphs[:entities] = !show_graphs[:entities] if ctx.key_just_pressed?('3')
  show_graphs[:memory] = !show_graphs[:memory] if ctx.key_just_pressed?('4')

  entity_cache.each { |_, e| ctx.world.despawn(e) if e }
  entity_cache.clear

  diag_configs = [
    { diag: fps_diagnostic, key: :fps, color: '#2ECC71', y: 180.0, max: 120.0 },
    { diag: frame_time_diagnostic, key: :frame_time, color: '#E74C3C', y: 100.0, max: 50.0 },
    { diag: entity_diagnostic, key: :entities, color: '#3498DB', y: 20.0, max: 200.0 },
    { diag: memory_diagnostic, key: :memory, color: '#F39C12', y: -60.0, max: 200.0 }
  ]

  diag_configs.each do |config|
    y = config[:y]
    diag = config[:diag]
    current_value = diag.value || 0.0
    avg = diag.average || 0.0

    value_text = "#{diag.name}: #{current_value.round(1)}#{diag.suffix} (avg: #{avg.round(1)})"
    text_entity = ctx.spawn(
      Bevy::Transform.from_xyz(-350.0, y + 20.0, 0.0),
      Bevy::Text2d.new(value_text, font_size: 12.0, color: Bevy::Color.from_hex(config[:color]))
    )
    entity_cache["text_#{config[:key]}"] = text_entity

    if show_graphs[config[:key]]
      graph_height = 50.0
      graph_bottom = y - graph_height / 2.0

      bg_entity = ctx.spawn(
        Bevy::Transform.from_xyz(50.0, y, -0.5),
        Bevy::Mesh::Rectangle.new(width: 400.0, height: graph_height, color: Bevy::Color.from_hex('#252535'))
      )
      entity_cache["bg_#{config[:key]}"] = bg_entity

      history_values = diag.history.last(60).map { |h| h[:value] }
      history_values.each_with_index do |val, i|
        normalized = [[val / config[:max], 1.0].min, 0.0].max
        bar_height = [normalized * (graph_height - 4.0), 1.0].max
        bar_x = -150.0 + i * 6.0
        bar_y = graph_bottom + bar_height / 2.0
        bar_entity = ctx.spawn(
          Bevy::Transform.from_xyz(bar_x, bar_y, 0.5),
          Bevy::Mesh::Rectangle.new(width: 4.0, height: bar_height, color: Bevy::Color.from_hex(config[:color]))
        )
        entity_cache["bar_#{config[:key]}_#{i}"] = bar_entity
      end
    else
      off_text = ctx.spawn(
        Bevy::Transform.from_xyz(50.0, y, 0.0),
        Bevy::Text2d.new('[Graph Hidden]', font_size: 12.0, color: Bevy::Color.from_hex('#555555'))
      )
      entity_cache["off_#{config[:key]}"] = off_text
    end
  end

  summary_text = "Frame: #{frame_count} | Spawned: #{spawned_entities.size}"
  summary_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -280.0, 0.0),
    Bevy::Text2d.new(summary_text, font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )
  entity_cache[:summary] = summary_entity

  exit_text = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -310.0, 0.0),
    Bevy::Text2d.new('Press ESC to exit', font_size: 12.0, color: Bevy::Color.from_hex('#666666'))
  )
  entity_cache[:exit] = exit_text

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Diagnostics System Demo'
puts ''
puts 'Real-time metrics displayed:'
puts '  - FPS (frames per second)'
puts '  - Frame Time (milliseconds)'
puts '  - Entity Count'
puts '  - Memory Usage (simulated)'
puts ''
puts 'Controls:'
puts '  [SPACE] Spawn 10 entities'
puts '  [C] Clear all spawned entities'
puts '  [1-4] Toggle graph visibility'
puts '  [ESC] Exit'

app.run
