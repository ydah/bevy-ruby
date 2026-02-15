# frozen_string_literal: true

# Practical Example: Game State Machine
# A visual state machine demonstrating game states and AI behavior.
# Watch the AI entity change states based on conditions.

require 'bevy'

class StateIndicator < Bevy::ComponentDSL
  attribute :state_name, String, default: 'idle'
end

class AIEntity < Bevy::ComponentDSL
  attribute :health, Float, default: 100.0
  attribute :target_distance, Float, default: 500.0
  attribute :ammo, Integer, default: 30
  attribute :alert_level, Float, default: 0.0
  attribute :has_target, :boolean, default: false
  attribute :current_state, String, default: 'idle'
end

class Target < Bevy::ComponentDSL
  attribute :active, :boolean, default: false
end

class HealthBar < Bevy::ComponentDSL
  attribute :max_width, Float, default: 100.0
end

class AmmoBar < Bevy::ComponentDSL
  attribute :max_width, Float, default: 100.0
end

class AlertBar < Bevy::ComponentDSL
  attribute :max_width, Float, default: 100.0
end

class GameState < Bevy::ResourceDSL
  attribute :spawn_target, :boolean, default: false
  attribute :damage_ai, :boolean, default: false
end

STATE_COLORS = {
  'idle' => '#3498DB',
  'alert' => '#F39C12',
  'chase' => '#9B59B6',
  'attack' => '#E74C3C',
  'reload' => '#1ABC9C',
  'flee' => '#95A5A6'
}.freeze

def update_ai_state(ai)
  if ai.health < 20
    'flee'
  elsif ai.ammo <= 0
    'reload'
  elsif ai.target_distance < 100 && ai.has_target && ai.ammo > 0
    'attack'
  elsif ai.has_target
    'chase'
  elsif ai.alert_level > 50
    'alert'
  else
    'idle'
  end
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'State Machine - SPACE: Spawn Target, D: Damage AI, R: Reset',
    width: 800.0,
    height: 600.0
  }
)

app.insert_resource(GameState.new)

app.add_startup_system do |ctx|
  ctx.spawn(
    AIEntity.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(STATE_COLORS['idle']),
      custom_size: Bevy::Vec2.new(60.0, 60.0)
    )
  )

  ctx.spawn(
    HealthBar.new(max_width: 100.0),
    Bevy::Transform.from_xyz(-300.0, 200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#2ECC71'),
      custom_size: Bevy::Vec2.new(100.0, 20.0)
    )
  )

  ctx.spawn(
    AmmoBar.new(max_width: 100.0),
    Bevy::Transform.from_xyz(-300.0, 170.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#F1C40F'),
      custom_size: Bevy::Vec2.new(100.0, 20.0)
    )
  )

  ctx.spawn(
    AlertBar.new(max_width: 100.0),
    Bevy::Transform.from_xyz(-300.0, 140.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(0.0, 20.0)
    )
  )
end

app.add_update_system do |ctx|
  game_state = ctx.resource(GameState)

  game_state.spawn_target = true if ctx.key_just_pressed?('SPACE')

  game_state.damage_ai = true if ctx.key_just_pressed?('D')

  if ctx.key_just_pressed?('R')
    ctx.world.each(AIEntity) do |entity, ai|
      ai.health = 100.0
      ai.ammo = 30
      ai.alert_level = 0.0
      ai.has_target = false
      ai.target_distance = 500.0
      ai.current_state = 'idle'
      ctx.world.insert_component(entity, ai)
    end

    ctx.world.each(Target) do |entity, _target|
      ctx.world.despawn(entity)
    end
  end
end

app.add_update_system do |ctx|
  game_state = ctx.resource(GameState)

  if game_state.spawn_target
    game_state.spawn_target = false

    has_target = false
    ctx.world.each(Target) { |_e, _t| has_target = true }

    unless has_target
      ctx.spawn(
        Target.new(active: true),
        Bevy::Transform.from_xyz(200.0, 0.0, 0.0),
        Bevy::Sprite.new(
          color: Bevy::Color.from_hex('#E74C3C'),
          custom_size: Bevy::Vec2.new(40.0, 40.0)
        )
      )

      ctx.world.each(AIEntity) do |entity, ai|
        ai.has_target = true
        ai.alert_level = 75.0
        ctx.world.insert_component(entity, ai)
      end
    end
  end

  if game_state.damage_ai
    game_state.damage_ai = false

    ctx.world.each(AIEntity) do |entity, ai|
      ai.health = [ai.health - 25, 0].max
      ai.alert_level = [ai.alert_level + 30, 100].min
      ctx.world.insert_component(entity, ai)
    end
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta

  ctx.world.each(AIEntity, Bevy::Transform, Bevy::Sprite) do |entity, ai, transform, sprite|
    old_state = ai.current_state

    case ai.current_state
    when 'idle'
      ai.alert_level = [ai.alert_level - delta * 10, 0].max

    when 'alert'
      ai.alert_level = [ai.alert_level - delta * 5, 0].max

    when 'chase'
      ai.target_distance = [ai.target_distance - delta * 100, 0].max
      ai.alert_level = [ai.alert_level + delta * 5, 100].min

    when 'attack'
      ai.ammo = [ai.ammo - 1, 0].max if rand < delta * 5

    when 'reload'
      ai.ammo = [ai.ammo + 5, 30].min if rand < delta * 2

    when 'flee'
      ai.target_distance = [ai.target_distance + delta * 150, 1000].min
      if ai.target_distance > 500
        ai.has_target = false
        ctx.world.each(Target) do |t_entity, _target|
          ctx.world.despawn(t_entity)
        end
      end
    end

    ai.current_state = update_ai_state(ai)

    if ai.current_state != old_state
      new_color = STATE_COLORS[ai.current_state] || '#FFFFFF'
      new_sprite = sprite.with_color(Bevy::Color.from_hex(new_color))
      ctx.world.insert_component(entity, new_sprite)
    end

    if ai.current_state == 'chase' && ai.target_distance > 0
      direction = ai.target_distance > 100 ? 1 : 0
      new_x = transform.translation.x + direction * delta * 50
      new_x = new_x.clamp(-350.0, 150.0)
      new_pos = Bevy::Vec3.new(new_x, transform.translation.y, transform.translation.z)
      ctx.world.insert_component(entity, transform.with_translation(new_pos))
    end

    if ai.current_state == 'flee'
      new_x = transform.translation.x - delta * 80
      new_x = new_x.clamp(-350.0, 150.0)
      new_pos = Bevy::Vec3.new(new_x, transform.translation.y, transform.translation.z)
      ctx.world.insert_component(entity, transform.with_translation(new_pos))
    end

    ctx.world.insert_component(entity, ai)
  end
end

app.add_update_system do |ctx|
  ai_data = nil
  ctx.world.each(AIEntity) do |_entity, ai|
    ai_data = ai
    break
  end

  return unless ai_data

  ctx.world.each(HealthBar, Bevy::Sprite) do |entity, bar, sprite|
    width = (ai_data.health / 100.0) * bar.max_width
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(width, 20.0))
    ctx.world.insert_component(entity, new_sprite)
  end

  ctx.world.each(AmmoBar, Bevy::Sprite) do |entity, bar, sprite|
    width = (ai_data.ammo / 30.0) * bar.max_width
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(width, 20.0))
    ctx.world.insert_component(entity, new_sprite)
  end

  ctx.world.each(AlertBar, Bevy::Sprite) do |entity, bar, sprite|
    width = (ai_data.alert_level / 100.0) * bar.max_width
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(width, 20.0))
    ctx.world.insert_component(entity, new_sprite)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'State Machine Demo'
puts 'Controls:'
puts '  SPACE - Spawn target (triggers chase)'
puts '  D - Damage AI (may trigger flee)'
puts '  R - Reset AI state'
puts '  ESC - Exit'
puts ''
puts 'States:'
puts '  Blue   = Idle'
puts '  Orange = Alert'
puts '  Purple = Chase'
puts '  Red    = Attack'
puts '  Teal   = Reload'
puts '  Gray   = Flee'
app.run
