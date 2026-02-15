# frozen_string_literal: true

RSpec.describe Bevy::Skeleton do
  describe '.new' do
    it 'creates empty skeleton' do
      skeleton = described_class.new
      expect(skeleton.bones).to be_empty
      expect(skeleton.root_bones).to be_empty
      expect(skeleton.bone_count).to eq(0)
    end
  end

  describe '#add_bone' do
    it 'adds bone to skeleton' do
      skeleton = described_class.new
      bone = Bevy::Bone.new(name: 'root')
      skeleton.add_bone(bone)
      expect(skeleton.bone_count).to eq(1)
    end

    it 'tracks root bones' do
      skeleton = described_class.new
      root = Bevy::Bone.new(name: 'root')
      child = Bevy::Bone.new(name: 'child', parent_index: 0)
      skeleton.add_bone(root)
      skeleton.add_bone(child)
      expect(skeleton.root_bones.size).to eq(1)
      expect(skeleton.root_bones.first.name).to eq('root')
    end

    it 'returns self for chaining' do
      skeleton = described_class.new
      result = skeleton.add_bone(Bevy::Bone.new(name: 'test'))
      expect(result).to eq(skeleton)
    end
  end

  describe '#get_bone' do
    it 'returns bone by index' do
      skeleton = described_class.new
      bone = Bevy::Bone.new(name: 'test')
      skeleton.add_bone(bone)
      expect(skeleton.get_bone(0)).to eq(bone)
    end
  end

  describe '#find_bone_by_name' do
    it 'finds bone by name' do
      skeleton = described_class.new
      skeleton.add_bone(Bevy::Bone.new(name: 'hip'))
      skeleton.add_bone(Bevy::Bone.new(name: 'spine'))
      bone = skeleton.find_bone_by_name('spine')
      expect(bone.name).to eq('spine')
    end

    it 'returns nil when not found' do
      skeleton = described_class.new
      expect(skeleton.find_bone_by_name('unknown')).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns Skeleton' do
      expect(described_class.new.type_name).to eq('Skeleton')
    end
  end
end

RSpec.describe Bevy::Bone do
  describe '.new' do
    it 'creates bone with name' do
      bone = described_class.new(name: 'hip')
      expect(bone.name).to eq('hip')
      expect(bone.parent_index).to be_nil
      expect(bone.inverse_bind_pose).to be_a(Bevy::Transform)
      expect(bone.local_transform).to be_a(Bevy::Transform)
    end

    it 'accepts parent index' do
      bone = described_class.new(name: 'spine', parent_index: 0)
      expect(bone.parent_index).to eq(0)
    end
  end

  describe '#type_name' do
    it 'returns Bone' do
      expect(described_class.new(name: 'test').type_name).to eq('Bone')
    end
  end
end

RSpec.describe Bevy::SkinnedMesh do
  let(:skeleton) { Bevy::Skeleton.new }

  describe '.new' do
    it 'creates skinned mesh with skeleton' do
      mesh = described_class.new(skeleton: skeleton)
      expect(mesh.skeleton).to eq(skeleton)
      expect(mesh.joint_indices).to be_empty
      expect(mesh.joint_weights).to be_empty
    end
  end

  describe '#add_vertex_weights' do
    it 'adds vertex skinning data' do
      mesh = described_class.new(skeleton: skeleton)
      mesh.add_vertex_weights([0, 1, 2, 3], [0.5, 0.3, 0.15, 0.05])
      expect(mesh.vertex_count).to eq(1)
      expect(mesh.joint_indices.first).to eq([0, 1, 2, 3])
      expect(mesh.joint_weights.first).to eq([0.5, 0.3, 0.15, 0.05])
    end
  end

  describe '#type_name' do
    it 'returns SkinnedMesh' do
      expect(described_class.new(skeleton: skeleton).type_name).to eq('SkinnedMesh')
    end
  end
end

RSpec.describe Bevy::SkeletalAnimation do
  describe '.new' do
    it 'creates animation with name and duration' do
      anim = described_class.new(name: 'walk', duration: 1.5)
      expect(anim.name).to eq('walk')
      expect(anim.duration).to eq(1.5)
      expect(anim.tracks).to be_empty
    end
  end

  describe '#add_track' do
    it 'adds bone track' do
      anim = described_class.new(name: 'walk', duration: 1.0)
      track = Bevy::BoneTrack.new(bone_name: 'hip')
      anim.add_track('hip', track)
      expect(anim.get_track('hip')).to eq(track)
    end

    it 'returns self for chaining' do
      anim = described_class.new(name: 'walk', duration: 1.0)
      result = anim.add_track('hip', Bevy::BoneTrack.new(bone_name: 'hip'))
      expect(result).to eq(anim)
    end
  end

  describe '#sample' do
    it 'samples all tracks at given time' do
      anim = described_class.new(name: 'walk', duration: 1.0)
      track = Bevy::BoneTrack.new(bone_name: 'hip')
      track.add_translation_key(0.0, Bevy::Vec3.zero)
      track.add_translation_key(1.0, Bevy::Vec3.new(0.0, 1.0, 0.0))
      anim.add_track('hip', track)
      result = anim.sample(0.5)
      expect(result).to have_key('hip')
    end
  end

  describe '#type_name' do
    it 'returns SkeletalAnimation' do
      expect(described_class.new(name: 'test', duration: 1.0).type_name).to eq('SkeletalAnimation')
    end
  end
end

RSpec.describe Bevy::BoneTrack do
  describe '.new' do
    it 'creates empty track for bone' do
      track = described_class.new(bone_name: 'hip')
      expect(track.bone_name).to eq('hip')
      expect(track.translation_keys).to be_empty
      expect(track.rotation_keys).to be_empty
      expect(track.scale_keys).to be_empty
    end
  end

  describe '#add_translation_key' do
    it 'adds translation keyframe' do
      track = described_class.new(bone_name: 'hip')
      track.add_translation_key(0.0, Bevy::Vec3.zero)
      expect(track.translation_keys.size).to eq(1)
    end

    it 'returns self for chaining' do
      track = described_class.new(bone_name: 'hip')
      result = track.add_translation_key(0.0, Bevy::Vec3.zero)
      expect(result).to eq(track)
    end
  end

  describe '#add_rotation_key' do
    it 'adds rotation keyframe' do
      track = described_class.new(bone_name: 'hip')
      track.add_rotation_key(0.0, Bevy::Quat.identity)
      expect(track.rotation_keys.size).to eq(1)
    end
  end

  describe '#add_scale_key' do
    it 'adds scale keyframe' do
      track = described_class.new(bone_name: 'hip')
      track.add_scale_key(0.0, Bevy::Vec3.one)
      expect(track.scale_keys.size).to eq(1)
    end
  end

  describe '#sample' do
    it 'samples track at given time' do
      track = described_class.new(bone_name: 'hip')
      track.add_translation_key(0.0, Bevy::Vec3.zero)
      track.add_translation_key(1.0, Bevy::Vec3.new(0.0, 10.0, 0.0))
      result = track.sample(0.5)
      expect(result).to have_key(:translation)
      expect(result).to have_key(:rotation)
      expect(result).to have_key(:scale)
    end
  end

  describe '#type_name' do
    it 'returns BoneTrack' do
      expect(described_class.new(bone_name: 'test').type_name).to eq('BoneTrack')
    end
  end
end

RSpec.describe Bevy::AnimationBlender do
  describe '.new' do
    it 'creates empty blender' do
      blender = described_class.new
      expect(blender.animations).to be_empty
      expect(blender.weights).to be_empty
    end
  end

  describe '#add_animation' do
    it 'adds animation with weight' do
      blender = described_class.new
      anim = Bevy::SkeletalAnimation.new(name: 'walk', duration: 1.0)
      blender.add_animation(anim, weight: 0.5)
      expect(blender.animations.size).to eq(1)
      expect(blender.weights.first).to eq(0.5)
    end

    it 'returns self for chaining' do
      blender = described_class.new
      anim = Bevy::SkeletalAnimation.new(name: 'walk', duration: 1.0)
      result = blender.add_animation(anim)
      expect(result).to eq(blender)
    end
  end

  describe '#set_weight' do
    it 'updates animation weight' do
      blender = described_class.new
      anim = Bevy::SkeletalAnimation.new(name: 'walk', duration: 1.0)
      blender.add_animation(anim, weight: 1.0)
      blender.set_weight(0, 0.5)
      expect(blender.weights.first).to eq(0.5)
    end
  end

  describe '#blend' do
    it 'returns empty hash when no animations' do
      blender = described_class.new
      expect(blender.blend(0.0)).to eq({})
    end

    it 'blends animations based on weights' do
      blender = described_class.new
      anim1 = Bevy::SkeletalAnimation.new(name: 'walk', duration: 1.0)
      track = Bevy::BoneTrack.new(bone_name: 'hip')
      track.add_translation_key(0.0, Bevy::Vec3.zero)
      anim1.add_track('hip', track)
      blender.add_animation(anim1, weight: 1.0)
      result = blender.blend(0.0)
      expect(result).to have_key('hip')
    end
  end

  describe '#type_name' do
    it 'returns AnimationBlender' do
      expect(described_class.new.type_name).to eq('AnimationBlender')
    end
  end
end

RSpec.describe Bevy::IkChain do
  describe '.new' do
    it 'creates IK chain with bones' do
      bones = [0, 1, 2]
      chain = described_class.new(bones: bones, iterations: 15)
      expect(chain.bones).to eq(bones)
      expect(chain.iterations).to eq(15)
      expect(chain.target).to be_a(Bevy::Vec3)
    end
  end

  describe '#set_target' do
    it 'sets target position' do
      chain = described_class.new(bones: [0, 1])
      target = Bevy::Vec3.new(10.0, 10.0, 0.0)
      chain.set_target(target)
      expect(chain.target).to eq(target)
    end
  end

  describe '#solve' do
    it 'runs IK solver iterations' do
      skeleton = Bevy::Skeleton.new
      skeleton.add_bone(Bevy::Bone.new(name: 'a'))
      skeleton.add_bone(Bevy::Bone.new(name: 'b', parent_index: 0))
      chain = described_class.new(bones: [0, 1])
      expect { chain.solve(skeleton) }.not_to raise_error
    end
  end

  describe '#type_name' do
    it 'returns IkChain' do
      expect(described_class.new(bones: []).type_name).to eq('IkChain')
    end
  end
end
