# frozen_string_literal: true

module Bevy
  class Aabb
    attr_accessor :center, :half_extents

    def initialize(center:, half_extents:)
      @center = center
      @half_extents = half_extents
    end

    def self.from_min_max(min, max)
      center = Vec3.new(
        (min.x + max.x) / 2.0,
        (min.y + max.y) / 2.0,
        (min.z + max.z) / 2.0
      )
      half_extents = Vec3.new(
        (max.x - min.x) / 2.0,
        (max.y - min.y) / 2.0,
        (max.z - min.z) / 2.0
      )
      new(center: center, half_extents: half_extents)
    end

    def min
      Vec3.new(
        @center.x - @half_extents.x,
        @center.y - @half_extents.y,
        @center.z - @half_extents.z
      )
    end

    def max
      Vec3.new(
        @center.x + @half_extents.x,
        @center.y + @half_extents.y,
        @center.z + @half_extents.z
      )
    end

    def contains_point?(point)
      m = min
      mx = max
      point.x >= m.x && point.x <= mx.x &&
        point.y >= m.y && point.y <= mx.y &&
        point.z >= m.z && point.z <= mx.z
    end

    def intersects?(other)
      min1 = min
      max1 = max
      min2 = other.min
      max2 = other.max

      min1.x <= max2.x && max1.x >= min2.x &&
        min1.y <= max2.y && max1.y >= min2.y &&
        min1.z <= max2.z && max1.z >= min2.z
    end

    def merge(other)
      new_min = Vec3.new(
        [min.x, other.min.x].min,
        [min.y, other.min.y].min,
        [min.z, other.min.z].min
      )
      new_max = Vec3.new(
        [max.x, other.max.x].max,
        [max.y, other.max.y].max,
        [max.z, other.max.z].max
      )
      Aabb.from_min_max(new_min, new_max)
    end

    def type_name
      'Aabb'
    end
  end

  class Frustum
    attr_reader :planes

    def initialize(planes)
      @planes = planes
    end

    def self.from_view_projection(view_projection)
      new([])
    end

    def contains_point?(point)
      @planes.all? { |plane| plane.signed_distance(point) >= 0 }
    end

    def intersects_aabb?(aabb)
      @planes.all? do |plane|
        p_vertex = Vec3.new(
          plane.normal.x >= 0 ? aabb.max.x : aabb.min.x,
          plane.normal.y >= 0 ? aabb.max.y : aabb.min.y,
          plane.normal.z >= 0 ? aabb.max.z : aabb.min.z
        )
        plane.signed_distance(p_vertex) >= 0
      end
    end

    def type_name
      'Frustum'
    end
  end

  class FrustumPlane
    attr_reader :normal, :distance

    def initialize(normal:, distance:)
      @normal = normal
      @distance = distance.to_f
    end

    def signed_distance(point)
      @normal.x * point.x + @normal.y * point.y + @normal.z * point.z + @distance
    end

    def type_name
      'FrustumPlane'
    end
  end

  class VisibleEntities
    attr_reader :entities

    def initialize
      @entities = []
    end

    def add(entity)
      @entities << entity
      self
    end

    def clear
      @entities = []
    end

    def count
      @entities.size
    end

    def include?(entity)
      @entities.include?(entity)
    end

    def type_name
      'VisibleEntities'
    end
  end

  class RenderLayers
    attr_reader :layers

    DEFAULT_LAYER = 0

    def initialize(layers = [DEFAULT_LAYER])
      @layers = layers.to_a
    end

    def self.layer(layer)
      new([layer])
    end

    def self.all
      new((0..31).to_a)
    end

    def self.none
      new([])
    end

    def with(layer)
      self.class.new(@layers + [layer])
    end

    def without(layer)
      self.class.new(@layers - [layer])
    end

    def intersects?(other)
      (@layers & other.layers).any?
    end

    def type_name
      'RenderLayers'
    end
  end

  class OcclusionCulling
    attr_accessor :enabled

    def initialize(enabled: true)
      @enabled = enabled
      @occluders = []
    end

    def add_occluder(aabb)
      @occluders << aabb
    end

    def clear_occluders
      @occluders = []
    end

    def is_occluded?(aabb, from_point)
      return false unless @enabled

      @occluders.any? do |occluder|
        occluder != aabb && occludes?(occluder, aabb, from_point)
      end
    end

    def type_name
      'OcclusionCulling'
    end

    private

    def occludes?(occluder, target, _from_point)
      occluder.contains_point?(target.center)
    end
  end

  class Lod
    attr_reader :distances, :current_level

    def initialize(distances:)
      @distances = distances.sort
      @current_level = 0
    end

    def update(distance)
      @current_level = @distances.index { |d| distance <= d } || @distances.size
    end

    def level_count
      @distances.size + 1
    end

    def type_name
      'Lod'
    end
  end
end
