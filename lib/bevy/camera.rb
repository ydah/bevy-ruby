# frozen_string_literal: true

module Bevy
  class Camera2d
    attr_reader :order, :clear_color, :viewport

    def initialize(order: 0, clear_color: nil, viewport: nil)
      @order = order
      @clear_color = clear_color || Color.black
      @viewport = viewport
    end

    def type_name
      'Camera2d'
    end

    def with_order(order)
      self.class.new(order: order, clear_color: @clear_color, viewport: @viewport)
    end

    def with_clear_color(clear_color)
      self.class.new(order: @order, clear_color: clear_color, viewport: @viewport)
    end

    def with_viewport(viewport)
      self.class.new(order: @order, clear_color: @clear_color, viewport: viewport)
    end

    def to_native
      native = Component.new('Camera2d')
      native['order'] = @order
      native['clear_color_r'] = @clear_color.r
      native['clear_color_g'] = @clear_color.g
      native['clear_color_b'] = @clear_color.b
      native['clear_color_a'] = @clear_color.a
      if @viewport
        native['viewport_x'] = @viewport.x
        native['viewport_y'] = @viewport.y
        native['viewport_width'] = @viewport.width
        native['viewport_height'] = @viewport.height
      end
      native
    end

    def self.from_native(native)
      clear_color = Color.new(
        native['clear_color_r'] || 0.0,
        native['clear_color_g'] || 0.0,
        native['clear_color_b'] || 0.0,
        native['clear_color_a'] || 1.0
      )
      viewport = nil
      if native['viewport_width']
        viewport = Viewport.new(
          native['viewport_x'] || 0,
          native['viewport_y'] || 0,
          native['viewport_width'],
          native['viewport_height']
        )
      end
      new(order: native['order'] || 0, clear_color: clear_color, viewport: viewport)
    end

    def to_h
      h = {
        order: @order,
        clear_color: @clear_color.to_a
      }
      h[:viewport] = @viewport.to_h if @viewport
      h
    end
  end

  class Camera3d
    attr_reader :order, :clear_color, :fov, :near, :far, :viewport

    def initialize(order: 0, clear_color: nil, fov: 45.0, near: 0.1, far: 1000.0, viewport: nil)
      @order = order
      @clear_color = clear_color || Color.black
      @fov = fov
      @near = near
      @far = far
      @viewport = viewport
    end

    def type_name
      'Camera3d'
    end

    def with_order(order)
      self.class.new(
        order: order,
        clear_color: @clear_color,
        fov: @fov,
        near: @near,
        far: @far,
        viewport: @viewport
      )
    end

    def with_clear_color(clear_color)
      self.class.new(
        order: @order,
        clear_color: clear_color,
        fov: @fov,
        near: @near,
        far: @far,
        viewport: @viewport
      )
    end

    def with_fov(fov)
      self.class.new(
        order: @order,
        clear_color: @clear_color,
        fov: fov,
        near: @near,
        far: @far,
        viewport: @viewport
      )
    end

    def with_near(near)
      self.class.new(
        order: @order,
        clear_color: @clear_color,
        fov: @fov,
        near: near,
        far: @far,
        viewport: @viewport
      )
    end

    def with_far(far)
      self.class.new(
        order: @order,
        clear_color: @clear_color,
        fov: @fov,
        near: @near,
        far: far,
        viewport: @viewport
      )
    end

    def with_viewport(viewport)
      self.class.new(
        order: @order,
        clear_color: @clear_color,
        fov: @fov,
        near: @near,
        far: @far,
        viewport: viewport
      )
    end

    def to_native
      native = Component.new('Camera3d')
      native['order'] = @order
      native['clear_color_r'] = @clear_color.r
      native['clear_color_g'] = @clear_color.g
      native['clear_color_b'] = @clear_color.b
      native['clear_color_a'] = @clear_color.a
      native['fov'] = @fov
      native['near'] = @near
      native['far'] = @far
      if @viewport
        native['viewport_x'] = @viewport.x
        native['viewport_y'] = @viewport.y
        native['viewport_width'] = @viewport.width
        native['viewport_height'] = @viewport.height
      end
      native
    end

    def self.from_native(native)
      clear_color = Color.new(
        native['clear_color_r'] || 0.0,
        native['clear_color_g'] || 0.0,
        native['clear_color_b'] || 0.0,
        native['clear_color_a'] || 1.0
      )
      viewport = nil
      if native['viewport_width']
        viewport = Viewport.new(
          native['viewport_x'] || 0,
          native['viewport_y'] || 0,
          native['viewport_width'],
          native['viewport_height']
        )
      end
      new(
        order: native['order'] || 0,
        clear_color: clear_color,
        fov: native['fov'] || 45.0,
        near: native['near'] || 0.1,
        far: native['far'] || 1000.0,
        viewport: viewport
      )
    end

    def to_h
      h = {
        order: @order,
        clear_color: @clear_color.to_a,
        fov: @fov,
        near: @near,
        far: @far
      }
      h[:viewport] = @viewport.to_h if @viewport
      h
    end
  end

  class Viewport
    attr_reader :x, :y, :width, :height

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    def to_h
      { x: @x, y: @y, width: @width, height: @height }
    end
  end

  class SmoothFollow
    attr_accessor :target, :offset, :smoothness, :enabled

    def initialize(smoothness: 5.0, offset: nil, enabled: true)
      @smoothness = smoothness
      @offset = offset || Vec3.new(0.0, 0.0, 0.0)
      @enabled = enabled
      @target = nil
    end

    def type_name
      'SmoothFollow'
    end

    def follow(target)
      @target = target
      self
    end

    def lerp_position(current, delta_time)
      return current unless @target && @enabled

      desired = Vec3.new(
        @target.x + @offset.x,
        @target.y + @offset.y,
        @target.z + @offset.z
      )
      t = [@smoothness * delta_time, 1.0].min
      Vec3.new(
        current.x + (desired.x - current.x) * t,
        current.y + (desired.y - current.y) * t,
        current.z + (desired.z - current.z) * t
      )
    end

    def to_native
      native = Component.new('SmoothFollow')
      native['smoothness'] = @smoothness
      native['offset_x'] = @offset.x
      native['offset_y'] = @offset.y
      native['offset_z'] = @offset.z
      native['enabled'] = @enabled
      if @target
        native['target_x'] = @target.x
        native['target_y'] = @target.y
        native['target_z'] = @target.z
      end
      native
    end
  end

  class CameraShake
    attr_accessor :intensity, :duration, :decay, :frequency
    attr_reader :remaining_time

    def initialize(frequency: 20.0, decay: 1.0)
      @intensity = 0.0
      @duration = 0.0
      @decay = decay
      @frequency = frequency
      @remaining_time = 0.0
      @time_elapsed = 0.0
    end

    def type_name
      'CameraShake'
    end

    def trigger(intensity, duration, decay: nil)
      @intensity = intensity
      @duration = duration
      @decay = decay if decay
      @remaining_time = duration
      @time_elapsed = 0.0
    end

    def update(delta_time)
      return Vec2.new(0.0, 0.0) if @remaining_time <= 0.0

      @remaining_time -= delta_time
      @time_elapsed += delta_time

      progress = 1.0 - (@remaining_time / @duration)
      decay_factor = (1.0 - progress)**@decay
      current_intensity = @intensity * decay_factor

      angle = @time_elapsed * @frequency * Math::PI * 2
      x = Math.sin(angle) * current_intensity
      y = Math.cos(angle * 1.3) * current_intensity

      Vec2.new(x, y)
    end

    def active?
      @remaining_time > 0.0
    end

    def stop
      @remaining_time = 0.0
    end

    def to_native
      native = Component.new('CameraShake')
      native['intensity'] = @intensity
      native['duration'] = @duration
      native['decay'] = @decay
      native['frequency'] = @frequency
      native['remaining_time'] = @remaining_time
      native
    end
  end

  class CameraBounds
    attr_accessor :min_x, :min_y, :max_x, :max_y, :enabled

    def initialize(min_x: nil, min_y: nil, max_x: nil, max_y: nil)
      @min_x = min_x || -Float::INFINITY
      @min_y = min_y || -Float::INFINITY
      @max_x = max_x || Float::INFINITY
      @max_y = max_y || Float::INFINITY
      @enabled = min_x || min_y || max_x || max_y ? true : false
    end

    def type_name
      'CameraBounds'
    end

    def clamp(position)
      return position unless @enabled

      Vec3.new(
        [[position.x, @min_x].max, @max_x].min,
        [[position.y, @min_y].max, @max_y].min,
        position.z
      )
    end

    def to_native
      native = Component.new('CameraBounds')
      native['min_x'] = @min_x
      native['min_y'] = @min_y
      native['max_x'] = @max_x
      native['max_y'] = @max_y
      native['enabled'] = @enabled
      native
    end
  end

  class CameraZoom
    attr_accessor :current, :min, :max, :speed

    def initialize(initial: 1.0, min: 0.1, max: 10.0, speed: 1.0)
      @current = initial
      @min = min
      @max = max
      @speed = speed
    end

    def type_name
      'CameraZoom'
    end

    def zoom_in(amount = 0.1)
      @current = [[@current - amount * @speed, @min].max, @max].min
    end

    def zoom_out(amount = 0.1)
      @current = [[@current + amount * @speed, @min].max, @max].min
    end

    def set(value)
      @current = [[value, @min].max, @max].min
    end

    def to_native
      native = Component.new('CameraZoom')
      native['current'] = @current
      native['min'] = @min
      native['max'] = @max
      native['speed'] = @speed
      native
    end
  end
end
