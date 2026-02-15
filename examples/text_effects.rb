# frozen_string_literal: true

# Text Demo
# Demonstrates the Text2d component for 2D text rendering.
# Shows various text styles, animations, and dynamic updates.

require 'bevy'

class ScoreDisplay < Bevy::ComponentDSL
  attribute :score, Integer, default: 0
end

class AnimatedText < Bevy::ComponentDSL
  attribute :animation_type, String, default: 'none'
  attribute :base_y, Float, default: 0.0
end

class TypewriterText < Bevy::ComponentDSL
  attribute :full_text, String, default: ''
  attribute :current_index, Integer, default: 0
end

TYPEWRITER_TIMERS = {}

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Text Demo - Text2d Rendering',
    width: 900.0,
    height: 700.0
  }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Text2d.new('Welcome to Bevy Ruby!', font_size: 56.0, color: Bevy::Color.from_hex('#3498DB')),
    AnimatedText.new(animation_type: 'wave', base_y: 280.0),
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Text2d Component Demo', font_size: 28.0, color: Bevy::Color.from_hex('#ECF0F1')),
    Bevy::Transform.from_xyz(0.0, 200.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Score: 0', font_size: 36.0, color: Bevy::Color.from_hex('#2ECC71')),
    ScoreDisplay.new(score: 0),
    Bevy::Transform.from_xyz(0.0, 100.0, 0.0)
  )

  typewriter_entity = ctx.spawn(
    Bevy::Text2d.new('', font_size: 24.0, color: Bevy::Color.from_hex('#F39C12')),
    TypewriterText.new(
      full_text: 'This text appears one character at a time...',
      current_index: 0
    ),
    Bevy::Transform.from_xyz(0.0, 20.0, 0.0)
  )
  TYPEWRITER_TIMERS[typewriter_entity.id] = Bevy::Timer.from_seconds(0.05, mode: Bevy::Timer::TimerMode::REPEATING)

  ctx.spawn(
    Bevy::Text2d.new('Pulsing Text', font_size: 32.0, color: Bevy::Color.from_hex('#E74C3C')),
    AnimatedText.new(animation_type: 'pulse', base_y: -60.0),
    Bevy::Transform.from_xyz(0.0, -60.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Color Shifting', font_size: 32.0, color: Bevy::Color.from_hex('#9B59B6')),
    AnimatedText.new(animation_type: 'rainbow', base_y: -120.0),
    Bevy::Transform.from_xyz(0.0, -120.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Rotating Text', font_size: 28.0, color: Bevy::Color.from_hex('#1ABC9C')),
    AnimatedText.new(animation_type: 'rotate', base_y: -200.0),
    Bevy::Transform.from_xyz(0.0, -200.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Press SPACE to add points | ESC to exit', font_size: 18.0, color: Bevy::Color.from_hex('#7F8C8D')),
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#1a1a2e'),
      custom_size: Bevy::Vec2.new(900.0, 700.0)
    )
  )
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(AnimatedText, Bevy::Transform) do |entity, anim, transform|
    case anim.animation_type
    when 'wave'
      new_y = anim.base_y + Math.sin(elapsed * 2.0) * 10.0
      new_transform = Bevy::Transform.new(
        translation: Bevy::Vec3.new(transform.translation.x, new_y, transform.translation.z),
        rotation: transform.rotation,
        scale: transform.scale
      )
      ctx.world.insert_component(entity, new_transform)

    when 'pulse'
      pulse = 1.0 + Math.sin(elapsed * 3.0) * 0.15
      new_transform = transform.with_scale(Bevy::Vec3.new(pulse, pulse, 1.0))
      ctx.world.insert_component(entity, new_transform)

    when 'rotate'
      rotation = Math.sin(elapsed) * 0.1
      new_transform = Bevy::Transform.new(
        translation: transform.translation,
        rotation: Bevy::Quat.from_rotation_z(rotation),
        scale: transform.scale
      )
      ctx.world.insert_component(entity, new_transform)
    end
  end
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(AnimatedText, Bevy::Text2d) do |entity, anim, text|
    next unless anim.animation_type == 'rainbow'

    hue = (elapsed * 50.0) % 360.0
    r, g, b = hsl_to_rgb(hue, 0.7, 0.6)
    new_color = Bevy::Color.rgba(r, g, b, 1.0)
    new_text = Bevy::Text2d.new(text.content, font_size: text.font_size, color: new_color)
    ctx.world.insert_component(entity, new_text)
  end
end

def hsl_to_rgb(h, s, l)
  c = (1 - (2 * l - 1).abs) * s
  x = c * (1 - ((h / 60.0) % 2 - 1).abs)
  m = l - c / 2

  r1, g1, b1 = case (h / 60.0).to_i % 6
               when 0 then [c, x, 0]
               when 1 then [x, c, 0]
               when 2 then [0, c, x]
               when 3 then [0, x, c]
               when 4 then [x, 0, c]
               else [c, 0, x]
               end

  [(r1 + m), (g1 + m), (b1 + m)]
end

app.add_update_system do |ctx|
  delta = ctx.delta

  TYPEWRITER_TIMERS.each_value { |timer| timer.tick(delta) }

  ctx.world.each(TypewriterText, Bevy::Text2d) do |entity, typewriter, text|
    timer = TYPEWRITER_TIMERS[entity.id]
    next unless timer

    if timer.just_finished? && typewriter.current_index < typewriter.full_text.length
      typewriter.current_index += 1
      displayed_text = typewriter.full_text[0...typewriter.current_index]
      new_text = Bevy::Text2d.new(displayed_text, font_size: text.font_size, color: text.color)
      ctx.world.insert_component(entity, new_text)
      ctx.world.insert_component(entity, typewriter)
    end

    next unless typewriter.current_index >= typewriter.full_text.length

    cursor_text = if (ctx.elapsed * 2).to_i.even?
                    typewriter.full_text + '_'
                  else
                    typewriter.full_text
                  end
    new_text = Bevy::Text2d.new(cursor_text, font_size: text.font_size, color: text.color)
    ctx.world.insert_component(entity, new_text)
  end
end

space_cooldown = 0.0

app.add_update_system do |ctx|
  delta = ctx.delta
  space_cooldown = [space_cooldown - delta, 0.0].max if defined?(space_cooldown) && space_cooldown > 0

  if ctx.key_pressed?('SPACE') && space_cooldown <= 0
    space_cooldown = 0.2

    ctx.world.each(ScoreDisplay, Bevy::Text2d) do |entity, score_display, text|
      score_display.score += 10
      new_text = Bevy::Text2d.new("Score: #{score_display.score}", font_size: text.font_size, color: text.color)
      ctx.world.insert_component(entity, new_text)
      ctx.world.insert_component(entity, score_display)
    end
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Text Demo'
puts ''
puts 'Text Effects:'
puts '  - Title: Wave animation'
puts '  - Score: Dynamic updates with SPACE'
puts '  - Typewriter: Character-by-character reveal'
puts '  - Pulsing: Scale animation'
puts '  - Rainbow: Color cycling'
puts '  - Rotating: Rotation animation'
puts ''
puts 'Controls:'
puts '  SPACE - Add 10 points'
puts '  ESC - Exit'
app.run
