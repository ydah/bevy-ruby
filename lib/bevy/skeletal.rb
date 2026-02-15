# frozen_string_literal: true

module Bevy
  class Skeleton
    attr_reader :bones, :root_bones

    def initialize
      @bones = []
      @root_bones = []
    end

    def add_bone(bone)
      @bones << bone
      @root_bones << bone if bone.parent_index.nil?
      self
    end

    def get_bone(index)
      @bones[index]
    end

    def bone_count
      @bones.size
    end

    def find_bone_by_name(name)
      @bones.find { |b| b.name == name }
    end

    def type_name
      'Skeleton'
    end
  end

  class Bone
    attr_accessor :name, :parent_index, :inverse_bind_pose, :local_transform

    def initialize(name:, parent_index: nil)
      @name = name
      @parent_index = parent_index
      @inverse_bind_pose = Transform.identity
      @local_transform = Transform.identity
    end

    def type_name
      'Bone'
    end
  end

  class SkinnedMesh
    attr_reader :skeleton, :joint_indices, :joint_weights

    def initialize(skeleton:)
      @skeleton = skeleton
      @joint_indices = []
      @joint_weights = []
    end

    def add_vertex_weights(indices, weights)
      @joint_indices << indices
      @joint_weights << weights
    end

    def vertex_count
      @joint_indices.size
    end

    def type_name
      'SkinnedMesh'
    end
  end

  class SkeletalAnimation
    attr_reader :name, :duration, :tracks

    def initialize(name:, duration:)
      @name = name
      @duration = duration.to_f
      @tracks = {}
    end

    def add_track(bone_name, track)
      @tracks[bone_name] = track
      self
    end

    def get_track(bone_name)
      @tracks[bone_name]
    end

    def sample(time)
      @tracks.transform_values { |track| track.sample(time) }
    end

    def type_name
      'SkeletalAnimation'
    end
  end

  class BoneTrack
    attr_reader :bone_name, :translation_keys, :rotation_keys, :scale_keys

    def initialize(bone_name:)
      @bone_name = bone_name
      @translation_keys = []
      @rotation_keys = []
      @scale_keys = []
    end

    def add_translation_key(time, value)
      @translation_keys << { time: time.to_f, value: value }
      self
    end

    def add_rotation_key(time, value)
      @rotation_keys << { time: time.to_f, value: value }
      self
    end

    def add_scale_key(time, value)
      @scale_keys << { time: time.to_f, value: value }
      self
    end

    def sample(time)
      {
        translation: sample_keys(@translation_keys, time),
        rotation: sample_keys(@rotation_keys, time),
        scale: sample_keys(@scale_keys, time)
      }
    end

    def type_name
      'BoneTrack'
    end

    private

    def sample_keys(keys, time)
      return nil if keys.empty?
      return keys.first[:value] if keys.size == 1

      prev_key = keys.last { |k| k[:time] <= time } || keys.first
      next_key = keys.find { |k| k[:time] > time } || keys.last

      return prev_key[:value] if prev_key == next_key

      t = (time - prev_key[:time]) / (next_key[:time] - prev_key[:time])
      lerp_value(prev_key[:value], next_key[:value], t)
    end

    def lerp_value(a, b, t)
      return a unless a.respond_to?(:x) && b.respond_to?(:x)

      Vec3.new(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
      )
    end
  end

  class AnimationBlender
    attr_reader :animations, :weights

    def initialize
      @animations = []
      @weights = []
    end

    def add_animation(animation, weight: 1.0)
      @animations << animation
      @weights << weight.to_f
      self
    end

    def set_weight(index, weight)
      @weights[index] = weight.to_f if index < @weights.size
    end

    def blend(time)
      return {} if @animations.empty?

      total_weight = @weights.sum
      return {} if total_weight == 0

      result = {}
      @animations.each_with_index do |anim, i|
        weight = @weights[i] / total_weight
        sample = anim.sample(time)
        sample.each do |bone_name, transform|
          result[bone_name] ||= { translation: Vec3.zero, rotation: Quat.identity, scale: Vec3.one }
          blend_transform(result[bone_name], transform, weight)
        end
      end
      result
    end

    def type_name
      'AnimationBlender'
    end

    private

    def blend_transform(result, transform, weight)
      if transform[:translation]
        result[:translation] = Vec3.new(
          result[:translation].x + transform[:translation].x * weight,
          result[:translation].y + transform[:translation].y * weight,
          result[:translation].z + transform[:translation].z * weight
        )
      end
    end
  end

  class IkChain
    attr_reader :target, :bones, :iterations

    def initialize(bones:, iterations: 10)
      @bones = bones
      @iterations = iterations
      @target = Vec3.zero
    end

    def set_target(position)
      @target = position
    end

    def solve(skeleton)
      @iterations.times do
        backward_pass(skeleton)
        forward_pass(skeleton)
      end
    end

    def type_name
      'IkChain'
    end

    private

    def backward_pass(_skeleton)
    end

    def forward_pass(_skeleton)
    end
  end
end
