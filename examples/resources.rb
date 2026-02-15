# frozen_string_literal: true

# Advanced Example: Resources
# This example demonstrates global resources for game state management.
# Score and level display updates in real-time.

require 'bevy'

# === Custom Resources ===

class GameState < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
  attribute :level, Integer, default: 1
  attribute :combo, Integer, default: 0
  attribute :paused, :boolean, default: false

  def add_score(points)
    self.score += points * (1 + combo * 0.1).to_i
    self.combo += 1
  end

  def reset_combo
    self.combo = 0
  end
end

class WaveConfig < Bevy::ResourceDSL
  attribute :enemies_per_wave, Integer, default: 3
  attribute :spawn_rate, Float, default: 2.0
  attribute :timer, Float, default: 0.0

  def should_spawn?(delta)
    self.timer += delta
    if timer >= spawn_rate
      self.timer = 0.0
      true
    else
      false
    end
  end
end

# Components
class ScoreDisplay < Bevy::ComponentDSL
end

class ComboDisplay < Bevy::ComponentDSL
end

class Target < Bevy::ComponentDSL
  attribute :points, Integer, default: 10
end

# Create app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Resources Demo - Click targets for points!',
    width: 800.0,
    height: 600.0
  }
)

# Insert resources
app.insert_resource(GameState.new)
app.insert_resource(WaveConfig.new(enemies_per_wave: 5, spawn_rate: 1.5))

app.add_startup_system do |ctx|
  # Score indicator (size represents score)
  ctx.spawn(
    ScoreDisplay.new,
    Bevy::Transform.from_xyz(-300.0, 250.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#F1C40F'),
      custom_size: Bevy::Vec2.new(20.0, 20.0)
    )
  )

  # Combo indicator
  ctx.spawn(
    ComboDisplay.new,
    Bevy::Transform.from_xyz(-200.0, 250.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(10.0, 10.0)
    )
  )

  # Spawn initial targets
  5.times do
    spawn_target(ctx)
  end
end

def spawn_target(ctx)
  x = rand(-300.0..300.0)
  y = rand(-200.0..150.0)
  size = rand(20.0..50.0)
  points = (60 - size).to_i # Smaller = more points

  ctx.spawn(
    Target.new(points: points),
    Bevy::Transform.from_xyz(x, y, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#3498DB'),
      custom_size: Bevy::Vec2.new(size, size)
    )
  )
end

# Spawn new targets periodically
app.add_update_system do |ctx|
  wave = ctx.resource(WaveConfig)
  state = ctx.resource(GameState)

  return if state.paused

  spawn_target(ctx) if wave.should_spawn?(ctx.delta)
end

# Click targets for points (simulate with SPACE key)
app.add_update_system do |ctx|
  state = ctx.resource(GameState)

  if ctx.key_just_pressed?('SPACE')
    # Find and destroy the first target
    target_found = nil
    ctx.world.each(Target) do |entity, target|
      target_found = { entity: entity, target: target }
      break
    end

    if target_found
      state.add_score(target_found[:target].points)
      ctx.world.despawn(target_found[:entity])
      spawn_target(ctx)
    end
  end

  # Reset combo if no hits for a while (R key for demo)
  if ctx.key_just_pressed?('R')
    state.reset_combo
    puts 'Combo reset!'
  end
end

# Update score display
app.add_update_system do |ctx|
  state = ctx.resource(GameState)

  ctx.world.each(ScoreDisplay, Bevy::Transform, Bevy::Sprite) do |entity, _disp, _transform, sprite|
    # Size grows with score
    size = 20.0 + (state.score / 10.0)
    size = [size, 100.0].min

    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(size, size))
    ctx.world.insert_component(entity, new_sprite)
  end

  ctx.world.each(ComboDisplay, Bevy::Sprite) do |entity, _disp, sprite|
    # Combo changes color intensity
    intensity = [0.3 + state.combo * 0.1, 1.0].min
    color = Bevy::Color.rgba(intensity, 0.2, 0.2, 1.0)

    size = 10.0 + state.combo * 5.0
    size = [size, 50.0].min

    new_sprite = sprite.with_color(color).with_custom_size(Bevy::Vec2.new(size, size))
    ctx.world.insert_component(entity, new_sprite)
  end
end

# Toggle pause
app.add_update_system do |ctx|
  state = ctx.resource(GameState)

  if ctx.key_just_pressed?('P')
    state.paused = !state.paused
    puts state.paused ? 'Paused' : 'Resumed'
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Resources Demo'
puts 'Controls:'
puts '  SPACE - Destroy a target (score points)'
puts '  R - Reset combo'
puts '  P - Pause'
puts '  ESC - Exit'
app.run

state = app.resources.get(GameState)
puts "\nFinal Score: #{state.score}"
