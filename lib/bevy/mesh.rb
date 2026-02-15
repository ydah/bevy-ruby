# frozen_string_literal: true

module Bevy
  module Mesh
    SHAPE_RECTANGLE = 0
    SHAPE_CIRCLE = 1
    SHAPE_REGULAR_POLYGON = 2
    SHAPE_LINE = 3
    SHAPE_ELLIPSE = 4

    class Rectangle
      attr_accessor :width, :height, :color, :fill, :thickness, :transform

      def initialize(width:, height:, color: Color.white, fill: true, thickness: 2.0)
        @width = width.to_f
        @height = height.to_f
        @color = color
        @fill = fill
        @thickness = thickness.to_f
        @transform = Transform.identity
      end

      def shape_type
        SHAPE_RECTANGLE
      end

      def to_mesh_data
        {
          shape_type: shape_type,
          color_r: @color.r,
          color_g: @color.g,
          color_b: @color.b,
          color_a: @color.a,
          width: @width,
          height: @height,
          radius: 0.0,
          sides: 0,
          line_start_x: 0.0,
          line_start_y: 0.0,
          line_end_x: 0.0,
          line_end_y: 0.0,
          thickness: @thickness,
          fill: @fill
        }
      end

      def type_name
        'Mesh::Rectangle'
      end
    end

    class Circle
      attr_accessor :radius, :color, :fill, :thickness, :transform

      def initialize(radius:, color: Color.white, fill: true, thickness: 2.0)
        @radius = radius.to_f
        @color = color
        @fill = fill
        @thickness = thickness.to_f
        @transform = Transform.identity
      end

      def diameter
        @radius * 2.0
      end

      def shape_type
        SHAPE_CIRCLE
      end

      def to_mesh_data
        {
          shape_type: shape_type,
          color_r: @color.r,
          color_g: @color.g,
          color_b: @color.b,
          color_a: @color.a,
          width: 0.0,
          height: 0.0,
          radius: @radius,
          sides: 0,
          line_start_x: 0.0,
          line_start_y: 0.0,
          line_end_x: 0.0,
          line_end_y: 0.0,
          thickness: @thickness,
          fill: @fill
        }
      end

      def type_name
        'Mesh::Circle'
      end
    end

    class RegularPolygon
      attr_accessor :radius, :sides, :color, :fill, :thickness, :transform

      def initialize(radius:, sides:, color: Color.white, fill: true, thickness: 2.0)
        @radius = radius.to_f
        @sides = [sides.to_i, 3].max
        @color = color
        @fill = fill
        @thickness = thickness.to_f
        @transform = Transform.identity
      end

      def shape_type
        SHAPE_REGULAR_POLYGON
      end

      def to_mesh_data
        {
          shape_type: shape_type,
          color_r: @color.r,
          color_g: @color.g,
          color_b: @color.b,
          color_a: @color.a,
          width: 0.0,
          height: 0.0,
          radius: @radius,
          sides: @sides,
          line_start_x: 0.0,
          line_start_y: 0.0,
          line_end_x: 0.0,
          line_end_y: 0.0,
          thickness: @thickness,
          fill: @fill
        }
      end

      def type_name
        'Mesh::RegularPolygon'
      end
    end

    class Triangle < RegularPolygon
      def initialize(radius:, color: Color.white, fill: true, thickness: 2.0)
        super(radius: radius, sides: 3, color: color, fill: fill, thickness: thickness)
      end

      def type_name
        'Mesh::Triangle'
      end
    end

    class Hexagon < RegularPolygon
      def initialize(radius:, color: Color.white, fill: true, thickness: 2.0)
        super(radius: radius, sides: 6, color: color, fill: fill, thickness: thickness)
      end

      def type_name
        'Mesh::Hexagon'
      end
    end

    class Line
      attr_accessor :start_point, :end_point, :color, :thickness, :transform

      def initialize(start_point:, end_point:, color: Color.white, thickness: 2.0)
        @start_point = start_point
        @end_point = end_point
        @color = color
        @thickness = thickness.to_f
        @transform = Transform.identity
      end

      def length
        dx = @end_point.x - @start_point.x
        dy = @end_point.y - @start_point.y
        Math.sqrt(dx * dx + dy * dy)
      end

      def angle
        dx = @end_point.x - @start_point.x
        dy = @end_point.y - @start_point.y
        Math.atan2(dy, dx)
      end

      def center
        Vec2.new(
          (@start_point.x + @end_point.x) / 2.0,
          (@start_point.y + @end_point.y) / 2.0
        )
      end

      def shape_type
        SHAPE_LINE
      end

      def to_mesh_data
        {
          shape_type: shape_type,
          color_r: @color.r,
          color_g: @color.g,
          color_b: @color.b,
          color_a: @color.a,
          width: 0.0,
          height: 0.0,
          radius: 0.0,
          sides: 0,
          line_start_x: @start_point.x,
          line_start_y: @start_point.y,
          line_end_x: @end_point.x,
          line_end_y: @end_point.y,
          thickness: @thickness,
          fill: false
        }
      end

      def type_name
        'Mesh::Line'
      end
    end

    class Ellipse
      attr_accessor :width, :height, :color, :fill, :thickness, :transform

      def initialize(width:, height:, color: Color.white, fill: true, thickness: 2.0)
        @width = width.to_f
        @height = height.to_f
        @color = color
        @fill = fill
        @thickness = thickness.to_f
        @transform = Transform.identity
      end

      def shape_type
        SHAPE_ELLIPSE
      end

      def to_mesh_data
        {
          shape_type: shape_type,
          color_r: @color.r,
          color_g: @color.g,
          color_b: @color.b,
          color_a: @color.a,
          width: @width,
          height: @height,
          radius: 0.0,
          sides: 0,
          line_start_x: 0.0,
          line_start_y: 0.0,
          line_end_x: 0.0,
          line_end_y: 0.0,
          thickness: @thickness,
          fill: @fill
        }
      end

      def type_name
        'Mesh::Ellipse'
      end
    end
  end
end
