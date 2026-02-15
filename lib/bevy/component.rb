# frozen_string_literal: true

module Bevy
  class ComponentDSL
    class << self
      def attribute(name, type, default: nil)
        @attributes ||= {}
        @attributes[name] = { type: type, default: default }

        define_method(name) do
          @data[name]
        end

        define_method(:"#{name}=") do |value|
          @data[name] = value
        end
      end

      def attributes
        @attributes ||= {}
      end

      def component_name
        name.split('::').last
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@attributes, attributes.dup)
      end
    end

    def initialize(**attrs)
      @data = {}

      self.class.attributes.each do |name, config|
        default = config[:default]
        default_value = default.respond_to?(:call) ? default.call : default
        @data[name] = attrs.fetch(name, default_value)
      end
    end

    def type_name
      self.class.component_name
    end

    def to_native
      native = Bevy::Component.new(type_name)
      @data.each do |key, value|
        next unless native_convertible?(value)

        native[key.to_s] = value
      end
      native
    end

    def to_h
      @data.dup
    end

    def [](name)
      @data[name.to_sym]
    end

    def []=(name, value)
      @data[name.to_sym] = value
    end

    def update_from_native(native)
      @data.each_key do |key|
        @data[key] = native[key.to_s]
      end
      self
    end

    private

    def native_convertible?(value)
      case value
      when NilClass, TrueClass, FalseClass, Integer, Float, String, Symbol
        true
      when Array
        value.all? { |v| native_convertible?(v) }
      when Hash
        value.all? { |k, v| native_convertible?(k) && native_convertible?(v) }
      else
        false
      end
    end
  end
end
