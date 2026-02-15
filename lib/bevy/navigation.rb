# frozen_string_literal: true

module Bevy
  class NavMesh
    attr_reader :vertices, :polygons

    def initialize
      @vertices = []
      @polygons = []
    end

    def add_vertex(position)
      index = @vertices.size
      @vertices << position
      index
    end

    def add_polygon(vertex_indices)
      @polygons << NavPolygon.new(indices: vertex_indices, mesh: self)
      self
    end

    def find_path(start_pos, end_pos)
      start_poly = find_polygon_at(start_pos)
      end_poly = find_polygon_at(end_pos)

      return nil unless start_poly && end_poly

      a_star(start_poly, end_poly, start_pos, end_pos)
    end

    def find_polygon_at(position)
      @polygons.find { |poly| poly.contains?(position) }
    end

    def polygon_count
      @polygons.size
    end

    def type_name
      'NavMesh'
    end

    private

    def a_star(start_poly, end_poly, start_pos, end_pos)
      return [start_pos, end_pos] if start_poly == end_poly

      open_set = [start_poly]
      came_from = {}
      g_score = { start_poly => 0 }
      f_score = { start_poly => heuristic(start_pos, end_pos) }

      until open_set.empty?
        current = open_set.min_by { |p| f_score[p] || Float::INFINITY }
        return reconstruct_path(came_from, current, start_pos, end_pos) if current == end_poly

        open_set.delete(current)

        current.neighbors(@polygons).each do |neighbor|
          tentative_g = (g_score[current] || Float::INFINITY) + current.distance_to(neighbor)

          next unless tentative_g < (g_score[neighbor] || Float::INFINITY)

          came_from[neighbor] = current
          g_score[neighbor] = tentative_g
          f_score[neighbor] = tentative_g + heuristic(neighbor.center, end_pos)
          open_set << neighbor unless open_set.include?(neighbor)
        end
      end

      nil
    end

    def heuristic(a, b)
      Math.sqrt((b.x - a.x)**2 + (b.y - a.y)**2)
    end

    def reconstruct_path(came_from, current, start_pos, end_pos)
      path = [end_pos]
      while came_from[current]
        path.unshift(current.center)
        current = came_from[current]
      end
      path.unshift(start_pos)
      path
    end
  end

  class NavPolygon
    attr_reader :indices

    def initialize(indices:, mesh:)
      @indices = indices
      @mesh = mesh
    end

    def vertices
      @indices.map { |i| @mesh.vertices[i] }
    end

    def center
      verts = vertices
      return Vec3.zero if verts.empty?

      sum_x = verts.sum(&:x)
      sum_y = verts.sum(&:y)
      sum_z = verts.sum(&:z)
      count = verts.size.to_f
      Vec3.new(sum_x / count, sum_y / count, sum_z / count)
    end

    def contains?(point)
      verts = vertices
      return false if verts.size < 3

      n = verts.size
      inside = false
      j = n - 1
      n.times do |i|
        if ((verts[i].y > point.y) != (verts[j].y > point.y)) &&
           (point.x < (verts[j].x - verts[i].x) * (point.y - verts[i].y) / (verts[j].y - verts[i].y) + verts[i].x)
          inside = !inside
        end
        j = i
      end
      inside
    end

    def neighbors(all_polygons)
      all_polygons.select { |other| other != self && shares_edge?(other) }
    end

    def shares_edge?(other)
      shared = @indices & other.indices
      shared.size >= 2
    end

    def distance_to(other)
      Math.sqrt((other.center.x - center.x)**2 + (other.center.y - center.y)**2)
    end

    def type_name
      'NavPolygon'
    end
  end

  class NavAgent
    attr_accessor :position, :target, :speed, :radius, :path

    def initialize(position: nil, speed: 5.0, radius: 0.5)
      @position = position || Vec3.zero
      @target = nil
      @speed = speed.to_f
      @radius = radius.to_f
      @path = []
      @current_waypoint = 0
    end

    def set_destination(target)
      @target = target
      @current_waypoint = 0
    end

    def update(delta, nav_mesh)
      return unless @target
      return if @path.empty? && !calculate_path(nav_mesh)

      move_along_path(delta)
    end

    def reached_destination?
      return false unless @target

      distance_to(@target) < @radius
    end

    def type_name
      'NavAgent'
    end

    private

    def calculate_path(nav_mesh)
      @path = nav_mesh.find_path(@position, @target) || []
      @current_waypoint = 0
      @path.any?
    end

    def move_along_path(delta)
      return if @current_waypoint >= @path.size

      waypoint = @path[@current_waypoint]
      direction = Vec3.new(
        waypoint.x - @position.x,
        waypoint.y - @position.y,
        waypoint.z - @position.z
      )
      distance = Math.sqrt(direction.x**2 + direction.y**2 + direction.z**2)

      if distance < @radius
        @current_waypoint += 1
        return
      end

      move_distance = @speed * delta
      if move_distance >= distance
        @position = waypoint
        @current_waypoint += 1
      else
        ratio = move_distance / distance
        @position = Vec3.new(
          @position.x + direction.x * ratio,
          @position.y + direction.y * ratio,
          @position.z + direction.z * ratio
        )
      end
    end

    def distance_to(point)
      Math.sqrt((@position.x - point.x)**2 + (@position.y - point.y)**2 + (@position.z - point.z)**2)
    end
  end

  class SteeringBehavior
    attr_accessor :weight

    def initialize(weight: 1.0)
      @weight = weight.to_f
    end

    def calculate(_agent)
      Vec3.zero
    end

    def type_name
      'SteeringBehavior'
    end
  end

  class SeekBehavior < SteeringBehavior
    attr_accessor :target

    def initialize(target: nil, **kwargs)
      super(**kwargs)
      @target = target
    end

    def calculate(agent)
      return Vec3.zero unless @target

      desired = Vec3.new(
        @target.x - agent.position.x,
        @target.y - agent.position.y,
        @target.z - agent.position.z
      )
      normalize(desired)
    end

    def type_name
      'SeekBehavior'
    end

    private

    def normalize(v)
      length = Math.sqrt(v.x**2 + v.y**2 + v.z**2)
      return Vec3.zero if length == 0

      Vec3.new(v.x / length, v.y / length, v.z / length)
    end
  end

  class FleeBehavior < SteeringBehavior
    attr_accessor :target, :panic_distance

    def initialize(target: nil, panic_distance: 10.0, **kwargs)
      super(**kwargs)
      @target = target
      @panic_distance = panic_distance.to_f
    end

    def calculate(agent)
      return Vec3.zero unless @target

      diff = Vec3.new(
        agent.position.x - @target.x,
        agent.position.y - @target.y,
        agent.position.z - @target.z
      )
      distance = Math.sqrt(diff.x**2 + diff.y**2 + diff.z**2)
      return Vec3.zero if distance > @panic_distance

      normalize(diff)
    end

    def type_name
      'FleeBehavior'
    end

    private

    def normalize(v)
      length = Math.sqrt(v.x**2 + v.y**2 + v.z**2)
      return Vec3.zero if length == 0

      Vec3.new(v.x / length, v.y / length, v.z / length)
    end
  end

  class WanderBehavior < SteeringBehavior
    attr_accessor :radius, :distance, :jitter

    def initialize(radius: 1.0, distance: 2.0, jitter: 0.5, **kwargs)
      super(**kwargs)
      @radius = radius.to_f
      @distance = distance.to_f
      @jitter = jitter.to_f
      @wander_target = Vec3.new(1.0, 0.0, 0.0)
    end

    def calculate(_agent)
      @wander_target = Vec3.new(
        @wander_target.x + (rand - 0.5) * @jitter,
        @wander_target.y + (rand - 0.5) * @jitter,
        0.0
      )
      normalize(@wander_target)
    end

    def type_name
      'WanderBehavior'
    end

    private

    def normalize(v)
      length = Math.sqrt(v.x**2 + v.y**2 + v.z**2)
      return Vec3.zero if length == 0

      Vec3.new(v.x / length, v.y / length, v.z / length)
    end
  end
end
