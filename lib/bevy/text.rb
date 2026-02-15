# frozen_string_literal: true

module Bevy
  class Text2d
    attr_reader :content, :font_size, :color

    def initialize(content, font_size: 24.0, color: Color.white)
      @content = content.to_s
      @font_size = font_size.to_f
      @color = color
    end

    def type_name
      'Text2d'
    end

    def with_content(content)
      self.class.new(content, font_size: @font_size, color: @color)
    end

    def with_font_size(font_size)
      self.class.new(@content, font_size: font_size, color: @color)
    end

    def with_color(color)
      self.class.new(@content, font_size: @font_size, color: color)
    end

    def to_sync_hash
      {
        content: @content,
        font_size: @font_size,
        color_r: @color.r,
        color_g: @color.g,
        color_b: @color.b,
        color_a: @color.a
      }
    end

    def to_native
      native = Component.new('Text2d')
      native['content'] = @content
      native['font_size'] = @font_size
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native
    end

    def self.from_native(native)
      color = Color.rgba(
        native['color_r'] || 1.0,
        native['color_g'] || 1.0,
        native['color_b'] || 1.0,
        native['color_a'] || 1.0
      )
      new(
        native['content'] || '',
        font_size: native['font_size'] || 24.0,
        color: color
      )
    end
  end

  class TextStyle
    attr_reader :font_size, :color

    def initialize(font_size: 24.0, color: Color.white)
      @font_size = font_size.to_f
      @color = color
    end

    def with_font_size(font_size)
      self.class.new(font_size: font_size, color: @color)
    end

    def with_color(color)
      self.class.new(font_size: @font_size, color: color)
    end
  end

  class TextSection
    attr_reader :value, :style

    def initialize(value, style: TextStyle.new)
      @value = value.to_s
      @style = style
    end

    def with_value(value)
      self.class.new(value, style: @style)
    end

    def with_style(style)
      self.class.new(@value, style: style)
    end
  end
end
