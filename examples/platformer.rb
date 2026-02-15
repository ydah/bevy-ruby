# frozen_string_literal: true

# Practical Example: Simple Platformer
# A basic platformer game demonstrating physics, input, and collision.
# Control the player with WASD/Arrow keys and jump with SPACE.

require 'bevy'

class Player < Bevy::ComponentDSL
  attribute :jump_force, Float, default: 400.0
  attribute :move_speed, Float, default: 200.0
  attribute :grounded, :boolean, default: false
end

class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
end

class Collider < Bevy::ComponentDSL
  attribute :width, Float, default: 32.0
  attribute :height, Float, default: 32.0
end

class Platform < Bevy::ComponentDSL
end

class Coin < Bevy::ComponentDSL
  attribute :value, Integer, default: 10
end

class GameState < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
  attribute :coins_collected, Integer, default: 0
end

class PhysicsConfig < Bevy::ResourceDSL
  attribute :gravity, Float, default: -800.0
  attribute :terminal_velocity, Float, default: -600.0
end

class CoinCollectedEvent < Bevy::EventDSL
  attribute :coin_id, Integer
  attribute :value, Integer
end

class PhysicsPlugin < Bevy::Plugin
  def build(app)
    app.insert_resource(PhysicsConfig.new)

    app.add_update_system do |ctx|
      physics = ctx.resource(PhysicsConfig)
      delta = ctx.delta

      ctx.world.each(Player, Velocity) do |entity, player, vel|
        next if player.grounded

        vel.y += physics.gravity * delta
        vel.y = [vel.y, physics.terminal_velocity].max
        ctx.world.insert_component(entity, vel)
      end
    end

    app.add_update_system do |ctx|
      delta = ctx.delta

      ctx.world.each(Velocity, Bevy::Transform) do |entity, vel, transform|
        new_x = transform.translation.x + vel.x * delta
        new_y = transform.translation.y + vel.y * delta

        new_x = new_x.clamp(-370.0, 370.0)

        new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
      end
    end
  end
end

class PlayerPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      ctx.world.each(Player, Velocity) do |entity, player, vel|
        vel.x = 0.0

        vel.x = -player.move_speed if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')

        vel.x = player.move_speed if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')

        jump_key = ctx.key_just_pressed?('SPACE') ||
                   ctx.key_just_pressed?('W') ||
                   ctx.key_just_pressed?('UP')

        if jump_key && player.grounded
          vel.y = player.jump_force
          player.grounded = false
        end

        ctx.world.insert_component(entity, player)
        ctx.world.insert_component(entity, vel)
      end
    end
  end
end

class CollisionPlugin < Bevy::Plugin
  def build(app)
    app.add_event(CoinCollectedEvent)

    app.add_update_system do |ctx|
      ctx.world.each(Player, Velocity, Bevy::Transform, Collider) do |entity, player, vel, transform, collider|
        ctx.world.each(Platform, Bevy::Transform, Collider) do |_p_entity, _platform, p_transform, p_collider|
          player_bottom = transform.translation.y - collider.height / 2
          platform_top = p_transform.translation.y + p_collider.height / 2

          player_left = transform.translation.x - collider.width / 2
          player_right = transform.translation.x + collider.width / 2
          platform_left = p_transform.translation.x - p_collider.width / 2
          platform_right = p_transform.translation.x + p_collider.width / 2

          horizontal_overlap = player_right > platform_left && player_left < platform_right

          unless horizontal_overlap && player_bottom <= platform_top && player_bottom > platform_top - 20 && vel.y <= 0
            next
          end

          new_y = platform_top + collider.height / 2
          new_pos = Bevy::Vec3.new(transform.translation.x, new_y, transform.translation.z)
          ctx.world.insert_component(entity, transform.with_translation(new_pos))

          vel.y = 0.0
          player.grounded = true
          ctx.world.insert_component(entity, vel)
          ctx.world.insert_component(entity, player)
        end
      end
    end

    app.add_update_system do |ctx|
      player_data = nil

      ctx.world.each(Player, Bevy::Transform, Collider) do |_entity, _player, transform, collider|
        player_data = { pos: transform.translation, size: collider }
        break
      end

      return unless player_data

      coins_to_remove = []

      ctx.world.each(Coin, Bevy::Transform) do |entity, coin, transform|
        dx = (transform.translation.x - player_data[:pos].x).abs
        dy = (transform.translation.y - player_data[:pos].y).abs

        coins_to_remove << { entity: entity, coin: coin } if dx < 25 && dy < 25
      end

      coins_to_remove.each do |data|
        ctx.events.writer(CoinCollectedEvent).send(
          CoinCollectedEvent.new(coin_id: data[:entity].id, value: data[:coin].value)
        )
        ctx.world.despawn(data[:entity])
      end
    end
  end
end

class ScoringPlugin < Bevy::Plugin
  def build(app)
    app.insert_resource(GameState.new)

    app.add_update_system do |ctx|
      reader = ctx.events.reader(CoinCollectedEvent)
      state = ctx.resource(GameState)

      reader.read.each do |event|
        state.score += event.value
        state.coins_collected += 1
      end
    end
  end
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Platformer - WASD/Arrows to move, SPACE to jump',
    width: 800.0,
    height: 600.0
  }
)

app.add_plugins(PhysicsPlugin.new)
app.add_plugins(PlayerPlugin.new)
app.add_plugins(CollisionPlugin.new)
app.add_plugins(ScoringPlugin.new)

app.add_startup_system do |ctx|
  ctx.spawn(
    Player.new(jump_force: 450.0, move_speed: 250.0),
    Velocity.new,
    Collider.new(width: 40.0, height: 50.0),
    Bevy::Transform.from_xyz(0.0, -150.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(40.0, 50.0)
    )
  )

  platforms = [
    { x: 0.0, y: -250.0, w: 800.0, h: 20.0 },
    { x: -200.0, y: -150.0, w: 150.0, h: 20.0 },
    { x: 150.0, y: -50.0, w: 150.0, h: 20.0 },
    { x: -100.0, y: 50.0, w: 150.0, h: 20.0 },
    { x: 200.0, y: 150.0, w: 150.0, h: 20.0 }
  ]

  platforms.each do |p|
    ctx.spawn(
      Platform.new,
      Collider.new(width: p[:w], height: p[:h]),
      Bevy::Transform.from_xyz(p[:x], p[:y], -1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#2C3E50'),
        custom_size: Bevy::Vec2.new(p[:w], p[:h])
      )
    )
  end

  coins = [
    { x: -200.0, y: -120.0 },
    { x: 150.0, y: -20.0 },
    { x: -100.0, y: 80.0 },
    { x: 200.0, y: 180.0 },
    { x: 0.0, y: -220.0 }
  ]

  coins.each do |c|
    ctx.spawn(
      Coin.new(value: 10),
      Bevy::Transform.from_xyz(c[:x], c[:y], 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#F1C40F'),
        custom_size: Bevy::Vec2.new(20.0, 20.0)
      )
    )
  end
end

app.add_update_system do |ctx|
  ctx.world.each(Player, Velocity, Bevy::Transform) do |entity, player, vel, transform|
    next unless transform.translation.y < -300.0

    new_pos = Bevy::Vec3.new(0.0, -150.0, 0.0)
    vel.x = 0.0
    vel.y = 0.0
    player.grounded = false
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
    ctx.world.insert_component(entity, vel)
    ctx.world.insert_component(entity, player)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Platformer Demo'
puts 'Controls:'
puts '  A/D or Left/Right - Move'
puts '  SPACE/W/Up - Jump'
puts '  ESC - Exit'
puts 'Collect all the yellow coins!'
app.run

state = app.resources.get(GameState)
puts "\nFinal Score: #{state.score}"
puts "Coins Collected: #{state.coins_collected}"
