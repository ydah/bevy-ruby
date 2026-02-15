# frozen_string_literal: true

# Advanced Example: Plugins
# This example demonstrates modular plugin architecture visually.
# Physics, health, and scoring systems work together.

require 'bevy'

# === Physics Plugin ===

class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
end

class PhysicsPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      ctx.world.each(Velocity, Bevy::Transform) do |entity, vel, transform|
        new_x = transform.translation.x + vel.x * ctx.delta
        new_y = transform.translation.y + vel.y * ctx.delta

        # Bounce off walls
        if new_x.abs > 350.0
          vel.x = -vel.x
          new_x = new_x.clamp(-350.0, 350.0)
        end
        if new_y.abs > 250.0
          vel.y = -vel.y
          new_y = new_y.clamp(-250.0, 250.0)
        end

        new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
        ctx.world.insert_component(entity, vel)
      end
    end
  end
end

# === Health Plugin ===

class Health < Bevy::ComponentDSL
  attribute :current, Integer, default: 100
  attribute :max, Integer, default: 100
end

class DamageEvent < Bevy::EventDSL
  attribute :target_id, Integer
  attribute :amount, Integer
end

class DeathEvent < Bevy::EventDSL
  attribute :entity_id, Integer
  attribute :x, Float
  attribute :y, Float
end

class HealthPlugin < Bevy::Plugin
  def build(app)
    app.add_event(DamageEvent)
    app.add_event(DeathEvent)

    app.add_update_system do |ctx|
      reader = ctx.events.reader(DamageEvent)
      death_writer = ctx.events.writer(DeathEvent)

      reader.read.each do |event|
        ctx.world.each(Health, Bevy::Transform) do |entity, health, transform|
          next unless entity.id == event.target_id

          health.current = [health.current - event.amount, 0].max
          ctx.world.insert_component(entity, health)

          next unless health.current <= 0

          death_writer.send(DeathEvent.new(
                              entity_id: entity.id,
                              x: transform.translation.x,
                              y: transform.translation.y
                            ))
        end
      end
    end
  end
end

# === Scoring Plugin ===

class GameScore < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
  attribute :kills, Integer, default: 0
end

class ScoringPlugin < Bevy::Plugin
  def build(app)
    app.insert_resource(GameScore.new)

    app.add_update_system do |ctx|
      score = ctx.resource(GameScore)
      reader = ctx.events.reader(DeathEvent)

      reader.read.each do |event|
        score.score += 100
        score.kills += 1

        # Despawn dead entity
        ctx.world.each(Health) do |entity, _health|
          if entity.id == event.entity_id
            ctx.world.despawn(entity)
            break
          end
        end
      end
    end
  end
end

# === Components ===

class Player < Bevy::ComponentDSL
end

class Enemy < Bevy::ComponentDSL
end

# === Game Plugins Bundle ===

class GamePlugins < Bevy::Plugin
  def build(app)
    PhysicsPlugin.new.build(app)
    HealthPlugin.new.build(app)
    ScoringPlugin.new.build(app)
  end
end

# Create app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Plugin System Demo',
    width: 800.0,
    height: 600.0
  }
)

# Load all plugins
app.add_plugins(GamePlugins.new)

app.add_startup_system do |ctx|
  # Spawn player
  ctx.spawn(
    Player.new,
    Health.new(current: 100, max: 100),
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  # Spawn enemies with random velocities
  8.times do
    x = rand(-300.0..300.0)
    y = rand(-200.0..200.0)
    vx = rand(-100.0..100.0)
    vy = rand(-100.0..100.0)

    ctx.spawn(
      Enemy.new,
      Health.new(current: 30, max: 30),
      Velocity.new(x: vx, y: vy),
      Bevy::Transform.from_xyz(x, y, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#E74C3C'),
        custom_size: Bevy::Vec2.new(35.0, 35.0)
      )
    )
  end
end

# Player movement
app.add_update_system do |ctx|
  ctx.world.each(Player, Bevy::Transform) do |entity, _player, transform|
    dx = 0.0
    dy = 0.0
    speed = 200.0

    dy += 1.0 if ctx.key_pressed?('W') || ctx.key_pressed?('UP')
    dy -= 1.0 if ctx.key_pressed?('S') || ctx.key_pressed?('DOWN')
    dx -= 1.0 if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')
    dx += 1.0 if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')

    new_x = (transform.translation.x + dx * speed * ctx.delta).clamp(-350.0, 350.0)
    new_y = (transform.translation.y + dy * speed * ctx.delta).clamp(-250.0, 250.0)

    new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end
end

# Attack with SPACE
app.add_update_system do |ctx|
  return unless ctx.key_just_pressed?('SPACE')

  # Find closest enemy to player
  player_pos = nil
  ctx.world.each(Player, Bevy::Transform) do |_entity, _player, transform|
    player_pos = transform.translation
    break
  end

  return unless player_pos

  closest = nil
  closest_dist = Float::INFINITY

  ctx.world.each(Enemy, Bevy::Transform) do |entity, _enemy, transform|
    dx = transform.translation.x - player_pos.x
    dy = transform.translation.y - player_pos.y
    dist = Math.sqrt(dx * dx + dy * dy)

    if dist < closest_dist && dist < 100.0 # Attack range
      closest_dist = dist
      closest = entity
    end
  end

  ctx.events.writer(DamageEvent).send(DamageEvent.new(target_id: closest.id, amount: 15)) if closest
end

# Respawn enemies
app.add_update_system do |ctx|
  enemy_count = 0
  ctx.world.each(Enemy) { |_e, _en| enemy_count += 1 }

  if enemy_count < 5
    x = rand(-300.0..300.0)
    y = rand(-200.0..200.0)
    vx = rand(-100.0..100.0)
    vy = rand(-100.0..100.0)

    ctx.spawn(
      Enemy.new,
      Health.new(current: 30, max: 30),
      Velocity.new(x: vx, y: vy),
      Bevy::Transform.from_xyz(x, y, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#E74C3C'),
        custom_size: Bevy::Vec2.new(35.0, 35.0)
      )
    )
  end
end

# Exit
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Plugin System Demo'
puts 'Controls:'
puts '  WASD/Arrows - Move player'
puts '  SPACE - Attack nearby enemy'
puts '  ESC - Exit'
app.run

score = app.resources.get(GameScore)
puts "\nFinal Score: #{score.score} (#{score.kills} kills)"
