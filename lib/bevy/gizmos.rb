# frozen_string_literal: true

module Bevy
  class Gizmos
    attr_accessor :enabled, :line_width

    def initialize
      @enabled = true
      @line_width = 1.0
      @commands = []
    end

    def line(start_point, end_point, color: nil)
      @commands << { type: :line, start: start_point, end: end_point, color: color || Color.white }
      self
    end

    def ray(origin, direction, length: 1.0, color: nil)
      end_point = Vec3.new(
        origin.x + direction.x * length,
        origin.y + direction.y * length,
        origin.z + direction.z * length
      )
      line(origin, end_point, color: color)
    end

    def circle(center, radius, color: nil, segments: 32)
      @commands << { type: :circle, center: center, radius: radius, color: color || Color.white, segments: segments }
      self
    end

    def sphere(center, radius, color: nil)
      @commands << { type: :sphere, center: center, radius: radius, color: color || Color.white }
      self
    end

    def rect(center, size, color: nil)
      @commands << { type: :rect, center: center, size: size, color: color || Color.white }
      self
    end

    def box3d(center, size, color: nil)
      @commands << { type: :box, center: center, size: size, color: color || Color.white }
      self
    end

    def arrow(start_point, end_point, color: nil)
      @commands << { type: :arrow, start: start_point, end: end_point, color: color || Color.white }
      self
    end

    def arc(center, radius, start_angle, end_angle, color: nil)
      @commands << { type: :arc, center: center, radius: radius, start_angle: start_angle, end_angle: end_angle, color: color || Color.white }
      self
    end

    def grid(center, cell_size, count, color: nil)
      @commands << { type: :grid, center: center, cell_size: cell_size, count: count, color: color || Color.rgba(0.5, 0.5, 0.5, 1.0) }
      self
    end

    def cross(center, size, color: nil)
      half = size / 2.0
      line(Vec3.new(center.x - half, center.y, center.z), Vec3.new(center.x + half, center.y, center.z), color: color)
      line(Vec3.new(center.x, center.y - half, center.z), Vec3.new(center.x, center.y + half, center.z), color: color)
    end

    def commands
      @commands
    end

    def clear
      @commands = []
    end

    def command_count
      @commands.size
    end

    def type_name
      'Gizmos'
    end
  end

  class GizmoConfig
    attr_accessor :enabled, :line_width, :depth_test, :render_layer

    def initialize(
      enabled: true,
      line_width: 1.0,
      depth_test: true,
      render_layer: 0
    )
      @enabled = enabled
      @line_width = line_width.to_f
      @depth_test = depth_test
      @render_layer = render_layer
    end

    def type_name
      'GizmoConfig'
    end
  end

  class AabbGizmo
    attr_accessor :color

    def initialize(color: nil)
      @color = color || Color.rgba(0.0, 1.0, 0.0, 1.0)
    end

    def type_name
      'AabbGizmo'
    end
  end

  class LightGizmo
    attr_accessor :draw_range, :draw_direction

    def initialize(draw_range: true, draw_direction: true)
      @draw_range = draw_range
      @draw_direction = draw_direction
    end

    def type_name
      'LightGizmo'
    end
  end

  class TransformGizmo
    attr_accessor :enabled, :mode

    TRANSLATE = :translate
    ROTATE = :rotate
    SCALE = :scale

    def initialize(enabled: true, mode: TRANSLATE)
      @enabled = enabled
      @mode = mode
    end

    def translate_mode
      @mode = TRANSLATE
    end

    def rotate_mode
      @mode = ROTATE
    end

    def scale_mode
      @mode = SCALE
    end

    def type_name
      'TransformGizmo'
    end
  end
end
