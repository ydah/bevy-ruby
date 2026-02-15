# frozen_string_literal: true

# Advanced Example: Event System
# This example demonstrates event-driven architecture visually.
# Explosions and score popups appear when events are triggered.

require 'bevy'

# === Events ===

class ExplosionEvent < Bevy::EventDSL
  attribute :x, Float
  attribute :y, Float
  attribute :size, Float, default: 50.0
end

class ScoreEvent < Bevy::EventDSL
  attribute :points, Integer
  attribute :x, Float
  attribute :y, Float
end

class SpawnEnemyEvent < Bevy::EventDSL
  attribute :x, Float
  attribute :y, Float
end

# === Components ===

class Enemy < Bevy::ComponentDSL
  attribute :health, Integer, default: 30
end

class Explosion < Bevy::ComponentDSL
  attribute :lifetime, Float, default: 0.5
  attribute :max_size, Float, default: 50.0
end

class ScorePopup < Bevy::ComponentDSL
  attribute :lifetime, Float, default: 1.0
  attribute :velocity_y, Float, default: 50.0
end

class GameScore < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
end

# Create app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Event System Demo',
    width: 800.0,
    height: 600.0
  }
)

app.add_event(ExplosionEvent)
app.add_event(ScoreEvent)
app.add_event(SpawnEnemyEvent)
app.insert_resource(GameScore.new)

app.add_startup_system do |ctx|
  # Spawn initial enemies
  5.times do
    x = rand(-300.0..300.0)
    y = rand(-200.0..200.0)
    ctx.events.writer(SpawnEnemyEvent).send(SpawnEnemyEvent.new(x: x, y: y))
  end
end

# Spawn enemy handler
app.add_update_system do |ctx|
  reader = ctx.events.reader(SpawnEnemyEvent)
  reader.read.each do |event|
    ctx.spawn(
      Enemy.new(health: 30),
      Bevy::Transform.from_xyz(event.x, event.y, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#E74C3C'),
        custom_size: Bevy::Vec2.new(40.0, 40.0)
      )
    )
  end
end

# Attack enemies with SPACE key
app.add_update_system do |ctx|
  return unless ctx.key_just_pressed?('SPACE')

  # Find and damage a random enemy
  enemies = []
  ctx.world.each(Enemy, Bevy::Transform) do |entity, enemy, transform|
    enemies << { entity: entity, enemy: enemy, transform: transform }
  end

  return if enemies.empty?

  target = enemies.sample
  target[:enemy].health -= 15
  ctx.world.insert_component(target[:entity], target[:enemy])

  x = target[:transform].translation.x
  y = target[:transform].translation.y

  if target[:enemy].health <= 0
    # Enemy killed - trigger explosion and score
    ctx.events.writer(ExplosionEvent).send(ExplosionEvent.new(x: x, y: y, size: 60.0))
    ctx.events.writer(ScoreEvent).send(ScoreEvent.new(points: 100, x: x, y: y))
    ctx.world.despawn(target[:entity])

    # Spawn new enemy elsewhere
    new_x = rand(-300.0..300.0)
    new_y = rand(-200.0..200.0)
    ctx.events.writer(SpawnEnemyEvent).send(SpawnEnemyEvent.new(x: new_x, y: new_y))
  else
    # Hit effect - small explosion
    ctx.events.writer(ExplosionEvent).send(ExplosionEvent.new(x: x, y: y, size: 20.0))
  end
end

# Explosion spawner
app.add_update_system do |ctx|
  reader = ctx.events.reader(ExplosionEvent)
  reader.read.each do |event|
    ctx.spawn(
      Explosion.new(lifetime: 0.3, max_size: event.size),
      Bevy::Transform.from_xyz(event.x, event.y, 1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#F1C40F'),
        custom_size: Bevy::Vec2.new(5.0, 5.0)
      )
    )
  end
end

# Score popup spawner
app.add_update_system do |ctx|
  reader = ctx.events.reader(ScoreEvent)
  score = ctx.resource(GameScore)

  reader.read.each do |event|
    score.score += event.points

    ctx.spawn(
      ScorePopup.new(lifetime: 1.0, velocity_y: 80.0),
      Bevy::Transform.from_xyz(event.x, event.y + 30.0, 2.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#2ECC71'),
        custom_size: Bevy::Vec2.new(20.0, 20.0)
      )
    )
  end
end

# Explosion animation
app.add_update_system do |ctx|
  to_remove = []

  ctx.world.each(Explosion, Bevy::Transform, Bevy::Sprite) do |entity, explosion, _transform, sprite|
    explosion.lifetime -= ctx.delta

    if explosion.lifetime <= 0
      to_remove << entity
    else
      # Grow and fade
      progress = 1.0 - (explosion.lifetime / 0.3)
      size = explosion.max_size * progress
      alpha = 1.0 - progress

      new_sprite = sprite
                   .with_custom_size(Bevy::Vec2.new(size, size))
                   .with_color(Bevy::Color.rgba(1.0, 0.8, 0.2, alpha))
      ctx.world.insert_component(entity, new_sprite)
      ctx.world.insert_component(entity, explosion)
    end
  end

  to_remove.each { |e| ctx.world.despawn(e) }
end

# Score popup animation
app.add_update_system do |ctx|
  to_remove = []

  ctx.world.each(ScorePopup, Bevy::Transform, Bevy::Sprite) do |entity, popup, transform, sprite|
    popup.lifetime -= ctx.delta

    if popup.lifetime <= 0
      to_remove << entity
    else
      # Float up and fade
      new_y = transform.translation.y + popup.velocity_y * ctx.delta
      new_pos = Bevy::Vec3.new(transform.translation.x, new_y, transform.translation.z)
      ctx.world.insert_component(entity, transform.with_translation(new_pos))

      alpha = popup.lifetime
      new_sprite = sprite.with_color(Bevy::Color.rgba(0.2, 0.9, 0.3, alpha))
      ctx.world.insert_component(entity, new_sprite)
      ctx.world.insert_component(entity, popup)
    end
  end

  to_remove.each { |e| ctx.world.despawn(e) }
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Event System Demo'
puts 'Controls:'
puts '  SPACE - Attack random enemy'
puts '  ESC - Exit'
puts 'Watch for explosions and score popups!'
app.run

puts "\nFinal Score: #{app.resources.get(GameScore).score}"
