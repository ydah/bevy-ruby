# Architecture

## Overview

Bevy Ruby is a layered Ruby + Rust system that bridges Ruby gameplay code into a Bevy runtime.

```text
Ruby App Code
  ↓
lib/bevy (Ruby API / DSL / loop orchestration)
  ↓
ext/bevy (Magnus FFI bindings)
  ↓
crates/bevy (Rust bridge + Bevy integration)
  ↓
Bevy 0.15 runtime (ECS, input, rendering, picking)
```

The design goal is:

- keep game/app logic in Ruby
- keep per-frame engine integration in Rust
- synchronize only required state across the language boundary

## Layer Responsibilities

## `lib/bevy/` (Ruby layer)

- Public API surface (`App`, `SystemContext`, DSL types)
- ECS-facing ergonomics (`ComponentDSL`, `ResourceDSL`, `EventDSL`)
- Schedule execution order (`STARTUP`, `FIRST`, `PRE_UPDATE`, `UPDATE`, `POST_UPDATE`, `LAST`, `FIXED_UPDATE`)
- Render-loop orchestration:
  - read input/gamepad/picking from native layer
  - run Ruby systems
  - queue sprite/text/mesh/camera/rumble updates back to native layer

## `ext/bevy/` (Magnus bindings)

- Ruby class/method definitions backed by Rust structs
- Type conversion between Ruby values and Rust structs
- Thread-local bridge buffers for per-frame shared state:
  - input snapshot
  - picking event batch
  - pending render sync ops
  - pending gamepad rumble commands

## `crates/bevy/` (Rust bridge)

- Owns Bevy `App`/plugins for render mode
- Collects native input and picking events each frame
- Applies queued render sync operations (sprite/text/mesh/camera)
- Emits native gamepad rumble events from Ruby commands

## Bevy runtime

- ECS execution
- Window/event loop
- Rendering (`Sprite`, `Text`, lyon shapes)
- Input and picking (`bevy_input`, `bevy_picking`)

## Runtime Modes

## Headless mode (`render: false`)

- Ruby loop only (`App#run_main_loop`)
- Schedules run entirely in Ruby
- No native rendering/input bridge

## Render mode (`render: true`)

- Native `RenderApp` owns Bevy loop
- Each frame performs bidirectional sync:
  1. Rust captures keyboard/mouse/gamepad/picking into bridge state
  2. Ruby callback runs
  3. Ruby systems execute and queue render/rumble/camera updates
  4. Rust applies queued updates and renders

## Frame Data Flow (render mode)

```text
Bevy systems (Rust)
  → input snapshot + picking batch
  → Ruby callback
  → Ruby App#sync_input_from_bevy
  → Ruby App#update (schedules + events/resources/world changes)
  → Ruby App#sync_sprites_to_bevy (sprite/text/mesh + rumble queue)
  → Rust apply_pending + rumble event write + render
```

## Synchronization Channels

## Rust → Ruby

- Keyboard and mouse states
- Gamepad connected/pressed/axis states
- Picking events (`over`, `out`, `down`, `up`, `click`)

Ruby consumes these via:

- `SystemContext` input helpers
- `Bevy::PickingEvent` entries in `EventRegistry`

## Ruby → Rust

- Sprite sync operations
- Text sync operations
- Mesh shape sync operations
- Camera position/scale changes
- Gamepad rumble commands
- Stop/exit signal

## ECS Representation

Ruby-defined components/resources/events are modeled as dynamic Ruby-side data structures and passed through bridge layers.

Built-in render-facing component families (`Transform`, `Sprite`, `Text2d`, mesh shapes) have explicit sync paths to native Bevy entities.

This split keeps Ruby DSL flexibility while preserving native render/update performance for frame-critical paths.

## Input and Interaction Architecture

## Input

- Rust collects native button/axis states each frame
- Ruby exposes high-level helpers:
  - keyboard/mouse checks
  - gamepad helpers (`gamepad_axis`, stick/trigger helpers, etc.)

## Rumble

- Ruby creates `RumbleRequest` on `GamepadInput`
- App sync converts pending requests into native rumble commands
- Rust emits `GamepadRumbleRequest` events to Bevy

## Picking

- Rust reads `bevy_picking` pointer events
- Events are normalized into bridge structs
- Ruby drains them into `Bevy::PickingEvent`
- Systems query through `picking_events` / `picked?`

## Feature Flags and Version Scope

- Rust crate feature:
  - `rendering` (default): enables window/render/input/picking plugins
- Current native Bevy target: `0.15`

The repository includes additional Ruby modules beyond the fully wired render/input paths; some domains are currently partial at native end-to-end parity.

## Extension Guidelines

When adding new engine features, keep the same staged pattern:

1. add/extend Ruby-facing API in `lib/bevy/`
2. bind methods and conversions in `ext/bevy/`
3. implement bridge data + Bevy system integration in `crates/bevy/`
4. add specs for Ruby behavior and bridge sync
5. update docs (`README`, `docs/api_reference.md`, this file)

This preserves a clear boundary between Ruby ergonomics and Rust runtime execution.
