# frozen_string_literal: true

RSpec.describe Bevy::World do
  describe '.new' do
    it 'creates a new World instance' do
      world = described_class.new
      expect(world).to be_a(described_class)
    end
  end

  describe '#spawn' do
    it 'creates a new entity' do
      world = described_class.new
      entity = world.spawn

      expect(entity).to be_a(Bevy::Entity)
    end

    it 'creates entities with unique IDs' do
      world = described_class.new
      entity1 = world.spawn
      entity2 = world.spawn

      expect(entity1.id).not_to eq(entity2.id)
    end
  end

  describe '#entity_exists?' do
    it 'returns true for existing entities' do
      world = described_class.new
      entity = world.spawn

      expect(world.entity_exists?(entity)).to be true
    end

    it 'returns false after despawn' do
      world = described_class.new
      entity = world.spawn
      world.despawn(entity)

      expect(world.entity_exists?(entity)).to be false
    end
  end

  describe '#despawn' do
    it 'removes an entity from the world' do
      world = described_class.new
      entity = world.spawn

      expect { world.despawn(entity) }.not_to raise_error
      expect(world.entity_exists?(entity)).to be false
    end
  end
end
