# frozen_string_literal: true

module Bevy
  module Easing
    def self.linear(t)
      t
    end

    def self.ease_in_quad(t)
      t * t
    end

    def self.ease_out_quad(t)
      1.0 - (1.0 - t) * (1.0 - t)
    end

    def self.ease_in_out_quad(t)
      t < 0.5 ? 2.0 * t * t : 1.0 - ((-2.0 * t + 2.0)**2) / 2.0
    end

    def self.ease_in_cubic(t)
      t * t * t
    end

    def self.ease_out_cubic(t)
      1.0 - ((1.0 - t)**3)
    end

    def self.ease_in_out_cubic(t)
      t < 0.5 ? 4.0 * t * t * t : 1.0 - ((-2.0 * t + 2.0)**3) / 2.0
    end

    def self.ease_in_sine(t)
      1.0 - Math.cos((t * Math::PI) / 2.0)
    end

    def self.ease_out_sine(t)
      Math.sin((t * Math::PI) / 2.0)
    end

    def self.ease_in_out_sine(t)
      -(Math.cos(Math::PI * t) - 1.0) / 2.0
    end

    def self.ease_in_expo(t)
      t == 0.0 ? 0.0 : 2.0**(10.0 * t - 10.0)
    end

    def self.ease_out_expo(t)
      t == 1.0 ? 1.0 : 1.0 - 2.0**(-10.0 * t)
    end

    def self.ease_in_out_expo(t)
      return 0.0 if t == 0.0
      return 1.0 if t == 1.0

      if t < 0.5
        2.0**(20.0 * t - 10.0) / 2.0
      else
        (2.0 - 2.0**(-20.0 * t + 10.0)) / 2.0
      end
    end

    def self.ease_in_back(t)
      c1 = 1.70158
      c3 = c1 + 1.0
      c3 * t * t * t - c1 * t * t
    end

    def self.ease_out_back(t)
      c1 = 1.70158
      c3 = c1 + 1.0
      1.0 + c3 * ((t - 1.0)**3) + c1 * ((t - 1.0)**2)
    end

    def self.ease_in_out_back(t)
      c1 = 1.70158
      c2 = c1 * 1.525
      if t < 0.5
        ((2.0 * t)**2 * ((c2 + 1.0) * 2.0 * t - c2)) / 2.0
      else
        ((2.0 * t - 2.0)**2 * ((c2 + 1.0) * (t * 2.0 - 2.0) + c2) + 2.0) / 2.0
      end
    end

    def self.ease_in_elastic(t)
      return 0.0 if t == 0.0
      return 1.0 if t == 1.0

      c4 = (2.0 * Math::PI) / 3.0
      -(2.0**(10.0 * t - 10.0)) * Math.sin((t * 10.0 - 10.75) * c4)
    end

    def self.ease_out_elastic(t)
      return 0.0 if t == 0.0
      return 1.0 if t == 1.0

      c4 = (2.0 * Math::PI) / 3.0
      2.0**(-10.0 * t) * Math.sin((t * 10.0 - 0.75) * c4) + 1.0
    end

    def self.ease_in_bounce(t)
      1.0 - ease_out_bounce(1.0 - t)
    end

    def self.ease_out_bounce(t)
      n1 = 7.5625
      d1 = 2.75

      if t < 1.0 / d1
        n1 * t * t
      elsif t < 2.0 / d1
        t -= 1.5 / d1
        n1 * t * t + 0.75
      elsif t < 2.5 / d1
        t -= 2.25 / d1
        n1 * t * t + 0.9375
      else
        t -= 2.625 / d1
        n1 * t * t + 0.984375
      end
    end

    def self.ease_in_out_bounce(t)
      if t < 0.5
        (1.0 - ease_out_bounce(1.0 - 2.0 * t)) / 2.0
      else
        (1.0 + ease_out_bounce(2.0 * t - 1.0)) / 2.0
      end
    end

    def self.apply(easing, t)
      case easing
      when :linear then linear(t)
      when :ease_in_quad then ease_in_quad(t)
      when :ease_out_quad then ease_out_quad(t)
      when :ease_in_out_quad then ease_in_out_quad(t)
      when :ease_in_cubic then ease_in_cubic(t)
      when :ease_out_cubic then ease_out_cubic(t)
      when :ease_in_out_cubic then ease_in_out_cubic(t)
      when :ease_in_sine then ease_in_sine(t)
      when :ease_out_sine then ease_out_sine(t)
      when :ease_in_out_sine then ease_in_out_sine(t)
      when :ease_in_expo then ease_in_expo(t)
      when :ease_out_expo then ease_out_expo(t)
      when :ease_in_out_expo then ease_in_out_expo(t)
      when :ease_in_back then ease_in_back(t)
      when :ease_out_back then ease_out_back(t)
      when :ease_in_out_back then ease_in_out_back(t)
      when :ease_in_elastic then ease_in_elastic(t)
      when :ease_out_elastic then ease_out_elastic(t)
      when :ease_in_bounce then ease_in_bounce(t)
      when :ease_out_bounce then ease_out_bounce(t)
      when :ease_in_out_bounce then ease_in_out_bounce(t)
      when Proc then easing.call(t)
      else linear(t)
      end
    end
  end

  class Keyframe
    attr_reader :time, :value, :easing

    def initialize(time, value, easing: :linear)
      @time = time.to_f
      @value = value
      @easing = easing
    end

    def interpolate_to(other, t)
      eased_t = Easing.apply(@easing, t)

      case @value
      when Numeric
        @value + (other.value - @value) * eased_t
      when Vec2
        Vec2.new(
          @value.x + (other.value.x - @value.x) * eased_t,
          @value.y + (other.value.y - @value.y) * eased_t
        )
      when Vec3
        Vec3.new(
          @value.x + (other.value.x - @value.x) * eased_t,
          @value.y + (other.value.y - @value.y) * eased_t,
          @value.z + (other.value.z - @value.z) * eased_t
        )
      when Color
        Color.rgba(
          @value.r + (other.value.r - @value.r) * eased_t,
          @value.g + (other.value.g - @value.g) * eased_t,
          @value.b + (other.value.b - @value.b) * eased_t,
          @value.a + (other.value.a - @value.a) * eased_t
        )
      when Array
        @value.zip(other.value).map do |a, b|
          a + (b - a) * eased_t
        end
      when Hash
        @value.keys.each_with_object({}) do |key, result|
          a = @value[key]
          b = other.value[key]
          result[key] = a + (b - a) * eased_t
        end
      else
        t < 1.0 ? @value : other.value
      end
    end
  end

  class AnimationTrack
    attr_reader :property, :keyframes

    def initialize(property)
      @property = property
      @keyframes = []
    end

    def add_keyframe(time, value, easing: :linear)
      @keyframes << Keyframe.new(time, value, easing: easing)
      @keyframes.sort_by!(&:time)
      self
    end

    def duration
      return 0.0 if @keyframes.empty?

      @keyframes.last.time
    end

    def sample(time)
      return nil if @keyframes.empty?
      return @keyframes.first.value if time <= @keyframes.first.time
      return @keyframes.last.value if time >= @keyframes.last.time

      prev_keyframe = nil
      next_keyframe = nil

      @keyframes.each_cons(2) do |a, b|
        if time >= a.time && time < b.time
          prev_keyframe = a
          next_keyframe = b
          break
        end
      end

      return @keyframes.last.value unless prev_keyframe && next_keyframe

      local_t = (time - prev_keyframe.time) / (next_keyframe.time - prev_keyframe.time)
      prev_keyframe.interpolate_to(next_keyframe, local_t)
    end
  end

  class AnimationClip
    attr_reader :name, :tracks, :repeat_mode

    def initialize(name, repeat_mode: :once)
      @name = name
      @tracks = {}
      @repeat_mode = repeat_mode
    end

    def add_track(property)
      @tracks[property] = AnimationTrack.new(property)
      @tracks[property]
    end

    def get_track(property)
      @tracks[property]
    end

    def duration
      @tracks.values.map(&:duration).max || 0.0
    end

    def sample(time)
      @tracks.transform_values { |track| track.sample(time) }
    end

    def sample_property(property, time)
      track = @tracks[property]
      track&.sample(time)
    end

    def type_name
      'AnimationClip'
    end
  end

  class AnimationPlayer
    attr_reader :current_clip, :elapsed, :speed, :paused

    def initialize
      @clips = {}
      @current_clip = nil
      @elapsed = 0.0
      @speed = 1.0
      @paused = false
      @on_finish_callbacks = []
      @on_loop_callbacks = []
    end

    def add_clip(clip)
      @clips[clip.name] = clip
      self
    end

    def play(clip_name, restart: false)
      if @current_clip != clip_name || restart
        @current_clip = clip_name
        @elapsed = 0.0
      end
      @paused = false
      self
    end

    def pause
      @paused = true
      self
    end

    def resume
      @paused = false
      self
    end

    def stop
      @current_clip = nil
      @elapsed = 0.0
      @paused = false
      self
    end

    def set_speed(speed)
      @speed = speed
      self
    end

    def seek(time)
      @elapsed = time.clamp(0.0, duration)
      self
    end

    def on_finish(&block)
      @on_finish_callbacks << block
      self
    end

    def on_loop(&block)
      @on_loop_callbacks << block
      self
    end

    def update(delta)
      return unless @current_clip && !@paused

      clip = @clips[@current_clip]
      return unless clip

      @elapsed += delta * @speed
      clip_duration = clip.duration

      return if clip_duration <= 0.0

      case clip.repeat_mode
      when :once
        if @elapsed >= clip_duration
          @elapsed = clip_duration
          @on_finish_callbacks.each(&:call)
          @current_clip = nil
        end
      when :loop
        while @elapsed >= clip_duration
          @elapsed -= clip_duration
          @on_loop_callbacks.each(&:call)
        end
      when :ping_pong
        cycle = (@elapsed / clip_duration).to_i
        local_t = @elapsed % clip_duration
        @elapsed = cycle.odd? ? clip_duration - local_t : local_t
      end
    end

    def sample
      return {} unless @current_clip

      clip = @clips[@current_clip]
      return {} unless clip

      clip.sample(@elapsed)
    end

    def sample_property(property)
      return nil unless @current_clip

      clip = @clips[@current_clip]
      return nil unless clip

      clip.sample_property(property, @elapsed)
    end

    def duration
      return 0.0 unless @current_clip

      @clips[@current_clip]&.duration || 0.0
    end

    def progress
      d = duration
      return 0.0 if d <= 0.0

      @elapsed / d
    end

    def playing?
      @current_clip && !@paused
    end

    def finished?
      @current_clip.nil? && @elapsed > 0.0
    end

    def type_name
      'AnimationPlayer'
    end
  end

  class Tween
    attr_reader :from, :to, :duration, :elapsed, :easing, :repeat_mode

    def initialize(from:, to:, duration:, easing: :linear, repeat_mode: :once, delay: 0.0)
      @from = from
      @to = to
      @duration = duration.to_f
      @easing = easing
      @repeat_mode = repeat_mode
      @delay = delay.to_f
      @elapsed = 0.0
      @started = false
      @finished = false
      @on_update_callbacks = []
      @on_complete_callbacks = []
    end

    def update(delta)
      return if @finished

      if !@started
        @delay -= delta
        if @delay <= 0.0
          @started = true
          @elapsed = -@delay
        else
          return
        end
      else
        @elapsed += delta
      end

      if @elapsed >= @duration
        case @repeat_mode
        when :once
          @elapsed = @duration
          @finished = true
          @on_complete_callbacks.each(&:call)
        when :loop
          @elapsed = @elapsed % @duration
        when :ping_pong
          cycle = (@elapsed / @duration).to_i
          local_t = @elapsed % @duration
          @elapsed = cycle.odd? ? @duration - local_t : local_t
        end
      end

      @on_update_callbacks.each { |cb| cb.call(current_value) }
    end

    def current_value
      t = progress
      Keyframe.new(0, @from, easing: @easing).interpolate_to(Keyframe.new(1, @to), t)
    end

    def progress
      return 0.0 if @duration <= 0.0

      (@elapsed / @duration).clamp(0.0, 1.0)
    end

    def finished?
      @finished
    end

    def started?
      @started
    end

    def reset
      @elapsed = 0.0
      @started = false
      @finished = false
      self
    end

    def on_update(&block)
      @on_update_callbacks << block
      self
    end

    def on_complete(&block)
      @on_complete_callbacks << block
      self
    end

    def type_name
      'Tween'
    end
  end

  class TweenSequence
    def initialize
      @tweens = []
      @current_index = 0
      @finished = false
    end

    def add(tween)
      @tweens << tween
      self
    end

    def update(delta)
      return if @finished || @tweens.empty?

      current_tween = @tweens[@current_index]
      current_tween.update(delta)

      if current_tween.finished?
        @current_index += 1
        if @current_index >= @tweens.size
          @finished = true
        end
      end
    end

    def current_value
      return nil if @tweens.empty?

      @tweens[@current_index]&.current_value
    end

    def finished?
      @finished
    end

    def reset
      @tweens.each(&:reset)
      @current_index = 0
      @finished = false
      self
    end

    def type_name
      'TweenSequence'
    end
  end

  class TweenGroup
    def initialize
      @tweens = []
    end

    def add(tween)
      @tweens << tween
      self
    end

    def update(delta)
      @tweens.each { |t| t.update(delta) }
    end

    def values
      @tweens.map(&:current_value)
    end

    def finished?
      @tweens.all?(&:finished?)
    end

    def reset
      @tweens.each(&:reset)
      self
    end

    def type_name
      'TweenGroup'
    end
  end
end
