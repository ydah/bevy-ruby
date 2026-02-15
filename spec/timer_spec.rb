# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bevy::Timer do
  describe '#initialize' do
    it 'creates a timer with specified duration' do
      timer = Bevy::Timer.new(2.0)
      expect(timer.duration).to eq(2.0)
      expect(timer.elapsed).to eq(0.0)
      expect(timer.finished?).to be false
    end

    it 'defaults to ONCE mode' do
      timer = Bevy::Timer.new(1.0)
      expect(timer.repeating?).to be false
    end

    it 'can be created as repeating' do
      timer = Bevy::Timer.new(1.0, mode: Bevy::Timer::TimerMode::REPEATING)
      expect(timer.repeating?).to be true
    end
  end

  describe '.from_seconds' do
    it 'creates a timer from seconds' do
      timer = Bevy::Timer.from_seconds(3.0)
      expect(timer.duration).to eq(3.0)
    end

    it 'accepts mode option' do
      timer = Bevy::Timer.from_seconds(1.0, mode: Bevy::Timer::TimerMode::REPEATING)
      expect(timer.repeating?).to be true
    end
  end

  describe '#tick' do
    it 'advances elapsed time' do
      timer = Bevy::Timer.new(2.0)
      timer.tick(0.5)
      expect(timer.elapsed).to eq(0.5)
    end

    it 'finishes when elapsed reaches duration' do
      timer = Bevy::Timer.new(1.0)
      timer.tick(1.0)
      expect(timer.finished?).to be true
      expect(timer.just_finished?).to be true
    end

    it 'does not exceed duration for ONCE mode' do
      timer = Bevy::Timer.new(1.0)
      timer.tick(2.0)
      expect(timer.elapsed).to eq(1.0)
      expect(timer.finished?).to be true
    end

    it 'wraps around for REPEATING mode' do
      timer = Bevy::Timer.new(1.0, mode: Bevy::Timer::TimerMode::REPEATING)
      timer.tick(1.5)
      expect(timer.elapsed).to eq(0.5)
      expect(timer.just_finished?).to be true
      expect(timer.finished?).to be false
    end

    it 'does not tick when paused' do
      timer = Bevy::Timer.new(1.0)
      timer.pause
      timer.tick(0.5)
      expect(timer.elapsed).to eq(0.0)
    end
  end

  describe '#just_finished?' do
    it 'is true only on the tick when timer finishes' do
      timer = Bevy::Timer.new(1.0)
      timer.tick(0.5)
      expect(timer.just_finished?).to be false

      timer.tick(0.5)
      expect(timer.just_finished?).to be true

      timer.tick(0.1)
      expect(timer.just_finished?).to be false
    end
  end

  describe '#percent' do
    it 'returns progress as percentage' do
      timer = Bevy::Timer.new(2.0)
      timer.tick(1.0)
      expect(timer.percent).to eq(0.5)
    end

    it 'clamps to 1.0' do
      timer = Bevy::Timer.new(1.0)
      timer.tick(2.0)
      expect(timer.percent).to eq(1.0)
    end
  end

  describe '#remaining' do
    it 'returns time left' do
      timer = Bevy::Timer.new(2.0)
      timer.tick(0.5)
      expect(timer.remaining).to eq(1.5)
    end
  end

  describe '#reset' do
    it 'resets the timer' do
      timer = Bevy::Timer.new(1.0)
      timer.tick(1.0)
      expect(timer.finished?).to be true

      timer.reset
      expect(timer.elapsed).to eq(0.0)
      expect(timer.finished?).to be false
    end
  end

  describe '#pause and #unpause' do
    it 'pauses and unpauses the timer' do
      timer = Bevy::Timer.new(2.0)
      timer.tick(0.5)

      timer.pause
      expect(timer.paused?).to be true
      timer.tick(0.5)
      expect(timer.elapsed).to eq(0.5)

      timer.unpause
      expect(timer.paused?).to be false
      timer.tick(0.5)
      expect(timer.elapsed).to eq(1.0)
    end
  end
end

RSpec.describe Bevy::Stopwatch do
  describe '#initialize' do
    it 'starts at zero' do
      sw = Bevy::Stopwatch.new
      expect(sw.elapsed).to eq(0.0)
    end
  end

  describe '#tick' do
    it 'accumulates time' do
      sw = Bevy::Stopwatch.new
      sw.tick(1.0)
      sw.tick(0.5)
      expect(sw.elapsed).to eq(1.5)
    end

    it 'does not tick when paused' do
      sw = Bevy::Stopwatch.new
      sw.tick(1.0)
      sw.pause
      sw.tick(1.0)
      expect(sw.elapsed).to eq(1.0)
    end
  end

  describe '#reset' do
    it 'resets elapsed time' do
      sw = Bevy::Stopwatch.new
      sw.tick(5.0)
      sw.reset
      expect(sw.elapsed).to eq(0.0)
    end
  end
end
