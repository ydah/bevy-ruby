# frozen_string_literal: true

# Basic Example: Sprites and Colors
# This example demonstrates Sprite, Color, and rendering components visually.
# Shows a grid of colorful sprites with different properties.

require 'bevy'

# Create an app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Sprites and Colors',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  # === Color Examples - Top Row ===

  # Predefined colors
  colors = [
    { color: Bevy::Color.red, label: 'Red' },
    { color: Bevy::Color.green, label: 'Green' },
    { color: Bevy::Color.blue, label: 'Blue' },
    { color: Bevy::Color.white, label: 'White' },
    { color: Bevy::Color.black, label: 'Black' }
  ]

  colors.each_with_index do |c, i|
    x = -300.0 + i * 150.0
    ctx.spawn(
      Bevy::Transform.from_xyz(x, 200.0, 0.0),
      Bevy::Sprite.new(
        color: c[:color],
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end

  # === Custom Colors - Second Row ===
  custom_colors = [
    Bevy::Color.rgba(0.5, 0.3, 0.8, 1.0), # Purple
    Bevy::Color.from_hex('#FF6B35'),         # Orange
    Bevy::Color.from_hex('#4ECDC4'),         # Teal
    Bevy::Color.from_hex('#F7DC6F'),         # Yellow
    Bevy::Color.from_hex('#BB8FCE')          # Lavender
  ]

  custom_colors.each_with_index do |color, i|
    x = -300.0 + i * 150.0
    ctx.spawn(
      Bevy::Transform.from_xyz(x, 80.0, 0.0),
      Bevy::Sprite.new(
        color: color,
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end

  # === Transparency - Third Row ===
  base_color = Bevy::Color.from_hex('#E74C3C')
  5.times do |i|
    alpha = 0.2 + i * 0.2 # 0.2, 0.4, 0.6, 0.8, 1.0
    x = -300.0 + i * 150.0
    ctx.spawn(
      Bevy::Transform.from_xyz(x, -40.0, 0.0),
      Bevy::Sprite.new(
        color: base_color.with_alpha(alpha),
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end

  # === Different Sizes - Fourth Row ===
  sizes = [20.0, 35.0, 50.0, 65.0, 80.0]
  sizes.each_with_index do |size, i|
    x = -300.0 + i * 150.0
    ctx.spawn(
      Bevy::Transform.from_xyz(x, -160.0, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#2ECC71'),
        custom_size: Bevy::Vec2.new(size, size)
      )
    )
  end

  # === Flipped Sprites - Bottom Row ===
  # Original
  ctx.spawn(
    Bevy::Transform.from_xyz(-200.0, -260.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#3498DB'),
      custom_size: Bevy::Vec2.new(80.0, 40.0) # Rectangle to show flip
    )
  )

  # Flipped X
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -260.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#9B59B6'),
      custom_size: Bevy::Vec2.new(80.0, 40.0),
      flip_x: true
    )
  )

  # Flipped Y
  ctx.spawn(
    Bevy::Transform.from_xyz(200.0, -260.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#1ABC9C'),
      custom_size: Bevy::Vec2.new(80.0, 40.0),
      flip_y: true
    )
  )
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Sprites and Colors Demo - Press ESC to exit'
puts 'Row 1: Predefined colors (red, green, blue, white, black)'
puts 'Row 2: Custom colors from hex'
puts 'Row 3: Transparency levels (20% to 100%)'
puts 'Row 4: Different sizes'
puts 'Row 5: Original and flipped sprites'
app.run
