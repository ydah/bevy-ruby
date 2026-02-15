# frozen_string_literal: true

module Bevy
  class ResourceDSL
    class << self
      def attribute(name, type, default: nil)
        @attributes ||= {}
        @attributes[name] = { type: type, default: default }

        define_method(name) { @data[name] }
        define_method(:"#{name}=") { |value| @data[name] = value }
      end

      def attributes
        @attributes ||= {}
      end

      def resource_name
        name || 'AnonymousResource'
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@attributes, attributes.dup)
      end
    end

    def initialize(**attrs)
      @data = {}
      self.class.attributes.each do |attr_name, config|
        default = config[:default]
        default_value = default.respond_to?(:call) ? default.call : default
        @data[attr_name] = attrs.fetch(attr_name, default_value)
      end
    end

    def to_h
      @data.dup
    end
  end

  class Resources
    def initialize
      @resources = {}
    end

    def insert(resource)
      type_name = resource_type_name(resource)
      @resources[type_name] = resource
    end

    def get(resource_class)
      type_name = resource_class_name(resource_class)
      @resources[type_name]
    end

    def get_or_insert(resource_class, &block)
      type_name = resource_class_name(resource_class)
      @resources[type_name] ||= block.call
    end

    def remove(resource_class)
      type_name = resource_class_name(resource_class)
      @resources.delete(type_name)
    end

    def contains?(resource_class)
      type_name = resource_class_name(resource_class)
      @resources.key?(type_name)
    end

    def clear
      @resources.clear
    end

    private

    def resource_type_name(resource)
      case resource
      when ResourceDSL
        resource.class.resource_name
      else
        resource.class.name || 'AnonymousResource'
      end
    end

    def resource_class_name(resource_class)
      case resource_class
      when Class
        resource_class.respond_to?(:resource_name) ? resource_class.resource_name : resource_class.name
      when String
        resource_class
      else
        raise ArgumentError, 'Expected Class or String'
      end
    end
  end

  class Time
    attr_reader :delta, :elapsed, :delta_seconds, :elapsed_seconds, :time_scale

    def initialize
      @start_time = ::Time.now
      @last_update = @start_time
      @delta = 0.0
      @elapsed = 0.0
      @delta_seconds = 0.0
      @elapsed_seconds = 0.0
      @paused = false
      @time_scale = 1.0
    end

    def update
      return if @paused

      now = ::Time.now
      raw_delta = now - @last_update
      @delta_seconds = raw_delta * @time_scale
      @delta = @delta_seconds
      @elapsed_seconds = now - @start_time
      @elapsed = @elapsed_seconds
      @last_update = now
    end

    def pause
      @paused = true
    end

    def unpause
      @paused = false
      @last_update = ::Time.now
    end

    def paused?
      @paused
    end

    def time_scale=(scale)
      @time_scale = scale.clamp(0.0, 10.0)
    end

    def reset
      @start_time = ::Time.now
      @last_update = @start_time
      @delta = 0.0
      @elapsed = 0.0
      @delta_seconds = 0.0
      @elapsed_seconds = 0.0
    end
  end

  class FixedTime
    attr_reader :delta, :overstep, :accumulated, :timestep

    def initialize(timestep: 1.0 / 60.0)
      @timestep = timestep
      @delta = timestep
      @accumulated = 0.0
      @overstep = 0.0
    end

    def timestep=(value)
      @timestep = value.clamp(0.001, 1.0)
      @delta = @timestep
    end

    def accumulate(delta)
      @accumulated += delta
    end

    def expend
      if @accumulated >= @timestep
        @accumulated -= @timestep
        @overstep = @accumulated
        true
      else
        false
      end
    end

    def steps_remaining
      (@accumulated / @timestep).floor
    end
  end
end
