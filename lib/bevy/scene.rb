# frozen_string_literal: true

require 'json'

module Bevy
  class Scene
    attr_reader :name, :entities

    def initialize(name = 'Untitled')
      @name = name
      @entities = []
    end

    def add_entity(components)
      @entities << components
      self
    end

    def spawn_all(world)
      spawned = []
      @entities.each do |components|
        entity = world.spawn_entity(*components)
        spawned << entity
      end
      spawned
    end

    def clear
      @entities.clear
      self
    end

    def entity_count
      @entities.size
    end

    def type_name
      'Scene'
    end
  end

  class DynamicScene
    attr_reader :name

    def initialize(name = 'DynamicScene')
      @name = name
      @entity_data = []
    end

    def capture_world(world, &filter)
      @entity_data.clear

      world.all_entities.each do |entity|
        next if block_given? && !filter.call(entity)

        entity_components = {}
        world.mesh_components[entity.id]&.each do |type_name, component|
          entity_components[type_name] = serialize_component(component)
        end

        @entity_data << {
          id: entity.id,
          components: entity_components
        }
      end

      self
    end

    def restore_to_world(world)
      spawned = []
      @entity_data.each do |data|
        components = data[:components].map do |type_name, comp_data|
          deserialize_component(type_name, comp_data)
        end.compact

        entity = world.spawn_entity(*components) if components.any?
        spawned << entity if entity
      end
      spawned
    end

    def to_data
      {
        name: @name,
        entities: @entity_data
      }
    end

    def load_data(data)
      @name = data[:name] || data['name'] || @name
      @entity_data = data[:entities] || data['entities'] || []
      self
    end

    def entity_count
      @entity_data.size
    end

    def type_name
      'DynamicScene'
    end

    private

    def serialize_component(component)
      case component
      when Mesh::Rectangle
        { type: 'Rectangle', width: component.width, height: component.height, color: component.color.to_a }
      when Mesh::Circle
        { type: 'Circle', radius: component.radius, color: component.color.to_a }
      when Mesh::RegularPolygon
        { type: 'RegularPolygon', radius: component.radius, sides: component.sides, color: component.color.to_a }
      else
        { type: component.class.name, data: component.respond_to?(:to_h) ? component.to_h : {} }
      end
    end

    def deserialize_component(type_name, data)
      case data[:type] || data['type']
      when 'Rectangle'
        color = data[:color] || data['color']
        Mesh::Rectangle.new(
          width: data[:width] || data['width'],
          height: data[:height] || data['height'],
          color: color.is_a?(Array) ? Color.rgba(*color) : Color.white
        )
      when 'Circle'
        color = data[:color] || data['color']
        Mesh::Circle.new(
          radius: data[:radius] || data['radius'],
          color: color.is_a?(Array) ? Color.rgba(*color) : Color.white
        )
      when 'RegularPolygon'
        color = data[:color] || data['color']
        Mesh::RegularPolygon.new(
          radius: data[:radius] || data['radius'],
          sides: data[:sides] || data['sides'],
          color: color.is_a?(Array) ? Color.rgba(*color) : Color.white
        )
      else
        nil
      end
    end
  end

  class SceneBundle
    attr_reader :scene, :transform

    def initialize(scene:, transform: nil)
      @scene = scene
      @transform = transform || Transform.identity
    end

    def type_name
      'SceneBundle'
    end
  end

  class SceneSpawner
    def initialize
      @pending_scenes = []
      @spawned_scenes = {}
    end

    def spawn(scene, transform: nil)
      @pending_scenes << { scene: scene, transform: transform }
      self
    end

    def spawn_pending(world)
      spawned = []
      @pending_scenes.each do |pending|
        scene = pending[:scene]
        entities = scene.spawn_all(world)
        spawned.concat(entities)
        @spawned_scenes[scene.name] = entities
      end
      @pending_scenes.clear
      spawned
    end

    def despawn_scene(name, world)
      entities = @spawned_scenes.delete(name)
      return [] unless entities

      entities.each { |e| world.despawn(e) }
      entities
    end

    def pending_count
      @pending_scenes.size
    end

    def spawned_scenes
      @spawned_scenes.keys
    end

    def type_name
      'SceneSpawner'
    end
  end

  module SceneSaver
    def self.save_to_json(scene, file_path)
      data = if scene.is_a?(DynamicScene)
               scene.to_data
             else
               { name: scene.name, entities: scene.entities.map { |e| serialize_entity(e) } }
             end

      File.write(file_path, JSON.pretty_generate(data))
      true
    rescue StandardError => e
      warn "Failed to save scene: #{e.message}"
      false
    end

    def self.load_from_json(file_path)
      return nil unless File.exist?(file_path)

      data = JSON.parse(File.read(file_path), symbolize_names: true)
      scene = DynamicScene.new(data[:name] || 'Loaded')
      scene.load_data(data)
      scene
    rescue StandardError => e
      warn "Failed to load scene: #{e.message}"
      nil
    end

    def self.serialize_entity(components)
      components.map do |comp|
        {
          type: comp.class.name,
          data: comp.respond_to?(:to_h) ? comp.to_h : {}
        }
      end
    end
  end

  class SceneInstance
    attr_reader :scene_name, :root_entity, :entities

    def initialize(scene_name, root_entity, entities)
      @scene_name = scene_name
      @root_entity = root_entity
      @entities = entities
    end

    def type_name
      'SceneInstance'
    end
  end
end
