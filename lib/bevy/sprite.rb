# frozen_string_literal: true

module Bevy
  class Sprite
    attr_reader :color, :flip_x, :flip_y, :custom_size, :anchor

    def initialize(color: nil, flip_x: false, flip_y: false, custom_size: nil, anchor: nil)
      @color = color || Color.white
      @flip_x = flip_x
      @flip_y = flip_y
      @custom_size = custom_size
      @anchor = anchor || Vec2.new(0.5, 0.5)
    end

    def type_name
      'Sprite'
    end

    def with_color(color)
      self.class.new(
        color: color,
        flip_x: @flip_x,
        flip_y: @flip_y,
        custom_size: @custom_size,
        anchor: @anchor
      )
    end

    def with_flip_x(flip_x)
      self.class.new(
        color: @color,
        flip_x: flip_x,
        flip_y: @flip_y,
        custom_size: @custom_size,
        anchor: @anchor
      )
    end

    def with_flip_y(flip_y)
      self.class.new(
        color: @color,
        flip_x: @flip_x,
        flip_y: flip_y,
        custom_size: @custom_size,
        anchor: @anchor
      )
    end

    def with_custom_size(size)
      self.class.new(
        color: @color,
        flip_x: @flip_x,
        flip_y: @flip_y,
        custom_size: size,
        anchor: @anchor
      )
    end

    def with_anchor(anchor)
      self.class.new(
        color: @color,
        flip_x: @flip_x,
        flip_y: @flip_y,
        custom_size: @custom_size,
        anchor: anchor
      )
    end

    def to_native
      native = Component.new('Sprite')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['flip_x'] = @flip_x
      native['flip_y'] = @flip_y
      native['anchor_x'] = @anchor.x
      native['anchor_y'] = @anchor.y
      if @custom_size
        native['custom_size_x'] = @custom_size.x
        native['custom_size_y'] = @custom_size.y
        native['has_custom_size'] = true
      else
        native['has_custom_size'] = false
      end
      native
    end

    def self.from_native(native)
      color = Color.new(
        native['color_r'] || 1.0,
        native['color_g'] || 1.0,
        native['color_b'] || 1.0,
        native['color_a'] || 1.0
      )
      anchor = Vec2.new(
        native['anchor_x'] || 0.5,
        native['anchor_y'] || 0.5
      )
      custom_size = (Vec2.new(native['custom_size_x'], native['custom_size_y']) if native['has_custom_size'])
      new(
        color: color,
        flip_x: native['flip_x'] || false,
        flip_y: native['flip_y'] || false,
        custom_size: custom_size,
        anchor: anchor
      )
    end

    def to_h
      h = {
        color: @color.to_a,
        flip_x: @flip_x,
        flip_y: @flip_y,
        anchor: @anchor.to_a
      }
      h[:custom_size] = @custom_size.to_a if @custom_size
      h
    end

    def to_sync_hash
      h = {
        color_r: @color.r,
        color_g: @color.g,
        color_b: @color.b,
        color_a: @color.a,
        flip_x: @flip_x,
        flip_y: @flip_y,
        anchor_x: @anchor.x,
        anchor_y: @anchor.y
      }
      if @custom_size
        h[:custom_size_x] = @custom_size.x
        h[:custom_size_y] = @custom_size.y
      end
      h
    end
  end

  class SpriteBundle
    attr_reader :sprite, :transform

    def initialize(sprite: nil, transform: nil)
      @sprite = sprite || Sprite.new
      @transform = transform || Transform.identity
    end

    def components
      [@sprite, @transform]
    end
  end
end
