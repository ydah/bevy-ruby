# frozen_string_literal: true

module Bevy
  module Schedule
    STARTUP = :startup
    FIRST = :first
    PRE_UPDATE = :pre_update
    UPDATE = :update
    POST_UPDATE = :post_update
    LAST = :last
    FIXED_UPDATE = :fixed_update
  end

  class System
    attr_reader :name, :schedule, :proc

    def initialize(name: nil, schedule: Schedule::UPDATE, &block)
      @name = name || "anonymous_system_#{object_id}"
      @schedule = schedule
      @proc = block
    end

    def run(context)
      @proc.call(context)
    end
  end

  class SystemSet
    attr_reader :name, :systems

    def initialize(name)
      @name = name
      @systems = []
    end

    def add(system)
      @systems << system
    end

    def run_all(context)
      @systems.each { |s| s.run(context) }
    end
  end

  class SystemContext
    attr_reader :world, :resources, :events, :time, :keyboard, :mouse, :gamepads, :app

    def initialize(world:, resources:, events:, time:, keyboard:, mouse:, gamepads:, app:, render_app: nil)
      @world = world
      @resources = resources
      @events = events
      @time = time
      @keyboard = keyboard
      @mouse = mouse
      @gamepads = gamepads
      @app = app
      @render_app = render_app
    end

    def delta
      @time.delta_seconds
    end

    def delta_seconds
      @time.delta_seconds
    end

    def elapsed
      @time.elapsed_seconds
    end

    def resource(resource_class)
      @resources.get(resource_class)
    end

    def insert_resource(resource)
      @resources.insert(resource)
    end

    def event_reader(event_class)
      @events.reader(event_class)
    end

    def event_writer(event_class)
      @events.writer(event_class)
    end

    def spawn(*components)
      @world.spawn_entity(*components)
    end

    def despawn(entity)
      @world.despawn(entity)
    end

    def query(*component_classes, &block)
      @world.each(*component_classes, &block)
    end

    def key_pressed?(key)
      if @render_app
        @render_app.key_pressed?(key)
      else
        @keyboard.pressed?(key)
      end
    end

    def key_just_pressed?(key)
      if @render_app
        @render_app.key_just_pressed?(key)
      else
        @keyboard.just_pressed?(key)
      end
    end

    def mouse_pressed?(button)
      button_str = button.to_s.upcase
      if @render_app
        @render_app.mouse_button_pressed?(button_str)
      else
        @mouse.pressed?(button_str)
      end
    end

    def mouse_just_pressed?(button)
      button_str = button.to_s.upcase
      if @render_app
        @render_app.mouse_button_just_pressed?(button_str)
      else
        @mouse.just_pressed?(button_str)
      end
    end

    def mouse_position
      if @render_app
        pos = @render_app.mouse_position
        Vec2.new(pos[0], pos[1])
      else
        @mouse.position
      end
    end

    def gamepad(gamepad_id = nil)
      if gamepad_id
        @gamepads.get(gamepad_id)
      else
        @gamepads.first
      end
    end

    def gamepad_connected?(gamepad_id)
      @gamepads.connected?(gamepad_id)
    end

    def any_gamepad_connected?
      @gamepads.any?
    end

    def connected_gamepad_ids
      @gamepads.connected_ids
    end

    def gamepad_pressed?(button, gamepad_id = nil)
      button_name = button.to_s
      if gamepad_id
        pad = gamepad(gamepad_id)
        pad ? pad.pressed?(button_name) : false
      else
        @gamepads.any_pressed?(button_name)
      end
    end

    def gamepad_just_pressed?(button, gamepad_id = nil)
      button_name = button.to_s
      if gamepad_id
        pad = gamepad(gamepad_id)
        pad ? pad.just_pressed?(button_name) : false
      else
        @gamepads.any_just_pressed?(button_name)
      end
    end

    def gamepad_just_released?(button, gamepad_id = nil)
      button_name = button.to_s
      if gamepad_id
        pad = gamepad(gamepad_id)
        pad ? pad.just_released?(button_name) : false
      else
        @gamepads.any_just_released?(button_name)
      end
    end

    def gamepad_axis(axis, gamepad_id = nil)
      pad = gamepad(gamepad_id)
      return 0.0 unless pad

      pad.axis(axis.to_s)
    end

    def gamepad_axis_raw(axis, gamepad_id = nil)
      pad = gamepad(gamepad_id)
      return 0.0 unless pad

      pad.axis_raw(axis.to_s)
    end

    def gamepad_left_stick(gamepad_id = nil)
      pad = gamepad(gamepad_id)
      pad ? pad.left_stick : Vec2.zero
    end

    def gamepad_right_stick(gamepad_id = nil)
      pad = gamepad(gamepad_id)
      pad ? pad.right_stick : Vec2.zero
    end

    def gamepad_left_trigger(gamepad_id = nil)
      pad = gamepad(gamepad_id)
      pad ? pad.left_trigger : 0.0
    end

    def gamepad_right_trigger(gamepad_id = nil)
      pad = gamepad(gamepad_id)
      pad ? pad.right_trigger : 0.0
    end

    def picking_events(kind = nil)
      event_list = @events.get_events(PickingEvent)
      return [] unless event_list

      events = event_list.read
      return events if kind.nil?

      kind_name = kind.to_s
      events.select { |event| event.kind == kind_name }
    end

    def picked?(entity_or_id, kind: nil)
      target_id = entity_or_id.respond_to?(:id) ? entity_or_id.id : entity_or_id
      picking_events(kind).any? { |event| event.target_id == target_id.to_i }
    end

    def camera_position
      if @render_app
        pos = @render_app.camera_position
        Vec3.new(pos[0], pos[1], pos[2])
      else
        Vec3.new(0.0, 0.0, 0.0)
      end
    end

    def set_camera_position(position)
      return unless @render_app

      if position.is_a?(Vec3)
        @render_app.set_camera_position(position.x, position.y, position.z)
      elsif position.is_a?(Vec2)
        @render_app.set_camera_position(position.x, position.y, 0.0)
      elsif position.is_a?(Array)
        @render_app.set_camera_position(position[0] || 0.0, position[1] || 0.0, position[2] || 0.0)
      end
    end

    def camera_scale
      @render_app ? @render_app.camera_scale : 1.0
    end

    def set_camera_scale(scale)
      @render_app&.set_camera_scale(scale)
    end

    alias camera_zoom camera_scale
    alias set_camera_zoom set_camera_scale
  end

  class App
    attr_reader :world, :resources, :events, :render_app, :time, :fixed_time, :keyboard, :mouse, :gamepads

    GAMEPAD_BUTTONS = [
      GamepadButton::SOUTH,
      GamepadButton::EAST,
      GamepadButton::NORTH,
      GamepadButton::WEST,
      GamepadButton::LEFT_TRIGGER,
      GamepadButton::LEFT_TRIGGER2,
      GamepadButton::RIGHT_TRIGGER,
      GamepadButton::RIGHT_TRIGGER2,
      GamepadButton::SELECT,
      GamepadButton::START,
      GamepadButton::MODE,
      GamepadButton::LEFT_THUMB,
      GamepadButton::RIGHT_THUMB,
      GamepadButton::DPAD_UP,
      GamepadButton::DPAD_DOWN,
      GamepadButton::DPAD_LEFT,
      GamepadButton::DPAD_RIGHT
    ].freeze

    GAMEPAD_AXES = [
      GamepadAxis::LEFT_STICK_X,
      GamepadAxis::LEFT_STICK_Y,
      GamepadAxis::RIGHT_STICK_X,
      GamepadAxis::RIGHT_STICK_Y,
      GamepadAxis::LEFT_TRIGGER,
      GamepadAxis::RIGHT_TRIGGER
    ].freeze

    def initialize(render: false, window: {})
      @world = World.new
      @resources = Resources.new
      @events = EventRegistry.new
      @events.register(PickingEvent)
      @systems = Hash.new { |h, k| h[k] = [] }
      @plugins = []
      @running = false
      @time = Time.new
      @fixed_time = FixedTime.new
      @keyboard = KeyboardInput.new
      @mouse = MouseInput.new
      @gamepads = Gamepads.new
      @render_enabled = render
      @window_config = window
      @render_app = nil

      yield self if block_given?
    end

    def render_enabled?
      @render_enabled
    end

    def add_plugins(*plugins)
      plugins.each do |plugin|
        @plugins << plugin
        plugin.build(self) if plugin.respond_to?(:build)
      end
      self
    end

    def add_systems(schedule, *systems, &block)
      if block_given?
        system = System.new(schedule: schedule, &block)
        @systems[schedule] << system
      else
        systems.each do |system|
          @systems[schedule] << system
        end
      end
      self
    end

    def add_startup_system(&block)
      add_systems(Schedule::STARTUP, &block)
    end

    def add_update_system(&block)
      add_systems(Schedule::UPDATE, &block)
    end

    def add_event(event_class)
      @events.register(event_class)
      self
    end

    def insert_resource(resource)
      @resources.insert(resource)
      self
    end

    def run
      @running = true
      run_startup_systems
      @render_enabled ? run_render_loop : run_main_loop
    end

    def run_once
      @running = true
      run_startup_systems
      update
      @running = false
    end

    def update
      @time.update
      accumulate_fixed_time

      run_schedule(Schedule::FIRST)
      run_schedule(Schedule::PRE_UPDATE)
      run_fixed_update
      run_schedule(Schedule::UPDATE)
      run_schedule(Schedule::POST_UPDATE)
      run_schedule(Schedule::LAST)

      clear_input_state
      @events.update_all
    end

    def stop
      @running = false
      @render_app&.stop!
    end

    def running?
      @running
    end

    private

    def run_startup_systems
      context = build_context
      @systems[Schedule::STARTUP].each { |s| s.run(context) }
    end

    def run_main_loop
      while @running
        update
        sleep(0.001)
      end
    end

    def run_render_loop
      @render_app = RenderApp.new(@window_config)
      @render_app.initialize!

      @render_app.run do
        sync_input_from_bevy
        update
        sync_sprites_to_bevy
      end

      @running = false
    end

    def sync_input_from_bevy
      return unless @render_app

      clear_input_state

      @keyboard.reset
      @render_app.pressed_keys.each do |key|
        @keyboard.press(key)
      end

      @render_app.pressed_keys.each do |key|
        @keyboard.set_just_pressed(key) unless @keyboard.was_pressed_last_frame?(key)
      end

      mouse_pos = @render_app.mouse_position
      @mouse.set_position(mouse_pos[0], mouse_pos[1]) if mouse_pos

      @mouse.reset
      %w[LEFT RIGHT MIDDLE].each do |button|
        @mouse.press(button) if @render_app.mouse_button_pressed?(button)
      end

      sync_gamepads_from_bevy
      sync_picking_events_from_bevy
    end

    def sync_sprites_to_bevy
      return unless @render_app

      @world.despawned_entity_ids.each do |entity_id|
        @render_app.remove_sprite(entity_id)
        @render_app.remove_text(entity_id)
        @render_app.remove_mesh(entity_id)
      end
      @world.clear_despawned_entity_ids

      @world.each(Sprite, Transform) do |entity, sprite, transform|
        @render_app.sync_sprite(
          entity.id,
          sprite.to_sync_hash,
          transform.to_sync_hash
        )
      end

      @world.each(Text2d, Transform) do |entity, text, transform|
        @render_app.sync_text(
          entity.id,
          text.to_sync_hash,
          transform.to_sync_hash
        )
      end

      sync_mesh_shapes
      sync_gamepad_rumble_to_bevy
    end

    def sync_mesh_shapes
      return unless @render_app

      @world.mesh_components.each do |entity_id, meshes|
        entity = @world.mesh_entities[entity_id]
        next unless entity

        begin
          next unless @world.has?(entity, Transform)

          transform = @world.get_component(entity, Transform)

          meshes.each_value do |mesh|
            @render_app.sync_mesh(
              entity_id,
              mesh.to_mesh_data,
              transform.to_sync_hash
            )
          end
        rescue StandardError
          next
        end
      end
    end

    def sync_gamepads_from_bevy
      return unless @render_app.respond_to?(:gamepads_state)

      gamepad_states = @render_app.gamepads_state
      connected_ids = []

      gamepad_states.each do |state|
        id = state[:id] || state['id']
        next if id.nil?

        name = state[:name] || state['name'] || "Gamepad #{id}"
        connected_ids << id

        gamepad = @gamepads.get(id)
        gamepad ||= @gamepads.connect(id, name: name)

        pressed_buttons = Array(state[:buttons_pressed] || state['buttons_pressed']).map(&:to_s)
        axes = state[:axes] || state['axes'] || {}

        buttons_to_sync = (GAMEPAD_BUTTONS + gamepad.known_buttons + pressed_buttons).uniq
        buttons_to_sync.each do |button|
          value = pressed_buttons.include?(button) ? 1.0 : 0.0
          gamepad.set_button_value(button, value)
        end

        axes_to_sync = (GAMEPAD_AXES + gamepad.known_axes + axes.keys.map(&:to_s)).uniq
        axes_to_sync.each do |axis|
          value = axes[axis] || axes[axis.to_sym] || 0.0
          gamepad.set_axis(axis, value.to_f)
        end
      end

      (@gamepads.connected_ids - connected_ids).each do |id|
        @gamepads.disconnect(id)
      end
    end

    def sync_gamepad_rumble_to_bevy
      return unless @render_app.respond_to?(:queue_gamepad_rumble)

      @gamepads.each do |gamepad|
        rumble = gamepad.pending_rumble
        next unless rumble

        @render_app.queue_gamepad_rumble(
          gamepad.id,
          rumble.strong_magnitude,
          rumble.weak_magnitude,
          rumble.duration
        )
        gamepad.clear_pending_rumble
      end
    end

    def sync_picking_events_from_bevy
      return unless @render_app.respond_to?(:drain_picking_events)

      writer = @events.writer(PickingEvent)
      unless writer
        @events.register(PickingEvent)
        writer = @events.writer(PickingEvent)
      end
      return unless writer

      Array(@render_app.drain_picking_events).each do |event_data|
        kind = event_data[:kind] || event_data['kind']
        target_id = event_data[:target_id] || event_data['target_id']
        pointer_id = event_data[:pointer_id] || event_data['pointer_id']
        button = event_data[:button] || event_data['button']
        position = event_data[:position] || event_data['position']
        camera_id = event_data[:camera_id] || event_data['camera_id']
        depth = event_data[:depth] || event_data['depth']
        hit_position = event_data[:hit_position] || event_data['hit_position']
        hit_normal = event_data[:hit_normal] || event_data['hit_normal']

        writer.send(
          PickingEvent.new(
            kind: kind.to_s,
            target_id: target_id.to_i,
            pointer_id: pointer_id.to_s,
            button: button&.to_s,
            position: to_vec2(position),
            camera_id: camera_id.nil? ? nil : camera_id.to_i,
            depth: depth.nil? ? nil : depth.to_f,
            hit_position: to_vec3_or_nil(hit_position),
            hit_normal: to_vec3_or_nil(hit_normal)
          )
        )
      end
    end

    def run_schedule(schedule)
      context = build_context
      @systems[schedule].each { |s| s.run(context) }
    end

    def run_fixed_update
      context = build_context
      @systems[Schedule::FIXED_UPDATE].each { |s| s.run(context) } while @fixed_time.expend
    end

    def accumulate_fixed_time
      @fixed_time.accumulate(@time.delta_seconds)
    end

    def build_context
      SystemContext.new(
        world: @world,
        resources: @resources,
        events: @events,
        time: @time,
        keyboard: @keyboard,
        mouse: @mouse,
        gamepads: @gamepads,
        app: self,
        render_app: @render_app
      )
    end

    def clear_input_state
      @keyboard.clear_just_pressed
      @mouse.clear_just_pressed
      @gamepads.clear_just_pressed
    end

    def to_vec2(value)
      return value if value.is_a?(Vec2)
      return Vec2.new(value[0].to_f, value[1].to_f) if value.is_a?(Array)

      Vec2.zero
    end

    def to_vec3_or_nil(value)
      return value if value.is_a?(Vec3)
      return Vec3.new(value[0].to_f, value[1].to_f, value[2].to_f) if value.is_a?(Array)

      nil
    end
  end

  class Plugin
    def build(app)
      raise NotImplementedError, 'Subclasses must implement #build'
    end
  end

  class DefaultPlugins < Plugin
    def build(app)
      app.insert_resource(Time.new)
      app.insert_resource(FixedTime.new)
    end
  end

  class InputPlugin < Plugin
    def build(app)
      app.insert_resource(KeyboardInput.new)
      app.insert_resource(MouseInput.new)
      app.insert_resource(Gamepads.new)
    end
  end
end
