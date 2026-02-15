# Getting Started with Bevy Ruby

## Prerequisites

- Ruby `3.2+`
- Rust toolchain (native extension build)

## Installation

### Bundler

Add to `Gemfile`:

```ruby
gem "bevy"
```

Install:

```bash
bundle install
```

### Manual

```bash
gem install bevy
```

## First App

Create `my_game.rb`:

```ruby
require "bevy"

class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 180.0
end

app = Bevy::App.new(
  render: true,
  window: { title: "My First Bevy Ruby App", width: 800.0, height: 600.0 }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    Velocity.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex("#4ECDC4"),
      custom_size: Bevy::Vec2.new(80.0, 80.0)
    )
  )
end

app.add_update_system do |ctx|
  ctx.query(Velocity, Bevy::Transform) do |entity, vel, transform|
    next_x = transform.translation.x + vel.x * ctx.delta
    if next_x > 360.0 || next_x < -360.0
      vel.x *= -1.0
      next_x = transform.translation.x + vel.x * ctx.delta
    end

    ctx.world.insert_component(
      entity,
      transform.with_translation(Bevy::Vec3.new(next_x, transform.translation.y, 0.0))
    )
  end

  ctx.app.stop if ctx.key_pressed?("ESCAPE")
end

app.run
```

Run:

```bash
bundle exec ruby my_game.rb
```

## Core Concepts

### App

`Bevy::App` manages:

- schedules and systems
- ECS world/resources/events
- render loop (when `render: true`)

### Components

Define components with `ComponentDSL`:

```ruby
class Health < Bevy::ComponentDSL
  attribute :current, Integer, default: 100
  attribute :max, Integer, default: 100
end
```

### Resources

Use `ResourceDSL` for global state:

```ruby
class Score < Bevy::ResourceDSL
  attribute :value, Integer, default: 0
end

app.insert_resource(Score.new)
```

### Events

Define and use typed events:

```ruby
class HitEvent < Bevy::EventDSL
  attribute :target_id, Integer, default: 0
end

app.add_event(HitEvent)

app.add_update_system do |ctx|
  ctx.event_writer(HitEvent).send(HitEvent.new(target_id: 10))
end

app.add_systems(Bevy::Schedule::POST_UPDATE) do |ctx|
  ctx.event_reader(HitEvent).read.each do |event|
    puts "hit #{event.target_id}"
  end
end
```

## Schedules

Available schedule labels:

- `STARTUP`
- `FIRST`
- `PRE_UPDATE`
- `UPDATE`
- `POST_UPDATE`
- `LAST`
- `FIXED_UPDATE`

## Input

```ruby
app.add_update_system do |ctx|
  if ctx.key_just_pressed?("SPACE")
    puts "jump"
  end

  if ctx.mouse_pressed?("LEFT")
    pos = ctx.mouse_position
    puts "mouse=#{pos.x},#{pos.y}"
  end
end
```

## Gamepad

```ruby
app.add_update_system do |ctx|
  next unless ctx.any_gamepad_connected?

  if ctx.gamepad_just_pressed?(Bevy::GamepadButton::SOUTH)
    ctx.gamepad&.rumble(
      Bevy::RumbleRequest.new(strong: 0.8, weak: 0.3, duration: 0.4)
    )
  end
end
```

Note:

- gamepad rumble forwarding works in render mode (`render: true`)

## Picking Events

Picking events are bridged as `Bevy::PickingEvent` (registered by default):

```ruby
app.add_update_system do |ctx|
  ctx.picking_events(:click).each do |event|
    puts "clicked target=#{event.target_id}"
  end
end
```

## Next Steps

- [API Reference](api_reference.md)
- [Architecture](architecture.md)
- `examples/` directory (for runnable samples)
