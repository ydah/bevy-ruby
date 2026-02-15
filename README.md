# Bevy Ruby

Bevy bindings for Ruby, providing ECS-driven game/app architecture, 2D rendering sync, input bridging, and runtime interaction events.

<img width="400" alt="Image" src="https://github.com/user-attachments/assets/440971a6-bf10-4cc2-abe6-e5cf28949b95" />

## Status

This project provides a practical, Bevy-compatible API surface in Ruby, with a mix of:

- native-backed features through Rust + Bevy integration
- Ruby convenience/DSL layers for ergonomic usage

### Native-backed (current)

- App/game loop integration (`App`, schedules, startup/update flow)
- ECS bridge (`World`, `Entity`, dynamic component/resource/event plumbing)
- Render bridge (window + camera + sync to Bevy scene)
  - `Sprite`
  - `Text2d`
  - `Mesh` 2D primitives (rectangle/circle/regular polygon/line/ellipse)
- Input bridge
  - keyboard and mouse state
  - gamepad state
  - gamepad rumble forwarding (`RumbleRequest`)
- Picking event bridge (`bevy_picking`)
  - `over`, `out`, `down`, `up`, `click`

### Ruby layer (current)

- DSL and registries
  - `ComponentDSL`
  - `ResourceDSL`
  - `EventDSL`
  - `EventRegistry`, readers/writers
- Runtime helpers
  - `SystemContext` query/spawn/resource/event APIs
  - input helper methods for keyboard/mouse/gamepad
  - picking helper methods (`picking_events`, `picked?`)
- Value and utility types
  - `Vec2`, `Vec3`, `Quat`, `Transform`, `Color`
  - `KeyboardInput`, `MouseInput`, `GamepadInput`, `Gamepads`, `DeadZone`

### Native build note

- The Rust backend currently targets Bevy `0.15`.
- A number of high-level Ruby modules exist in `lib/bevy/*`, but not all are fully wired end-to-end in native Bevy systems yet (for example, parts of audio/scene/gltf/ui/shader/material-related areas).

## Requirements

- Ruby 3.2+
- Rust toolchain (`rustc`, `cargo`) for native extension build

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bevy'
```

Then run:

```bash
bundle install
```

## Installing Native Library

This gem does not require installing a separate external runtime shared library.

The native extension is built from this repository's Rust crates.

### macOS

```bash
xcode-select --install
bundle install
bundle exec rake compile
```

### Linux

```bash
bundle install
bundle exec rake compile
```

### Windows

```powershell
bundle install
bundle exec rake compile
```

## Quick Start

```ruby
require 'bevy'

class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 120.0
end

app = Bevy::App.new(
  render: true,
  window: { title: 'Bevy Ruby', width: 800.0, height: 600.0 }
)

app.add_startup_system do |ctx|
  ctx.spawn(
    Velocity.new,
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#4ECDC4'),
      custom_size: Bevy::Vec2.new(80.0, 80.0)
    )
  )
end

app.add_update_system do |ctx|
  ctx.query(Velocity, Bevy::Transform) do |entity, vel, transform|
    next_x = transform.translation.x + vel.x * ctx.delta
    vel.x *= -1.0 if next_x > 360.0 || next_x < -360.0

    ctx.world.insert_component(
      entity,
      transform.with_translation(Bevy::Vec3.new(transform.translation.x + vel.x * ctx.delta, 0.0, 0.0))
    )
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

app.run
```

## Gamepad Rumble Example

```ruby
require 'bevy'

app = Bevy::App.new(render: true)

app.add_update_system do |ctx|
  next unless ctx.any_gamepad_connected?

  if ctx.gamepad_just_pressed?(Bevy::GamepadButton::SOUTH)
    ctx.gamepad&.rumble(
      Bevy::RumbleRequest.new(strong: 0.8, weak: 0.3, duration: 0.4)
    )
  end
end

app.run
```

## Picking Event Example

```ruby
require 'bevy'

app = Bevy::App.new(render: true)

app.add_update_system do |ctx|
  ctx.picking_events(:click).each do |event|
    puts "clicked target=#{event.target_id} button=#{event.button}"
  end
end

app.run
```

## API Coverage (Bevy docs parity)

| Area | Status | Notes |
| --- | --- | --- |
| ECS basics (`App`/`World`/entities/components/resources/events) | Implemented | Core loop and dynamic ECS bindings are available |
| 2D render sync (`Sprite`/`Text2d`/`Mesh` shapes) | Implemented | Ruby-side component data is synchronized to Bevy |
| Keyboard and mouse input | Implemented | Render loop input state is exposed through `SystemContext` |
| Gamepad input + rumble | Implemented | State bridge plus `RumbleRequest` forwarding |
| Picking events (`over`/`out`/`down`/`up`/`click`) | Implemented | Exposed as `Bevy::PickingEvent` |
| Camera transform controls (2D) | Implemented | Position/scale helpers are available |
| 3D/PBR-native workflows | Partial | Current bridge is primarily focused on 2D sync |
| Asset/scene/gltf/audio/ui/full parity with upstream Bevy | Partial | Some APIs exist in Ruby, but native end-to-end wiring is incomplete in several domains |
| Upstream Bevy version parity (`0.18+`/`main`) | Not implemented | Current backend target is Bevy `0.15` |

## Development

After checking out the repo, install dependencies:

```bash
bundle install
```

Build native extension:

```bash
bundle exec rake compile
```

Run tests:

```bash
bundle exec rake spec
```

Run examples:

```bash
bundle exec ruby examples/hello_world.rb
bundle exec ruby examples/input_handling.rb
bundle exec ruby examples/gamepad.rb
bundle exec ruby examples/shapes_2d.rb
bundle exec ruby examples/space_shooter.rb
```

## License

This project is available under the [MIT License](LICENSE).

## Contributing

Bug reports and pull requests are welcome at:

- https://github.com/ydah/bevy-ruby
