# frozen_string_literal: true

RSpec.describe Bevy::Particle do
  describe '.new' do
    it 'creates with default values' do
      particle = described_class.new
      expect(particle.position.x).to eq(0.0)
      expect(particle.velocity.x).to eq(0.0)
      expect(particle.lifetime).to eq(1.0)
      expect(particle.alive).to be true
    end

    it 'creates with custom values' do
      particle = described_class.new(
        position: Bevy::Vec3.new(10.0, 20.0, 0.0),
        velocity: Bevy::Vec3.new(5.0, 0.0, 0.0),
        lifetime: 2.0,
        size: 5.0
      )
      expect(particle.position.x).to eq(10.0)
      expect(particle.velocity.x).to eq(5.0)
      expect(particle.lifetime).to eq(2.0)
      expect(particle.size).to eq(5.0)
    end
  end

  describe '#update' do
    it 'updates position based on velocity' do
      particle = described_class.new(
        velocity: Bevy::Vec3.new(100.0, 0.0, 0.0)
      )
      particle.update(0.1)
      expect(particle.position.x).to be_within(0.01).of(10.0)
    end

    it 'updates age' do
      particle = described_class.new(lifetime: 2.0)
      particle.update(0.5)
      expect(particle.age).to eq(0.5)
    end

    it 'marks as dead when lifetime exceeded' do
      particle = described_class.new(lifetime: 1.0)
      particle.update(1.5)
      expect(particle.alive).to be false
    end
  end

  describe '#progress' do
    it 'returns 0 at start' do
      particle = described_class.new(lifetime: 2.0)
      expect(particle.progress).to eq(0.0)
    end

    it 'returns 0.5 at halfway' do
      particle = described_class.new(lifetime: 2.0)
      particle.update(1.0)
      expect(particle.progress).to eq(0.5)
    end
  end

  describe '#remaining_lifetime' do
    it 'returns remaining time' do
      particle = described_class.new(lifetime: 2.0)
      particle.update(0.5)
      expect(particle.remaining_lifetime).to eq(1.5)
    end
  end

  describe '#type_name' do
    it 'returns Particle' do
      expect(described_class.new.type_name).to eq('Particle')
    end
  end
end

RSpec.describe Bevy::ParticleEmitter do
  describe '.new' do
    it 'creates with default values' do
      emitter = described_class.new
      expect(emitter.rate).to eq(10.0)
      expect(emitter.lifetime).to eq(1.0)
      expect(emitter.enabled).to be true
    end

    it 'creates with custom values' do
      emitter = described_class.new(
        rate: 50.0,
        lifetime: 2.0,
        speed: 200.0,
        max_particles: 500
      )
      expect(emitter.rate).to eq(50.0)
      expect(emitter.lifetime).to eq(2.0)
      expect(emitter.speed).to eq(200.0)
      expect(emitter.max_particles).to eq(500)
    end
  end

  describe '#emit_count' do
    it 'returns particles to emit based on rate and delta' do
      emitter = described_class.new(rate: 100.0)
      count = emitter.emit_count(0.1)
      expect(count).to eq(10)
    end

    it 'returns 0 when disabled' do
      emitter = described_class.new(rate: 100.0)
      emitter.enabled = false
      count = emitter.emit_count(0.1)
      expect(count).to eq(0)
    end
  end

  describe '#spawn_particle' do
    it 'creates a particle at emitter position' do
      emitter = described_class.new(position: Bevy::Vec3.new(50.0, 50.0, 0.0))
      particle = emitter.spawn_particle
      expect(particle).to be_a(Bevy::Particle)
      expect(particle.position.x).to eq(50.0)
    end
  end

  describe '#type_name' do
    it 'returns ParticleEmitter' do
      expect(described_class.new.type_name).to eq('ParticleEmitter')
    end
  end
end

RSpec.describe Bevy::ParticleSystem do
  describe '.new' do
    it 'creates with default emitter' do
      system = described_class.new
      expect(system.emitter).to be_a(Bevy::ParticleEmitter)
      expect(system.particles).to be_empty
    end

    it 'creates with custom emitter' do
      emitter = Bevy::ParticleEmitter.new(rate: 50.0)
      system = described_class.new(emitter: emitter)
      expect(system.emitter.rate).to eq(50.0)
    end
  end

  describe '#update' do
    it 'spawns and updates particles' do
      emitter = Bevy::ParticleEmitter.new(rate: 100.0)
      system = described_class.new(emitter: emitter)
      system.update(0.1)
      expect(system.active_count).to be > 0
    end

    it 'removes dead particles' do
      emitter = Bevy::ParticleEmitter.new(rate: 10.0, lifetime: 0.1)
      system = described_class.new(emitter: emitter)
      system.update(0.1)
      system.emitter.enabled = false
      system.update(0.2)
      expect(system.active_count).to eq(0)
    end
  end

  describe '#burst' do
    it 'spawns specified number of particles' do
      system = described_class.new
      system.burst(50)
      expect(system.active_count).to eq(50)
    end

    it 'respects max_particles' do
      emitter = Bevy::ParticleEmitter.new(max_particles: 10)
      system = described_class.new(emitter: emitter)
      system.burst(50)
      expect(system.active_count).to eq(10)
    end
  end

  describe '#clear' do
    it 'removes all particles' do
      system = described_class.new
      system.burst(10)
      system.clear
      expect(system.active_count).to eq(0)
    end
  end

  describe '#type_name' do
    it 'returns ParticleSystem' do
      expect(described_class.new.type_name).to eq('ParticleSystem')
    end
  end
end

RSpec.describe Bevy::ShapeEmitter do
  describe '.new' do
    it 'creates with default point shape' do
      emitter = described_class.new
      expect(emitter.shape).to eq(Bevy::EmitterShape::POINT)
    end
  end

  describe '#sample_position' do
    it 'returns center for point shape' do
      emitter = described_class.new(shape: Bevy::EmitterShape::POINT)
      center = Bevy::Vec3.new(10.0, 20.0, 0.0)
      result = emitter.sample_position(center)
      expect(result.x).to eq(10.0)
      expect(result.y).to eq(20.0)
    end

    it 'returns position within circle for circle shape' do
      emitter = described_class.new(shape: Bevy::EmitterShape::CIRCLE, radius: 10.0)
      center = Bevy::Vec3.zero
      100.times do
        result = emitter.sample_position(center)
        distance = Math.sqrt(result.x**2 + result.y**2)
        expect(distance).to be <= 10.0
      end
    end
  end

  describe '#type_name' do
    it 'returns ShapeEmitter' do
      expect(described_class.new.type_name).to eq('ShapeEmitter')
    end
  end
end

RSpec.describe Bevy::ParticleEffect do
  describe '.new' do
    it 'creates with name' do
      effect = described_class.new(name: 'Explosion')
      expect(effect.name).to eq('Explosion')
    end

    it 'creates with duration' do
      effect = described_class.new(name: 'Sparkle', duration: 2.0, looping: false)
      expect(effect.duration).to eq(2.0)
      expect(effect.looping).to be false
    end
  end

  describe '#build_emitter' do
    it 'creates emitter from settings' do
      effect = described_class.new(
        name: 'Test',
        emitter_settings: { rate: 50.0, lifetime: 2.0 }
      )
      emitter = effect.build_emitter
      expect(emitter).to be_a(Bevy::ParticleEmitter)
      expect(emitter.rate).to eq(50.0)
    end
  end

  describe '#type_name' do
    it 'returns ParticleEffect' do
      expect(described_class.new(name: 'Test').type_name).to eq('ParticleEffect')
    end
  end
end
