# frozen_string_literal: true

# Timer Demo
# Demonstrates the Timer and Stopwatch utilities.
# Watch sprites change color and spawn based on timer events.

require 'bevy'

class TimerController < Bevy::ComponentDSL
end

class ColorBox < Bevy::ComponentDSL
  attribute :index, Integer, default: 0
end

class SpawnedParticle < Bevy::ComponentDSL
  attribute :spawn_time, Float, default: 0.0
  attribute :lifetime_duration, Float, default: 2.0
end

COLORS = [
  '#E74C3C',
  '#3498DB',
  '#2ECC71',
  '#F39C12',
  '#9B59B6',
  '#1ABC9C'
].freeze

COLOR_TIMER = Bevy::Timer.from_seconds(1.0, mode: Bevy::Timer::TimerMode::REPEATING)
SPAWN_TIMER = Bevy::Timer.from_seconds(0.3, mode: Bevy::Timer::TimerMode::REPEATING)
STOPWATCH = Bevy::Stopwatch.new

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Timer Demo - Watch timers in action!',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    TimerController.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(COLORS[0]),
      custom_size: Bevy::Vec2.new(100.0, 100.0)
    )
  )

  ctx.spawn(
    ColorBox.new(index: 0),
    Bevy::Transform.from_xyz(-200.0, 200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#7F8C8D'),
      custom_size: Bevy::Vec2.new(60.0, 60.0)
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -250.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#2C3E50'),
      custom_size: Bevy::Vec2.new(800.0, 100.0)
    )
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  COLOR_TIMER.tick(delta)
  SPAWN_TIMER.tick(delta)
  STOPWATCH.tick(delta)

  ctx.world.each(TimerController, Bevy::Sprite) do |entity, _, sprite|
    if COLOR_TIMER.just_finished?
      color_index = STOPWATCH.elapsed_secs.to_i % COLORS.length
      new_color = Bevy::Color.from_hex(COLORS[color_index])
      ctx.world.insert_component(entity, sprite.with_color(new_color))

      ctx.world.each(ColorBox, Bevy::Sprite) do |box_entity, box, box_sprite|
        box.index = color_index
        ctx.world.insert_component(box_entity, box)
        ctx.world.insert_component(box_entity, box_sprite.with_color(new_color))
      end
    end

    next unless SPAWN_TIMER.just_finished?

    x = rand(-300.0..300.0)
    y = rand(-150.0..150.0)

    ctx.spawn(
      SpawnedParticle.new(
        spawn_time: STOPWATCH.elapsed_secs,
        lifetime_duration: 2.0
      ),
      Bevy::Transform.from_xyz(x, y, 1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(COLORS.sample).with_alpha(0.7),
        custom_size: Bevy::Vec2.new(20.0, 20.0)
      )
    )
  end
end

app.add_update_system do |ctx|
  elapsed = STOPWATCH.elapsed_secs
  to_remove = []

  ctx.world.each(SpawnedParticle, Bevy::Transform, Bevy::Sprite) do |entity, particle, transform, sprite|
    age = elapsed - particle.spawn_time
    lifetime_percent = age / particle.lifetime_duration

    if lifetime_percent >= 1.0
      to_remove << entity
    else
      percent_left = 1.0 - lifetime_percent
      scale = 0.5 + percent_left * 0.5
      new_scale = Bevy::Vec3.new(scale, scale, 1.0)

      new_color = sprite.color.with_alpha(percent_left * 0.7)

      ctx.world.insert_component(entity, transform.with_scale(new_scale))
      ctx.world.insert_component(entity, sprite.with_color(new_color))
    end
  end

  to_remove.each { |e| ctx.world.despawn(e) }
end

app.add_update_system do |ctx|
  elapsed = STOPWATCH.elapsed_secs

  ctx.world.each(ColorBox, Bevy::Transform) do |entity, _, transform|
    pulse = 1.0 + Math.sin(elapsed * 3.0) * 0.2
    new_scale = Bevy::Vec3.new(pulse, pulse, 1.0)
    ctx.world.insert_component(entity, transform.with_scale(new_scale))
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Timer Demo'
puts ''
puts 'Features:'
puts '  - Color Timer: Changes main box color every 1 second'
puts '  - Spawn Timer: Spawns particles every 0.3 seconds'
puts '  - Stopwatch: Tracks total elapsed time'
puts '  - Lifetime: Particles fade out over 2 seconds'
puts ''
puts 'Press ESC to exit'
app.run
