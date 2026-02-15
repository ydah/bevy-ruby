# frozen_string_literal: true

module Bevy
  class TypeRegistry
    attr_reader :registrations

    def initialize
      @registrations = {}
    end

    def register(type)
      type_name = extract_type_name(type)
      @registrations[type_name] = TypeRegistration.new(type)
      self
    end

    def get(type_name)
      @registrations[type_name]
    end

    def registered?(type_name)
      @registrations.key?(type_name)
    end

    def type_names
      @registrations.keys
    end

    def type_name
      'TypeRegistry'
    end

    private

    def extract_type_name(type)
      if type.is_a?(Class)
        instance = type.allocate rescue nil
        if instance && instance.respond_to?(:type_name)
          instance.type_name
        else
          type.name.split('::').last
        end
      else
        type.respond_to?(:type_name) ? type.type_name : type.to_s
      end
    end
  end

  class TypeRegistration
    attr_reader :type, :type_info, :data

    def initialize(type)
      @type = type
      @type_info = build_type_info(type)
      @data = {}
    end

    def type_name
      'TypeRegistration'
    end

    def insert_data(key, value)
      @data[key] = value
      self
    end

    def get_data(key)
      @data[key]
    end

    def type_name
      'TypeRegistration'
    end

    private

    def build_type_info(type)
      if type.is_a?(Class)
        StructInfo.new(type)
      else
        ValueInfo.new(type)
      end
    end
  end

  class TypeInfo
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def type_name
      'TypeInfo'
    end
  end

  class StructInfo < TypeInfo
    attr_reader :fields

    def initialize(type)
      name = if type.is_a?(Class)
               instance = type.allocate rescue nil
               if instance && instance.respond_to?(:type_name)
                 instance.type_name
               else
                 type.name.split('::').last
               end
             else
               type.respond_to?(:type_name) ? type.type_name : type.to_s
             end
      super(name)
      @fields = extract_fields(type)
    end

    def field(name)
      @fields.find { |f| f.name == name }
    end

    def field_count
      @fields.size
    end

    def type_name
      'StructInfo'
    end

    private

    def extract_fields(type)
      fields = []
      if type.respond_to?(:attributes)
        type.attributes.each do |name, config|
          fields << FieldInfo.new(name: name, type: config[:type])
        end
      elsif type.is_a?(Class)
        type.instance_methods(false).each do |method|
          next if method.to_s.end_with?('=')
          next if %i[initialize type_name to_h to_native].include?(method)

          fields << FieldInfo.new(name: method, type: :unknown)
        end
      end
      fields
    end
  end

  class ValueInfo < TypeInfo
    def type_name
      'ValueInfo'
    end
  end

  class FieldInfo
    attr_reader :name, :type, :default

    def initialize(name:, type:, default: nil)
      @name = name.to_sym
      @type = type
      @default = default
    end

    def type_name
      'FieldInfo'
    end
  end

  module Reflect
    def get_field(name)
      if respond_to?(name)
        send(name)
      elsif instance_variable_defined?(:"@#{name}")
        instance_variable_get(:"@#{name}")
      end
    end

    def set_field(name, value)
      setter = :"#{name}="
      if respond_to?(setter)
        send(setter, value)
      elsif instance_variable_defined?(:"@#{name}")
        instance_variable_set(:"@#{name}", value)
      end
    end

    def field_names
      instance_variables.map { |v| v.to_s.delete('@').to_sym }
    end

    def apply(other)
      other.field_names.each do |name|
        set_field(name, other.get_field(name))
      end
      self
    end

    def clone_value
      clone
    end
  end

  class ReflectComponent
    attr_reader :component_type

    def initialize(component_type)
      @component_type = component_type
    end

    def insert(entity, component, world)
      world.insert_component(entity, component)
    end

    def remove(entity, world)
      world.remove_component(entity, @component_type)
    end

    def reflect(entity, world)
      world.get_component(entity, @component_type)
    end

    def type_name
      'ReflectComponent'
    end
  end

  class ReflectResource
    attr_reader :resource_type

    def initialize(resource_type)
      @resource_type = resource_type
    end

    def insert(resource, world)
      world.insert_resource(resource)
    end

    def remove(world)
      world.remove_resource(@resource_type)
    end

    def reflect(world)
      world.get_resource(@resource_type)
    end

    def type_name
      'ReflectResource'
    end
  end

  class DynamicStruct
    include Reflect

    def initialize(type_name:, fields: {})
      @_type_name = type_name
      fields.each do |name, value|
        instance_variable_set(:"@#{name}", value)
        define_singleton_method(name) { instance_variable_get(:"@#{name}") }
        define_singleton_method(:"#{name}=") { |v| instance_variable_set(:"@#{name}", v) }
      end
    end

    def type_name
      @_type_name
    end

    def to_h
      field_names.reject { |n| n == :_type_name }.to_h { |n| [n, get_field(n)] }
    end
  end

  class FromReflect
    def self.from_reflect(reflected)
      return nil unless reflected

      case reflected
      when Hash
        DynamicStruct.new(type_name: 'Anonymous', fields: reflected)
      when DynamicStruct
        reflected.clone_value
      else
        reflected.respond_to?(:clone_value) ? reflected.clone_value : reflected.dup
      end
    end
  end

  class ReflectSerializer
    def self.serialize(value)
      case value
      when nil, true, false, Integer, Float, String, Symbol
        value
      when Array
        value.map { |v| serialize(v) }
      when Hash
        value.transform_values { |v| serialize(v) }
      when Reflect
        { _type: value.type_name }.merge(
          value.field_names.to_h { |n| [n, serialize(value.get_field(n))] }
        )
      else
        value.respond_to?(:to_h) ? serialize(value.to_h) : value.to_s
      end
    end
  end

  class ReflectDeserializer
    def initialize(registry)
      @registry = registry
    end

    def deserialize(data)
      case data
      when Hash
        if data[:_type]
          type_name = data[:_type]
          registration = @registry.get(type_name)
          if registration
            fields = data.reject { |k, _| k == :_type }
            DynamicStruct.new(type_name: type_name, fields: fields)
          else
            DynamicStruct.new(type_name: type_name, fields: data.reject { |k, _| k == :_type })
          end
        else
          data.transform_values { |v| deserialize(v) }
        end
      when Array
        data.map { |v| deserialize(v) }
      else
        data
      end
    end

    def type_name
      'ReflectDeserializer'
    end
  end

  class TypePath
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def module_name
      parts = @path.split('::')
      parts.size > 1 ? parts[0..-2].join('::') : nil
    end

    def type_ident
      @path.split('::').last
    end

    def full_path
      @path
    end

    def type_name
      'TypePath'
    end
  end
end
