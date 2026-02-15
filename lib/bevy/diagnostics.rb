# frozen_string_literal: true

module Bevy
  class DiagnosticsStore
    attr_reader :diagnostics

    def initialize
      @diagnostics = {}
    end

    def add(diagnostic)
      @diagnostics[diagnostic.id] = diagnostic
      self
    end

    def get(id)
      @diagnostics[id]
    end

    def remove(id)
      @diagnostics.delete(id)
    end

    def get_measurement(id)
      diagnostic = @diagnostics[id]
      diagnostic&.average
    end

    def type_name
      'DiagnosticsStore'
    end
  end

  class Diagnostic
    attr_reader :id, :name, :suffix, :history

    def initialize(id:, name:, max_history: 120, suffix: nil)
      @id = id
      @name = name
      @suffix = suffix || ''
      @max_history = max_history
      @history = []
    end

    def add_measurement(value)
      @history << { value: value.to_f, time: ::Time.now }
      @history.shift while @history.size > @max_history
    end

    def value
      @history.last&.fetch(:value)
    end

    def average
      return nil if @history.empty?

      @history.sum { |m| m[:value] } / @history.size
    end

    def smoothed
      return nil if @history.size < 2

      @history.last(10).sum { |m| m[:value] } / [10, @history.size].min
    end

    def clear_history
      @history = []
    end

    def type_name
      'Diagnostic'
    end
  end

  class FrameTimeDiagnostics
    FPS_ID = 'fps'
    FRAME_TIME_ID = 'frame_time'
    FRAME_COUNT_ID = 'frame_count'

    attr_reader :fps, :frame_time, :frame_count

    def initialize
      @fps = Diagnostic.new(id: FPS_ID, name: 'FPS', suffix: ' fps')
      @frame_time = Diagnostic.new(id: FRAME_TIME_ID, name: 'Frame Time', suffix: ' ms')
      @frame_count = 0
      @last_time = ::Time.now
    end

    def update
      current_time = ::Time.now
      delta = current_time - @last_time
      @last_time = current_time
      @frame_count += 1

      @frame_time.add_measurement(delta * 1000.0)
      @fps.add_measurement(1.0 / delta) if delta > 0
    end

    def diagnostics
      [@fps, @frame_time]
    end

    def type_name
      'FrameTimeDiagnostics'
    end
  end

  class EntityCountDiagnostics
    ENTITY_COUNT_ID = 'entity_count'

    attr_reader :entity_count

    def initialize
      @entity_count = Diagnostic.new(id: ENTITY_COUNT_ID, name: 'Entity Count')
    end

    def update(world)
      count = world.respond_to?(:entity_count) ? world.entity_count : 0
      @entity_count.add_measurement(count)
    end

    def diagnostics
      [@entity_count]
    end

    def type_name
      'EntityCountDiagnostics'
    end
  end

  class SystemDiagnostics
    attr_reader :system_timings

    def initialize
      @system_timings = {}
    end

    def start_system(name)
      @system_timings[name] ||= Diagnostic.new(id: "system_#{name}", name: name, suffix: ' ms')
      @system_timings[name].instance_variable_set(:@start_time, ::Time.now)
    end

    def end_system(name)
      diagnostic = @system_timings[name]
      return unless diagnostic

      start_time = diagnostic.instance_variable_get(:@start_time)
      return unless start_time

      elapsed = (::Time.now - start_time) * 1000.0
      diagnostic.add_measurement(elapsed)
    end

    def diagnostics
      @system_timings.values
    end

    def type_name
      'SystemDiagnostics'
    end
  end

  class LogDiagnostics
    attr_accessor :enabled, :wait_duration

    def initialize(wait_duration: 1.0)
      @enabled = true
      @wait_duration = wait_duration.to_f
      @last_log_time = ::Time.now
    end

    def log(store)
      return unless @enabled

      current_time = ::Time.now
      return unless current_time - @last_log_time >= @wait_duration

      @last_log_time = current_time
      store.diagnostics.each_value do |diagnostic|
        puts format_diagnostic(diagnostic) if diagnostic.value
      end
    end

    def type_name
      'LogDiagnostics'
    end

    private

    def format_diagnostic(diagnostic)
      value = diagnostic.smoothed || diagnostic.value
      "#{diagnostic.name}: #{value.round(2)}#{diagnostic.suffix}"
    end
  end

  class PerformanceMetrics
    attr_reader :draw_calls, :triangles, :vertices, :textures_bound

    def initialize
      @draw_calls = 0
      @triangles = 0
      @vertices = 0
      @textures_bound = 0
    end

    def reset
      @draw_calls = 0
      @triangles = 0
      @vertices = 0
      @textures_bound = 0
    end

    def add_draw_call(triangles: 0, vertices: 0)
      @draw_calls += 1
      @triangles += triangles
      @vertices += vertices
    end

    def bind_texture
      @textures_bound += 1
    end

    def type_name
      'PerformanceMetrics'
    end
  end
end
