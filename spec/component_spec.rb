# frozen_string_literal: true

RSpec.describe Bevy::Component do
  describe '.new' do
    it 'creates a component with a type name' do
      component = described_class.new('Position')
      expect(component.type_name).to eq('Position')
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash' do
      component = described_class.from_hash('Position', { x: 10, y: 20 })

      expect(component.type_name).to eq('Position')
      expect(component['x']).to eq(10)
      expect(component['y']).to eq(20)
    end
  end

  describe '#[]' do
    it 'gets a value by name' do
      component = described_class.from_hash('Position', { x: 10 })
      expect(component['x']).to eq(10)
    end

    it 'returns nil for missing keys' do
      component = described_class.new('Position')
      expect(component['missing']).to be_nil
    end
  end

  describe '#[]=' do
    it 'sets a value by name' do
      component = described_class.new('Position')
      component['x'] = 100
      expect(component['x']).to eq(100)
    end

    it 'supports various types' do
      component = described_class.new('Test')

      component['integer'] = 42
      component['float'] = 3.14
      component['string'] = 'hello'
      component['boolean'] = true

      expect(component['integer']).to eq(42)
      expect(component['float']).to eq(3.14)
      expect(component['string']).to eq('hello')
      expect(component['boolean']).to be true
    end
  end

  describe '#to_h' do
    it 'converts component to a hash' do
      component = described_class.from_hash('Position', { x: 10, y: 20 })
      hash = component.to_h

      expect(hash[:x]).to eq(10)
      expect(hash[:y]).to eq(20)
    end
  end
end

RSpec.describe 'World with Components' do
  let(:world) { Bevy::World.new }

  describe '#spawn_with' do
    it 'spawns an entity with components' do
      position = Bevy::Component.from_hash('Position', { x: 10, y: 20 })
      velocity = Bevy::Component.from_hash('Velocity', { x: 1, y: 0 })

      entity = world.spawn_with([position, velocity])

      expect(entity).to be_a(Bevy::Entity)
      expect(world.has_component?(entity, 'Position')).to be true
      expect(world.has_component?(entity, 'Velocity')).to be true
    end
  end

  describe '#insert' do
    it 'inserts a component into an entity' do
      entity = world.spawn
      position = Bevy::Component.from_hash('Position', { x: 10, y: 20 })

      world.insert(entity, position)

      expect(world.has_component?(entity, 'Position')).to be true
    end
  end

  describe '#get' do
    it 'gets a component from an entity' do
      position = Bevy::Component.from_hash('Position', { x: 10, y: 20 })
      entity = world.spawn_with([position])

      retrieved = world.get(entity, 'Position')

      expect(retrieved.type_name).to eq('Position')
      expect(retrieved['x']).to eq(10)
      expect(retrieved['y']).to eq(20)
    end

    it 'raises an error for missing components' do
      entity = world.spawn

      expect { world.get(entity, 'Missing') }.to raise_error(RuntimeError)
    end
  end

  describe '#has_component?' do
    it 'returns true for existing components' do
      position = Bevy::Component.from_hash('Position', { x: 0, y: 0 })
      entity = world.spawn_with([position])

      expect(world.has_component?(entity, 'Position')).to be true
    end

    it 'returns false for missing components' do
      entity = world.spawn

      expect(world.has_component?(entity, 'Position')).to be false
    end
  end

  describe '#query' do
    it 'returns entities matching component types' do
      pos1 = Bevy::Component.from_hash('Position', { x: 0, y: 0 })
      vel1 = Bevy::Component.from_hash('Velocity', { x: 1, y: 0 })
      pos2 = Bevy::Component.from_hash('Position', { x: 10, y: 10 })
      vel2 = Bevy::Component.from_hash('Velocity', { x: 0, y: 1 })
      pos3 = Bevy::Component.from_hash('Position', { x: 20, y: 20 })

      entity1 = world.spawn_with([pos1, vel1])
      entity2 = world.spawn_with([pos2, vel2])
      world.spawn_with([pos3])

      entities = world.query(%w[Position Velocity])

      expect(entities.length).to eq(2)
      expect(entities.map(&:id)).to contain_exactly(entity1.id, entity2.id)
    end

    it 'returns empty array when no entities match' do
      entities = world.query(%w[NonExistent])
      expect(entities).to be_empty
    end
  end
end
