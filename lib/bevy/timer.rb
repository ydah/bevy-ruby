# frozen_string_literal: true

module Bevy
  class Timer
    attr_reader :duration, :elapsed, :mode

    module TimerMode
      ONCE = :once
      REPEATING = :repeating
    end

    def initialize(duration, mode: TimerMode::ONCE)
      @duration = duration.to_f
      @elapsed = 0.0
      @mode = mode
      @finished = false
      @just_finished = false
      @times_finished = 0
      @paused = false
    end

    def self.from_seconds(seconds, mode: TimerMode::ONCE)
      new(seconds, mode: mode)
    end

    def tick(delta)
      @just_finished = false

      return self if @paused
      return self if @mode == TimerMode::ONCE && @finished

      @elapsed += delta

      if @elapsed >= @duration
        @times_finished += 1
        @just_finished = true

        if @mode == TimerMode::REPEATING
          @elapsed -= @duration
        else
          @elapsed = @duration
          @finished = true
        end
      end

      self
    end

    def finished?
      @finished
    end

    def just_finished?
      @just_finished
    end

    def percent
      return 1.0 if @duration <= 0.0

      (@elapsed / @duration).clamp(0.0, 1.0)
    end

    def percent_left
      1.0 - percent
    end

    def remaining
      (@duration - @elapsed).clamp(0.0, @duration)
    end

    def times_finished_this_tick
      @just_finished ? 1 : 0
    end

    def reset
      @elapsed = 0.0
      @finished = false
      @just_finished = false
      self
    end

    def pause
      @paused = true
      self
    end

    def unpause
      @paused = false
      self
    end

    def paused?
      @paused
    end

    def repeating?
      @mode == TimerMode::REPEATING
    end

    def set_duration(duration)
      @duration = duration.to_f
      self
    end

    def set_elapsed(elapsed)
      @elapsed = elapsed.to_f
      self
    end
  end

  class Stopwatch
    attr_reader :elapsed

    def initialize
      @elapsed = 0.0
      @paused = false
    end

    def tick(delta)
      @elapsed += delta unless @paused
      self
    end

    def pause
      @paused = true
      self
    end

    def unpause
      @paused = false
      self
    end

    def paused?
      @paused
    end

    def reset
      @elapsed = 0.0
      self
    end

    def elapsed_secs
      @elapsed
    end
  end
end
