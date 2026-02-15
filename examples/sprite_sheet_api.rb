# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Sprite Sheet System Demo',
    width: 900.0,
    height: 700.0
  }
)

class AnimatedCharacter
  attr_accessor :position, :current_frame, :frames, :frame_timer, :frame_duration, :color, :playing, :direction

  def initialize(position:, frames:, frame_duration:, color:)
    @position = position
    @frames = frames
    @current_frame = 0
    @frame_timer = 0.0
    @frame_duration = frame_duration
    @color = color
    @playing = true
    @direction = 1
  end

  def update(delta)
    return unless @playing

    @frame_timer += delta
    if @frame_timer >= @frame_duration
      @frame_timer = 0.0
      @current_frame = (@current_frame + 1) % @frames.size
    end
  end

  def current_frame_data
    @frames[@current_frame]
  end
end

idle_frames = 4.times.map { |i| { width: 30.0 + Math.sin(i * 0.5) * 3.0, height: 40.0 } }
walk_frames = 8.times.map { |i| { width: 32.0, height: 40.0, offset_y: Math.sin(i * Math::PI / 4.0) * 5.0 } }
attack_frames = 5.times.map { |i| { width: 35.0 + i * 3.0, height: 40.0, offset_x: i * 5.0 } }

animations = {
  idle: { frames: idle_frames, duration: 0.2, color: '#3498DB' },
  walk: { frames: walk_frames, duration: 0.1, color: '#2ECC71' },
  attack: { frames: attack_frames, duration: 0.08, color: '#E74C3C' }
}

characters = [
  AnimatedCharacter.new(position: Bevy::Vec3.new(-200.0, 50.0, 0.0), frames: idle_frames, frame_duration: 0.2, color: Bevy::Color.from_hex('#3498DB')),
  AnimatedCharacter.new(position: Bevy::Vec3.new(0.0, 50.0, 0.0), frames: walk_frames, frame_duration: 0.1, color: Bevy::Color.from_hex('#2ECC71')),
  AnimatedCharacter.new(position: Bevy::Vec3.new(200.0, 50.0, 0.0), frames: attack_frames, frame_duration: 0.08, color: Bevy::Color.from_hex('#E74C3C'))
]

animation_labels = ['Idle', 'Walk', 'Attack']

atlas_grid = {
  columns: 8,
  rows: 4,
  tile_size: 32.0,
  padding: 2.0
}

selected_tile = 0
entity_cache = {}
status_entity = nil
time_elapsed = 0.0

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Sprite Sheet System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[SPACE] Pause/Resume  [1-3] Select Animation  [Arrow Keys] Select Tile', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 140.0, 0.0),
    Bevy::Text2d.new('Animated Sprites', font_size: 16.0, color: Bevy::Color.white)
  )

  characters.each_with_index do |char, i|
    ctx.spawn(
      Bevy::Transform.from_xyz(char.position.x, char.position.y + 50.0, 0.0),
      Bevy::Text2d.new(animation_labels[i], font_size: 12.0, color: char.color)
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(-300.0, -80.0, 0.0),
    Bevy::Text2d.new('Texture Atlas Grid (8x4)', font_size: 14.0, color: Bevy::Color.white)
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Frame: 0 | Selected Tile: 0', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  if ctx.key_just_pressed?('SPACE')
    characters.each { |c| c.playing = !c.playing }
  end

  if ctx.key_just_pressed?('LEFT')
    selected_tile = (selected_tile - 1) % (atlas_grid[:columns] * atlas_grid[:rows])
  elsif ctx.key_just_pressed?('RIGHT')
    selected_tile = (selected_tile + 1) % (atlas_grid[:columns] * atlas_grid[:rows])
  elsif ctx.key_just_pressed?('UP')
    selected_tile = (selected_tile - atlas_grid[:columns]) % (atlas_grid[:columns] * atlas_grid[:rows])
  elsif ctx.key_just_pressed?('DOWN')
    selected_tile = (selected_tile + atlas_grid[:columns]) % (atlas_grid[:columns] * atlas_grid[:rows])
  end

  characters.each { |char| char.update(delta) }

  entity_cache.each { |_, e| ctx.world.despawn(e) if e }
  entity_cache.clear

  characters.each_with_index do |char, i|
    frame_data = char.current_frame_data
    offset_x = frame_data[:offset_x] || 0.0
    offset_y = frame_data[:offset_y] || 0.0

    char_entity = ctx.spawn(
      Bevy::Transform.from_xyz(char.position.x + offset_x, char.position.y + offset_y, 1.0),
      Bevy::Mesh::Rectangle.new(width: frame_data[:width], height: frame_data[:height], color: char.color)
    )
    entity_cache["char_#{i}"] = char_entity

    frame_indicator = ctx.spawn(
      Bevy::Transform.from_xyz(char.position.x, char.position.y - 40.0, 2.0),
      Bevy::Text2d.new("Frame #{char.current_frame + 1}/#{char.frames.size}", font_size: 10.0, color: Bevy::Color.from_hex('#AAAAAA'))
    )
    entity_cache["frame_#{i}"] = frame_indicator
  end

  grid_start_x = -280.0
  grid_start_y = -120.0
  tile_display_size = 25.0
  gap = 3.0

  atlas_grid[:rows].times do |row|
    atlas_grid[:columns].times do |col|
      tile_index = row * atlas_grid[:columns] + col
      x = grid_start_x + col * (tile_display_size + gap)
      y = grid_start_y - row * (tile_display_size + gap)

      is_selected = tile_index == selected_tile
      hue = tile_index.to_f / (atlas_grid[:columns] * atlas_grid[:rows])
      tile_color = Bevy::Color.from_hsv(hue * 360, 0.6, 0.8)

      if is_selected
        highlight = ctx.spawn(
          Bevy::Transform.from_xyz(x, y, 0.5),
          Bevy::Mesh::Rectangle.new(width: tile_display_size + 6.0, height: tile_display_size + 6.0, color: Bevy::Color.from_hex('#FFD700'))
        )
        entity_cache["highlight_#{tile_index}"] = highlight
      end

      tile_entity = ctx.spawn(
        Bevy::Transform.from_xyz(x, y, 1.0),
        Bevy::Mesh::Rectangle.new(width: tile_display_size, height: tile_display_size, color: tile_color)
      )
      entity_cache["tile_#{tile_index}"] = tile_entity
    end
  end

  preview_x = 250.0
  preview_y = -160.0
  hue = selected_tile.to_f / (atlas_grid[:columns] * atlas_grid[:rows])
  preview_color = Bevy::Color.from_hsv(hue * 360, 0.6, 0.8)

  preview_bg = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y, 0.0),
    Bevy::Mesh::Rectangle.new(width: 110.0, height: 110.0, color: Bevy::Color.from_hex('#333344'))
  )
  entity_cache[:preview_bg] = preview_bg

  preview_entity = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y, 1.0),
    Bevy::Mesh::Rectangle.new(width: 80.0, height: 80.0, color: preview_color)
  )
  entity_cache[:preview] = preview_entity

  preview_label = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y + 70.0, 2.0),
    Bevy::Text2d.new('Selected Tile', font_size: 12.0, color: Bevy::Color.white)
  )
  entity_cache[:preview_label] = preview_label

  col = selected_tile % atlas_grid[:columns]
  row = selected_tile / atlas_grid[:columns]
  preview_info = ctx.spawn(
    Bevy::Transform.from_xyz(preview_x, preview_y - 70.0, 2.0),
    Bevy::Text2d.new("Index: #{selected_tile} (#{col}, #{row})", font_size: 10.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )
  entity_cache[:preview_info] = preview_info

  if status_entity
    playing_status = characters.first.playing ? 'Playing' : 'Paused'
    status_text = "Status: #{playing_status} | Selected Tile: #{selected_tile}"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Sprite Sheet System Demo'
puts ''
puts 'Features:'
puts '  - Animated sprite playback (Idle, Walk, Attack)'
puts '  - Texture atlas grid visualization (8x4 = 32 tiles)'
puts '  - Tile selection and preview'
puts ''
puts 'Controls:'
puts '  [SPACE] Pause/Resume animations'
puts '  [Arrow Keys] Navigate tile selection'
puts '  [ESC] Exit'

app.run
