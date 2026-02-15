# frozen_string_literal: true

module Bevy
  class Particle
    attr_accessor :position, :velocity, :acceleration
    attr_accessor :lifetime, :age, :size, :rotation, :color
    attr_accessor :alive

    def initialize(
      position: nil,
      velocity: nil,
      lifetime: 1.0,
      size: 1.0,
      color: nil
    )
      @position = position || Vec3.zero
      @velocity = velocity || Vec3.zero
      @acceleration = Vec3.zero
      @lifetime = lifetime.to_f
      @age = 0.0
      @size = size.to_f
      @rotation = 0.0
      @color = color || Color.white
      @alive = true
    end

    def update(delta)
      return unless @alive

      @age += delta
      if @age >= @lifetime
        @alive = false
        return
      end

      @velocity = Vec3.new(
        @velocity.x + @acceleration.x * delta,
        @velocity.y + @acceleration.y * delta,
        @velocity.z + @acceleration.z * delta
      )

      @position = Vec3.new(
        @position.x + @velocity.x * delta,
        @position.y + @velocity.y * delta,
        @position.z + @velocity.z * delta
      )
    end

    def progress
      return 1.0 if @lifetime <= 0

      (@age / @lifetime).clamp(0.0, 1.0)
    end

    def remaining_lifetime
      [@lifetime - @age, 0.0].max
    end

    def type_name
      'Particle'
    end
  end

  class ParticleEmitter
    attr_accessor :position, :rate, :lifetime, :speed
    attr_accessor :direction, :spread, :gravity
    attr_accessor :start_size, :end_size
    attr_accessor :start_color, :end_color
    attr_accessor :max_particles, :enabled

    def initialize(
      position: nil,
      rate: 10.0,
      lifetime: 1.0,
      speed: 100.0,
      direction: nil,
      spread: Math::PI / 4.0,
      gravity: nil,
      start_size: 10.0,
      end_size: 0.0,
      start_color: nil,
      end_color: nil,
      max_particles: 1000
    )
      @position = position || Vec3.zero
      @rate = rate.to_f
      @lifetime = lifetime.to_f
      @speed = speed.to_f
      @direction = direction || Vec3.new(0.0, 1.0, 0.0)
      @spread = spread.to_f
      @gravity = gravity || Vec3.new(0.0, -100.0, 0.0)
      @start_size = start_size.to_f
      @end_size = end_size.to_f
      @start_color = start_color || Color.white
      @end_color = end_color || Color.rgba(1.0, 1.0, 1.0, 0.0)
      @max_particles = max_particles
      @enabled = true
      @emission_accumulator = 0.0
    end

    def emit_count(delta)
      return 0 unless @enabled

      @emission_accumulator += @rate * delta
      count = @emission_accumulator.floor
      @emission_accumulator -= count
      count
    end

    def spawn_particle
      angle = rand * @spread - @spread / 2.0
      cos_a = Math.cos(angle)
      sin_a = Math.sin(angle)

      vel = Vec3.new(
        @direction.x * cos_a - @direction.y * sin_a,
        @direction.x * sin_a + @direction.y * cos_a,
        @direction.z
      )

      speed_variance = @speed * (0.8 + rand * 0.4)
      vel = Vec3.new(
        vel.x * speed_variance,
        vel.y * speed_variance,
        vel.z * speed_variance
      )

      lifetime_variance = @lifetime * (0.8 + rand * 0.4)

      Particle.new(
        position: Vec3.new(@position.x, @position.y, @position.z),
        velocity: vel,
        lifetime: lifetime_variance,
        size: @start_size,
        color: @start_color
      )
    end

    def type_name
      'ParticleEmitter'
    end
  end

  class ParticleSystem
    attr_reader :particles, :emitter

    def initialize(emitter: nil)
      @emitter = emitter || ParticleEmitter.new
      @particles = []
    end

    def update(delta)
      @particles.each do |particle|
        particle.acceleration = @emitter.gravity
        particle.update(delta)

        if particle.alive
          t = particle.progress
          particle.size = lerp(@emitter.start_size, @emitter.end_size, t)
          particle.color = lerp_color(@emitter.start_color, @emitter.end_color, t)
        end
      end

      @particles.reject! { |p| !p.alive }

      spawn_count = @emitter.emit_count(delta)
      spawn_count.times do
        break if @particles.size >= @emitter.max_particles

        @particles << @emitter.spawn_particle
      end
    end

    def active_count
      @particles.size
    end

    def clear
      @particles.clear
    end

    def burst(count)
      count.times do
        break if @particles.size >= @emitter.max_particles

        @particles << @emitter.spawn_particle
      end
    end

    def type_name
      'ParticleSystem'
    end

    private

    def lerp(a, b, t)
      a + (b - a) * t
    end

    def lerp_color(a, b, t)
      Color.rgba(
        lerp(a.r, b.r, t),
        lerp(a.g, b.g, t),
        lerp(a.b, b.b, t),
        lerp(a.a, b.a, t)
      )
    end
  end

  class ParticleBundle
    attr_reader :particle_system, :transform

    def initialize(emitter: nil, transform: nil)
      @particle_system = ParticleSystem.new(emitter: emitter)
      @transform = transform || Transform.identity
    end

    def type_name
      'ParticleBundle'
    end
  end

  module EmitterShape
    POINT = :point
    CIRCLE = :circle
    RECTANGLE = :rectangle
    SPHERE = :sphere
    CONE = :cone
  end

  class ShapeEmitter
    attr_accessor :shape, :radius, :width, :height, :depth, :angle

    def initialize(shape: EmitterShape::POINT, radius: 0.0, width: 0.0, height: 0.0, depth: 0.0, angle: 0.0)
      @shape = shape
      @radius = radius.to_f
      @width = width.to_f
      @height = height.to_f
      @depth = depth.to_f
      @angle = angle.to_f
    end

    def sample_position(center)
      case @shape
      when EmitterShape::POINT
        center
      when EmitterShape::CIRCLE
        angle = rand * 2.0 * Math::PI
        r = Math.sqrt(rand) * @radius
        Vec3.new(
          center.x + r * Math.cos(angle),
          center.y + r * Math.sin(angle),
          center.z
        )
      when EmitterShape::RECTANGLE
        Vec3.new(
          center.x + (rand - 0.5) * @width,
          center.y + (rand - 0.5) * @height,
          center.z
        )
      when EmitterShape::SPHERE
        theta = rand * 2.0 * Math::PI
        phi = Math.acos(2.0 * rand - 1.0)
        r = (rand**(1.0 / 3.0)) * @radius
        Vec3.new(
          center.x + r * Math.sin(phi) * Math.cos(theta),
          center.y + r * Math.sin(phi) * Math.sin(theta),
          center.z + r * Math.cos(phi)
        )
      else
        center
      end
    end

    def type_name
      'ShapeEmitter'
    end
  end

  class ParticleEffect
    attr_reader :name, :emitter_settings, :duration, :looping

    def initialize(name:, emitter_settings: nil, duration: Float::INFINITY, looping: true)
      @name = name
      @emitter_settings = emitter_settings || {}
      @duration = duration.to_f
      @looping = looping
    end

    def build_emitter
      ParticleEmitter.new(**@emitter_settings)
    end

    def type_name
      'ParticleEffect'
    end
  end

  class ParticleEffectInstance
    attr_reader :effect, :elapsed, :finished

    def initialize(effect)
      @effect = effect
      @elapsed = 0.0
      @finished = false
      @system = ParticleSystem.new(emitter: effect.build_emitter)
    end

    def update(delta)
      return if @finished

      @elapsed += delta
      @system.update(delta)

      if @elapsed >= @effect.duration
        if @effect.looping
          @elapsed = 0.0
        else
          @system.emitter.enabled = false
          @finished = true if @system.active_count.zero?
        end
      end
    end

    def particles
      @system.particles
    end

    def active_count
      @system.active_count
    end

    def type_name
      'ParticleEffectInstance'
    end
  end
end
