# frozen_string_literal: true

module Bevy
  module BlendMode
    OPAQUE = :opaque
    BLEND = :blend
    ALPHA_BLEND = :alpha_blend
    PREMULTIPLIED = :premultiplied
    ADD = :add
    MULTIPLY = :multiply
  end

  class ColorMaterial
    attr_accessor :color, :alpha_mode

    def initialize(color = nil, alpha_mode: nil)
      @color = color || Color.white
      @alpha_mode = alpha_mode || (@color.a < 1.0 ? BlendMode::BLEND : BlendMode::OPAQUE)
    end

    def type_name
      'ColorMaterial'
    end

    def self.from_rgb(r, g, b)
      new(Color.new(r, g, b, 1.0))
    end

    def self.from_rgba(r, g, b, a)
      new(Color.new(r, g, b, a))
    end

    def with_alpha_mode(mode)
      self.class.new(@color, alpha_mode: mode)
    end

    def to_native
      native = Component.new('ColorMaterial')
      native['color_r'] = @color.r
      native['color_g'] = @color.g
      native['color_b'] = @color.b
      native['color_a'] = @color.a
      native['alpha_mode'] = @alpha_mode.to_s
      native
    end

    def to_h
      {
        color: @color.to_a,
        alpha_mode: @alpha_mode
      }
    end
  end

  class StandardMaterial
    attr_accessor :base_color, :emissive, :metallic, :roughness, :reflectance
    attr_accessor :alpha_mode, :unlit, :double_sided
    attr_accessor :texture_path, :normal_map_path

    def initialize(
      base_color: nil,
      emissive: nil,
      metallic: 0.0,
      roughness: 0.5,
      reflectance: 0.5,
      alpha_mode: nil,
      unlit: false,
      double_sided: false,
      texture_path: nil,
      normal_map_path: nil
    )
      @base_color = base_color || Color.white
      @emissive = emissive || Color.black
      @metallic = metallic
      @roughness = roughness
      @reflectance = reflectance
      @alpha_mode = alpha_mode || BlendMode::OPAQUE
      @unlit = unlit
      @double_sided = double_sided
      @texture_path = texture_path
      @normal_map_path = normal_map_path
    end

    def type_name
      'StandardMaterial'
    end

    def self.from_color(color)
      new(base_color: color, alpha_mode: color.a < 1.0 ? BlendMode::BLEND : BlendMode::OPAQUE)
    end

    def with_base_color(color)
      dup.tap { |m| m.base_color = color }
    end

    def with_emissive(color)
      dup.tap { |m| m.emissive = color }
    end

    def with_metallic(value)
      dup.tap { |m| m.metallic = value.clamp(0.0, 1.0) }
    end

    def with_roughness(value)
      dup.tap { |m| m.roughness = value.clamp(0.0, 1.0) }
    end

    def with_reflectance(value)
      dup.tap { |m| m.reflectance = value.clamp(0.0, 1.0) }
    end

    def with_alpha_mode(mode)
      dup.tap { |m| m.alpha_mode = mode }
    end

    def with_unlit(value = true)
      dup.tap { |m| m.unlit = value }
    end

    def with_double_sided(value = true)
      dup.tap { |m| m.double_sided = value }
    end

    def with_texture(path)
      dup.tap { |m| m.texture_path = path }
    end

    def with_normal_map(path)
      dup.tap { |m| m.normal_map_path = path }
    end

    def to_native
      native = Component.new('StandardMaterial')
      native['base_color_r'] = @base_color.r
      native['base_color_g'] = @base_color.g
      native['base_color_b'] = @base_color.b
      native['base_color_a'] = @base_color.a
      native['emissive_r'] = @emissive.r
      native['emissive_g'] = @emissive.g
      native['emissive_b'] = @emissive.b
      native['metallic'] = @metallic
      native['roughness'] = @roughness
      native['reflectance'] = @reflectance
      native['alpha_mode'] = @alpha_mode.to_s
      native['unlit'] = @unlit
      native['double_sided'] = @double_sided
      native['texture_path'] = @texture_path if @texture_path
      native['normal_map_path'] = @normal_map_path if @normal_map_path
      native
    end

    def to_h
      {
        base_color: @base_color.to_a,
        emissive: @emissive.to_a,
        metallic: @metallic,
        roughness: @roughness,
        reflectance: @reflectance,
        alpha_mode: @alpha_mode,
        unlit: @unlit,
        double_sided: @double_sided,
        texture_path: @texture_path,
        normal_map_path: @normal_map_path
      }
    end
  end

  class MaterialBuilder
    def initialize
      @base_color = Color.white
      @emissive = Color.black
      @metallic = 0.0
      @roughness = 0.5
      @reflectance = 0.5
      @alpha_mode = BlendMode::OPAQUE
      @unlit = false
      @double_sided = false
      @texture_path = nil
      @normal_map_path = nil
    end

    def color(r, g, b, a = 1.0)
      @base_color = Color.new(r, g, b, a)
      @alpha_mode = BlendMode::BLEND if a < 1.0
      self
    end

    def emissive(r, g, b)
      @emissive = Color.new(r, g, b, 1.0)
      self
    end

    def metallic(value)
      @metallic = value.clamp(0.0, 1.0)
      self
    end

    def roughness(value)
      @roughness = value.clamp(0.0, 1.0)
      self
    end

    def reflectance(value)
      @reflectance = value.clamp(0.0, 1.0)
      self
    end

    def unlit
      @unlit = true
      self
    end

    def double_sided
      @double_sided = true
      self
    end

    def texture(path)
      @texture_path = path
      self
    end

    def normal_map(path)
      @normal_map_path = path
      self
    end

    def blend_mode(mode)
      @alpha_mode = mode
      self
    end

    def build
      StandardMaterial.new(
        base_color: @base_color,
        emissive: @emissive,
        metallic: @metallic,
        roughness: @roughness,
        reflectance: @reflectance,
        alpha_mode: @alpha_mode,
        unlit: @unlit,
        double_sided: @double_sided,
        texture_path: @texture_path,
        normal_map_path: @normal_map_path
      )
    end
  end
end
