# frozen_string_literal: true

class Position < Bevy::ComponentDSL
  attribute :x, :float, default: 0.0
  attribute :y, :float, default: 0.0
end

class Velocity < Bevy::ComponentDSL
  attribute :x, :float, default: 0.0
  attribute :y, :float, default: 0.0
end

class Health < Bevy::ComponentDSL
  attribute :current, :integer, default: 100
  attribute :max, :integer, default: 100
end

class Player < Bevy::ComponentDSL
end

RSpec.describe Bevy::ComponentDSL do
  describe '.attribute' do
    it 'defines getter and setter methods' do
      pos = Position.new

      expect(pos).to respond_to(:x)
      expect(pos).to respond_to(:x=)
      expect(pos).to respond_to(:y)
      expect(pos).to respond_to(:y=)
    end

    it 'uses default values' do
      pos = Position.new

      expect(pos.x).to eq(0.0)
      expect(pos.y).to eq(0.0)
    end

    it 'allows overriding defaults in initializer' do
      pos = Position.new(x: 10.0, y: 20.0)

      expect(pos.x).to eq(10.0)
      expect(pos.y).to eq(20.0)
    end
  end

  describe '#type_name' do
    it 'returns the class name' do
      expect(Position.new.type_name).to eq('Position')
      expect(Health.new.type_name).to eq('Health')
    end
  end

  describe '#to_native' do
    it 'converts to native Component' do
      pos = Position.new(x: 5.0, y: 10.0)
      native = pos.to_native

      expect(native).to be_a(Bevy::Component)
      expect(native.type_name).to eq('Position')
      expect(native['x']).to eq(5.0)
      expect(native['y']).to eq(10.0)
    end
  end

  describe '#to_h' do
    it 'returns a hash of attributes' do
      pos = Position.new(x: 1.0, y: 2.0)

      expect(pos.to_h).to eq({ x: 1.0, y: 2.0 })
    end
  end

  describe '#[] and #[]=' do
    it 'provides hash-like access' do
      pos = Position.new

      pos[:x] = 100.0
      expect(pos[:x]).to eq(100.0)
    end
  end
end

RSpec.describe 'World with ComponentDSL' do
  let(:world) { Bevy::World.new }

  describe '#spawn_entity' do
    it 'spawns an entity with DSL components' do
      entity = world.spawn_entity(
        Position.new(x: 10.0, y: 20.0),
        Velocity.new(x: 1.0, y: 0.0)
      )

      expect(entity).to be_a(Bevy::Entity)
      expect(world.has?(entity, Position)).to be true
      expect(world.has?(entity, Velocity)).to be true
    end

    it 'works with marker components' do
      entity = world.spawn_entity(Player.new, Position.new)

      expect(world.has?(entity, Player)).to be true
      expect(world.has?(entity, Position)).to be true
    end
  end

  describe '#insert_component' do
    it 'inserts a DSL component' do
      entity = world.spawn
      world.insert_component(entity, Health.new(current: 50))

      expect(world.has?(entity, Health)).to be true
    end
  end

  describe '#get_component' do
    it 'retrieves a component as the DSL class' do
      entity = world.spawn_entity(Position.new(x: 15.0, y: 25.0))

      pos = world.get_component(entity, Position)

      expect(pos).to be_a(Position)
      expect(pos.x).to eq(15.0)
      expect(pos.y).to eq(25.0)
    end
  end

  describe '#has?' do
    it 'checks component presence with class' do
      entity = world.spawn_entity(Position.new)

      expect(world.has?(entity, Position)).to be true
      expect(world.has?(entity, Velocity)).to be false
    end
  end

  describe '#each' do
    it 'iterates over entities with matching components' do
      world.spawn_entity(Position.new(x: 0.0, y: 0.0), Velocity.new(x: 1.0, y: 0.0))
      world.spawn_entity(Position.new(x: 10.0, y: 10.0), Velocity.new(x: 0.0, y: 1.0))
      world.spawn_entity(Position.new(x: 20.0, y: 20.0))

      count = 0
      world.each(Position, Velocity) do |entity, pos, vel|
        expect(entity).to be_a(Bevy::Entity)
        expect(pos).to be_a(Position)
        expect(vel).to be_a(Velocity)
        count += 1
      end

      expect(count).to eq(2)
    end

    it 'provides components with correct values' do
      world.spawn_entity(Position.new(x: 5.0, y: 10.0), Velocity.new(x: 2.0, y: 3.0))

      world.each(Position, Velocity) do |_entity, pos, vel|
        expect(pos.x).to eq(5.0)
        expect(pos.y).to eq(10.0)
        expect(vel.x).to eq(2.0)
        expect(vel.y).to eq(3.0)
      end
    end
  end
end
