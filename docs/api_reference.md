# API Reference

This document reflects the current implementation in this repository.

## Bevy::App

Main application class.

```ruby
app = Bevy::App.new(
  render: true,
  window: { title: "Game", width: 800.0, height: 600.0, resizable: true }
)
```

### Attributes

- `world`
- `resources`
- `events`
- `render_app`
- `time`
- `fixed_time`
- `keyboard`
- `mouse`
- `gamepads`

### Methods

| Method | Description |
|--------|-------------|
| `render_enabled?` | Returns whether render loop is enabled |
| `add_plugins(*plugins)` | Adds plugin instances |
| `add_systems(schedule, *systems, &block)` | Adds systems to schedule |
| `add_startup_system(&block)` | Shortcut for `STARTUP` |
| `add_update_system(&block)` | Shortcut for `UPDATE` |
| `add_event(event_class)` | Registers an event class |
| `insert_resource(resource)` | Inserts a resource instance |
| `run` | Runs startup then main/render loop |
| `run_once` | Runs startup + one update |
| `update` | Runs one frame update |
| `stop` | Stops app loop |
| `running?` | Returns running state |

## Bevy::Schedule

Schedule constants:

- `Bevy::Schedule::STARTUP`
- `Bevy::Schedule::FIRST`
- `Bevy::Schedule::PRE_UPDATE`
- `Bevy::Schedule::UPDATE`
- `Bevy::Schedule::POST_UPDATE`
- `Bevy::Schedule::LAST`
- `Bevy::Schedule::FIXED_UPDATE`

## Bevy::SystemContext

Systems receive one `ctx` object.

### Core

| Method | Description |
|--------|-------------|
| `delta` / `delta_seconds` | Frame delta seconds |
| `elapsed` | Elapsed seconds |
| `resource(ResourceClass)` | Gets resource |
| `insert_resource(resource)` | Inserts/overwrites resource |
| `event_reader(EventClass)` | Returns reader |
| `event_writer(EventClass)` | Returns writer |
| `spawn(*components)` | Spawns entity |
| `despawn(entity)` | Despawns entity |
| `query(*components) { ... }` | Iterates matching entities |

### Keyboard and Mouse

| Method | Description |
|--------|-------------|
| `key_pressed?(key)` | Held key |
| `key_just_pressed?(key)` | Pressed this frame |
| `mouse_pressed?(button)` | Held mouse button |
| `mouse_just_pressed?(button)` | Pressed this frame |
| `mouse_position` | Returns `Bevy::Vec2` |

Note:

- In render mode, keyboard/mouse checks are typically used with uppercase tokens such as `"SPACE"`, `"ESCAPE"`, `"LEFT"`, `"RIGHT"`, `"MIDDLE"`.

### Gamepad Helpers

| Method | Description |
|--------|-------------|
| `gamepad(id = nil)` | `id` gamepad or first connected |
| `gamepad_connected?(id)` | Connected check |
| `any_gamepad_connected?` | Any connected |
| `connected_gamepad_ids` | Connected ids |
| `gamepad_pressed?(button, id = nil)` | Button held |
| `gamepad_just_pressed?(button, id = nil)` | Button pressed this frame |
| `gamepad_just_released?(button, id = nil)` | Button released this frame |
| `gamepad_axis(axis, id = nil)` | Dead-zone processed axis |
| `gamepad_axis_raw(axis, id = nil)` | Raw axis |
| `gamepad_left_stick(id = nil)` | `Bevy::Vec2` |
| `gamepad_right_stick(id = nil)` | `Bevy::Vec2` |
| `gamepad_left_trigger(id = nil)` | Float |
| `gamepad_right_trigger(id = nil)` | Float |

### Picking Helpers

| Method | Description |
|--------|-------------|
| `picking_events(kind = nil)` | Returns `Bevy::PickingEvent` list |
| `picked?(entity_or_id, kind: nil)` | Target-picked convenience check |

### Camera Helpers

| Method | Description |
|--------|-------------|
| `camera_position` | Returns `Bevy::Vec3` |
| `set_camera_position(vec_or_array)` | Sets 2D camera position |
| `camera_scale` | Returns current scale |
| `set_camera_scale(scale)` | Sets scale |
| `camera_zoom` / `set_camera_zoom` | Aliases |

## Components and DSL

### Bevy::ComponentDSL

```ruby
class Velocity < Bevy::ComponentDSL
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
end
```

Useful methods:

- `to_h`
- `[]`, `[]=`
- `type_name`

### Built-in Render Components

- `Bevy::Transform`
- `Bevy::Sprite`
- `Bevy::Text2d`
- `Bevy::Mesh::Rectangle`
- `Bevy::Mesh::Circle`
- `Bevy::Mesh::RegularPolygon`
- `Bevy::Mesh::Line`
- `Bevy::Mesh::Ellipse`

## Resources

### Bevy::ResourceDSL

```ruby
class Score < Bevy::ResourceDSL
  attribute :value, Integer, default: 0
end
```

### Bevy::Resources

| Method | Description |
|--------|-------------|
| `insert(resource)` | Inserts resource |
| `get(ResourceClass)` | Gets resource |
| `get_or_insert(ResourceClass) { ... }` | Lazy insert |
| `remove(ResourceClass)` | Removes resource |
| `contains?(ResourceClass)` | Contains check |

### Time Resources

- `Bevy::Time`
- `Bevy::FixedTime`

## Events

### Bevy::EventDSL

```ruby
class DamageEvent < Bevy::EventDSL
  attribute :target_id, Integer, default: 0
  attribute :amount, Float, default: 0.0
end
```

### Event Registration and Access

```ruby
app.add_event(DamageEvent)

app.add_update_system do |ctx|
  ctx.event_writer(DamageEvent).send(DamageEvent.new(target_id: 1, amount: 10.0))
end

app.add_systems(Bevy::Schedule::POST_UPDATE) do |ctx|
  ctx.event_reader(DamageEvent).read.each do |event|
    puts event.amount
  end
end
```

### Bevy::PickingEvent

`Bevy::App` registers this event by default.

Fields:

- `kind` (`"over"`, `"out"`, `"down"`, `"up"`, `"click"`)
- `target_id`
- `pointer_id`
- `button` (optional)
- `position` (`Bevy::Vec2`)
- `camera_id` (optional)
- `depth` (optional)
- `hit_position` (`Bevy::Vec3`, optional)
- `hit_normal` (`Bevy::Vec3`, optional)

## Input Constants and Types

### Constants

- `Bevy::KeyCode::*`
- `Bevy::MouseButton::*`
- `Bevy::GamepadButton::*`
- `Bevy::GamepadAxis::*`

Note:

- `Bevy::KeyCode::*` and `Bevy::MouseButton::*` constants exist as data definitions, but render-loop input checks in `SystemContext` are commonly written with uppercase string tokens as shown above.

### Keyboard and Mouse State Objects

- `Bevy::KeyboardInput`
- `Bevy::MouseInput`

### Gamepad Types

- `Bevy::DeadZone`
- `Bevy::RumbleRequest`
- `Bevy::GamepadInput`
- `Bevy::Gamepads`

`Bevy::GamepadInput#rumble(...)` requests are forwarded to Bevy when `render: true` is enabled.

## Plugin API

```ruby
class MyPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      # logic
    end
  end
end

app.add_plugins(MyPlugin.new)
```
