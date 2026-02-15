# frozen_string_literal: true

# Advanced Example: Custom Components with DSL
# This example shows advanced component patterns with visual representation.
# Health bars and status effects are displayed as colored sprites.

require 'bevy'

# === Custom Components ===

class Health < Bevy::ComponentDSL
  attribute :current, Integer, default: 100
  attribute :max, Integer, default: 100

  def percentage
    return 0.0 if max.zero?

    current.to_f / max
  end

  def damage(amount)
    self.current = [current - amount, 0].max
  end

  def heal(amount)
    self.current = [current + amount, max].min
  end

  def dead?
    current <= 0
  end
end

class HealthBar < Bevy::ComponentDSL
  attribute :owner_id, Integer
end

class Poisoned < Bevy::ComponentDSL
  attribute :damage_per_second, Float, default: 5.0
  attribute :duration, Float, default: 3.0
end

class Player < Bevy::ComponentDSL
end

class Enemy < Bevy::ComponentDSL
  attribute :name, String, default: 'Enemy'
end

# Create app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Custom Components Demo',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  # Spawn player with health bar
  player = ctx.spawn(
    Player.new,
    Health.new(current: 100, max: 100),
    Bevy::Transform.from_xyz(-200.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(60.0, 60.0)
    )
  )

  # Health bar background
  ctx.spawn(
    HealthBar.new(owner_id: player.id),
    Bevy::Transform.from_xyz(-200.0, 50.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#333333'),
      custom_size: Bevy::Vec2.new(64.0, 8.0)
    )
  )

  # Spawn enemies with health bars
  enemy_data = [
    { name: 'Goblin', x: 100.0, y: 100.0, hp: 50, color: '#E74C3C' },
    { name: 'Orc', x: 200.0, y: 0.0, hp: 80, color: '#E67E22' },
    { name: 'Dragon', x: 100.0, y: -100.0, hp: 150, color: '#9B59B6' }
  ]

  enemy_data.each do |data|
    enemy = ctx.spawn(
      Enemy.new(name: data[:name]),
      Health.new(current: data[:hp], max: data[:hp]),
      Bevy::Transform.from_xyz(data[:x], data[:y], 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(data[:color]),
        custom_size: Bevy::Vec2.new(50.0, 50.0)
      )
    )

    # Health bar for enemy
    ctx.spawn(
      HealthBar.new(owner_id: enemy.id),
      Bevy::Transform.from_xyz(data[:x], data[:y] + 40.0, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#2ECC71'),
        custom_size: Bevy::Vec2.new(50.0, 6.0)
      )
    )
  end
end

# Poison system - applies damage over time
app.add_update_system do |ctx|
  ctx.world.each(Poisoned, Health) do |entity, poison, health|
    damage = (poison.damage_per_second * ctx.delta).to_i
    health.damage(damage) if damage > 0

    poison.duration -= ctx.delta
    ctx.world.insert_component(entity, health)

    if poison.duration <= 0
      ctx.world.remove_component(entity, Poisoned)
    else
      ctx.world.insert_component(entity, poison)
    end
  end
end

# Update health bars based on owner's health
app.add_update_system do |ctx|
  ctx.world.each(HealthBar, Bevy::Sprite) do |bar_entity, bar, sprite|
    # Find owner's health
    ctx.world.each(Health) do |owner_entity, health|
      next unless owner_entity.id == bar.owner_id

      # Update bar width based on health percentage
      full_width = 50.0
      new_width = full_width * health.percentage
      new_width = [new_width, 2.0].max # Minimum width

      # Change color based on health
      color = if health.percentage > 0.6
                Bevy::Color.from_hex('#2ECC71')  # Green
              elsif health.percentage > 0.3
                Bevy::Color.from_hex('#F1C40F')  # Yellow
              else
                Bevy::Color.from_hex('#E74C3C')  # Red
              end

      new_sprite = sprite.with_color(color).with_custom_size(Bevy::Vec2.new(new_width, 6.0))
      ctx.world.insert_component(bar_entity, new_sprite)
      break
    end
  end
end

# Apply damage on SPACE key
app.add_update_system do |ctx|
  if ctx.key_just_pressed?('SPACE')
    # Damage all enemies
    ctx.world.each(Enemy, Health) do |entity, _enemy, health|
      health.damage(15)
      ctx.world.insert_component(entity, health)
    end
  end

  # Poison player on P key
  if ctx.key_just_pressed?('P')
    ctx.world.each(Player, Health) do |entity, _player, _health|
      unless ctx.world.has?(entity, Poisoned)
        ctx.world.insert_component(entity, Poisoned.new(damage_per_second: 20.0, duration: 3.0))
        puts 'Player poisoned!'
      end
    end
  end

  # Heal player on H key
  if ctx.key_just_pressed?('H')
    ctx.world.each(Player, Health) do |entity, _player, health|
      health.heal(25)
      ctx.world.insert_component(entity, health)
      puts 'Player healed!'
    end
  end
end

# Remove dead entities
app.add_update_system do |ctx|
  dead_entities = []
  ctx.world.each(Health) do |entity, health|
    dead_entities << entity if health.dead?
  end

  dead_entities.each do |entity|
    ctx.world.despawn(entity)
  end
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Custom Components Demo'
puts 'Controls:'
puts '  SPACE - Damage all enemies'
puts '  P - Poison player'
puts '  H - Heal player'
puts '  ESC - Exit'
app.run
