# frozen_string_literal: true

module Bevy
  class ShaderSource
    attr_reader :vertex, :fragment, :compute

    def initialize(vertex: nil, fragment: nil, compute: nil)
      @vertex = vertex
      @fragment = fragment
      @compute = compute
    end

    def has_vertex?
      !@vertex.nil?
    end

    def has_fragment?
      !@fragment.nil?
    end

    def has_compute?
      !@compute.nil?
    end

    def type_name
      'ShaderSource'
    end
  end

  class Shader
    attr_reader :name, :source, :path

    def initialize(name:, source: nil, path: nil)
      @name = name
      @source = source
      @path = path
    end

    def self.from_wgsl(name, wgsl_source)
      new(name: name, source: ShaderSource.new(fragment: wgsl_source, vertex: wgsl_source))
    end

    def self.from_file(name, path)
      new(name: name, path: path)
    end

    def loaded?
      @source || @path
    end

    def type_name
      'Shader'
    end
  end

  class ShaderDefVal
    attr_reader :key, :value

    def initialize(key, value)
      @key = key.to_s
      @value = value
    end

    def self.bool(key, value)
      new(key, value ? 1 : 0)
    end

    def self.int(key, value)
      new(key, value.to_i)
    end

    def self.uint(key, value)
      new(key, value.to_i.abs)
    end

    def type_name
      'ShaderDefVal'
    end
  end

  class ShaderDefs
    def initialize
      @defs = {}
    end

    def set(key, value)
      @defs[key.to_s] = value
      self
    end

    def get(key)
      @defs[key.to_s]
    end

    def remove(key)
      @defs.delete(key.to_s)
      self
    end

    def to_h
      @defs.dup
    end

    def type_name
      'ShaderDefs'
    end
  end

  class PostProcessSettings
    attr_accessor :enabled, :intensity

    def initialize(enabled: true, intensity: 1.0)
      @enabled = enabled
      @intensity = intensity.to_f
    end

    def type_name
      'PostProcessSettings'
    end
  end

  class Bloom
    attr_accessor :intensity, :threshold, :soft_threshold, :composite_mode

    def initialize(intensity: 0.5, threshold: 1.0, soft_threshold: 0.5, composite_mode: :additive)
      @intensity = intensity.to_f
      @threshold = threshold.to_f
      @soft_threshold = soft_threshold.to_f
      @composite_mode = composite_mode
    end

    def type_name
      'Bloom'
    end

    def to_h
      {
        intensity: @intensity,
        threshold: @threshold,
        soft_threshold: @soft_threshold,
        composite_mode: @composite_mode
      }
    end
  end

  class ChromaticAberration
    attr_accessor :intensity, :max_samples

    def initialize(intensity: 0.02, max_samples: 8)
      @intensity = intensity.to_f
      @max_samples = max_samples
    end

    def type_name
      'ChromaticAberration'
    end

    def to_h
      {
        intensity: @intensity,
        max_samples: @max_samples
      }
    end
  end

  class Vignette
    attr_accessor :intensity, :radius, :smoothness, :color

    def initialize(intensity: 0.5, radius: 0.5, smoothness: 0.5, color: nil)
      @intensity = intensity.to_f
      @radius = radius.to_f
      @smoothness = smoothness.to_f
      @color = color || Color.black
    end

    def type_name
      'Vignette'
    end

    def to_h
      {
        intensity: @intensity,
        radius: @radius,
        smoothness: @smoothness,
        color: @color.to_a
      }
    end
  end

  class FilmGrain
    attr_accessor :intensity, :response

    def initialize(intensity: 0.1, response: 0.5)
      @intensity = intensity.to_f
      @response = response.to_f
    end

    def type_name
      'FilmGrain'
    end

    def to_h
      {
        intensity: @intensity,
        response: @response
      }
    end
  end

  class Tonemapping
    attr_accessor :mode

    MODES = %i[none reinhard reinhard_luminance aces_fitted aces_approximate tony_mc_mapface blender_filmic].freeze

    def initialize(mode: :tony_mc_mapface)
      @mode = mode
    end

    def type_name
      'Tonemapping'
    end
  end

  class ColorGrading
    attr_accessor :exposure, :gamma, :saturation, :contrast

    def initialize(exposure: 0.0, gamma: 1.0, saturation: 1.0, contrast: 1.0)
      @exposure = exposure.to_f
      @gamma = gamma.to_f
      @saturation = saturation.to_f
      @contrast = contrast.to_f
    end

    def type_name
      'ColorGrading'
    end

    def to_h
      {
        exposure: @exposure,
        gamma: @gamma,
        saturation: @saturation,
        contrast: @contrast
      }
    end
  end

  class DepthOfField
    attr_accessor :focal_distance, :focal_length, :aperture_f_stops, :max_blur

    def initialize(focal_distance: 10.0, focal_length: 50.0, aperture_f_stops: 2.8, max_blur: 0.01)
      @focal_distance = focal_distance.to_f
      @focal_length = focal_length.to_f
      @aperture_f_stops = aperture_f_stops.to_f
      @max_blur = max_blur.to_f
    end

    def type_name
      'DepthOfField'
    end

    def to_h
      {
        focal_distance: @focal_distance,
        focal_length: @focal_length,
        aperture_f_stops: @aperture_f_stops,
        max_blur: @max_blur
      }
    end
  end

  class MotionBlur
    attr_accessor :shutter_angle, :samples

    def initialize(shutter_angle: 0.5, samples: 4)
      @shutter_angle = shutter_angle.to_f
      @samples = samples
    end

    def type_name
      'MotionBlur'
    end

    def to_h
      {
        shutter_angle: @shutter_angle,
        samples: @samples
      }
    end
  end

  class Fxaa
    attr_accessor :enabled, :edge_threshold, :edge_threshold_min

    def initialize(enabled: true, edge_threshold: :high, edge_threshold_min: :high)
      @enabled = enabled
      @edge_threshold = edge_threshold
      @edge_threshold_min = edge_threshold_min
    end

    def type_name
      'Fxaa'
    end
  end

  class Smaa
    attr_accessor :preset

    PRESETS = %i[low medium high ultra].freeze

    def initialize(preset: :high)
      @preset = preset
    end

    def type_name
      'Smaa'
    end
  end
end
