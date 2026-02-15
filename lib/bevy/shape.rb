# frozen_string_literal: true

module Bevy
  module Shape
    class Rectangle
      attr_reader :width, :height, :color

      def initialize(width:, height:, color: Color.white)
        @width = width.to_f
        @height = height.to_f
        @color = color
      end

      def to_sprite
        Sprite.new(
          color: @color,
          custom_size: Vec2.new(@width, @height)
        )
      end

      def type_name
        'Shape::Rectangle'
      end
    end

    class Circle
      attr_reader :radius, :color, :segments

      def initialize(radius:, color: Color.white, segments: 32)
        @radius = radius.to_f
        @color = color
        @segments = segments
      end

      def diameter
        @radius * 2.0
      end

      def to_sprite
        Sprite.new(
          color: @color,
          custom_size: Vec2.new(diameter, diameter)
        )
      end

      def type_name
        'Shape::Circle'
      end
    end

    class Line
      attr_reader :start_point, :end_point, :thickness, :color

      def initialize(start_point:, end_point:, thickness: 2.0, color: Color.white)
        @start_point = start_point
        @end_point = end_point
        @thickness = thickness.to_f
        @color = color
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

      def to_sprite
        Sprite.new(
          color: @color,
          custom_size: Vec2.new(length, @thickness)
        )
      end

      def to_transform(z: 0.0)
        center_point = center
        Transform.new(
          translation: Vec3.new(center_point.x, center_point.y, z),
          rotation: Quat.from_rotation_z(angle),
          scale: Vec3.one
        )
      end

      def type_name
        'Shape::Line'
      end
    end

    class Polygon
      attr_reader :points, :color

      def initialize(points:, color: Color.white)
        @points = points
        @color = color
      end

      def centroid
        return Vec2.zero if @points.empty?

        sum_x = @points.sum(&:x)
        sum_y = @points.sum(&:y)
        Vec2.new(sum_x / @points.length, sum_y / @points.length)
      end

      def bounding_box
        return { min: Vec2.zero, max: Vec2.zero } if @points.empty?

        min_x = @points.map(&:x).min
        max_x = @points.map(&:x).max
        min_y = @points.map(&:y).min
        max_y = @points.map(&:y).max

        { min: Vec2.new(min_x, min_y), max: Vec2.new(max_x, max_y) }
      end

      def to_sprite
        bbox = bounding_box
        width = bbox[:max].x - bbox[:min].x
        height = bbox[:max].y - bbox[:min].y

        Sprite.new(
          color: @color,
          custom_size: Vec2.new(width, height)
        )
      end

      def type_name
        'Shape::Polygon'
      end
    end

    class RegularPolygon
      attr_reader :radius, :sides, :color

      def initialize(radius:, sides:, color: Color.white)
        @radius = radius.to_f
        @sides = [sides.to_i, 3].max
        @color = color
      end

      def points
        (0...@sides).map do |i|
          angle = (2.0 * Math::PI * i / @sides) - (Math::PI / 2.0)
          Vec2.new(
            @radius * Math.cos(angle),
            @radius * Math.sin(angle)
          )
        end
      end

      def to_sprite
        Sprite.new(
          color: @color,
          custom_size: Vec2.new(@radius * 2, @radius * 2)
        )
      end

      def type_name
        'Shape::RegularPolygon'
      end
    end

    class Triangle < RegularPolygon
      def initialize(radius:, color: Color.white)
        super(radius: radius, sides: 3, color: color)
      end

      def type_name
        'Shape::Triangle'
      end
    end

    class Hexagon < RegularPolygon
      def initialize(radius:, color: Color.white)
        super(radius: radius, sides: 6, color: color)
      end

      def type_name
        'Shape::Hexagon'
      end
    end
  end
end
