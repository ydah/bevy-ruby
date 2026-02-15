# frozen_string_literal: true

# Desk Toy Example
# An interactive desktop mascot that responds to mouse and keyboard input.
# The character has idle animations, follows the mouse, and reacts to clicks.

require 'bevy'

module ToyState
  IDLE = :idle
  FOLLOWING = :following
  EXCITED = :excited
  SLEEPING = :sleeping
end

class DeskToy < Bevy::ComponentDSL
  attribute :state, Symbol, default: ToyState::IDLE
  attribute :idle_timer, Float, default: 0.0
  attribute :excitement_timer, Float, default: 0.0
  attribute :sleep_timer, Float, default: 0.0
  attribute :blink_timer, Float, default: 0.0
  attribute :is_blinking, :boolean, default: false
end

class ToyBody < Bevy::ComponentDSL
end

class ToyEye < Bevy::ComponentDSL
  attribute :side, String, default: 'left'
  attribute :base_x_offset, Float, default: 0.0
end

class ToyMouth < Bevy::ComponentDSL
end

class ToyAccessory < Bevy::ComponentDSL
  attribute :accessory_type, String, default: 'none'
end

class Particle < Bevy::ComponentDSL
  attribute :lifetime, Float, default: 1.0
  attribute :velocity_x, Float, default: 0.0
  attribute :velocity_y, Float, default: 0.0
end

BODY_COLOR = '#5DADE2'
EYE_COLOR = '#2C3E50'
MOUTH_COLOR = '#E74C3C'
HAPPY_COLOR = '#F39C12'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Desk Toy - Click and interact!',
    width: 600.0,
    height: 500.0
  }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    DeskToy.new,
    ToyBody.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(BODY_COLOR),
      custom_size: Bevy::Vec2.new(100.0, 100.0)
    )
  )

  ctx.spawn(
    ToyEye.new(side: 'left', base_x_offset: -20.0),
    Bevy::Transform.from_xyz(-20.0, 15.0, 1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(EYE_COLOR),
      custom_size: Bevy::Vec2.new(20.0, 25.0)
    )
  )

  ctx.spawn(
    ToyEye.new(side: 'right', base_x_offset: 20.0),
    Bevy::Transform.from_xyz(20.0, 15.0, 1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(EYE_COLOR),
      custom_size: Bevy::Vec2.new(20.0, 25.0)
    )
  )

  ctx.spawn(
    ToyMouth.new,
    Bevy::Transform.from_xyz(0.0, -20.0, 1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(MOUTH_COLOR),
      custom_size: Bevy::Vec2.new(30.0, 10.0)
    )
  )

  ctx.spawn(
    ToyAccessory.new(accessory_type: 'hat'),
    Bevy::Transform.from_xyz(0.0, 60.0, 1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#9B59B6'),
      custom_size: Bevy::Vec2.new(60.0, 20.0)
    )
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -200.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#2C3E50'),
      custom_size: Bevy::Vec2.new(600.0, 100.0)
    )
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  ctx.world.each(DeskToy) do |entity, toy|
    case toy.state
    when ToyState::IDLE
      toy.idle_timer += delta
      if toy.idle_timer > 10.0
        toy.state = ToyState::SLEEPING
        toy.idle_timer = 0.0
      end
    when ToyState::EXCITED
      toy.excitement_timer -= delta
      if toy.excitement_timer <= 0.0
        toy.state = ToyState::IDLE
        toy.excitement_timer = 0.0
      end
    when ToyState::SLEEPING
      toy.sleep_timer += delta
    when ToyState::FOLLOWING
      toy.idle_timer = 0.0
    end

    toy.blink_timer += delta
    if !toy.is_blinking && toy.blink_timer > rand(2.0..5.0)
      toy.is_blinking = true
      toy.blink_timer = 0.0
    elsif toy.is_blinking && toy.blink_timer > 0.15
      toy.is_blinking = false
      toy.blink_timer = 0.0
    end

    ctx.world.insert_component(entity, toy)
  end
end

app.add_update_system do |ctx|
  ctx.mouse_position

  toy_state = nil
  ctx.world.each(DeskToy) do |_, toy|
    toy_state = toy
  end

  return unless toy_state

  if ctx.mouse_just_pressed?('LEFT')
    ctx.world.each(DeskToy) do |entity, toy|
      if toy.state == ToyState::SLEEPING
        toy.state = ToyState::IDLE
        toy.sleep_timer = 0.0
      else
        toy.state = ToyState::EXCITED
        toy.excitement_timer = 2.0
      end
      toy.idle_timer = 0.0
      ctx.world.insert_component(entity, toy)
    end

    5.times do
      angle = rand(0.0..Math::PI * 2)
      speed = rand(50.0..150.0)
      ctx.spawn(
        Particle.new(
          lifetime: rand(0.5..1.5),
          velocity_x: Math.cos(angle) * speed,
          velocity_y: Math.sin(angle) * speed + 50.0
        ),
        Bevy::Transform.from_xyz(0.0, 0.0, 2.0),
        Bevy::Sprite.new(
          color: Bevy::Color.from_hex(HAPPY_COLOR),
          custom_size: Bevy::Vec2.new(10.0, 10.0)
        )
      )
    end
  end

  if ctx.mouse_pressed?('LEFT')
    ctx.world.each(DeskToy) do |entity, toy|
      next if toy.state == ToyState::SLEEPING

      toy.state = ToyState::FOLLOWING
      ctx.world.insert_component(entity, toy)
    end
  else
    ctx.world.each(DeskToy) do |entity, toy|
      if toy.state == ToyState::FOLLOWING
        toy.state = ToyState::IDLE
        ctx.world.insert_component(entity, toy)
      end
    end
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta
  mouse_pos = ctx.mouse_position

  toy_state = nil
  body_pos = nil

  ctx.world.each(DeskToy, ToyBody, Bevy::Transform) do |entity, toy, _, transform|
    toy_state = toy
    body_pos = transform.translation

    if toy.state == ToyState::FOLLOWING
      dx = mouse_pos.x - body_pos.x
      dy = mouse_pos.y - body_pos.y
      distance = Math.sqrt(dx * dx + dy * dy)

      if distance > 10.0
        speed = 200.0
        move_x = (dx / distance) * speed * delta
        move_y = (dy / distance) * speed * delta

        new_x = body_pos.x + move_x
        new_y = (body_pos.y + move_y).clamp(-150.0, 150.0)

        new_pos = Bevy::Vec3.new(new_x, new_y, 0.0)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
        body_pos = new_pos
      end
    end

    wobble = case toy.state
             when ToyState::IDLE
               Math.sin(ctx.elapsed * 2.0) * 0.05
             when ToyState::EXCITED
               Math.sin(ctx.elapsed * 15.0) * 0.15
             when ToyState::SLEEPING
               Math.sin(ctx.elapsed * 0.5) * 0.02
             else
               0.0
             end

    base_scale = toy.state == ToyState::SLEEPING ? 0.9 : 1.0
    new_scale = Bevy::Vec3.new(base_scale + wobble, base_scale - wobble * 0.5, 1.0)
    ctx.world.insert_component(entity, transform.with_scale(new_scale))
  end

  return unless body_pos && toy_state

  ctx.world.each(ToyEye, Bevy::Transform, Bevy::Sprite) do |entity, eye, transform, sprite|
    if toy_state.is_blinking || toy_state.state == ToyState::SLEEPING
      new_sprite = sprite.with_custom_size(Bevy::Vec2.new(20.0, 3.0))
      ctx.world.insert_component(entity, new_sprite)
    else
      new_sprite = sprite.with_custom_size(Bevy::Vec2.new(20.0, 25.0))
      ctx.world.insert_component(entity, new_sprite)

      dx = mouse_pos.x - body_pos.x
      dy = mouse_pos.y - body_pos.y
      max_offset = 5.0

      eye_offset_x = (dx / 200.0).clamp(-1.0, 1.0) * max_offset
      eye_offset_y = (dy / 200.0).clamp(-1.0, 1.0) * max_offset

      new_x = body_pos.x + eye.base_x_offset + eye_offset_x
      new_y = body_pos.y + 15.0 + eye_offset_y

      new_pos = Bevy::Vec3.new(new_x, new_y, 1.0)
      ctx.world.insert_component(entity, transform.with_translation(new_pos))
    end
  end

  ctx.world.each(ToyMouth, Bevy::Transform, Bevy::Sprite) do |entity, _, transform, sprite|
    new_x = body_pos.x
    new_y = body_pos.y - 20.0

    mouth_width = case toy_state.state
                  when ToyState::EXCITED
                    40.0 + Math.sin(ctx.elapsed * 10.0) * 10.0
                  when ToyState::SLEEPING
                    15.0
                  else
                    30.0
                  end

    mouth_height = toy_state.state == ToyState::EXCITED ? 15.0 : 10.0

    new_pos = Bevy::Vec3.new(new_x, new_y, 1.0)
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(mouth_width, mouth_height))

    ctx.world.insert_component(entity, transform.with_translation(new_pos))
    ctx.world.insert_component(entity, new_sprite)
  end

  ctx.world.each(ToyAccessory, Bevy::Transform) do |entity, _, transform|
    new_x = body_pos.x
    new_y = body_pos.y + 60.0
    new_pos = Bevy::Vec3.new(new_x, new_y, 1.0)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta
  to_remove = []

  ctx.world.each(Particle, Bevy::Transform, Bevy::Sprite) do |entity, particle, transform, sprite|
    particle.lifetime -= delta
    particle.velocity_y -= 200.0 * delta

    if particle.lifetime <= 0.0
      to_remove << entity
    else
      new_x = transform.translation.x + particle.velocity_x * delta
      new_y = transform.translation.y + particle.velocity_y * delta

      new_pos = Bevy::Vec3.new(new_x, new_y, 2.0)
      alpha = (particle.lifetime / 1.5).clamp(0.0, 1.0)
      new_color = Bevy::Color.rgba(0.95, 0.61, 0.07, alpha)

      ctx.world.insert_component(entity, transform.with_translation(new_pos))
      ctx.world.insert_component(entity, sprite.with_color(new_color))
      ctx.world.insert_component(entity, particle)
    end
  end

  to_remove.each { |e| ctx.world.despawn(e) }
end

app.add_update_system do |ctx|
  if ctx.key_pressed?('1')
    ctx.world.each(ToyBody, Bevy::Sprite) do |entity, _, sprite|
      ctx.world.insert_component(entity, sprite.with_color(Bevy::Color.from_hex('#5DADE2')))
    end
  elsif ctx.key_pressed?('2')
    ctx.world.each(ToyBody, Bevy::Sprite) do |entity, _, sprite|
      ctx.world.insert_component(entity, sprite.with_color(Bevy::Color.from_hex('#58D68D')))
    end
  elsif ctx.key_pressed?('3')
    ctx.world.each(ToyBody, Bevy::Sprite) do |entity, _, sprite|
      ctx.world.insert_component(entity, sprite.with_color(Bevy::Color.from_hex('#F1948A')))
    end
  elsif ctx.key_pressed?('4')
    ctx.world.each(ToyBody, Bevy::Sprite) do |entity, _, sprite|
      ctx.world.insert_component(entity, sprite.with_color(Bevy::Color.from_hex('#BB8FCE')))
    end
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Desk Toy Example'
puts ''
puts 'Interactions:'
puts '  Click       - Make the toy excited!'
puts '  Click+Drag  - The toy follows the mouse'
puts '  Wait 10s    - The toy falls asleep'
puts '  1/2/3/4     - Change toy color'
puts '  ESC         - Exit'
puts ''
puts 'Watch the toy blink, wobble, and react!'
app.run
