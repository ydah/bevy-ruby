# frozen_string_literal: true

module Bevy
  class Gltf
    attr_reader :path, :scenes, :meshes, :materials, :animations, :nodes

    def initialize(path)
      @path = path
      @scenes = []
      @meshes = []
      @materials = []
      @animations = []
      @nodes = []
      @loaded = false
    end

    def loaded?
      @loaded
    end

    def mark_loaded(data = {})
      @scenes = data[:scenes] || []
      @meshes = data[:meshes] || []
      @materials = data[:materials] || []
      @animations = data[:animations] || []
      @nodes = data[:nodes] || []
      @loaded = true
    end

    def default_scene
      @scenes.first
    end

    def type_name
      'Gltf'
    end
  end

  class GltfMesh
    attr_reader :name, :primitives

    def initialize(name, primitives = [])
      @name = name
      @primitives = primitives
    end

    def type_name
      'GltfMesh'
    end
  end

  class GltfPrimitive
    attr_reader :mesh, :material

    def initialize(mesh:, material: nil)
      @mesh = mesh
      @material = material
    end

    def type_name
      'GltfPrimitive'
    end
  end

  class GltfNode
    attr_reader :name, :transform, :mesh, :children

    def initialize(name:, transform: nil, mesh: nil, children: [])
      @name = name
      @transform = transform || Transform.identity
      @mesh = mesh
      @children = children
    end

    def type_name
      'GltfNode'
    end
  end

  class GltfScene
    attr_reader :name, :nodes

    def initialize(name, nodes = [])
      @name = name
      @nodes = nodes
    end

    def type_name
      'GltfScene'
    end
  end

  class GltfAnimation
    attr_reader :name, :duration

    def initialize(name, duration = 0.0)
      @name = name
      @duration = duration.to_f
    end

    def type_name
      'GltfAnimation'
    end
  end

  class SceneBundle3d
    attr_reader :scene, :transform

    def initialize(scene:, transform: nil)
      @scene = scene
      @transform = transform || Transform.identity
    end

    def type_name
      'SceneBundle3d'
    end
  end

  class GltfAssetLoader
    def initialize
      @cache = {}
    end

    def load(path)
      return @cache[path] if @cache[path]

      gltf = Gltf.new(path)
      @cache[path] = gltf
      gltf
    end

    def is_loaded?(path)
      @cache[path]&.loaded?
    end

    def get(path)
      @cache[path]
    end

    def unload(path)
      @cache.delete(path)
    end

    def clear
      @cache.clear
    end

    def type_name
      'GltfAssetLoader'
    end
  end

  class Mesh3d
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end

    def type_name
      'Mesh3d'
    end
  end

  class MeshMaterial3d
    attr_reader :material

    def initialize(material)
      @material = material
    end

    def type_name
      'MeshMaterial3d'
    end
  end

  class Pbr
    attr_reader :base_color, :metallic, :roughness, :emissive

    def initialize(base_color: nil, metallic: 0.0, roughness: 0.5, emissive: nil)
      @base_color = base_color || Color.white
      @metallic = metallic.to_f
      @roughness = roughness.to_f
      @emissive = emissive || Color.black
    end

    def with_base_color(color)
      self.class.new(
        base_color: color,
        metallic: @metallic,
        roughness: @roughness,
        emissive: @emissive
      )
    end

    def with_metallic(metallic)
      self.class.new(
        base_color: @base_color,
        metallic: metallic,
        roughness: @roughness,
        emissive: @emissive
      )
    end

    def with_roughness(roughness)
      self.class.new(
        base_color: @base_color,
        metallic: @metallic,
        roughness: roughness,
        emissive: @emissive
      )
    end

    def type_name
      'Pbr'
    end

    def to_h
      {
        base_color: @base_color.to_a,
        metallic: @metallic,
        roughness: @roughness,
        emissive: @emissive.to_a
      }
    end
  end
end
