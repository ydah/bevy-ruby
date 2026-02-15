# frozen_string_literal: true

module Bevy
  class SystemBuilder
    attr_reader :name, :schedule, :run_conditions, :ordering

    def initialize(name = nil)
      @name = name || "system_#{object_id}"
      @schedule = Schedule::UPDATE
      @run_conditions = []
      @ordering = { before: [], after: [] }
      @proc = nil
    end

    def in_schedule(schedule)
      @schedule = schedule
      self
    end

    def run_if(&condition)
      @run_conditions << condition
      self
    end

    def before(system_name)
      @ordering[:before] << system_name
      self
    end

    def after(system_name)
      @ordering[:after] << system_name
      self
    end

    def with_block(&block)
      @proc = block
      self
    end

    def build
      System.new(
        name: @name,
        schedule: @schedule,
        run_conditions: @run_conditions,
        ordering: @ordering,
        &@proc
      )
    end
  end

  class SystemRunner
    def initialize(systems)
      @systems = systems
    end

    def run(context)
      sorted_systems.each do |system|
        next unless should_run?(system, context)

        system.run(context)
      end
    end

    private

    def sorted_systems
      @systems
    end

    def should_run?(system, context)
      return true if system.run_conditions.empty?

      system.run_conditions.all? { |cond| cond.call(context) }
    end
  end

  class ParallelSystemConfig
    attr_reader :systems

    def initialize
      @systems = []
    end

    def add(system)
      @systems << system
      self
    end
  end

  module SystemParam
    class Query
      attr_reader :component_types, :filters

      def initialize(*component_types)
        @component_types = component_types
        @filters = { with: [], without: [], changed: [], added: [] }
      end

      def with(*components)
        @filters[:with].concat(components)
        self
      end

      def without(*components)
        @filters[:without].concat(components)
        self
      end

      def changed(*components)
        @filters[:changed].concat(components)
        self
      end

      def added(*components)
        @filters[:added].concat(components)
        self
      end

      def each(world, &block)
        world.each(*@component_types, &block)
      end
    end

    class Res
      attr_reader :resource_type

      def initialize(resource_type)
        @resource_type = resource_type
      end

      def get(resources)
        resources.get(@resource_type)
      end
    end

    class ResMut < Res
    end

    class Commands
      def initialize(world)
        @world = world
        @pending = []
      end

      def spawn(*components)
        @pending << [:spawn, components]
        self
      end

      def despawn(entity)
        @pending << [:despawn, entity]
        self
      end

      def insert(entity, *components)
        @pending << [:insert, entity, components]
        self
      end

      def remove(entity, *component_types)
        @pending << [:remove, entity, component_types]
        self
      end

      def apply
        @pending.each do |command|
          case command[0]
          when :spawn
            @world.spawn_entity(*command[1])
          when :despawn
            @world.despawn(command[1])
          when :insert
            command[2].each { |c| @world.add_component(command[1], c) }
          when :remove
            command[2].each { |t| @world.remove_component(command[1], t) }
          end
        end
        @pending.clear
      end
    end

    class EventReader
      attr_reader :event_type

      def initialize(event_type)
        @event_type = event_type
      end

      def read(events)
        events.reader(@event_type)
      end
    end

    class EventWriter
      attr_reader :event_type

      def initialize(event_type)
        @event_type = event_type
      end

      def get(events)
        events.writer(@event_type)
      end
    end
  end
end
