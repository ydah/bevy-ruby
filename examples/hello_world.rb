# frozen_string_literal: true

# Basic Example: Hello World
# This example demonstrates the minimal setup for a Bevy application with rendering.
# A simple sprite is displayed in the window.

require 'bevy'

# Create an app with rendering enabled
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Hello Bevy Ruby!',
    width: 800.0,
    height: 600.0
  }
)

# Add a startup system that spawns a sprite
app.add_startup_system do |ctx|
  # Spawn a simple blue square in the center
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(100.0, 100.0)
    )
  )
end

# Add a frame counter (shown in console)
frame = 0
app.add_update_system do |ctx|
  frame += 1

  # Print frame info every 60 frames
  puts "Frame #{frame}, delta: #{ctx.delta.round(4)}s" if frame % 60 == 0

  # Press ESC to exit
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

# Run the app - window will open and display the sprite
puts 'Starting Bevy Ruby - Press ESC to exit'
app.run
puts 'Goodbye!'
