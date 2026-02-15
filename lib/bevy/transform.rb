# frozen_string_literal: true

module Bevy
  class Transform
    attr_reader :translation, :rotation, :scale

    def initialize(translation: nil, rotation: nil, scale: nil)
      @translation = translation || Vec3.zero
      @rotation = rotation || Quat.identity
      @scale = scale || Vec3.one
    end

    def self.from_translation(translation)
      new(translation: translation)
    end

    def self.from_rotation(rotation)
      new(rotation: rotation)
    end

    def self.from_scale(scale)
      new(scale: scale)
    end

    def self.from_xyz(x, y, z)
      new(translation: Vec3.new(x, y, z))
    end

    def self.identity
      new
    end

    def type_name
      'Transform'
    end

    def translate(&block)
      result = block.call(@translation)
      @translation = result if result.is_a?(Vec3)
      self
    end

    def rotate(&block)
      result = block.call(@rotation)
      @rotation = result if result.is_a?(Quat)
      self
    end

    def with_translation(translation)
      self.class.new(
        translation: translation,
        rotation: @rotation,
        scale: @scale
      )
    end

    def with_rotation(rotation)
      self.class.new(
        translation: @translation,
        rotation: rotation,
        scale: @scale
      )
    end

    def with_scale(scale)
      self.class.new(
        translation: @translation,
        rotation: @rotation,
        scale: scale
      )
    end

    def rotate_x(angle)
      new_rotation = @rotation * Quat.from_rotation_x(angle)
      with_rotation(new_rotation)
    end

    def rotate_y(angle)
      new_rotation = @rotation * Quat.from_rotation_y(angle)
      with_rotation(new_rotation)
    end

    def rotate_z(angle)
      new_rotation = @rotation * Quat.from_rotation_z(angle)
      with_rotation(new_rotation)
    end

    def forward
      @rotation.mul_vec3(Vec3.new(0.0, 0.0, -1.0))
    end

    def right
      @rotation.mul_vec3(Vec3.new(1.0, 0.0, 0.0))
    end

    def up
      @rotation.mul_vec3(Vec3.new(0.0, 1.0, 0.0))
    end

    def to_native
      native = Component.new('Transform')
      native['translation_x'] = @translation.x
      native['translation_y'] = @translation.y
      native['translation_z'] = @translation.z
      native['rotation_x'] = @rotation.x
      native['rotation_y'] = @rotation.y
      native['rotation_z'] = @rotation.z
      native['rotation_w'] = @rotation.w
      native['scale_x'] = @scale.x
      native['scale_y'] = @scale.y
      native['scale_z'] = @scale.z
      native
    end

    def self.from_native(native)
      translation = Vec3.new(
        native['translation_x'],
        native['translation_y'],
        native['translation_z']
      )
      rotation = Quat.identity
      scale = Vec3.new(
        native['scale_x'] || 1.0,
        native['scale_y'] || 1.0,
        native['scale_z'] || 1.0
      )
      new(translation: translation, rotation: rotation, scale: scale)
    end

    def to_h
      {
        translation: @translation.to_a,
        rotation: @rotation.to_a,
        scale: @scale.to_a
      }
    end

    def to_sync_hash
      {
        x: @translation.x,
        y: @translation.y,
        z: @translation.z,
        rotation: rotation_z_angle,
        scale_x: @scale.x,
        scale_y: @scale.y,
        scale_z: @scale.z
      }
    end

    private

    def rotation_z_angle
      # Extract Z rotation angle from quaternion (2D rotation)
      # For 2D, we only care about rotation around the Z axis
      2.0 * Math.atan2(@rotation.z, @rotation.w)
    end
  end
end
