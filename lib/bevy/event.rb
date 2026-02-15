# frozen_string_literal: true

module Bevy
  class EventDSL
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

      def event_name
        name || 'AnonymousEvent'
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

  class Events
    def initialize(event_class)
      @event_class = event_class
      @events = []
      @events_last_frame = []
    end

    def send(event)
      validate_event!(event)
      @events << event
    end

    def read
      @events_last_frame + @events
    end

    def drain
      result = @events.dup
      @events.clear
      result
    end

    def clear
      @events.clear
    end

    def update
      @events_last_frame = @events.dup
      @events.clear
    end

    def empty?
      @events.empty? && @events_last_frame.empty?
    end

    def len
      @events.length + @events_last_frame.length
    end

    private

    def validate_event!(event)
      return if event.is_a?(@event_class)

      raise ArgumentError, "Expected #{@event_class}, got #{event.class}"
    end
  end

  class EventReader
    def initialize(events)
      @events = events
      @cursor = 0
    end

    def read
      all_events = @events.read
      new_events = all_events[@cursor..]
      @cursor = all_events.length
      new_events || []
    end

    def is_empty?
      @events.read.length <= @cursor
    end

    def len
      [@events.read.length - @cursor, 0].max
    end

    def clear
      @cursor = @events.read.length
    end
  end

  class EventWriter
    def initialize(events)
      @events = events
    end

    def send(event)
      @events.send(event)
    end

    def send_batch(events)
      events.each { |e| @events.send(e) }
    end

    def send_default
      @events.send(@events.instance_variable_get(:@event_class).new)
    end
  end

  class EventRegistry
    def initialize
      @events = {}
      @readers = {}
    end

    def register(event_class)
      type_name = event_class_name(event_class)
      @events[type_name] ||= Events.new(event_class)
    end

    def get_events(event_class)
      type_name = event_class_name(event_class)
      @events[type_name]
    end

    def reader(event_class)
      type_name = event_class_name(event_class)
      events = @events[type_name]
      return nil unless events

      @readers[type_name] ||= EventReader.new(events)
    end

    def writer(event_class)
      type_name = event_class_name(event_class)
      events = @events[type_name]
      return nil unless events

      EventWriter.new(events)
    end

    def update_all
      @events.each_value(&:update)
    end

    def clear_all
      @events.each_value(&:clear)
    end

    private

    def event_class_name(event_class)
      case event_class
      when Class
        event_class.respond_to?(:event_name) ? event_class.event_name : event_class.name
      when String
        event_class
      else
        raise ArgumentError, 'Expected Class or String'
      end
    end
  end

  class PickingEvent < EventDSL
    attribute :kind, :string, default: ''
    attribute :target_id, :integer, default: 0
    attribute :pointer_id, :string, default: ''
    attribute :button, :string, default: nil
    attribute :position, :vec2, default: -> { Vec2.zero }
    attribute :camera_id, :integer, default: nil
    attribute :depth, :float, default: nil
    attribute :hit_position, :vec3, default: nil
    attribute :hit_normal, :vec3, default: nil
  end
end
