# frozen_string_literal: true

# Advanced Example: Audio System
# This example demonstrates audio visualization concepts.
# Visual indicators pulse when "sounds" play.

require 'bevy'

# === Events ===

class PlaySoundEvent < Bevy::EventDSL
  attribute :sound, String
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
end

# === Components ===

class SoundIndicator < Bevy::ComponentDSL
  attribute :lifetime, Float, default: 0.5
  attribute :max_size, Float, default: 100.0
end

class MusicVisualizer < Bevy::ComponentDSL
  attribute :beat_time, Float, default: 0.0
  attribute :bpm, Float, default: 120.0
end

class SoundEmitter < Bevy::ComponentDSL
  attribute :sound, String
  attribute :cooldown, Float, default: 0.0
end

# Create app with rendering
app = Bevy::App.new(
  render: true,
  window: {
    title: 'Audio System Visualization',
    width: 800.0,
    height: 600.0
  }
)

app.add_event(PlaySoundEvent)

app.add_startup_system do |ctx|
  # Music visualizer bar (pulses with beat)
  ctx.spawn(
    MusicVisualizer.new(bpm: 120.0),
    Bevy::Transform.from_xyz(0.0, -250.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#9B59B6'),
      custom_size: Bevy::Vec2.new(600.0, 20.0)
    )
  )

  # Sound emitters at different positions
  emitters = [
    { x: -200.0, y: 100.0, sound: 'Drum', color: '#E74C3C' },
    { x: 0.0, y: 100.0, sound: 'Synth', color: '#3498DB' },
    { x: 200.0, y: 100.0, sound: 'Bass', color: '#2ECC71' }
  ]

  emitters.each do |e|
    ctx.spawn(
      SoundEmitter.new(sound: e[:sound]),
      Bevy::Transform.from_xyz(e[:x], e[:y], 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(e[:color]),
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end
end

# Music visualizer beat animation
app.add_update_system do |ctx|
  ctx.world.each(MusicVisualizer, Bevy::Sprite) do |entity, viz, sprite|
    viz.beat_time += ctx.delta
    beat_interval = 60.0 / viz.bpm

    # Pulse on beat
    beat_progress = (viz.beat_time % beat_interval) / beat_interval
    scale = 1.0 + (1.0 - beat_progress) * 0.3 # Pulse effect

    height = 20.0 * scale
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(600.0, height))
    ctx.world.insert_component(entity, new_sprite)
    ctx.world.insert_component(entity, viz)
  end
end

# Trigger sounds with number keys
app.add_update_system do |ctx|
  ctx.world.each(SoundEmitter, Bevy::Transform) do |_entity, emitter, transform|
    should_play = case emitter.sound
                  when 'Drum' then ctx.key_just_pressed?('1')
                  when 'Synth' then ctx.key_just_pressed?('2')
                  when 'Bass' then ctx.key_just_pressed?('3')
                  else false
                  end

    next unless should_play

    ctx.events.writer(PlaySoundEvent).send(
      PlaySoundEvent.new(
        sound: emitter.sound,
        x: transform.translation.x,
        y: transform.translation.y
      )
    )
  end

  # Play all on SPACE
  if ctx.key_just_pressed?('SPACE')
    ctx.world.each(SoundEmitter, Bevy::Transform) do |_entity, emitter, transform|
      ctx.events.writer(PlaySoundEvent).send(
        PlaySoundEvent.new(
          sound: emitter.sound,
          x: transform.translation.x,
          y: transform.translation.y
        )
      )
    end
  end
end

# Spawn sound indicators
app.add_update_system do |ctx|
  reader = ctx.events.reader(PlaySoundEvent)

  reader.read.each do |event|
    color = case event.sound
            when 'Drum' then '#E74C3C'
            when 'Synth' then '#3498DB'
            when 'Bass' then '#2ECC71'
            else '#FFFFFF'
            end

    ctx.spawn(
      SoundIndicator.new(lifetime: 0.4, max_size: 120.0),
      Bevy::Transform.from_xyz(event.x, event.y, -1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(color).with_alpha(0.8),
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end
end

# Animate sound indicators (expand and fade)
app.add_update_system do |ctx|
  to_remove = []

  ctx.world.each(SoundIndicator, Bevy::Sprite) do |entity, indicator, sprite|
    indicator.lifetime -= ctx.delta

    if indicator.lifetime <= 0
      to_remove << entity
    else
      progress = 1.0 - (indicator.lifetime / 0.4)
      size = 60.0 + (indicator.max_size - 60.0) * progress
      alpha = 0.8 * (1.0 - progress)

      current_color = sprite.color
      new_sprite = sprite
                   .with_custom_size(Bevy::Vec2.new(size, size))
                   .with_color(Bevy::Color.rgba(current_color.r, current_color.g, current_color.b, alpha))

      ctx.world.insert_component(entity, new_sprite)
      ctx.world.insert_component(entity, indicator)
    end
  end

  to_remove.each { |e| ctx.world.despawn(e) }
end

# Exit on ESC
app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Audio System Visualization'
puts 'Controls:'
puts '  1 - Play Drum sound'
puts '  2 - Play Synth sound'
puts '  3 - Play Bass sound'
puts '  SPACE - Play all sounds'
puts '  ESC - Exit'
puts "\nWatch the visual sound waves expand!"
app.run
