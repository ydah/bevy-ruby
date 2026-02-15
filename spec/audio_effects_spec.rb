# frozen_string_literal: true

RSpec.describe Bevy::AudioEffect do
  describe '.new' do
    it 'creates enabled effect by default' do
      effect = described_class.new
      expect(effect.enabled).to be true
      expect(effect.mix).to eq(1.0)
    end

    it 'accepts custom parameters' do
      effect = described_class.new(enabled: false, mix: 0.5)
      expect(effect.enabled).to be false
      expect(effect.mix).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns AudioEffect' do
      expect(described_class.new.type_name).to eq('AudioEffect')
    end
  end
end

RSpec.describe Bevy::Reverb do
  describe '.new' do
    it 'creates with default values' do
      reverb = described_class.new
      expect(reverb.room_size).to eq(0.5)
      expect(reverb.damping).to eq(0.5)
      expect(reverb.wet_level).to eq(0.33)
      expect(reverb.dry_level).to eq(0.4)
      expect(reverb.width).to eq(1.0)
      expect(reverb.enabled).to be true
    end

    it 'accepts custom parameters' do
      reverb = described_class.new(room_size: 0.8, damping: 0.3)
      expect(reverb.room_size).to eq(0.8)
      expect(reverb.damping).to eq(0.3)
    end
  end

  describe '#type_name' do
    it 'returns Reverb' do
      expect(described_class.new.type_name).to eq('Reverb')
    end
  end
end

RSpec.describe Bevy::Delay do
  describe '.new' do
    it 'creates with default values' do
      delay = described_class.new
      expect(delay.delay_time).to eq(0.5)
      expect(delay.feedback).to eq(0.5)
      expect(delay.wet_level).to eq(0.5)
    end

    it 'accepts custom parameters' do
      delay = described_class.new(delay_time: 0.25, feedback: 0.7)
      expect(delay.delay_time).to eq(0.25)
      expect(delay.feedback).to eq(0.7)
    end
  end

  describe '#type_name' do
    it 'returns Delay' do
      expect(described_class.new.type_name).to eq('Delay')
    end
  end
end

RSpec.describe Bevy::LowPassFilter do
  describe '.new' do
    it 'creates with default values' do
      filter = described_class.new
      expect(filter.cutoff).to eq(1000.0)
      expect(filter.resonance).to eq(0.707)
    end

    it 'accepts custom parameters' do
      filter = described_class.new(cutoff: 500.0, resonance: 1.0)
      expect(filter.cutoff).to eq(500.0)
      expect(filter.resonance).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns LowPassFilter' do
      expect(described_class.new.type_name).to eq('LowPassFilter')
    end
  end
end

RSpec.describe Bevy::HighPassFilter do
  describe '.new' do
    it 'creates with default values' do
      filter = described_class.new
      expect(filter.cutoff).to eq(200.0)
      expect(filter.resonance).to eq(0.707)
    end

    it 'accepts custom parameters' do
      filter = described_class.new(cutoff: 100.0, resonance: 0.5)
      expect(filter.cutoff).to eq(100.0)
      expect(filter.resonance).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns HighPassFilter' do
      expect(described_class.new.type_name).to eq('HighPassFilter')
    end
  end
end

RSpec.describe Bevy::Compressor do
  describe '.new' do
    it 'creates with default values' do
      comp = described_class.new
      expect(comp.threshold).to eq(-20.0)
      expect(comp.ratio).to eq(4.0)
      expect(comp.attack).to eq(0.01)
      expect(comp.release).to eq(0.1)
      expect(comp.makeup_gain).to eq(0.0)
    end

    it 'accepts custom parameters' do
      comp = described_class.new(threshold: -10.0, ratio: 8.0)
      expect(comp.threshold).to eq(-10.0)
      expect(comp.ratio).to eq(8.0)
    end
  end

  describe '#type_name' do
    it 'returns Compressor' do
      expect(described_class.new.type_name).to eq('Compressor')
    end
  end
end

RSpec.describe Bevy::Equalizer do
  describe '.new' do
    it 'creates with empty bands' do
      eq = described_class.new
      expect(eq.bands).to be_empty
    end
  end

  describe '#add_band' do
    it 'adds equalizer bands' do
      eq = described_class.new
      eq.add_band(frequency: 100.0, gain: 3.0)
      eq.add_band(frequency: 1000.0, gain: -2.0, q: 2.0)
      expect(eq.bands.size).to eq(2)
      expect(eq.bands.first.frequency).to eq(100.0)
      expect(eq.bands.first.gain).to eq(3.0)
      expect(eq.bands.last.q).to eq(2.0)
    end

    it 'returns self for chaining' do
      eq = described_class.new
      result = eq.add_band(frequency: 100.0, gain: 0.0)
      expect(result).to eq(eq)
    end
  end

  describe '#type_name' do
    it 'returns Equalizer' do
      expect(described_class.new.type_name).to eq('Equalizer')
    end
  end
end

RSpec.describe Bevy::EqualizerBand do
  describe '.new' do
    it 'creates with specified values' do
      band = described_class.new(frequency: 440.0, gain: 6.0, q: 1.5)
      expect(band.frequency).to eq(440.0)
      expect(band.gain).to eq(6.0)
      expect(band.q).to eq(1.5)
    end

    it 'uses default q value' do
      band = described_class.new(frequency: 1000.0, gain: 0.0)
      expect(band.q).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns EqualizerBand' do
      expect(described_class.new(frequency: 100.0, gain: 0.0).type_name).to eq('EqualizerBand')
    end
  end
end

RSpec.describe Bevy::Chorus do
  describe '.new' do
    it 'creates with default values' do
      chorus = described_class.new
      expect(chorus.rate).to eq(1.5)
      expect(chorus.depth).to eq(0.02)
      expect(chorus.delay).to eq(0.03)
      expect(chorus.feedback).to eq(0.25)
    end

    it 'accepts custom parameters' do
      chorus = described_class.new(rate: 2.0, depth: 0.05)
      expect(chorus.rate).to eq(2.0)
      expect(chorus.depth).to eq(0.05)
    end
  end

  describe '#type_name' do
    it 'returns Chorus' do
      expect(described_class.new.type_name).to eq('Chorus')
    end
  end
end

RSpec.describe Bevy::Flanger do
  describe '.new' do
    it 'creates with default values' do
      flanger = described_class.new
      expect(flanger.rate).to eq(0.5)
      expect(flanger.depth).to eq(1.0)
      expect(flanger.feedback).to eq(0.5)
      expect(flanger.delay).to eq(0.001)
    end

    it 'accepts custom parameters' do
      flanger = described_class.new(rate: 1.0, feedback: 0.8)
      expect(flanger.rate).to eq(1.0)
      expect(flanger.feedback).to eq(0.8)
    end
  end

  describe '#type_name' do
    it 'returns Flanger' do
      expect(described_class.new.type_name).to eq('Flanger')
    end
  end
end

RSpec.describe Bevy::Distortion do
  describe '.new' do
    it 'creates with default values' do
      dist = described_class.new
      expect(dist.drive).to eq(0.5)
      expect(dist.range).to eq(1000.0)
      expect(dist.blend).to eq(0.5)
    end

    it 'accepts custom parameters' do
      dist = described_class.new(drive: 0.9, blend: 0.7)
      expect(dist.drive).to eq(0.9)
      expect(dist.blend).to eq(0.7)
    end
  end

  describe '#type_name' do
    it 'returns Distortion' do
      expect(described_class.new.type_name).to eq('Distortion')
    end
  end
end

RSpec.describe Bevy::AudioEffectChain do
  describe '.new' do
    it 'creates with empty effects' do
      chain = described_class.new
      expect(chain.effects).to be_empty
    end
  end

  describe '#add' do
    it 'adds effects to chain' do
      chain = described_class.new
      chain.add(Bevy::Reverb.new)
      chain.add(Bevy::Delay.new)
      expect(chain.effects.size).to eq(2)
    end

    it 'returns self for chaining' do
      chain = described_class.new
      result = chain.add(Bevy::Reverb.new)
      expect(result).to eq(chain)
    end
  end

  describe '#remove' do
    it 'removes effect at index' do
      chain = described_class.new
      chain.add(Bevy::Reverb.new)
      chain.add(Bevy::Delay.new)
      chain.remove(0)
      expect(chain.effects.size).to eq(1)
      expect(chain.effects.first).to be_a(Bevy::Delay)
    end
  end

  describe '#clear' do
    it 'removes all effects' do
      chain = described_class.new
      chain.add(Bevy::Reverb.new)
      chain.add(Bevy::Delay.new)
      chain.clear
      expect(chain.effects).to be_empty
    end
  end

  describe '#process' do
    it 'processes sample through enabled effects' do
      chain = described_class.new
      chain.add(Bevy::Reverb.new)
      result = chain.process(0.5)
      expect(result).to eq(0.5)
    end

    it 'skips disabled effects' do
      chain = described_class.new
      effect = Bevy::Reverb.new(enabled: false)
      chain.add(effect)
      result = chain.process(0.5)
      expect(result).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns AudioEffectChain' do
      expect(described_class.new.type_name).to eq('AudioEffectChain')
    end
  end
end
