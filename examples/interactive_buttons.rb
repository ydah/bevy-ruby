# frozen_string_literal: true

require 'bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'UI Demo - Interactive Buttons',
    width: 800.0,
    height: 600.0
  }
)

button_colors = [
  Bevy::Color.from_hex('#3498DB'),
  Bevy::Color.from_hex('#E74C3C'),
  Bevy::Color.from_hex('#2ECC71'),
  Bevy::Color.from_hex('#F39C12'),
  Bevy::Color.from_hex('#9B59B6')
]

button_positions = [
  { x: -200.0, y: 50.0 },
  { x: 0.0, y: 50.0 },
  { x: 200.0, y: 50.0 },
  { x: -100.0, y: -70.0 },
  { x: 100.0, y: -70.0 }
]

click_count = 0
entity_cache = {}

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#1a1a2e'),
      custom_size: Bevy::Vec2.new(1000.0, 800.0)
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 250.0, 0.0),
    Bevy::Text2d.new('UI Demo: Click the buttons!', font_size: 32.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -180.0, 0.0),
    Bevy::Text2d.new('Style Examples:', font_size: 24.0, color: Bevy::Color.from_hex('#ECF0F1'))
  )

  rounded_positions = [-250.0, -125.0, 0.0, 125.0, 250.0]
  sizes = [30.0, 40.0, 50.0, 40.0, 30.0]
  rounded_positions.each_with_index do |x, i|
    gray_value = 0.3 + (i * 0.15)
    ctx.spawn(
      Bevy::Transform.from_xyz(x, -250.0, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.rgba(gray_value, gray_value, gray_value + 0.1, 1.0),
        custom_size: Bevy::Vec2.new(sizes[i], sizes[i])
      )
    )
  end
end

app.add_update_system do |ctx|
  mouse_pos = ctx.mouse_position

  hovered_button = nil
  button_positions.each_with_index do |pos, i|
    if (mouse_pos.x - pos[:x]).abs < 60.0 && (mouse_pos.y - pos[:y]).abs < 30.0
      hovered_button = i
    end
  end

  if ctx.mouse_just_pressed?(:left) && hovered_button
    click_count += 1
  end

  entity_cache.each { |_, e| ctx.world.despawn(e) }
  entity_cache.clear

  counter_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 180.0, 0.0),
    Bevy::Text2d.new("Total Clicks: #{click_count}", font_size: 24.0, color: Bevy::Color.from_hex('#BDC3C7'))
  )
  entity_cache[:counter] = counter_entity

  button_positions.each_with_index do |pos, i|
    base_color = button_colors[i]

    color = if i == hovered_button
              Bevy::Color.rgba(
                [base_color.r * 1.3, 1.0].min,
                [base_color.g * 1.3, 1.0].min,
                [base_color.b * 1.3, 1.0].min,
                1.0
              )
            else
              base_color
            end

    btn_entity = ctx.spawn(
      Bevy::Transform.from_xyz(pos[:x], pos[:y], 1.0),
      Bevy::Sprite.new(
        color: color,
        custom_size: Bevy::Vec2.new(120.0, 60.0)
      )
    )
    entity_cache["btn_#{i}"] = btn_entity

    label_entity = ctx.spawn(
      Bevy::Transform.from_xyz(pos[:x], pos[:y], 2.0),
      Bevy::Text2d.new("Button #{i + 1}", font_size: 14.0, color: Bevy::Color.white)
    )
    entity_cache["label_#{i}"] = label_entity
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'UI Demo'
puts ''
puts 'Features:'
puts '  - Button hover effects'
puts '  - Click counting'
puts '  - Various shape sizes'
puts ''
puts 'Controls:'
puts '  Mouse - Hover and click buttons'
puts '  ESC   - Exit'

app.run
