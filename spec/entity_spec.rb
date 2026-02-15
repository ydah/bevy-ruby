# frozen_string_literal: true

RSpec.describe Bevy::Entity do
  let(:world) { Bevy::World.new }

  describe '#id' do
    it 'returns a unique identifier' do
      entity = world.spawn

      expect(entity.id).to be_a(Integer)
    end

    it 'returns different IDs for different entities' do
      entity1 = world.spawn
      entity2 = world.spawn

      expect(entity1.id).not_to eq(entity2.id)
    end
  end
end
