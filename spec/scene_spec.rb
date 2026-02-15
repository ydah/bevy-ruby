# frozen_string_literal: true

RSpec.describe Bevy::Scene do
  describe '.new' do
    it 'creates with default name' do
      scene = described_class.new
      expect(scene.name).to eq('Untitled')
      expect(scene.entities).to be_empty
    end

    it 'creates with custom name' do
      scene = described_class.new('Level1')
      expect(scene.name).to eq('Level1')
    end
  end

  describe '#add_entity' do
    it 'adds components to entities list' do
      scene = described_class.new
      scene.add_entity([Bevy::Transform.identity])
      expect(scene.entity_count).to eq(1)
    end

    it 'returns self for chaining' do
      scene = described_class.new
      result = scene.add_entity([])
      expect(result).to eq(scene)
    end
  end

  describe '#clear' do
    it 'removes all entities' do
      scene = described_class.new
      scene.add_entity([Bevy::Transform.identity])
      scene.add_entity([Bevy::Transform.identity])
      scene.clear
      expect(scene.entity_count).to eq(0)
    end
  end

  describe '#type_name' do
    it 'returns Scene' do
      expect(described_class.new.type_name).to eq('Scene')
    end
  end
end

RSpec.describe Bevy::DynamicScene do
  describe '.new' do
    it 'creates with default name' do
      scene = described_class.new
      expect(scene.name).to eq('DynamicScene')
    end

    it 'creates with custom name' do
      scene = described_class.new('SavedGame')
      expect(scene.name).to eq('SavedGame')
    end
  end

  describe '#to_data' do
    it 'returns serializable data' do
      scene = described_class.new('Test')
      data = scene.to_data
      expect(data[:name]).to eq('Test')
      expect(data[:entities]).to be_an(Array)
    end
  end

  describe '#load_data' do
    it 'loads data from hash' do
      scene = described_class.new
      scene.load_data({ name: 'Loaded', entities: [{ id: 1, components: {} }] })
      expect(scene.name).to eq('Loaded')
      expect(scene.entity_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns DynamicScene' do
      expect(described_class.new.type_name).to eq('DynamicScene')
    end
  end
end

RSpec.describe Bevy::SceneSpawner do
  describe '.new' do
    it 'creates empty spawner' do
      spawner = described_class.new
      expect(spawner.pending_count).to eq(0)
      expect(spawner.spawned_scenes).to be_empty
    end
  end

  describe '#spawn' do
    it 'adds scene to pending list' do
      spawner = described_class.new
      scene = Bevy::Scene.new('Test')
      spawner.spawn(scene)
      expect(spawner.pending_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns SceneSpawner' do
      expect(described_class.new.type_name).to eq('SceneSpawner')
    end
  end
end

RSpec.describe Bevy::SceneBundle do
  describe '.new' do
    it 'creates bundle with scene' do
      scene = Bevy::Scene.new('Test')
      bundle = described_class.new(scene: scene)
      expect(bundle.scene).to eq(scene)
      expect(bundle.transform).to be_a(Bevy::Transform)
    end
  end

  describe '#type_name' do
    it 'returns SceneBundle' do
      scene = Bevy::Scene.new
      bundle = described_class.new(scene: scene)
      expect(bundle.type_name).to eq('SceneBundle')
    end
  end
end
