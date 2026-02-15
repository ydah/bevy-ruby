# frozen_string_literal: true

RSpec.describe Bevy::Gltf do
  describe '.new' do
    it 'creates unloaded gltf asset' do
      gltf = described_class.new('model.gltf')
      expect(gltf.path).to eq('model.gltf')
      expect(gltf.loaded?).to be false
      expect(gltf.scenes).to be_empty
      expect(gltf.meshes).to be_empty
      expect(gltf.materials).to be_empty
      expect(gltf.animations).to be_empty
      expect(gltf.nodes).to be_empty
    end
  end

  describe '#mark_loaded' do
    it 'marks asset as loaded with data' do
      gltf = described_class.new('model.gltf')
      scene = Bevy::GltfScene.new('Scene')
      mesh = Bevy::GltfMesh.new('Mesh')
      gltf.mark_loaded(scenes: [scene], meshes: [mesh])
      expect(gltf.loaded?).to be true
      expect(gltf.scenes).to include(scene)
      expect(gltf.meshes).to include(mesh)
    end
  end

  describe '#default_scene' do
    it 'returns first scene' do
      gltf = described_class.new('model.gltf')
      scene = Bevy::GltfScene.new('Main')
      gltf.mark_loaded(scenes: [scene])
      expect(gltf.default_scene).to eq(scene)
    end

    it 'returns nil when no scenes' do
      gltf = described_class.new('model.gltf')
      expect(gltf.default_scene).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns Gltf' do
      expect(described_class.new('test.gltf').type_name).to eq('Gltf')
    end
  end
end

RSpec.describe Bevy::GltfMesh do
  describe '.new' do
    it 'creates mesh with name and primitives' do
      primitives = [Bevy::GltfPrimitive.new(mesh: :mesh_handle)]
      mesh = described_class.new('MyMesh', primitives)
      expect(mesh.name).to eq('MyMesh')
      expect(mesh.primitives).to eq(primitives)
    end

    it 'defaults to empty primitives' do
      mesh = described_class.new('EmptyMesh')
      expect(mesh.primitives).to be_empty
    end
  end

  describe '#type_name' do
    it 'returns GltfMesh' do
      expect(described_class.new('test').type_name).to eq('GltfMesh')
    end
  end
end

RSpec.describe Bevy::GltfPrimitive do
  describe '.new' do
    it 'creates primitive with mesh and material' do
      primitive = described_class.new(mesh: :mesh_handle, material: :mat_handle)
      expect(primitive.mesh).to eq(:mesh_handle)
      expect(primitive.material).to eq(:mat_handle)
    end

    it 'allows nil material' do
      primitive = described_class.new(mesh: :mesh_handle)
      expect(primitive.material).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns GltfPrimitive' do
      expect(described_class.new(mesh: :handle).type_name).to eq('GltfPrimitive')
    end
  end
end

RSpec.describe Bevy::GltfNode do
  describe '.new' do
    it 'creates node with name' do
      node = described_class.new(name: 'Root')
      expect(node.name).to eq('Root')
      expect(node.transform).to be_a(Bevy::Transform)
      expect(node.mesh).to be_nil
      expect(node.children).to be_empty
    end

    it 'accepts custom transform and children' do
      transform = Bevy::Transform.new(translation: Bevy::Vec3.new(1.0, 2.0, 3.0))
      child = described_class.new(name: 'Child')
      node = described_class.new(name: 'Parent', transform: transform, children: [child])
      expect(node.transform.translation.x).to eq(1.0)
      expect(node.children).to include(child)
    end
  end

  describe '#type_name' do
    it 'returns GltfNode' do
      expect(described_class.new(name: 'test').type_name).to eq('GltfNode')
    end
  end
end

RSpec.describe Bevy::GltfScene do
  describe '.new' do
    it 'creates scene with name and nodes' do
      node = Bevy::GltfNode.new(name: 'Node')
      scene = described_class.new('MainScene', [node])
      expect(scene.name).to eq('MainScene')
      expect(scene.nodes).to include(node)
    end

    it 'defaults to empty nodes' do
      scene = described_class.new('Empty')
      expect(scene.nodes).to be_empty
    end
  end

  describe '#type_name' do
    it 'returns GltfScene' do
      expect(described_class.new('test').type_name).to eq('GltfScene')
    end
  end
end

RSpec.describe Bevy::GltfAnimation do
  describe '.new' do
    it 'creates animation with name and duration' do
      anim = described_class.new('Walk', 2.5)
      expect(anim.name).to eq('Walk')
      expect(anim.duration).to eq(2.5)
    end

    it 'defaults to zero duration' do
      anim = described_class.new('Idle')
      expect(anim.duration).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns GltfAnimation' do
      expect(described_class.new('test').type_name).to eq('GltfAnimation')
    end
  end
end

RSpec.describe Bevy::SceneBundle3d do
  describe '.new' do
    it 'creates bundle with scene' do
      scene = :scene_handle
      bundle = described_class.new(scene: scene)
      expect(bundle.scene).to eq(scene)
      expect(bundle.transform).to be_a(Bevy::Transform)
    end

    it 'accepts custom transform' do
      transform = Bevy::Transform.new(scale: Bevy::Vec3.new(2.0, 2.0, 2.0))
      bundle = described_class.new(scene: :scene, transform: transform)
      expect(bundle.transform.scale.x).to eq(2.0)
    end
  end

  describe '#type_name' do
    it 'returns SceneBundle3d' do
      expect(described_class.new(scene: :scene).type_name).to eq('SceneBundle3d')
    end
  end
end

RSpec.describe Bevy::GltfAssetLoader do
  describe '.new' do
    it 'creates loader with empty cache' do
      loader = described_class.new
      expect(loader).to be_a(described_class)
    end
  end

  describe '#load' do
    it 'creates and caches gltf asset' do
      loader = described_class.new
      gltf = loader.load('model.gltf')
      expect(gltf).to be_a(Bevy::Gltf)
      expect(gltf.path).to eq('model.gltf')
    end

    it 'returns cached asset on subsequent calls' do
      loader = described_class.new
      gltf1 = loader.load('model.gltf')
      gltf2 = loader.load('model.gltf')
      expect(gltf1).to eq(gltf2)
    end
  end

  describe '#is_loaded?' do
    it 'returns false for unloaded asset' do
      loader = described_class.new
      loader.load('model.gltf')
      expect(loader.is_loaded?('model.gltf')).to be false
    end

    it 'returns true for loaded asset' do
      loader = described_class.new
      gltf = loader.load('model.gltf')
      gltf.mark_loaded
      expect(loader.is_loaded?('model.gltf')).to be true
    end
  end

  describe '#get' do
    it 'returns cached asset' do
      loader = described_class.new
      loader.load('model.gltf')
      expect(loader.get('model.gltf')).to be_a(Bevy::Gltf)
    end

    it 'returns nil for uncached asset' do
      loader = described_class.new
      expect(loader.get('unknown.gltf')).to be_nil
    end
  end

  describe '#unload' do
    it 'removes asset from cache' do
      loader = described_class.new
      loader.load('model.gltf')
      loader.unload('model.gltf')
      expect(loader.get('model.gltf')).to be_nil
    end
  end

  describe '#clear' do
    it 'removes all assets from cache' do
      loader = described_class.new
      loader.load('a.gltf')
      loader.load('b.gltf')
      loader.clear
      expect(loader.get('a.gltf')).to be_nil
      expect(loader.get('b.gltf')).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns GltfAssetLoader' do
      expect(described_class.new.type_name).to eq('GltfAssetLoader')
    end
  end
end

RSpec.describe Bevy::Mesh3d do
  describe '.new' do
    it 'creates mesh3d with handle' do
      mesh = described_class.new(:mesh_handle)
      expect(mesh.handle).to eq(:mesh_handle)
    end
  end

  describe '#type_name' do
    it 'returns Mesh3d' do
      expect(described_class.new(:handle).type_name).to eq('Mesh3d')
    end
  end
end

RSpec.describe Bevy::MeshMaterial3d do
  describe '.new' do
    it 'creates mesh material with material' do
      mat = described_class.new(:material_handle)
      expect(mat.material).to eq(:material_handle)
    end
  end

  describe '#type_name' do
    it 'returns MeshMaterial3d' do
      expect(described_class.new(:handle).type_name).to eq('MeshMaterial3d')
    end
  end
end

RSpec.describe Bevy::Pbr do
  describe '.new' do
    it 'creates with default values' do
      pbr = described_class.new
      expect(pbr.base_color.r).to eq(1.0)
      expect(pbr.metallic).to eq(0.0)
      expect(pbr.roughness).to eq(0.5)
      expect(pbr.emissive.r).to eq(0.0)
    end

    it 'accepts custom values' do
      pbr = described_class.new(metallic: 1.0, roughness: 0.1)
      expect(pbr.metallic).to eq(1.0)
      expect(pbr.roughness).to eq(0.1)
    end
  end

  describe '#with_base_color' do
    it 'returns new Pbr with updated base color' do
      pbr = described_class.new
      new_pbr = pbr.with_base_color(Bevy::Color.red)
      expect(new_pbr.base_color.r).to eq(1.0)
      expect(new_pbr.base_color.g).to eq(0.0)
      expect(pbr.base_color.r).to eq(1.0)
    end
  end

  describe '#with_metallic' do
    it 'returns new Pbr with updated metallic' do
      pbr = described_class.new
      new_pbr = pbr.with_metallic(0.8)
      expect(new_pbr.metallic).to eq(0.8)
    end
  end

  describe '#with_roughness' do
    it 'returns new Pbr with updated roughness' do
      pbr = described_class.new
      new_pbr = pbr.with_roughness(0.2)
      expect(new_pbr.roughness).to eq(0.2)
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      pbr = described_class.new
      hash = pbr.to_h
      expect(hash).to have_key(:base_color)
      expect(hash).to have_key(:metallic)
      expect(hash).to have_key(:roughness)
      expect(hash).to have_key(:emissive)
    end
  end

  describe '#type_name' do
    it 'returns Pbr' do
      expect(described_class.new.type_name).to eq('Pbr')
    end
  end
end
