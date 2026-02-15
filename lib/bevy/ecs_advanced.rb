# frozen_string_literal: true

module Bevy
  class Changed
    attr_reader :component_type

    def initialize(component_type)
      @component_type = component_type
    end

    def type_name
      'Changed'
    end
  end

  class Added
    attr_reader :component_type

    def initialize(component_type)
      @component_type = component_type
    end

    def type_name
      'Added'
    end
  end

  class With
    attr_reader :component_types

    def initialize(*component_types)
      @component_types = component_types
    end

    def type_name
      'With'
    end
  end

  class Without
    attr_reader :component_types

    def initialize(*component_types)
      @component_types = component_types
    end

    def type_name
      'Without'
    end
  end

  class Or
    attr_reader :filters

    def initialize(*filters)
      @filters = filters
    end

    def type_name
      'Or'
    end
  end

  class ChangeTrackers
    attr_reader :entity, :component_type

    def initialize(entity:, component_type:)
      @entity = entity
      @component_type = component_type
      @added_tick = 0
      @changed_tick = 0
      @last_run = 0
    end

    def is_added?(current_tick)
      @added_tick > @last_run && @added_tick <= current_tick
    end

    def is_changed?(current_tick)
      @changed_tick > @last_run && @changed_tick <= current_tick
    end

    def set_added(tick)
      @added_tick = tick
    end

    def set_changed(tick)
      @changed_tick = tick
    end

    def update_last_run(tick)
      @last_run = tick
    end

    def type_name
      'ChangeTrackers'
    end
  end

  class ComponentTracker
    def initialize
      @trackers = {}
      @current_tick = 0
    end

    def tick
      @current_tick += 1
    end

    def current_tick
      @current_tick
    end

    def track_add(entity, component_type)
      key = [entity, component_type]
      @trackers[key] ||= ChangeTrackers.new(entity: entity, component_type: component_type)
      @trackers[key].set_added(@current_tick)
    end

    def track_change(entity, component_type)
      key = [entity, component_type]
      @trackers[key] ||= ChangeTrackers.new(entity: entity, component_type: component_type)
      @trackers[key].set_changed(@current_tick)
    end

    def added?(entity, component_type)
      key = [entity, component_type]
      tracker = @trackers[key]
      tracker&.is_added?(@current_tick) || false
    end

    def changed?(entity, component_type)
      key = [entity, component_type]
      tracker = @trackers[key]
      tracker&.is_changed?(@current_tick) || false
    end

    def type_name
      'ComponentTracker'
    end
  end

  class SystemSet
    attr_reader :name, :systems

    def initialize(name)
      @name = name
      @systems = []
      @run_condition = nil
    end

    def add_system(system)
      @systems << system
      self
    end

    def run_if(&condition)
      @run_condition = condition
      self
    end

    def should_run?(context)
      return true unless @run_condition

      @run_condition.call(context)
    end

    def type_name
      'SystemSet'
    end
  end

  class RunCondition
    def self.resource_exists(resource_type)
      ->(ctx) { ctx.has_resource?(resource_type) }
    end

    def self.resource_equals(resource_type, value)
      ->(ctx) { ctx.get_resource(resource_type) == value }
    end

    def self.state_equals(state_type, value)
      ->(ctx) { ctx.get_state(state_type) == value }
    end

    def self.in_state(state)
      ->(ctx) { ctx.current_state == state }
    end

    def self.run_once
      ran = false
      lambda do |_ctx|
        return false if ran

        ran = true
        true
      end
    end

    def self.not(condition)
      ->(ctx) { !condition.call(ctx) }
    end

    def self.and(cond1, cond2)
      ->(ctx) { cond1.call(ctx) && cond2.call(ctx) }
    end

    def self.or(cond1, cond2)
      ->(ctx) { cond1.call(ctx) || cond2.call(ctx) }
    end
  end

  class Commands
    def initialize(world)
      @world = world
      @command_queue = []
    end

    def spawn(*components)
      entity = @world.spawn_entity(*components)
      EntityCommands.new(entity, @world)
    end

    def entity(entity)
      EntityCommands.new(entity, @world)
    end

    def despawn(entity)
      @command_queue << [:despawn, entity]
      self
    end

    def insert_resource(resource)
      @command_queue << [:insert_resource, resource]
      self
    end

    def remove_resource(resource_type)
      @command_queue << [:remove_resource, resource_type]
      self
    end

    def apply
      @command_queue.each do |cmd, *args|
        case cmd
        when :despawn
          @world.despawn(args[0])
        when :insert_resource
          @world.insert_resource(args[0])
        when :remove_resource
          @world.remove_resource(args[0])
        end
      end
      @command_queue = []
    end

    def type_name
      'Commands'
    end
  end

  class EntityCommands
    def initialize(entity, world)
      @entity = entity
      @world = world
    end

    def insert(*components)
      components.each do |component|
        @world.insert_component(@entity, component)
      end
      self
    end

    def remove(component_type)
      @world.remove_component(@entity, component_type)
      self
    end

    def despawn
      @world.despawn(@entity)
    end

    def despawn_recursive
      DespawnRecursive.despawn(@world, @entity)
    end

    def id
      @entity
    end

    def type_name
      'EntityCommands'
    end
  end
end
