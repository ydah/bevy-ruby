# frozen_string_literal: true

module Bevy
  module WindowMode
    WINDOWED = :windowed
    BORDERLESS_FULLSCREEN = :borderless_fullscreen
    SIZED_FULLSCREEN = :sized_fullscreen
    FULLSCREEN = :fullscreen
  end

  module CursorGrabMode
    NONE = :none
    CONFINED = :confined
    LOCKED = :locked
  end

  module PresentMode
    AUTO_VSYNC = :auto_vsync
    AUTO_NO_VSYNC = :auto_no_vsync
    FIFO = :fifo
    FIFO_RELAXED = :fifo_relaxed
    IMMEDIATE = :immediate
    MAILBOX = :mailbox
  end

  class Window
    attr_accessor :title, :width, :height, :position_x, :position_y
    attr_accessor :mode, :present_mode, :resizable, :decorations
    attr_accessor :cursor_visible, :cursor_grab_mode
    attr_accessor :focused, :visible, :always_on_top
    attr_accessor :resolution_scale_factor

    def initialize(
      title: 'Bevy App',
      width: 1280.0,
      height: 720.0,
      mode: WindowMode::WINDOWED,
      resizable: true,
      decorations: true
    )
      @title = title
      @width = width.to_f
      @height = height.to_f
      @position_x = nil
      @position_y = nil
      @mode = mode
      @present_mode = PresentMode::AUTO_VSYNC
      @resizable = resizable
      @decorations = decorations
      @cursor_visible = true
      @cursor_grab_mode = CursorGrabMode::NONE
      @focused = true
      @visible = true
      @always_on_top = false
      @resolution_scale_factor = 1.0
    end

    def set_title(title)
      @title = title
      self
    end

    def resize(width, height)
      @width = width.to_f
      @height = height.to_f
      self
    end

    def set_position(x, y)
      @position_x = x.to_f
      @position_y = y.to_f
      self
    end

    def center
      @position_x = nil
      @position_y = nil
      self
    end

    def set_mode(mode)
      @mode = mode
      self
    end

    def fullscreen
      @mode = WindowMode::FULLSCREEN
      self
    end

    def borderless_fullscreen
      @mode = WindowMode::BORDERLESS_FULLSCREEN
      self
    end

    def windowed
      @mode = WindowMode::WINDOWED
      self
    end

    def toggle_fullscreen
      @mode = if @mode == WindowMode::WINDOWED
                WindowMode::BORDERLESS_FULLSCREEN
              else
                WindowMode::WINDOWED
              end
      self
    end

    def hide_cursor
      @cursor_visible = false
      self
    end

    def show_cursor
      @cursor_visible = true
      self
    end

    def lock_cursor
      @cursor_grab_mode = CursorGrabMode::LOCKED
      self
    end

    def confine_cursor
      @cursor_grab_mode = CursorGrabMode::CONFINED
      self
    end

    def release_cursor
      @cursor_grab_mode = CursorGrabMode::NONE
      self
    end

    def aspect_ratio
      return 0.0 if @height.zero?

      @width / @height
    end

    def resolution
      Vec2.new(@width, @height)
    end

    def fullscreen?
      @mode != WindowMode::WINDOWED
    end

    def type_name
      'Window'
    end

    def to_h
      {
        title: @title,
        width: @width,
        height: @height,
        mode: @mode,
        resizable: @resizable,
        decorations: @decorations,
        cursor_visible: @cursor_visible,
        cursor_grab_mode: @cursor_grab_mode
      }
    end
  end

  class PrimaryWindow
    attr_reader :window

    def initialize(window = nil)
      @window = window || Window.new
    end

    delegate_missing_to :@window if defined?(delegate_missing_to)

    def method_missing(method, *args, &block)
      if @window.respond_to?(method)
        @window.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @window.respond_to?(method) || super
    end

    def type_name
      'PrimaryWindow'
    end
  end

  class WindowResized
    attr_reader :window_id, :width, :height

    def initialize(window_id:, width:, height:)
      @window_id = window_id
      @width = width.to_f
      @height = height.to_f
    end

    def type_name
      'WindowResized'
    end
  end

  class WindowMoved
    attr_reader :window_id, :position_x, :position_y

    def initialize(window_id:, position_x:, position_y:)
      @window_id = window_id
      @position_x = position_x.to_f
      @position_y = position_y.to_f
    end

    def type_name
      'WindowMoved'
    end
  end

  class WindowFocused
    attr_reader :window_id, :focused

    def initialize(window_id:, focused:)
      @window_id = window_id
      @focused = focused
    end

    def focused?
      @focused
    end

    def type_name
      'WindowFocused'
    end
  end

  class WindowCloseRequested
    attr_reader :window_id

    def initialize(window_id:)
      @window_id = window_id
    end

    def type_name
      'WindowCloseRequested'
    end
  end

  class WindowCreated
    attr_reader :window_id

    def initialize(window_id:)
      @window_id = window_id
    end

    def type_name
      'WindowCreated'
    end
  end

  class Monitor
    attr_reader :name, :physical_width, :physical_height, :refresh_rate, :scale_factor

    def initialize(name:, physical_width:, physical_height:, refresh_rate: 60.0, scale_factor: 1.0)
      @name = name
      @physical_width = physical_width
      @physical_height = physical_height
      @refresh_rate = refresh_rate.to_f
      @scale_factor = scale_factor.to_f
    end

    def resolution
      Vec2.new(@physical_width.to_f, @physical_height.to_f)
    end

    def type_name
      'Monitor'
    end
  end

  class WindowPlugin
    attr_accessor :primary_window, :exit_condition, :close_when_requested

    def initialize(primary_window: nil, close_when_requested: true)
      @primary_window = primary_window
      @close_when_requested = close_when_requested
      @exit_condition = :on_primary_closed
    end

    def build(app)
      if @primary_window
        app.insert_resource(PrimaryWindow.new(@primary_window))
      end
      app
    end

    def type_name
      'WindowPlugin'
    end
  end
end
