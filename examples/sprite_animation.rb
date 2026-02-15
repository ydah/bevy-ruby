# frozen_string_literal: true

# Sprite Animation Example
# Demonstrates sprite sheet animation using frame-based timing.
# This simulates animated sprites without actual texture atlas support.

require 'bevy'

class AnimationConfig < Bevy::ComponentDSL
  attribute :first_frame, Integer, default: 0
  attribute :last_frame, Integer, default: 3
  attribute :current_frame, Integer, default: 0
  attribute :fps, Float, default: 10.0
  attribute :timer, Float, default: 0.0
  attribute :playing, :boolean, default: true
end

class AnimatedSprite < Bevy::ComponentDSL
  attribute :name, String, default: ''
end

FRAME_COLORS = [
  '#E74C3C',
  '#E67E22',
  '#F1C40F',
  '#2ECC71',
  '#3498DB',
  '#9B59B6',
  '#1ABC9C',
  '#34495E'
].freeze

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Sprite Animation - Press LEFT/RIGHT to trigger animations',
    width: 800.0,
    height: 600.0
  }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    AnimatedSprite.new(name: 'left_sprite'),
    AnimationConfig.new(first_frame: 0, last_frame: 3, fps: 8.0, playing: false),
    Bevy::Transform.from_xyz(-150.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(FRAME_COLORS[0]),
      custom_size: Bevy::Vec2.new(80.0, 80.0)
    )
  )

  ctx.spawn(
    AnimatedSprite.new(name: 'right_sprite'),
    AnimationConfig.new(first_frame: 4, last_frame: 7, fps: 12.0, playing: false),
    Bevy::Transform.from_xyz(150.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(FRAME_COLORS[4]),
      custom_size: Bevy::Vec2.new(80.0, 80.0)
    )
  )

  ctx.spawn(
    AnimatedSprite.new(name: 'center_sprite'),
    AnimationConfig.new(first_frame: 0, last_frame: 7, fps: 6.0, playing: true),
    Bevy::Transform.from_xyz(0.0, 150.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(FRAME_COLORS[0]),
      custom_size: Bevy::Vec2.new(60.0, 60.0)
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#7F8C8D'),
      custom_size: Bevy::Vec2.new(600.0, 40.0)
    )
  )
end

app.add_update_system do |ctx|
  if ctx.key_just_pressed?('LEFT')
    ctx.world.each(AnimatedSprite, AnimationConfig) do |entity, sprite, config|
      next unless sprite.name == 'left_sprite'

      config.playing = true
      config.current_frame = config.first_frame
      config.timer = 0.0
      ctx.world.insert_component(entity, config)
    end
  end

  if ctx.key_just_pressed?('RIGHT')
    ctx.world.each(AnimatedSprite, AnimationConfig) do |entity, sprite, config|
      next unless sprite.name == 'right_sprite'

      config.playing = true
      config.current_frame = config.first_frame
      config.timer = 0.0
      ctx.world.insert_component(entity, config)
    end
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta

  ctx.world.each(AnimationConfig, Bevy::Sprite) do |entity, config, sprite|
    next unless config.playing

    config.timer += delta
    frame_duration = 1.0 / config.fps

    if config.timer >= frame_duration
      config.timer -= frame_duration
      config.current_frame += 1

      if config.current_frame > config.last_frame
        config.current_frame = config.first_frame

        ctx.world.each(AnimatedSprite) do |e, anim_sprite|
          config.playing = false if e.id == entity.id && anim_sprite.name != 'center_sprite'
        end
      end

      new_color = Bevy::Color.from_hex(FRAME_COLORS[config.current_frame % FRAME_COLORS.length])
      new_sprite = sprite.with_color(new_color)
      ctx.world.insert_component(entity, new_sprite)
    end

    ctx.world.insert_component(entity, config)
  end
end

app.add_update_system do |ctx|
  ctx.world.each(AnimationConfig, Bevy::Transform) do |entity, config, transform|
    next unless config.playing

    scale_pulse = 1.0 + Math.sin(ctx.elapsed * 10.0) * 0.1
    new_transform = transform.with_scale(Bevy::Vec3.new(scale_pulse, scale_pulse, 1.0))
    ctx.world.insert_component(entity, new_transform)
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Sprite Animation Example'
puts 'Controls:'
puts '  LEFT  - Trigger left sprite animation'
puts '  RIGHT - Trigger right sprite animation'
puts '  ESC   - Exit'
puts ''
puts 'The center sprite animates continuously.'
puts 'Left and right sprites animate once when triggered.'
app.run
