# frozen_string_literal: true

module Bevy
  module Anchor
    CENTER = :center
    TOP_LEFT = :top_left
    TOP_CENTER = :top_center
    TOP_RIGHT = :top_right
    CENTER_LEFT = :center_left
    CENTER_RIGHT = :center_right
    BOTTOM_LEFT = :bottom_left
    BOTTOM_CENTER = :bottom_center
    BOTTOM_RIGHT = :bottom_right
  end

  class TextureAtlasLayout
    attr_reader :size, :tile_size, :columns, :rows, :padding, :offset
    attr_reader :textures

    def initialize(
      tile_size:,
      columns:,
      rows:,
      padding: nil,
      offset: nil
    )
      @tile_size = tile_size
      @columns = columns
      @rows = rows
      @padding = padding || Vec2.zero
      @offset = offset || Vec2.zero
      @size = Vec2.new(
        @tile_size.x * @columns + @padding.x * (@columns - 1) + @offset.x * 2,
        @tile_size.y * @rows + @padding.y * (@rows - 1) + @offset.y * 2
      )
      @textures = build_texture_rects
    end

    def self.from_grid(tile_size:, columns:, rows:, padding: nil, offset: nil)
      new(
        tile_size: tile_size,
        columns: columns,
        rows: rows,
        padding: padding,
        offset: offset
      )
    end

    def tile_count
      @columns * @rows
    end

    def get_texture_rect(index)
      return nil if index < 0 || index >= tile_count

      @textures[index]
    end

    def index_for(column, row)
      return nil if column < 0 || column >= @columns
      return nil if row < 0 || row >= @rows

      row * @columns + column
    end

    def column_row_for(index)
      return nil if index < 0 || index >= tile_count

      row = index / @columns
      column = index % @columns
      [column, row]
    end

    def type_name
      'TextureAtlasLayout'
    end

    private

    def build_texture_rects
      rects = []
      @rows.times do |row|
        @columns.times do |col|
          x = @offset.x + col * (@tile_size.x + @padding.x)
          y = @offset.y + row * (@tile_size.y + @padding.y)
          rects << Rect.new(
            min: Vec2.new(x, y),
            max: Vec2.new(x + @tile_size.x, y + @tile_size.y)
          )
        end
      end
      rects
    end
  end

  class TextureAtlas
    attr_reader :layout, :image

    def initialize(layout:, image:)
      @layout = layout
      @image = image
    end

    def tile_count
      @layout.tile_count
    end

    def get_texture_rect(index)
      @layout.get_texture_rect(index)
    end

    def type_name
      'TextureAtlas'
    end
  end

  class TextureAtlasSprite
    attr_accessor :index, :color, :flip_x, :flip_y, :custom_size, :anchor

    def initialize(
      index: 0,
      color: nil,
      flip_x: false,
      flip_y: false,
      custom_size: nil,
      anchor: nil
    )
      @index = index
      @color = color || Color.white
      @flip_x = flip_x
      @flip_y = flip_y
      @custom_size = custom_size
      @anchor = anchor || Anchor::CENTER
    end

    def type_name
      'TextureAtlasSprite'
    end
  end

  class SpriteSheetBundle
    attr_reader :sprite, :atlas, :transform, :global_transform, :visibility

    def initialize(
      sprite: nil,
      atlas: nil,
      transform: nil
    )
      @sprite = sprite || TextureAtlasSprite.new
      @atlas = atlas
      @transform = transform || Transform.identity
      @global_transform = GlobalTransform.from_transform(@transform)
      @visibility = Visibility.new
    end

    def components
      [@sprite, @atlas, @transform, @global_transform, @visibility]
    end

    def type_name
      'SpriteSheetBundle'
    end
  end

  class AnimatedSprite
    attr_accessor :frames, :current_frame, :timer, :looping, :playing

    def initialize(
      frames: [],
      frame_duration: 0.1,
      looping: true
    )
      @frames = frames
      @frame_duration = frame_duration
      @current_frame = 0
      @timer = 0.0
      @looping = looping
      @playing = true
    end

    def frame_duration
      @frame_duration
    end

    def frame_duration=(value)
      @frame_duration = value.to_f
    end

    def fps
      1.0 / @frame_duration
    end

    def fps=(value)
      @frame_duration = 1.0 / value.to_f
    end

    def update(delta)
      return unless @playing
      return if @frames.empty?

      @timer += delta

      while @timer >= @frame_duration
        @timer -= @frame_duration
        @current_frame += 1

        if @current_frame >= @frames.size
          if @looping
            @current_frame = 0
          else
            @current_frame = @frames.size - 1
            @playing = false
          end
        end
      end
    end

    def current_index
      return 0 if @frames.empty?

      @frames[@current_frame]
    end

    def play
      @playing = true
    end

    def pause
      @playing = false
    end

    def stop
      @playing = false
      @current_frame = 0
      @timer = 0.0
    end

    def reset
      @current_frame = 0
      @timer = 0.0
    end

    def finished?
      !@looping && @current_frame >= @frames.size - 1 && @timer >= @frame_duration
    end

    def type_name
      'AnimatedSprite'
    end
  end

  class SpriteSheetAnimation
    attr_reader :name, :frames, :frame_duration, :looping

    def initialize(name:, frames:, frame_duration: 0.1, looping: true)
      @name = name
      @frames = frames
      @frame_duration = frame_duration
      @looping = looping
    end

    def to_animated_sprite
      AnimatedSprite.new(
        frames: @frames,
        frame_duration: @frame_duration,
        looping: @looping
      )
    end

    def type_name
      'SpriteSheetAnimation'
    end
  end

  class AnimationLibrary
    attr_reader :animations

    def initialize
      @animations = {}
    end

    def add(animation)
      @animations[animation.name] = animation
      self
    end

    def get(name)
      @animations[name]
    end

    def remove(name)
      @animations.delete(name)
    end

    def names
      @animations.keys
    end

    def type_name
      'AnimationLibrary'
    end
  end

  class Rect
    attr_accessor :min, :max

    def initialize(min:, max:)
      @min = min
      @max = max
    end

    def width
      @max.x - @min.x
    end

    def height
      @max.y - @min.y
    end

    def size
      Vec2.new(width, height)
    end

    def center
      Vec2.new(
        (@min.x + @max.x) / 2.0,
        (@min.y + @max.y) / 2.0
      )
    end

    def contains?(point)
      point.x >= @min.x && point.x <= @max.x &&
        point.y >= @min.y && point.y <= @max.y
    end

    def intersects?(other)
      @min.x < other.max.x && @max.x > other.min.x &&
        @min.y < other.max.y && @max.y > other.min.y
    end

    def type_name
      'Rect'
    end
  end

  class NineSlice
    attr_reader :border_left, :border_right, :border_top, :border_bottom
    attr_accessor :center_scale_mode

    STRETCH = :stretch
    TILE = :tile

    def initialize(
      border_left: 0.0,
      border_right: 0.0,
      border_top: 0.0,
      border_bottom: 0.0,
      center_scale_mode: STRETCH
    )
      @border_left = border_left.to_f
      @border_right = border_right.to_f
      @border_top = border_top.to_f
      @border_bottom = border_bottom.to_f
      @center_scale_mode = center_scale_mode
    end

    def self.from_single_border(border)
      new(
        border_left: border,
        border_right: border,
        border_top: border,
        border_bottom: border
      )
    end

    def slices_for(source_rect, target_size)
      source_w = source_rect.width
      source_h = source_rect.height
      target_w = target_size.x
      target_h = target_size.y

      center_source_w = source_w - @border_left - @border_right
      center_source_h = source_h - @border_top - @border_bottom
      center_target_w = target_w - @border_left - @border_right
      center_target_h = target_h - @border_top - @border_bottom

      {
        top_left: slice_rect(source_rect.min.x, source_rect.min.y, @border_left, @border_top),
        top: slice_rect(source_rect.min.x + @border_left, source_rect.min.y, center_source_w, @border_top),
        top_right: slice_rect(source_rect.max.x - @border_right, source_rect.min.y, @border_right, @border_top),
        left: slice_rect(source_rect.min.x, source_rect.min.y + @border_top, @border_left, center_source_h),
        center: slice_rect(source_rect.min.x + @border_left, source_rect.min.y + @border_top, center_source_w, center_source_h),
        right: slice_rect(source_rect.max.x - @border_right, source_rect.min.y + @border_top, @border_right, center_source_h),
        bottom_left: slice_rect(source_rect.min.x, source_rect.max.y - @border_bottom, @border_left, @border_bottom),
        bottom: slice_rect(source_rect.min.x + @border_left, source_rect.max.y - @border_bottom, center_source_w, @border_bottom),
        bottom_right: slice_rect(source_rect.max.x - @border_right, source_rect.max.y - @border_bottom, @border_right, @border_bottom)
      }
    end

    def type_name
      'NineSlice'
    end

    private

    def slice_rect(x, y, width, height)
      Rect.new(
        min: Vec2.new(x, y),
        max: Vec2.new(x + width, y + height)
      )
    end
  end

  class TiledSprite
    attr_accessor :tile_size, :repeat_x, :repeat_y, :spacing

    def initialize(
      tile_size:,
      repeat_x: 1,
      repeat_y: 1,
      spacing: nil
    )
      @tile_size = tile_size
      @repeat_x = repeat_x
      @repeat_y = repeat_y
      @spacing = spacing || Vec2.zero
    end

    def total_size
      Vec2.new(
        @tile_size.x * @repeat_x + @spacing.x * (@repeat_x - 1),
        @tile_size.y * @repeat_y + @spacing.y * (@repeat_y - 1)
      )
    end

    def tile_count
      @repeat_x * @repeat_y
    end

    def type_name
      'TiledSprite'
    end
  end
end
