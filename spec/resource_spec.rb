# frozen_string_literal: true

class GameState < Bevy::ResourceDSL
  attribute :score, :integer, default: 0
  attribute :level, :integer, default: 1
  attribute :paused, :boolean, default: false
end

class Settings < Bevy::ResourceDSL
  attribute :volume, :float, default: 1.0
  attribute :fullscreen, :boolean, default: false
end

RSpec.describe Bevy::ResourceDSL do
  describe '.attribute' do
    it 'defines getters and setters' do
      state = GameState.new
      expect(state).to respond_to(:score)
      expect(state).to respond_to(:score=)
    end
  end

  describe '.new' do
    it 'creates a resource with default values' do
      state = GameState.new
      expect(state.score).to eq(0)
      expect(state.level).to eq(1)
      expect(state.paused).to be false
    end

    it 'creates a resource with custom values' do
      state = GameState.new(score: 100, level: 5, paused: true)
      expect(state.score).to eq(100)
      expect(state.level).to eq(5)
      expect(state.paused).to be true
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      state = GameState.new(score: 50)
      h = state.to_h
      expect(h[:score]).to eq(50)
      expect(h[:level]).to eq(1)
    end
  end

  describe 'setters' do
    it 'allows modifying values' do
      state = GameState.new
      state.score = 100
      state.level = 3
      expect(state.score).to eq(100)
      expect(state.level).to eq(3)
    end
  end

  describe '.resource_name' do
    it 'returns the class name' do
      expect(GameState.resource_name).to eq('GameState')
    end
  end

  describe 'inheritance' do
    it 'copies attributes to subclass' do
      subclass = Class.new(GameState) do
        attribute :lives, :integer, default: 3
      end

      instance = subclass.new
      expect(instance.score).to eq(0)
      expect(instance.lives).to eq(3)
    end
  end
end

RSpec.describe Bevy::Resources do
  let(:resources) { described_class.new }

  describe '#insert' do
    it 'stores a resource' do
      state = GameState.new
      resources.insert(state)
      expect(resources.contains?(GameState)).to be true
    end
  end

  describe '#get' do
    it 'retrieves a resource' do
      state = GameState.new(score: 100)
      resources.insert(state)
      retrieved = resources.get(GameState)
      expect(retrieved.score).to eq(100)
    end

    it 'returns nil for missing resource' do
      expect(resources.get(GameState)).to be_nil
    end
  end

  describe '#get_or_insert' do
    it 'returns existing resource' do
      state = GameState.new(score: 50)
      resources.insert(state)

      retrieved = resources.get_or_insert(GameState) { GameState.new(score: 100) }
      expect(retrieved.score).to eq(50)
    end

    it 'inserts and returns new resource if missing' do
      retrieved = resources.get_or_insert(GameState) { GameState.new(score: 100) }
      expect(retrieved.score).to eq(100)
      expect(resources.contains?(GameState)).to be true
    end
  end

  describe '#remove' do
    it 'removes a resource' do
      resources.insert(GameState.new)
      resources.remove(GameState)
      expect(resources.contains?(GameState)).to be false
    end
  end

  describe '#contains?' do
    it 'checks if resource exists' do
      expect(resources.contains?(GameState)).to be false
      resources.insert(GameState.new)
      expect(resources.contains?(GameState)).to be true
    end
  end

  describe '#clear' do
    it 'removes all resources' do
      resources.insert(GameState.new)
      resources.insert(Settings.new)
      resources.clear
      expect(resources.contains?(GameState)).to be false
      expect(resources.contains?(Settings)).to be false
    end
  end
end

RSpec.describe Bevy::Time do
  let(:time) { described_class.new }

  describe '.new' do
    it 'initializes with zero delta' do
      expect(time.delta).to eq(0.0)
      expect(time.delta_seconds).to eq(0.0)
    end
  end

  describe '#update' do
    it 'calculates delta time' do
      sleep(0.01)
      time.update
      expect(time.delta_seconds).to be > 0.0
      expect(time.elapsed_seconds).to be > 0.0
    end
  end

  describe '#pause and #unpause' do
    it 'pauses time updates' do
      time.pause
      expect(time.paused?).to be true

      initial_delta = time.delta
      sleep(0.01)
      time.update
      expect(time.delta).to eq(initial_delta)

      time.unpause
      expect(time.paused?).to be false
    end
  end

  describe '#time_scale' do
    it 'scales delta time' do
      time.time_scale = 2.0
      expect(time.time_scale).to eq(2.0)
    end

    it 'clamps time scale' do
      time.time_scale = 15.0
      expect(time.time_scale).to eq(10.0)

      time.time_scale = -1.0
      expect(time.time_scale).to eq(0.0)
    end
  end

  describe '#reset' do
    it 'resets all time values' do
      time.update
      time.reset
      expect(time.delta).to eq(0.0)
      expect(time.elapsed).to eq(0.0)
    end
  end
end

RSpec.describe Bevy::FixedTime do
  let(:fixed) { described_class.new(timestep: 1.0 / 60.0) }

  describe '.new' do
    it 'initializes with timestep' do
      expect(fixed.timestep).to be_within(0.001).of(1.0 / 60.0)
      expect(fixed.delta).to eq(fixed.timestep)
    end
  end

  describe '#accumulate and #expend' do
    it 'accumulates time and expends in fixed steps' do
      fixed.accumulate(0.05)
      expect(fixed.accumulated).to eq(0.05)

      steps = 0
      steps += 1 while fixed.expend
      expect(steps).to eq(3)
    end
  end

  describe '#steps_remaining' do
    it 'calculates remaining steps' do
      fixed.accumulate(0.05)
      expect(fixed.steps_remaining).to eq(3)
    end
  end

  describe '#timestep=' do
    it 'clamps timestep' do
      fixed.timestep = 0.0001
      expect(fixed.timestep).to eq(0.001)

      fixed.timestep = 2.0
      expect(fixed.timestep).to eq(1.0)
    end
  end
end
