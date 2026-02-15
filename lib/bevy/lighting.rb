# frozen_string_literal: true

module Bevy
  class PointLight
    attr_accessor :color, :intensity, :range, :radius, :shadows_enabled

    def initialize(color: nil, intensity: 800.0, range: 20.0, radius: 0.0, shadows_enabled: true)
      @color = color || Color.white
      @intensity = intensity.to_f
      @range = range.to_f
      @radius = radius.to_f
      @shadows_enabled = shadows_enabled
    end

    def with_color(color)
      self.class.new(
        color: color,
        intensity: @intensity,
        range: @range,
        radius: @radius,
        shadows_enabled: @shadows_enabled
      )
    end

    def with_intensity(intensity)
      self.class.new(
        color: @color,
        intensity: intensity,
        range: @range,
        radius: @radius,
        shadows_enabled: @shadows_enabled
      )
    end

    def with_range(range)
      self.class.new(
        color: @color,
        intensity: @intensity,
        range: range,
        radius: @radius,
        shadows_enabled: @shadows_enabled
      )
    end

    def type_name
      'PointLight'
    end

    def to_h
      {
        color: @color.to_a,
        intensity: @intensity,
        range: @range,
        radius: @radius,
        shadows_enabled: @shadows_enabled
      }
    end

    def to_native
      native = Component.new('PointLight')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['intensity'] = @intensity
      native['range'] = @range
      native['radius'] = @radius
      native['shadows_enabled'] = @shadows_enabled
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
        color: color,
        intensity: native['intensity'] || 800.0,
        range: native['range'] || 20.0,
        radius: native['radius'] || 0.0,
        shadows_enabled: native['shadows_enabled'] != false
      )
    end
  end

  class DirectionalLight
    attr_accessor :color, :illuminance, :shadows_enabled

    def initialize(color: nil, illuminance: 100_000.0, shadows_enabled: true)
      @color = color || Color.white
      @illuminance = illuminance.to_f
      @shadows_enabled = shadows_enabled
    end

    def with_color(color)
      self.class.new(color: color, illuminance: @illuminance, shadows_enabled: @shadows_enabled)
    end

    def with_illuminance(illuminance)
      self.class.new(color: @color, illuminance: illuminance, shadows_enabled: @shadows_enabled)
    end

    def type_name
      'DirectionalLight'
    end

    def to_h
      {
        color: @color.to_a,
        illuminance: @illuminance,
        shadows_enabled: @shadows_enabled
      }
    end

    def to_native
      native = Component.new('DirectionalLight')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['illuminance'] = @illuminance
      native['shadows_enabled'] = @shadows_enabled
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
        color: color,
        illuminance: native['illuminance'] || 100_000.0,
        shadows_enabled: native['shadows_enabled'] != false
      )
    end
  end

  class SpotLight
    attr_accessor :color, :intensity, :range, :radius, :inner_angle, :outer_angle, :shadows_enabled

    def initialize(
      color: nil,
      intensity: 800.0,
      range: 20.0,
      radius: 0.0,
      inner_angle: 0.0,
      outer_angle: Math::PI / 4.0,
      shadows_enabled: true
    )
      @color = color || Color.white
      @intensity = intensity.to_f
      @range = range.to_f
      @radius = radius.to_f
      @inner_angle = inner_angle.to_f
      @outer_angle = outer_angle.to_f
      @shadows_enabled = shadows_enabled
    end

    def with_color(color)
      self.class.new(
        color: color,
        intensity: @intensity,
        range: @range,
        radius: @radius,
        inner_angle: @inner_angle,
        outer_angle: @outer_angle,
        shadows_enabled: @shadows_enabled
      )
    end

    def with_intensity(intensity)
      self.class.new(
        color: @color,
        intensity: intensity,
        range: @range,
        radius: @radius,
        inner_angle: @inner_angle,
        outer_angle: @outer_angle,
        shadows_enabled: @shadows_enabled
      )
    end

    def with_angles(inner, outer)
      self.class.new(
        color: @color,
        intensity: @intensity,
        range: @range,
        radius: @radius,
        inner_angle: inner,
        outer_angle: outer,
        shadows_enabled: @shadows_enabled
      )
    end

    def type_name
      'SpotLight'
    end

    def to_h
      {
        color: @color.to_a,
        intensity: @intensity,
        range: @range,
        radius: @radius,
        inner_angle: @inner_angle,
        outer_angle: @outer_angle,
        shadows_enabled: @shadows_enabled
      }
    end

    def to_native
      native = Component.new('SpotLight')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['intensity'] = @intensity
      native['range'] = @range
      native['radius'] = @radius
      native['inner_angle'] = @inner_angle
      native['outer_angle'] = @outer_angle
      native['shadows_enabled'] = @shadows_enabled
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
        color: color,
        intensity: native['intensity'] || 800.0,
        range: native['range'] || 20.0,
        radius: native['radius'] || 0.0,
        inner_angle: native['inner_angle'] || 0.0,
        outer_angle: native['outer_angle'] || Math::PI / 4.0,
        shadows_enabled: native['shadows_enabled'] != false
      )
    end
  end

  class AmbientLight
    attr_accessor :color, :brightness

    def initialize(color: nil, brightness: 0.05)
      @color = color || Color.white
      @brightness = brightness.to_f
    end

    def with_color(color)
      self.class.new(color: color, brightness: @brightness)
    end

    def with_brightness(brightness)
      self.class.new(color: @color, brightness: brightness)
    end

    def type_name
      'AmbientLight'
    end

    def to_h
      {
        color: @color.to_a,
        brightness: @brightness
      }
    end

    def to_native
      native = Component.new('AmbientLight')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['brightness'] = @brightness
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
        color: color,
        brightness: native['brightness'] || 0.05
      )
    end
  end

  class EnvironmentMapLight
    attr_accessor :diffuse_map, :specular_map, :intensity

    def initialize(diffuse_map: nil, specular_map: nil, intensity: 1.0)
      @diffuse_map = diffuse_map
      @specular_map = specular_map
      @intensity = intensity.to_f
    end

    def type_name
      'EnvironmentMapLight'
    end

    def to_h
      {
        diffuse_map: @diffuse_map,
        specular_map: @specular_map,
        intensity: @intensity
      }
    end
  end

  class CascadeShadowConfig
    attr_accessor :num_cascades, :minimum_distance, :maximum_distance, :first_cascade_far_bound, :overlap_proportion

    def initialize(
      num_cascades: 4,
      minimum_distance: 0.1,
      maximum_distance: 1000.0,
      first_cascade_far_bound: 5.0,
      overlap_proportion: 0.2
    )
      @num_cascades = num_cascades
      @minimum_distance = minimum_distance.to_f
      @maximum_distance = maximum_distance.to_f
      @first_cascade_far_bound = first_cascade_far_bound.to_f
      @overlap_proportion = overlap_proportion.to_f
    end

    def type_name
      'CascadeShadowConfig'
    end

    def to_h
      {
        num_cascades: @num_cascades,
        minimum_distance: @minimum_distance,
        maximum_distance: @maximum_distance,
        first_cascade_far_bound: @first_cascade_far_bound,
        overlap_proportion: @overlap_proportion
      }
    end
  end

  class LightBundle
    attr_reader :light, :transform, :visibility

    def initialize(light:, transform: nil, visibility: true)
      @light = light
      @transform = transform || Transform.identity
      @visibility = visibility
    end

    def type_name
      "#{@light.class.name.split('::').last}Bundle"
    end
  end
end
