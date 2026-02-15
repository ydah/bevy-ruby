# frozen_string_literal: true

class TestResource < Bevy::ResourceDSL
  attribute :counter, :integer, default: 0
end

class TestEvent < Bevy::EventDSL
  attribute :message, :string, default: ''
end

class TestPosition < Bevy::ComponentDSL
  attribute :x, :float, default: 0.0
  attribute :y, :float, default: 0.0
end

RSpec.describe Bevy::Schedule do
  it 'defines schedule constants' do
    expect(Bevy::Schedule::STARTUP).to eq(:startup)
    expect(Bevy::Schedule::UPDATE).to eq(:update)
    expect(Bevy::Schedule::FIXED_UPDATE).to eq(:fixed_update)
    expect(Bevy::Schedule::PRE_UPDATE).to eq(:pre_update)
    expect(Bevy::Schedule::POST_UPDATE).to eq(:post_update)
  end
end

RSpec.describe Bevy::System do
  describe '.new' do
    it 'creates a system with a block' do
      system = described_class.new(name: 'test_system') { |_ctx| 'executed' }
      expect(system.name).to eq('test_system')
      expect(system.schedule).to eq(Bevy::Schedule::UPDATE)
    end

    it 'creates a system with custom schedule' do
      system = described_class.new(schedule: Bevy::Schedule::STARTUP) { |_ctx| }
      expect(system.schedule).to eq(Bevy::Schedule::STARTUP)
    end
  end

  describe '#run' do
    it 'executes the system block' do
      result = nil
      system = described_class.new { |ctx| result = ctx.delta }

      context = instance_double(Bevy::SystemContext, delta: 0.016)
      system.run(context)

      expect(result).to eq(0.016)
    end
  end
end

RSpec.describe Bevy::SystemContext do
  let(:world) { Bevy::World.new }
  let(:resources) { Bevy::Resources.new }
  let(:events) { Bevy::EventRegistry.new }
  let(:time) { Bevy::Time.new }
  let(:keyboard) { Bevy::KeyboardInput.new }
  let(:mouse) { Bevy::MouseInput.new }
  let(:gamepads) { Bevy::Gamepads.new }

  let(:app) { Bevy::App.new }

  let(:context) do
    described_class.new(
      world: world,
      resources: resources,
      events: events,
      time: time,
      keyboard: keyboard,
      mouse: mouse,
      gamepads: gamepads,
      app: app
    )
  end

  describe '#delta' do
    it 'returns delta time' do
      expect(context.delta).to eq(time.delta_seconds)
    end
  end

  describe '#resource' do
    it 'retrieves a resource' do
      resources.insert(TestResource.new(counter: 5))
      res = context.resource(TestResource)
      expect(res.counter).to eq(5)
    end
  end

  describe '#insert_resource' do
    it 'inserts a resource' do
      context.insert_resource(TestResource.new(counter: 10))
      expect(resources.get(TestResource).counter).to eq(10)
    end
  end

  describe '#spawn' do
    it 'spawns an entity' do
      entity = context.spawn(TestPosition.new(x: 5.0, y: 10.0))
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#key_pressed?' do
    it 'checks keyboard state' do
      keyboard.press(Bevy::KeyCode::SPACE)
      expect(context.key_pressed?(Bevy::KeyCode::SPACE)).to be true
    end
  end

  describe '#mouse_position' do
    it 'returns mouse position' do
      mouse.set_position(100.0, 200.0)
      pos = context.mouse_position
      expect(pos.x).to eq(100.0)
      expect(pos.y).to eq(200.0)
    end
  end

  describe 'gamepad helpers' do
    before do
      gamepads.connect(0)
      gamepads.connect(1)
      gamepads[1].press(Bevy::GamepadButton::SOUTH)
      gamepads[1].set_axis(Bevy::GamepadAxis::LEFT_STICK_X, 0.75)
      gamepads[1].set_axis(Bevy::GamepadAxis::LEFT_STICK_Y, -0.5)
      gamepads[1].set_axis(Bevy::GamepadAxis::LEFT_TRIGGER, 0.4)
    end

    it 'returns gamepad by id and first connected gamepad when id is omitted' do
      expect(context.gamepad(1)&.id).to eq(1)
      expect(context.gamepad).not_to be_nil
    end

    it 'checks connected state and connected ids' do
      expect(context.gamepad_connected?(1)).to be true
      expect(context.gamepad_connected?(99)).to be false
      expect(context.any_gamepad_connected?).to be true
      expect(context.connected_gamepad_ids).to contain_exactly(0, 1)
    end

    it 'checks button state with and without id' do
      expect(context.gamepad_pressed?(Bevy::GamepadButton::SOUTH)).to be true
      expect(context.gamepad_pressed?(Bevy::GamepadButton::SOUTH, 1)).to be true
      expect(context.gamepad_pressed?(Bevy::GamepadButton::SOUTH, 0)).to be false
    end

    it 'reads axis and stick/trigger helpers' do
      expect(context.gamepad_axis_raw(Bevy::GamepadAxis::LEFT_STICK_X, 1)).to be_within(0.001).of(0.75)
      expect(context.gamepad_axis(Bevy::GamepadAxis::LEFT_STICK_Y, 1)).to be_within(0.001).of(
        gamepads[1].axis(Bevy::GamepadAxis::LEFT_STICK_Y)
      )
      expect(context.gamepad_left_trigger(1)).to be_within(0.001).of(gamepads[1].left_trigger)

      left_stick = context.gamepad_left_stick(1)
      expect(left_stick.x).not_to eq(0.0)
      expect(left_stick.y).not_to eq(0.0)

      expect(context.gamepad_axis_raw(Bevy::GamepadAxis::LEFT_STICK_X, 99)).to eq(0.0)
      expect(context.gamepad_right_trigger(99)).to eq(0.0)
    end
  end

  describe 'picking helpers' do
    before do
      events.register(Bevy::PickingEvent)
      writer = events.writer(Bevy::PickingEvent)
      writer.send(
        Bevy::PickingEvent.new(
          kind: 'over',
          target_id: 10,
          pointer_id: 'Mouse',
          position: Bevy::Vec2.new(12.0, 24.0)
        )
      )
      writer.send(
        Bevy::PickingEvent.new(
          kind: 'click',
          target_id: 11,
          pointer_id: 'Mouse',
          button: 'Primary',
          position: Bevy::Vec2.new(12.0, 24.0)
        )
      )
    end

    it 'returns picking events and supports kind filtering' do
      expect(context.picking_events.size).to eq(2)
      expect(context.picking_events(:over).map(&:kind)).to eq(['over'])
      expect(context.picking_events(:drag)).to be_empty
    end

    it 'checks whether an entity or id was picked' do
      entity = instance_double(Bevy::Entity, id: 10)
      expect(context.picked?(10)).to be true
      expect(context.picked?(entity, kind: :over)).to be true
      expect(context.picked?(10, kind: :click)).to be false
      expect(context.picked?(999)).to be false
    end
  end
end

RSpec.describe Bevy::App do
  describe '.new' do
    it 'creates an app with world and resources' do
      app = described_class.new
      expect(app.world).to be_a(Bevy::World)
      expect(app.resources).to be_a(Bevy::Resources)
      expect(app.events).to be_a(Bevy::EventRegistry)
    end

    it 'accepts a block for configuration' do
      resource_inserted = false
      _app = described_class.new do |a|
        a.insert_resource(TestResource.new)
        resource_inserted = true
      end
      expect(resource_inserted).to be true
    end
  end

  describe '#add_systems' do
    it 'adds a system to a schedule' do
      app = described_class.new
      app.add_systems(Bevy::Schedule::UPDATE) { |_ctx| }
      app.run_once
    end
  end

  describe '#add_startup_system' do
    it 'adds a startup system' do
      counter = 0
      app = described_class.new
      app.add_startup_system { |_ctx| counter += 1 }
      app.run_once

      expect(counter).to eq(1)
    end
  end

  describe '#add_update_system' do
    it 'adds an update system' do
      counter = 0
      app = described_class.new
      app.add_update_system { |_ctx| counter += 1 }
      app.run_once

      expect(counter).to eq(1)
    end
  end

  describe '#add_event' do
    it 'registers an event type' do
      app = described_class.new
      app.add_event(TestEvent)
      expect(app.events.get_events(TestEvent)).not_to be_nil
    end
  end

  describe '#insert_resource' do
    it 'inserts a resource' do
      app = described_class.new
      app.insert_resource(TestResource.new(counter: 42))
      expect(app.resources.get(TestResource).counter).to eq(42)
    end
  end

  describe '#run_once' do
    it 'runs startup and one update cycle' do
      startup_count = 0
      update_count = 0

      app = described_class.new
      app.add_startup_system { |_ctx| startup_count += 1 }
      app.add_update_system { |_ctx| update_count += 1 }
      app.run_once

      expect(startup_count).to eq(1)
      expect(update_count).to eq(1)
    end
  end

  describe '#update' do
    it 'runs update systems' do
      counter = 0
      app = described_class.new
      app.add_update_system { |_ctx| counter += 1 }
      app.update

      expect(counter).to eq(1)
    end
  end

  describe '#stop' do
    it 'stops the app' do
      app = described_class.new
      app.add_startup_system { |_ctx| }
      app.run_once
      app.stop
      expect(app.running?).to be false
    end
  end

  describe 'system execution order' do
    it 'executes systems in schedule order' do
      order = []

      app = described_class.new
      app.add_systems(Bevy::Schedule::FIRST) { |_ctx| order << :first }
      app.add_systems(Bevy::Schedule::PRE_UPDATE) { |_ctx| order << :pre_update }
      app.add_systems(Bevy::Schedule::UPDATE) { |_ctx| order << :update }
      app.add_systems(Bevy::Schedule::POST_UPDATE) { |_ctx| order << :post_update }
      app.add_systems(Bevy::Schedule::LAST) { |_ctx| order << :last }
      app.update

      expect(order).to eq(%i[first pre_update update post_update last])
    end
  end

  describe 'integration with ECS' do
    it 'allows spawning entities from systems' do
      app = described_class.new

      app.add_startup_system do |ctx|
        ctx.spawn(TestPosition.new(x: 1.0, y: 2.0))
        ctx.spawn(TestPosition.new(x: 3.0, y: 4.0))
      end

      count = 0
      app.add_update_system do |ctx|
        ctx.query(TestPosition) do |_entity, pos|
          count += 1
          expect(pos.x).to be > 0
        end
      end

      app.run_once
      expect(count).to eq(2)
    end
  end

  describe 'integration with resources' do
    it 'allows modifying resources from systems' do
      app = described_class.new
      app.insert_resource(TestResource.new(counter: 0))

      app.add_update_system do |ctx|
        res = ctx.resource(TestResource)
        res.counter += 1
      end

      5.times { app.update }

      expect(app.resources.get(TestResource).counter).to eq(5)
    end
  end

  describe 'integration with events' do
    it 'allows sending and reading events' do
      app = described_class.new
      app.add_event(TestEvent)

      received = []

      app.add_update_system do |ctx|
        writer = ctx.event_writer(TestEvent)
        writer.send(TestEvent.new(message: 'hello'))
      end

      app.add_systems(Bevy::Schedule::POST_UPDATE) do |ctx|
        reader = ctx.event_reader(TestEvent)
        reader.read.each { |e| received << e.message }
      end

      app.update
      expect(received).to include('hello')
    end
  end

  describe 'render gamepad synchronization' do
    let(:render_app) { double('render_app') }

    before do
      allow(render_app).to receive(:pressed_keys).and_return([])
      allow(render_app).to receive(:mouse_position).and_return([0.0, 0.0])
      allow(render_app).to receive(:mouse_button_pressed?).and_return(false)
    end

    it 'syncs gamepad button and axis state from render app' do
      app = described_class.new(render: true)
      allow(render_app).to receive(:gamepads_state).and_return([
                                                            {
                                                              id: 1,
                                                              name: 'Pad One',
                                                              buttons_pressed: [Bevy::GamepadButton::SOUTH],
                                                              axes: {
                                                                Bevy::GamepadAxis::LEFT_STICK_X => 0.5,
                                                                Bevy::GamepadAxis::LEFT_STICK_Y => -0.25
                                                              }
                                                            }
                                                          ])
      app.instance_variable_set(:@render_app, render_app)

      app.send(:sync_input_from_bevy)

      gamepad = app.gamepads.get(1)
      expect(gamepad).not_to be_nil
      expect(gamepad.pressed?(Bevy::GamepadButton::SOUTH)).to be true
      expect(gamepad.just_pressed?(Bevy::GamepadButton::SOUTH)).to be true
      expect(gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_X)).to be_within(0.001).of(0.5)
      expect(gamepad.axis_raw(Bevy::GamepadAxis::LEFT_STICK_Y)).to be_within(0.001).of(-0.25)
    end

    it 'disconnects removed gamepads and tracks button release transitions' do
      app = described_class.new(render: true)
      allow(render_app).to receive(:gamepads_state).and_return(
        [
          {
            id: 1,
            name: 'Pad One',
            buttons_pressed: [Bevy::GamepadButton::SOUTH],
            axes: {}
          }
        ],
        [
          {
            id: 1,
            name: 'Pad One',
            buttons_pressed: [],
            axes: {}
          }
        ],
        []
      )
      app.instance_variable_set(:@render_app, render_app)

      app.send(:sync_input_from_bevy)
      app.send(:sync_input_from_bevy)

      gamepad = app.gamepads.get(1)
      expect(gamepad.pressed?(Bevy::GamepadButton::SOUTH)).to be false
      expect(gamepad.just_released?(Bevy::GamepadButton::SOUTH)).to be true

      app.send(:sync_input_from_bevy)
      expect(app.gamepads.get(1)).to be_nil
    end
  end

  describe 'gamepad rumble forwarding' do
    let(:render_app) { double('render_app') }

    before do
      allow(render_app).to receive(:queue_gamepad_rumble)
    end

    it 'forwards pending rumble requests to render app and clears them' do
      app = described_class.new(render: true)
      app.instance_variable_set(:@render_app, render_app)
      app.gamepads.connect(2)
      gamepad = app.gamepads.get(2)
      gamepad.rumble(Bevy::RumbleRequest.new(strong: 0.8, weak: 0.3, duration: 0.5))

      app.send(:sync_gamepad_rumble_to_bevy)

      expect(render_app).to have_received(:queue_gamepad_rumble).with(2, 0.8, 0.3, 0.5)
      expect(gamepad.pending_rumble).to be_nil
    end

    it 'does not call render app when there is no pending rumble' do
      app = described_class.new(render: true)
      app.instance_variable_set(:@render_app, render_app)
      app.gamepads.connect(3)

      app.send(:sync_gamepad_rumble_to_bevy)

      expect(render_app).not_to have_received(:queue_gamepad_rumble)
    end
  end

  describe 'render picking synchronization' do
    let(:render_app) { double('render_app') }

    before do
      allow(render_app).to receive(:pressed_keys).and_return([])
      allow(render_app).to receive(:mouse_position).and_return([0.0, 0.0])
      allow(render_app).to receive(:mouse_button_pressed?).and_return(false)
      allow(render_app).to receive(:gamepads_state).and_return([])
    end

    it 'imports picking events from render app into the event registry' do
      allow(render_app).to receive(:drain_picking_events).and_return([
                                                                      {
                                                                        kind: 'over',
                                                                        target_id: 77,
                                                                        pointer_id: 'Mouse',
                                                                        position: [10.5, 20.25],
                                                                        camera_id: 5,
                                                                        depth: 1.5,
                                                                        hit_position: [1.0, 2.0, 3.0],
                                                                        hit_normal: [0.0, 0.0, 1.0]
                                                                      },
                                                                      {
                                                                        kind: 'click',
                                                                        target_id: 77,
                                                                        pointer_id: 'Mouse',
                                                                        button: 'Primary',
                                                                        position: [10.5, 20.25]
                                                                      }
                                                                    ])

      app = described_class.new(render: true)
      app.instance_variable_set(:@render_app, render_app)

      app.send(:sync_input_from_bevy)

      reader = app.events.reader(Bevy::PickingEvent)
      events = reader.read
      expect(events.map(&:kind)).to include('over', 'click')

      over_event = events.find { |event| event.kind == 'over' }
      expect(over_event.target_id).to eq(77)
      expect(over_event.pointer_id).to eq('Mouse')
      expect(over_event.position).to be_a(Bevy::Vec2)
      expect(over_event.position.x).to be_within(0.001).of(10.5)
      expect(over_event.position.y).to be_within(0.001).of(20.25)
      expect(over_event.camera_id).to eq(5)
      expect(over_event.depth).to be_within(0.001).of(1.5)
      expect(over_event.hit_position).to be_a(Bevy::Vec3)
      expect(over_event.hit_normal).to be_a(Bevy::Vec3)
    end

    it 'handles empty picking event batches' do
      allow(render_app).to receive(:drain_picking_events).and_return([])

      app = described_class.new(render: true)
      app.instance_variable_set(:@render_app, render_app)

      expect { app.send(:sync_input_from_bevy) }.not_to raise_error
      reader = app.events.reader(Bevy::PickingEvent)
      expect(reader.read).to be_empty
    end
  end
end

RSpec.describe Bevy::Plugin do
  describe '#build' do
    it 'raises NotImplementedError' do
      plugin = described_class.new
      expect { plugin.build(nil) }.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe Bevy::DefaultPlugins do
  describe '#build' do
    it 'inserts default resources' do
      app = Bevy::App.new
      plugin = described_class.new
      plugin.build(app)

      expect(app.resources.get(Bevy::Time)).to be_a(Bevy::Time)
      expect(app.resources.get(Bevy::FixedTime)).to be_a(Bevy::FixedTime)
    end
  end
end

RSpec.describe 'App#add_plugins' do
  it 'adds and builds plugins' do
    app = Bevy::App.new
    app.add_plugins(Bevy::DefaultPlugins.new, Bevy::InputPlugin.new)

    expect(app.resources.get(Bevy::Time)).not_to be_nil
    expect(app.resources.get(Bevy::KeyboardInput)).not_to be_nil
  end
end
