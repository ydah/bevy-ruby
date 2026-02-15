# frozen_string_literal: true

require_relative 'bevy/version'

begin
  require "bevy/#{RUBY_VERSION.to_f}/bevy"
rescue LoadError
  require_relative 'bevy/bevy'
end

require_relative 'bevy/component'
require_relative 'bevy/transform'
require_relative 'bevy/camera'
require_relative 'bevy/material'
require_relative 'bevy/sprite'
require_relative 'bevy/sprite_sheet'
require_relative 'bevy/input'
require_relative 'bevy/audio'
require_relative 'bevy/asset'
require_relative 'bevy/resource'
require_relative 'bevy/event'
require_relative 'bevy/timer'
require_relative 'bevy/shape'
require_relative 'bevy/mesh'
require_relative 'bevy/text'
require_relative 'bevy/text_advanced'
require_relative 'bevy/ui'
require_relative 'bevy/ui_advanced'
require_relative 'bevy/state'
require_relative 'bevy/animation'
require_relative 'bevy/lighting'
require_relative 'bevy/scene'
require_relative 'bevy/gltf'
require_relative 'bevy/physics'
require_relative 'bevy/window'
require_relative 'bevy/shader'
require_relative 'bevy/particle'
require_relative 'bevy/system'
require_relative 'bevy/reflect'
require_relative 'bevy/render_graph'
require_relative 'bevy/gizmos'
require_relative 'bevy/diagnostics'
require_relative 'bevy/visibility'
require_relative 'bevy/skeletal'
require_relative 'bevy/audio_effects'
require_relative 'bevy/ecs_advanced'
require_relative 'bevy/navigation'
require_relative 'bevy/networking'
require_relative 'bevy/hierarchy'
require_relative 'bevy/app'
require_relative 'bevy/plugins/default_plugins'
require_relative 'bevy/plugins/input_plugin'

module Bevy
  class Error < StandardError; end

  class EntityNotFoundError < Error; end

  class ComponentNotFoundError < Error; end

  class ComponentAlreadyExistsError < Error; end

  class ResourceNotFoundError < Error; end

  class ResourceAlreadyExistsError < Error; end

  class SystemError < Error; end

  class InvalidSystemParamError < SystemError; end

  class ConversionError < Error; end

  class InvalidTypeError < ConversionError; end

  class World
    MESH_CLASSES = [
      Mesh::Rectangle, Mesh::Circle, Mesh::RegularPolygon,
      Mesh::Triangle, Mesh::Hexagon, Mesh::Line, Mesh::Ellipse
    ].freeze

    HIERARCHY_CLASSES = [
      Parent, Children, GlobalTransform, Visibility, InheritedVisibility, ViewVisibility
    ].freeze

    def initialize
      @despawned_entity_ids = []
      @mesh_components = {}
      @hierarchy_components = {}
    end

    def spawn_entity(*components)
      mesh_comps, rest = components.partition { |c| mesh_component?(c) }
      hier_comps, native_comps = rest.partition { |c| hierarchy_component?(c) }

      entity = if native_comps.empty?
                 spawn
               else
                 native_components = native_comps.map { |comp| component_to_native(comp) }
                 spawn_with(native_components)
               end

      if mesh_comps.any?
        mesh_entities[entity.id] = entity
        mesh_comps.each do |mesh|
          mesh_components[entity.id] ||= {}
          mesh_components[entity.id][mesh.type_name] = mesh
        end
      end

      if hier_comps.any?
        hierarchy_entities[entity.id] = entity
        hier_comps.each do |hier|
          hierarchy_components[entity.id] ||= {}
          hierarchy_components[entity.id][hier.type_name] = hier
        end
      end

      entity
    end

    def hierarchy_component?(comp)
      HIERARCHY_CLASSES.any? { |klass| comp.is_a?(klass) }
    end

    def hierarchy_components
      @hierarchy_components ||= {}
    end

    def hierarchy_entities
      @hierarchy_entities ||= {}
    end

    def despawn(entity)
      entity_id = entity.id
      despawn_native(entity)
      despawned_entity_ids << entity_id
      mesh_components.delete(entity_id)
      mesh_entities.delete(entity_id)
      hierarchy_components.delete(entity_id)
      hierarchy_entities.delete(entity_id)
      true
    rescue StandardError
      false
    end

    def mesh_component?(comp)
      MESH_CLASSES.any? { |klass| comp.is_a?(klass) }
    end

    def mesh_components
      @mesh_components ||= {}
    end

    def mesh_entities
      @mesh_entities ||= {}
    end

    def despawned_entity_ids
      @despawned_entity_ids ||= []
    end

    def clear_despawned_entity_ids
      @despawned_entity_ids = []
    end

    def insert_component(entity, component)
      if hierarchy_component?(component)
        hierarchy_entities[entity.id] = entity
        hierarchy_components[entity.id] ||= {}
        hierarchy_components[entity.id][component.type_name] = component
      elsif mesh_component?(component)
        mesh_entities[entity.id] = entity
        mesh_components[entity.id] ||= {}
        mesh_components[entity.id][component.type_name] = component
      else
        native = component_to_native(component)
        insert(entity, native)
      end
    end

    def remove_component(entity, component_class)
      type_name = component_type_name(component_class)

      if HIERARCHY_CLASSES.include?(component_class)
        hier = hierarchy_components[entity.id]
        return nil unless hier

        return hier.delete(type_name)
      end

      if MESH_CLASSES.include?(component_class)
        mesh = mesh_components[entity.id]
        return nil unless mesh

        return mesh.delete(type_name)
      end

      begin
        remove(entity, type_name)
      rescue StandardError
        nil
      end
    end

    def get_component(entity, component_class)
      type_name = component_type_name(component_class)

      if HIERARCHY_CLASSES.include?(component_class)
        hier = hierarchy_components[entity.id]
        raise ComponentNotFoundError, "Component #{type_name} not found" unless hier && hier[type_name]

        return hier[type_name]
      end

      if MESH_CLASSES.include?(component_class)
        mesh = mesh_components[entity.id]
        raise ComponentNotFoundError, "Component #{type_name} not found" unless mesh && mesh[type_name]

        return mesh[type_name]
      end

      native = get(entity, type_name)

      case component_class
      when ->(c) { c == Transform }
        Transform.from_native(native)
      when ->(c) { c == Camera2d }
        Camera2d.from_native(native)
      when ->(c) { c == Camera3d }
        Camera3d.from_native(native)
      when ->(c) { c == Sprite }
        Sprite.from_native(native)
      when ->(c) { c == Text2d }
        Text2d.from_native(native)
      when ->(c) { c == AudioPlayer }
        AudioPlayer.from_native(native)
      when ->(c) { c == SpatialAudioSettings }
        SpatialAudioSettings.from_native(native)
      when ->(c) { c.is_a?(Class) && c < ComponentDSL }
        instance = component_class.allocate
        instance.instance_variable_set(:@data, {})
        component_class.attributes.each_key do |key|
          instance.instance_variable_get(:@data)[key] = native[key.to_s]
        end
        instance
      else
        native
      end
    end

    def has?(entity, component_class)
      type_name = component_type_name(component_class)
      has_component?(entity, type_name)
    end

    def each(*component_classes, &block)
      mesh_classes, native_classes = component_classes.partition { |cc| MESH_CLASSES.include?(cc) }

      if mesh_classes.any?
        each_with_mesh(component_classes, mesh_classes, native_classes, &block)
      else
        type_names = native_classes.map { |cc| component_type_name(cc) }
        entities = query(type_names)

        entities.each do |entity|
          components = component_classes.map { |cc| get_component(entity, cc) }
          block.call(entity, *components)
        end
      end
    end

    def each_with_mesh(component_classes, mesh_classes, native_classes, &block)
      @mesh_components.each do |entity_id, meshes|
        mesh_classes.map do |mc|
          mc.new(width: 0, height: 0, radius: 0, sides: 3,
                 start_point: Vec2.zero, end_point: Vec2.zero).type_name
        rescue StandardError
          mc.name.split('::').last
        end

        has_all_meshes = mesh_classes.all? do |mc|
          type_name = component_type_name(mc)
          meshes.key?(type_name)
        end
        next unless has_all_meshes

        entity = get_entity_by_id(entity_id)
        next unless entity

        if native_classes.any?
          type_names = native_classes.map { |cc| component_type_name(cc) }
          next unless type_names.all? { |tn| has_component?(entity, tn) }
        end

        components = component_classes.map do |cc|
          type_name = component_type_name(cc)
          if MESH_CLASSES.include?(cc)
            meshes[type_name]
          else
            get_component(entity, cc)
          end
        end

        block.call(entity, *components)
      end
    end

    def get_entity_by_id(entity_id)
      all_entities.find { |e| e.id == entity_id }
    end

    def all_entities
      @mesh_components.keys.map { |id| entity_from_id(id) }.compact
    end

    def entity_from_id(entity_id)
      Entity.new(entity_id)
    end

    private

    def component_to_native(comp)
      case comp
      when ComponentDSL then comp.to_native
      when Transform then comp.to_native
      when Camera2d then comp.to_native
      when Camera3d then comp.to_native
      when Sprite then comp.to_native
      when Text2d then comp.to_native
      when AudioPlayer then comp.to_native
      when SpatialAudioSettings then comp.to_native
      when Component then comp
      else
        raise ArgumentError,
              "Expected Component, ComponentDSL, Transform, Camera, Sprite, Text2d, or Audio, got #{comp.class}"
      end
    end

    def component_type_name(component_class)
      case component_class
      when ->(c) { c == Transform }
        'Transform'
      when ->(c) { c == Camera2d }
        'Camera2d'
      when ->(c) { c == Camera3d }
        'Camera3d'
      when ->(c) { c == Sprite }
        'Sprite'
      when ->(c) { c == Text2d }
        'Text2d'
      when ->(c) { c == AudioPlayer }
        'AudioPlayer'
      when ->(c) { c == SpatialAudioSettings }
        'SpatialAudioSettings'
      when ->(c) { c == Mesh::Rectangle }
        'Mesh::Rectangle'
      when ->(c) { c == Mesh::Circle }
        'Mesh::Circle'
      when ->(c) { c == Mesh::RegularPolygon }
        'Mesh::RegularPolygon'
      when ->(c) { c == Mesh::Triangle }
        'Mesh::Triangle'
      when ->(c) { c == Mesh::Hexagon }
        'Mesh::Hexagon'
      when ->(c) { c == Mesh::Line }
        'Mesh::Line'
      when ->(c) { c == Mesh::Ellipse }
        'Mesh::Ellipse'
      when ->(c) { c == Parent }
        'Parent'
      when ->(c) { c == Children }
        'Children'
      when ->(c) { c == GlobalTransform }
        'GlobalTransform'
      when ->(c) { c == Visibility }
        'Visibility'
      when ->(c) { c == InheritedVisibility }
        'InheritedVisibility'
      when ->(c) { c == ViewVisibility }
        'ViewVisibility'
      when ->(c) { c.is_a?(Class) && c < ComponentDSL }
        component_class.component_name
      when String
        component_class
      else
        raise ArgumentError, 'Expected Component class or String'
      end
    end
  end
end
