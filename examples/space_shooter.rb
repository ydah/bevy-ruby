# frozen_string_literal: true

# Practical Example: Space Shooter
# A top-down shooter demonstrating entity spawning, projectiles, and scoring.
# Control the ship with WASD/Arrows and shoot with SPACE.

require 'bevy'

class Player < Bevy::ComponentDSL
  attribute :fire_rate, Float, default: 0.15
  attribute :last_fire, Float, default: 0.0
  attribute :speed, Float, default: 300.0
end

class Enemy < Bevy::ComponentDSL
  attribute :points, Integer, default: 100
  attribute :speed, Float, default: 80.0
end

class Bullet < Bevy::ComponentDSL
  attribute :damage, Integer, default: 10
  attribute :speed, Float, default: 400.0
  attribute :owner, String, default: 'player'
end

class Health < Bevy::ComponentDSL
  attribute :current, Integer, default: 100
  attribute :max, Integer, default: 100
end

class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
end

class GameState < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
  attribute :wave, Integer, default: 1
  attribute :enemies_killed, Integer, default: 0
  attribute :player_alive, :boolean, default: true
end

class SpawnTimer < Bevy::ResourceDSL
  attribute :cooldown, Float, default: 1.5
  attribute :timer, Float, default: 0.0
end

class ShootEvent < Bevy::EventDSL
  attribute :x, Float
  attribute :y, Float
  attribute :owner, String
end

class DeathEvent < Bevy::EventDSL
  attribute :entity_id, Integer
  attribute :entity_type, String
  attribute :points, Integer, default: 0
end

class MovementPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      delta = ctx.delta

      ctx.world.each(Velocity, Bevy::Transform) do |entity, vel, transform|
        new_x = transform.translation.x + vel.x * delta
        new_y = transform.translation.y + vel.y * delta

        new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
      end
    end
  end
end

class PlayerPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      return unless state.player_alive

      ctx.world.each(Player, Velocity, Bevy::Transform) do |entity, player, vel, transform|
        vel.x = 0.0
        vel.y = 0.0

        vel.x -= player.speed if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')
        vel.x += player.speed if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')
        vel.y += player.speed if ctx.key_pressed?('W') || ctx.key_pressed?('UP')
        vel.y -= player.speed if ctx.key_pressed?('S') || ctx.key_pressed?('DOWN')

        new_x = transform.translation.x.clamp(-370.0, 370.0)
        new_y = transform.translation.y.clamp(-270.0, 270.0)
        if new_x != transform.translation.x || new_y != transform.translation.y
          new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
          ctx.world.insert_component(entity, transform.with_translation(new_pos))
        end

        ctx.world.insert_component(entity, vel)

        elapsed = ctx.elapsed
        next unless ctx.key_pressed?('SPACE') && elapsed - player.last_fire >= player.fire_rate

        player.last_fire = elapsed
        ctx.events.writer(ShootEvent).send(
          ShootEvent.new(
            x: transform.translation.x,
            y: transform.translation.y + 30,
            owner: 'player'
          )
        )
        ctx.world.insert_component(entity, player)
      end
    end
  end
end

class BulletPlugin < Bevy::Plugin
  def build(app)
    app.add_event(ShootEvent)

    app.add_update_system do |ctx|
      reader = ctx.events.reader(ShootEvent)

      reader.read.each do |event|
        speed = event.owner == 'player' ? 500.0 : -300.0
        color = event.owner == 'player' ? '#2ECC71' : '#E74C3C'

        ctx.spawn(
          Bullet.new(damage: 10, speed: speed.abs, owner: event.owner),
          Velocity.new(x: 0.0, y: speed),
          Bevy::Transform.from_xyz(event.x, event.y, 0.0),
          Bevy::Sprite.new(
            color: Bevy::Color.from_hex(color),
            custom_size: Bevy::Vec2.new(6.0, 15.0)
          )
        )
      end
    end

    app.add_update_system do |ctx|
      to_remove = []

      ctx.world.each(Bullet, Bevy::Transform) do |entity, _bullet, transform|
        y = transform.translation.y
        to_remove << entity if y > 320 || y < -320
      end

      to_remove.each { |e| ctx.world.despawn(e) }
    end
  end
end

class EnemyPlugin < Bevy::Plugin
  def build(app)
    app.insert_resource(SpawnTimer.new)

    app.add_update_system do |ctx|
      timer = ctx.resource(SpawnTimer)
      timer.timer += ctx.delta

      if timer.timer >= timer.cooldown
        timer.timer = 0.0
        x = rand(-300.0..300.0)

        ctx.spawn(
          Enemy.new(points: 100, speed: rand(60.0..120.0)),
          Health.new(current: 30, max: 30),
          Velocity.new(x: rand(-30.0..30.0), y: rand(-80.0..-40.0)),
          Bevy::Transform.from_xyz(x, 320.0, 0.0),
          Bevy::Sprite.new(
            color: Bevy::Color.from_hex('#E74C3C'),
            custom_size: Bevy::Vec2.new(40.0, 40.0)
          )
        )
      end
    end

    app.add_update_system do |ctx|
      ctx.world.each(Enemy, Bevy::Transform) do |entity, _enemy, transform|
        if transform.translation.y < -320
          ctx.world.despawn(entity)
          next
        end

        next unless rand < 0.005

        ctx.events.writer(ShootEvent).send(
          ShootEvent.new(
            x: transform.translation.x,
            y: transform.translation.y - 25,
            owner: 'enemy'
          )
        )
      end
    end
  end
end

class CombatPlugin < Bevy::Plugin
  def build(app)
    app.add_event(DeathEvent)

    app.add_update_system do |ctx|
      bullets = []
      ctx.world.each(Bullet, Bevy::Transform) do |entity, bullet, transform|
        bullets << { entity: entity, bullet: bullet, pos: transform.translation }
      end

      bullets_to_remove = []

      ctx.world.each(Enemy, Health, Bevy::Transform) do |entity, enemy, health, transform|
        bullets.each do |b|
          next unless b[:bullet].owner == 'player'

          dx = (b[:pos].x - transform.translation.x).abs
          dy = (b[:pos].y - transform.translation.y).abs

          next unless dx < 25 && dy < 25

          health.current -= b[:bullet].damage
          bullets_to_remove << b[:entity]

          if health.current <= 0
            ctx.events.writer(DeathEvent).send(
              DeathEvent.new(entity_id: entity.id, entity_type: 'enemy', points: enemy.points)
            )
          else
            ctx.world.insert_component(entity, health)
          end
        end
      end

      ctx.world.each(Player, Health, Bevy::Transform) do |entity, _player, health, transform|
        bullets.each do |b|
          next unless b[:bullet].owner == 'enemy'

          dx = (b[:pos].x - transform.translation.x).abs
          dy = (b[:pos].y - transform.translation.y).abs

          next unless dx < 25 && dy < 30

          health.current -= b[:bullet].damage
          bullets_to_remove << b[:entity]

          if health.current <= 0
            ctx.events.writer(DeathEvent).send(
              DeathEvent.new(entity_id: entity.id, entity_type: 'player')
            )
          else
            ctx.world.insert_component(entity, health)
          end
        end
      end

      bullets_to_remove.uniq.each { |e| ctx.world.despawn(e) }
    end

    app.add_update_system do |ctx|
      reader = ctx.events.reader(DeathEvent)
      state = ctx.resource(GameState)
      entities_to_remove = []

      reader.read.each do |event|
        if event.entity_type == 'enemy'
          state.score += event.points
          state.enemies_killed += 1
        elsif event.entity_type == 'player'
          state.player_alive = false
        end

        ctx.world.each(Enemy) do |entity, _|
          entities_to_remove << entity if entity.id == event.entity_id
        end
      end

      entities_to_remove.each { |e| ctx.world.despawn(e) }
    end
  end
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Space Shooter - WASD to move, SPACE to shoot',
    width: 800.0,
    height: 600.0
  }
)

app.add_plugins(MovementPlugin.new)
app.add_plugins(PlayerPlugin.new)
app.add_plugins(BulletPlugin.new)
app.add_plugins(EnemyPlugin.new)
app.add_plugins(CombatPlugin.new)
app.insert_resource(GameState.new)

app.add_startup_system do |ctx|
  ctx.spawn(
    Player.new(fire_rate: 0.12, speed: 350.0),
    Health.new(current: 100, max: 100),
    Velocity.new,
    Bevy::Transform.from_xyz(0.0, -220.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(45.0, 55.0)
    )
  )

  3.times do |i|
    x = (i - 1) * 150.0
    ctx.spawn(
      Enemy.new(points: 100, speed: 60.0),
      Health.new(current: 30, max: 30),
      Velocity.new(x: rand(-20.0..20.0), y: -50.0),
      Bevy::Transform.from_xyz(x, 250.0, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#E74C3C'),
        custom_size: Bevy::Vec2.new(40.0, 40.0)
      )
    )
  end
end

app.add_update_system do |ctx|
  state = ctx.resource(GameState)

  ctx.app.stop unless state.player_alive

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Space Shooter Demo'
puts 'Controls:'
puts '  WASD or Arrows - Move'
puts '  SPACE - Shoot'
puts '  ESC - Exit'
puts 'Destroy all enemies!'
app.run

state = app.resources.get(GameState)
puts "\nFinal Score: #{state.score}"
puts "Enemies Killed: #{state.enemies_killed}"
puts "Survived: #{state.player_alive ? 'Yes' : 'No'}"
