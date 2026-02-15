# frozen_string_literal: true

module Bevy
  class AudioEffect
    attr_accessor :enabled, :mix

    def initialize(enabled: true, mix: 1.0)
      @enabled = enabled
      @mix = mix.to_f
    end

    def type_name
      'AudioEffect'
    end
  end

  class Reverb < AudioEffect
    attr_accessor :room_size, :damping, :wet_level, :dry_level, :width

    def initialize(
      room_size: 0.5,
      damping: 0.5,
      wet_level: 0.33,
      dry_level: 0.4,
      width: 1.0,
      **kwargs
    )
      super(**kwargs)
      @room_size = room_size.to_f
      @damping = damping.to_f
      @wet_level = wet_level.to_f
      @dry_level = dry_level.to_f
      @width = width.to_f
    end

    def type_name
      'Reverb'
    end
  end

  class Delay < AudioEffect
    attr_accessor :delay_time, :feedback, :wet_level

    def initialize(delay_time: 0.5, feedback: 0.5, wet_level: 0.5, **kwargs)
      super(**kwargs)
      @delay_time = delay_time.to_f
      @feedback = feedback.to_f
      @wet_level = wet_level.to_f
    end

    def type_name
      'Delay'
    end
  end

  class LowPassFilter < AudioEffect
    attr_accessor :cutoff, :resonance

    def initialize(cutoff: 1000.0, resonance: 0.707, **kwargs)
      super(**kwargs)
      @cutoff = cutoff.to_f
      @resonance = resonance.to_f
    end

    def type_name
      'LowPassFilter'
    end
  end

  class HighPassFilter < AudioEffect
    attr_accessor :cutoff, :resonance

    def initialize(cutoff: 200.0, resonance: 0.707, **kwargs)
      super(**kwargs)
      @cutoff = cutoff.to_f
      @resonance = resonance.to_f
    end

    def type_name
      'HighPassFilter'
    end
  end

  class Compressor < AudioEffect
    attr_accessor :threshold, :ratio, :attack, :release, :makeup_gain

    def initialize(
      threshold: -20.0,
      ratio: 4.0,
      attack: 0.01,
      release: 0.1,
      makeup_gain: 0.0,
      **kwargs
    )
      super(**kwargs)
      @threshold = threshold.to_f
      @ratio = ratio.to_f
      @attack = attack.to_f
      @release = release.to_f
      @makeup_gain = makeup_gain.to_f
    end

    def type_name
      'Compressor'
    end
  end

  class Equalizer < AudioEffect
    attr_reader :bands

    def initialize(**kwargs)
      super(**kwargs)
      @bands = []
    end

    def add_band(frequency:, gain:, q: 1.0)
      @bands << EqualizerBand.new(frequency: frequency, gain: gain, q: q)
      self
    end

    def type_name
      'Equalizer'
    end
  end

  class EqualizerBand
    attr_accessor :frequency, :gain, :q

    def initialize(frequency:, gain:, q: 1.0)
      @frequency = frequency.to_f
      @gain = gain.to_f
      @q = q.to_f
    end

    def type_name
      'EqualizerBand'
    end
  end

  class Chorus < AudioEffect
    attr_accessor :rate, :depth, :delay, :feedback

    def initialize(rate: 1.5, depth: 0.02, delay: 0.03, feedback: 0.25, **kwargs)
      super(**kwargs)
      @rate = rate.to_f
      @depth = depth.to_f
      @delay = delay.to_f
      @feedback = feedback.to_f
    end

    def type_name
      'Chorus'
    end
  end

  class Flanger < AudioEffect
    attr_accessor :rate, :depth, :feedback, :delay

    def initialize(rate: 0.5, depth: 1.0, feedback: 0.5, delay: 0.001, **kwargs)
      super(**kwargs)
      @rate = rate.to_f
      @depth = depth.to_f
      @feedback = feedback.to_f
      @delay = delay.to_f
    end

    def type_name
      'Flanger'
    end
  end

  class Distortion < AudioEffect
    attr_accessor :drive, :range, :blend

    def initialize(drive: 0.5, range: 1000.0, blend: 0.5, **kwargs)
      super(**kwargs)
      @drive = drive.to_f
      @range = range.to_f
      @blend = blend.to_f
    end

    def type_name
      'Distortion'
    end
  end

  class AudioEffectChain
    attr_reader :effects

    def initialize
      @effects = []
    end

    def add(effect)
      @effects << effect
      self
    end

    def remove(index)
      @effects.delete_at(index)
    end

    def clear
      @effects = []
    end

    def process(sample)
      @effects.reduce(sample) do |s, effect|
        effect.enabled ? apply_effect(effect, s) : s
      end
    end

    def type_name
      'AudioEffectChain'
    end

    private

    def apply_effect(_effect, sample)
      sample
    end
  end

end
