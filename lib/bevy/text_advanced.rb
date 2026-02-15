# frozen_string_literal: true

module Bevy
  class Font
    attr_reader :path, :data

    def initialize(path: nil, data: nil)
      @path = path
      @data = data
    end

    def loaded?
      !@data.nil?
    end

    def type_name
      'Font'
    end
  end

  class FontAtlas
    attr_reader :font, :size, :glyphs

    def initialize(font:, size: 16.0)
      @font = font
      @size = size.to_f
      @glyphs = {}
    end

    def add_glyph(char, glyph_info)
      @glyphs[char] = glyph_info
    end

    def get_glyph(char)
      @glyphs[char]
    end

    def has_glyph?(char)
      @glyphs.key?(char)
    end

    def type_name
      'FontAtlas'
    end
  end

  class GlyphInfo
    attr_reader :char, :rect, :bearing, :advance

    def initialize(char:, rect:, bearing:, advance:)
      @char = char
      @rect = rect
      @bearing = bearing
      @advance = advance.to_f
    end

    def type_name
      'GlyphInfo'
    end
  end

  class TextStyle
    attr_accessor :font, :font_size, :color

    def initialize(font: nil, font_size: 16.0, color: nil)
      @font = font
      @font_size = font_size.to_f
      @color = color || Color.white
    end

    def with_font(font)
      self.class.new(font: font, font_size: @font_size, color: @color)
    end

    def with_font_size(size)
      self.class.new(font: @font, font_size: size, color: @color)
    end

    def with_color(color)
      self.class.new(font: @font, font_size: @font_size, color: color)
    end

    def type_name
      'TextStyle'
    end
  end

  module JustifyText
    LEFT = :left
    CENTER = :center
    RIGHT = :right
  end

  class Text
    attr_accessor :sections, :justify, :linebreak_behavior

    def initialize(value = '', style: nil)
      if value.is_a?(String)
        @sections = [TextSection.new(value: value, style: style || TextStyle.new)]
      else
        @sections = value.is_a?(Array) ? value : [value]
      end
      @justify = JustifyText::LEFT
      @linebreak_behavior = :word_boundary
    end

    def self.from_section(section)
      new([section])
    end

    def self.from_sections(sections)
      new(sections)
    end

    def add_section(section)
      @sections << section
      self
    end

    def clear
      @sections = []
      self
    end

    def full_text
      @sections.map(&:value).join
    end

    def with_justify(justify)
      @justify = justify
      self
    end

    def type_name
      'Text'
    end
  end

  class TextSection
    attr_accessor :value, :style

    def initialize(value: '', style: nil)
      @value = value
      @style = style || TextStyle.new
    end

    def with_style(style)
      self.class.new(value: @value, style: style)
    end

    def type_name
      'TextSection'
    end
  end

  class TextLayoutInfo
    attr_accessor :glyphs, :size

    def initialize
      @glyphs = []
      @size = Vec2.zero
    end

    def type_name
      'TextLayoutInfo'
    end
  end

  class TextFlags
    attr_accessor :needs_recompute

    def initialize
      @needs_recompute = true
    end

    def type_name
      'TextFlags'
    end
  end

  class CalculatedSize
    attr_accessor :size

    def initialize(size: nil)
      @size = size || Vec2.zero
    end

    def type_name
      'CalculatedSize'
    end
  end

  class ZIndex
    attr_accessor :value

    GLOBAL = :global
    LOCAL = :local

    def initialize(value: 0, mode: LOCAL)
      @value = value
      @mode = mode
    end

    def global?
      @mode == GLOBAL
    end

    def local?
      @mode == LOCAL
    end

    def type_name
      'ZIndex'
    end
  end

  module FocusPolicy
    NONE = :none
    BLOCK = :block
    PASS = :pass
  end

  class RichText
    attr_reader :sections

    def initialize
      @sections = []
    end

    def push(text, style: nil)
      @sections << RichTextSection.new(text: text, style: style || TextStyle.new)
      self
    end

    def bold(text, base_style: nil)
      style = (base_style || TextStyle.new).dup
      push(text, style: RichTextStyle.new(base: style, weight: :bold))
    end

    def italic(text, base_style: nil)
      style = (base_style || TextStyle.new).dup
      push(text, style: RichTextStyle.new(base: style, slant: :italic))
    end

    def colored(text, color, base_style: nil)
      style = (base_style || TextStyle.new).with_color(color)
      push(text, style: style)
    end

    def sized(text, size, base_style: nil)
      style = (base_style || TextStyle.new).with_font_size(size)
      push(text, style: style)
    end

    def clear
      @sections = []
      self
    end

    def to_text
      Text.from_sections(@sections.map { |s| s.to_text_section })
    end

    def type_name
      'RichText'
    end
  end

  class RichTextSection
    attr_reader :text, :style

    def initialize(text:, style:)
      @text = text
      @style = style
    end

    def to_text_section
      TextSection.new(value: @text, style: @style.respond_to?(:base) ? @style.base : @style)
    end

    def type_name
      'RichTextSection'
    end
  end

  class RichTextStyle
    attr_reader :base, :weight, :slant, :underline, :strikethrough

    WEIGHT_NORMAL = :normal
    WEIGHT_BOLD = :bold
    WEIGHT_LIGHT = :light

    SLANT_NORMAL = :normal
    SLANT_ITALIC = :italic
    SLANT_OBLIQUE = :oblique

    def initialize(
      base:,
      weight: WEIGHT_NORMAL,
      slant: SLANT_NORMAL,
      underline: false,
      strikethrough: false
    )
      @base = base
      @weight = weight
      @slant = slant
      @underline = underline
      @strikethrough = strikethrough
    end

    def bold?
      @weight == WEIGHT_BOLD
    end

    def italic?
      @slant == SLANT_ITALIC
    end

    def underlined?
      @underline
    end

    def strikethrough?
      @strikethrough
    end

    def type_name
      'RichTextStyle'
    end
  end

  class TextPipeline
    attr_reader :fonts

    def initialize
      @fonts = {}
    end

    def register_font(name, font)
      @fonts[name] = font
      self
    end

    def get_font(name)
      @fonts[name]
    end

    def type_name
      'TextPipeline'
    end
  end

  class TextMeasure
    def self.measure(text, style, max_width: nil)
      char_width = style.font_size * 0.6
      line_height = style.font_size * 1.2

      full_text = text.is_a?(Text) ? text.full_text : text.to_s
      lines = full_text.split("\n")

      if max_width
        lines = lines.flat_map { |line| wrap_line(line, char_width, max_width) }
      end

      width = lines.map { |line| line.length * char_width }.max || 0.0
      height = lines.size * line_height

      Vec2.new(width, height)
    end

    def self.wrap_line(line, char_width, max_width)
      chars_per_line = (max_width / char_width).floor
      return [line] if line.length <= chars_per_line

      wrapped = []
      remaining = line
      while remaining.length > chars_per_line
        break_point = remaining.rindex(' ', chars_per_line) || chars_per_line
        wrapped << remaining[0...break_point]
        remaining = remaining[(break_point + 1)..-1] || ''
      end
      wrapped << remaining unless remaining.empty?
      wrapped
    end

    def type_name
      'TextMeasure'
    end
  end

  class TypewriterEffect
    attr_accessor :text, :visible_chars, :chars_per_second, :timer

    def initialize(text:, chars_per_second: 30.0)
      @text = text
      @chars_per_second = chars_per_second.to_f
      @visible_chars = 0
      @timer = 0.0
    end

    def update(delta)
      @timer += delta
      chars_to_add = (@timer * @chars_per_second).floor
      @timer -= chars_to_add / @chars_per_second
      @visible_chars = [@visible_chars + chars_to_add, total_chars].min
    end

    def total_chars
      @text.length
    end

    def visible_text
      @text[0...@visible_chars]
    end

    def finished?
      @visible_chars >= total_chars
    end

    def reset
      @visible_chars = 0
      @timer = 0.0
    end

    def skip
      @visible_chars = total_chars
    end

    def type_name
      'TypewriterEffect'
    end
  end

  class TextBlink
    attr_accessor :visible, :interval, :timer

    def initialize(interval: 0.5)
      @interval = interval.to_f
      @visible = true
      @timer = 0.0
    end

    def update(delta)
      @timer += delta
      while @timer >= @interval
        @timer -= @interval
        @visible = !@visible
      end
    end

    def type_name
      'TextBlink'
    end
  end
end
