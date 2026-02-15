# frozen_string_literal: true

module Bevy
  module Val
    def self.px(value)
      { type: :px, value: value.to_f }
    end

    def self.percent(value)
      { type: :percent, value: value.to_f }
    end

    def self.auto
      { type: :auto, value: 0.0 }
    end

    def self.vw(value)
      { type: :vw, value: value.to_f }
    end

    def self.vh(value)
      { type: :vh, value: value.to_f }
    end

    def self.vmin(value)
      { type: :vmin, value: value.to_f }
    end

    def self.vmax(value)
      { type: :vmax, value: value.to_f }
    end
  end

  module FlexDirection
    ROW = :row
    ROW_REVERSE = :row_reverse
    COLUMN = :column
    COLUMN_REVERSE = :column_reverse
  end

  module JustifyContent
    START = :start
    END_POS = :end
    FLEX_START = :flex_start
    FLEX_END = :flex_end
    CENTER = :center
    SPACE_BETWEEN = :space_between
    SPACE_AROUND = :space_around
    SPACE_EVENLY = :space_evenly
  end

  module AlignItems
    DEFAULT = :default
    START = :start
    END_POS = :end
    FLEX_START = :flex_start
    FLEX_END = :flex_end
    CENTER = :center
    BASELINE = :baseline
    STRETCH = :stretch
  end

  module AlignSelf
    AUTO = :auto
    START = :start
    END_POS = :end
    FLEX_START = :flex_start
    FLEX_END = :flex_end
    CENTER = :center
    BASELINE = :baseline
    STRETCH = :stretch
  end

  module AlignContent
    DEFAULT = :default
    START = :start
    END_POS = :end
    FLEX_START = :flex_start
    FLEX_END = :flex_end
    CENTER = :center
    STRETCH = :stretch
    SPACE_BETWEEN = :space_between
    SPACE_AROUND = :space_around
    SPACE_EVENLY = :space_evenly
  end

  module Display
    FLEX = :flex
    GRID = :grid
    NONE = :none
  end

  module PositionType
    RELATIVE = :relative
    ABSOLUTE = :absolute
  end

  module Overflow
    VISIBLE = :visible
    CLIP = :clip
    SCROLL = :scroll
  end

  class UiRect
    attr_accessor :left, :right, :top, :bottom

    def initialize(left: nil, right: nil, top: nil, bottom: nil, all: nil, horizontal: nil, vertical: nil)
      if all
        @left = @right = @top = @bottom = all
      else
        @left = horizontal || left || Val.px(0)
        @right = horizontal || right || Val.px(0)
        @top = vertical || top || Val.px(0)
        @bottom = vertical || bottom || Val.px(0)
      end
    end

    def self.all(val)
      new(all: val)
    end

    def self.horizontal(val)
      new(horizontal: val)
    end

    def self.vertical(val)
      new(vertical: val)
    end

    def self.axes(horizontal, vertical)
      new(horizontal: horizontal, vertical: vertical)
    end

    def self.left(val)
      new(left: val)
    end

    def self.right(val)
      new(right: val)
    end

    def self.top(val)
      new(top: val)
    end

    def self.bottom(val)
      new(bottom: val)
    end

    def to_h
      { left: @left, right: @right, top: @top, bottom: @bottom }
    end
  end

  class Style
    attr_accessor :display, :position_type, :overflow_x, :overflow_y
    attr_accessor :left, :right, :top, :bottom
    attr_accessor :width, :height, :min_width, :min_height, :max_width, :max_height
    attr_accessor :aspect_ratio
    attr_accessor :margin, :padding, :border
    attr_accessor :flex_direction, :flex_wrap, :flex_grow, :flex_shrink, :flex_basis
    attr_accessor :justify_content, :align_items, :align_self, :align_content
    attr_accessor :row_gap, :column_gap

    def initialize(
      display: Display::FLEX,
      position_type: PositionType::RELATIVE,
      overflow_x: Overflow::VISIBLE,
      overflow_y: Overflow::VISIBLE,
      left: Val.auto,
      right: Val.auto,
      top: Val.auto,
      bottom: Val.auto,
      width: Val.auto,
      height: Val.auto,
      min_width: Val.auto,
      min_height: Val.auto,
      max_width: Val.auto,
      max_height: Val.auto,
      aspect_ratio: nil,
      margin: nil,
      padding: nil,
      border: nil,
      flex_direction: FlexDirection::ROW,
      flex_wrap: :no_wrap,
      flex_grow: 0.0,
      flex_shrink: 1.0,
      flex_basis: Val.auto,
      justify_content: JustifyContent::START,
      align_items: AlignItems::STRETCH,
      align_self: AlignSelf::AUTO,
      align_content: AlignContent::DEFAULT,
      row_gap: Val.px(0),
      column_gap: Val.px(0)
    )
      @display = display
      @position_type = position_type
      @overflow_x = overflow_x
      @overflow_y = overflow_y
      @left = left
      @right = right
      @top = top
      @bottom = bottom
      @width = width
      @height = height
      @min_width = min_width
      @min_height = min_height
      @max_width = max_width
      @max_height = max_height
      @aspect_ratio = aspect_ratio
      @margin = margin || UiRect.all(Val.px(0))
      @padding = padding || UiRect.all(Val.px(0))
      @border = border || UiRect.all(Val.px(0))
      @flex_direction = flex_direction
      @flex_wrap = flex_wrap
      @flex_grow = flex_grow
      @flex_shrink = flex_shrink
      @flex_basis = flex_basis
      @justify_content = justify_content
      @align_items = align_items
      @align_self = align_self
      @align_content = align_content
      @row_gap = row_gap
      @column_gap = column_gap
    end

    def to_h
      {
        display: @display,
        position_type: @position_type,
        overflow_x: @overflow_x,
        overflow_y: @overflow_y,
        left: @left,
        right: @right,
        top: @top,
        bottom: @bottom,
        width: @width,
        height: @height,
        min_width: @min_width,
        min_height: @min_height,
        max_width: @max_width,
        max_height: @max_height,
        aspect_ratio: @aspect_ratio,
        margin: @margin.to_h,
        padding: @padding.to_h,
        border: @border.to_h,
        flex_direction: @flex_direction,
        flex_wrap: @flex_wrap,
        flex_grow: @flex_grow,
        flex_shrink: @flex_shrink,
        flex_basis: @flex_basis,
        justify_content: @justify_content,
        align_items: @align_items,
        align_self: @align_self,
        align_content: @align_content,
        row_gap: @row_gap,
        column_gap: @column_gap
      }
    end
  end

  class Node
    attr_accessor :style

    def initialize(style: nil)
      @style = style || Style.new
    end

    def type_name
      'Node'
    end

    def to_h
      { style: @style.to_h }
    end
  end

  class BackgroundColor
    attr_accessor :color

    def initialize(color = nil)
      @color = color || Color.white
    end

    def type_name
      'BackgroundColor'
    end

    def to_h
      { color: @color.to_a }
    end
  end

  class BorderColor
    attr_accessor :color

    def initialize(color = nil)
      @color = color || Color.transparent
    end

    def type_name
      'BorderColor'
    end

    def to_h
      { color: @color.to_a }
    end
  end

  class BorderRadius
    attr_accessor :top_left, :top_right, :bottom_left, :bottom_right

    def initialize(top_left: Val.px(0), top_right: Val.px(0), bottom_left: Val.px(0), bottom_right: Val.px(0), all: nil)
      if all
        @top_left = @top_right = @bottom_left = @bottom_right = all
      else
        @top_left = top_left
        @top_right = top_right
        @bottom_left = bottom_left
        @bottom_right = bottom_right
      end
    end

    def self.all(val)
      new(all: val)
    end

    def to_h
      { top_left: @top_left, top_right: @top_right, bottom_left: @bottom_left, bottom_right: @bottom_right }
    end
  end

  module Interaction
    NONE = :none
    PRESSED = :pressed
    HOVERED = :hovered
  end

  class Button
    attr_accessor :interaction

    def initialize
      @interaction = Interaction::NONE
    end

    def type_name
      'Button'
    end

    def pressed?
      @interaction == Interaction::PRESSED
    end

    def hovered?
      @interaction == Interaction::HOVERED
    end

    def none?
      @interaction == Interaction::NONE
    end
  end

  class UiImage
    attr_accessor :texture, :flip_x, :flip_y, :color

    def initialize(texture: nil, flip_x: false, flip_y: false, color: nil)
      @texture = texture
      @flip_x = flip_x
      @flip_y = flip_y
      @color = color || Color.white
    end

    def type_name
      'UiImage'
    end

    def to_h
      { texture: @texture, flip_x: @flip_x, flip_y: @flip_y, color: @color.to_a }
    end
  end

  class TextBundle
    attr_accessor :text, :style

    def initialize(text:, style: nil)
      @text = text
      @style = style || Style.new
    end

    def type_name
      'TextBundle'
    end
  end

  class ButtonBundle
    attr_accessor :node, :button, :style, :background_color, :border_color, :border_radius

    def initialize(
      style: nil,
      background_color: nil,
      border_color: nil,
      border_radius: nil
    )
      @node = Node.new(style: style || Style.new)
      @button = Button.new
      @style = style || Style.new
      @background_color = background_color || BackgroundColor.new
      @border_color = border_color || BorderColor.new
      @border_radius = border_radius || BorderRadius.new
    end

    def type_name
      'ButtonBundle'
    end
  end

  class NodeBundle
    attr_accessor :node, :style, :background_color, :border_color, :border_radius, :z_index

    def initialize(
      style: nil,
      background_color: nil,
      border_color: nil,
      border_radius: nil,
      z_index: 0
    )
      @style = style || Style.new
      @node = Node.new(style: @style)
      @background_color = background_color || BackgroundColor.new(Color.transparent)
      @border_color = border_color || BorderColor.new
      @border_radius = border_radius || BorderRadius.new
      @z_index = z_index
    end

    def type_name
      'NodeBundle'
    end
  end

  class ImageBundle
    attr_accessor :node, :style, :image, :background_color

    def initialize(style: nil, image: nil, background_color: nil)
      @style = style || Style.new
      @node = Node.new(style: @style)
      @image = image || UiImage.new
      @background_color = background_color || BackgroundColor.new(Color.white)
    end

    def type_name
      'ImageBundle'
    end
  end
end
