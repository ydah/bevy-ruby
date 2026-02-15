# frozen_string_literal: true

# Practical Example: Particle System
# A flexible particle system for visual effects.
# Press 1-5 to spawn different particle effects, SPACE for explosion.

require 'bevy'

class Particle < Bevy::ComponentDSL
  attribute :lifetime, Float, default: 1.0
  attribute :age, Float, default: 0.0
  attribute :initial_size, Float, default: 8.0
  attribute :shrink, :boolean, default: true
  attribute :fade, :boolean, default: true
end

class ParticleVelocity < Bevy::ComponentDSL
  attribute :x, Float, default: 0.0
  attribute :y, Float, default: 0.0
  attribute :gravity, Float, default: 0.0
  attribute :drag, Float, default: 0.0
end

class ParticleEmitter < Bevy::ComponentDSL
  attribute :active, :boolean, default: true
  attribute :spawn_timer, Float, default: 0.0
  attribute :spawn_rate, Float, default: 20.0
  attribute :max_particles, Integer, default: 100
  attribute :particle_count, Integer, default: 0
  attribute :preset, String, default: 'fire'
end

class EmitterConfig
  attr_accessor :spawn_rate, :max_particles, :lifetime_min, :lifetime_max, :speed_min, :speed_max, :angle_min,
                :angle_max, :size_min, :size_max, :color, :gravity, :fade, :shrink, :drag

  def initialize
    @spawn_rate = 20.0
    @max_particles = 100
    @lifetime_min = 0.5
    @lifetime_max = 1.5
    @speed_min = 50.0
    @speed_max = 100.0
    @angle_min = 0.0
    @angle_max = 360.0
    @size_min = 4.0
    @size_max = 10.0
    @color = '#FFFFFF'
    @gravity = 0.0
    @fade = true
    @shrink = false
    @drag = 0.0
  end
end

module Presets
  def self.fire
    config = EmitterConfig.new
    config.spawn_rate = 40.0
    config.max_particles = 150
    config.lifetime_min = 0.3
    config.lifetime_max = 0.7
    config.speed_min = 80.0
    config.speed_max = 150.0
    config.angle_min = 70.0
    config.angle_max = 110.0
    config.size_min = 10.0
    config.size_max = 20.0
    config.color = '#FF6B35'
    config.gravity = 100.0
    config.fade = true
    config.shrink = true
    config
  end

  def self.smoke
    config = EmitterConfig.new
    config.spawn_rate = 15.0
    config.max_particles = 80
    config.lifetime_min = 1.5
    config.lifetime_max = 2.5
    config.speed_min = 20.0
    config.speed_max = 50.0
    config.angle_min = 80.0
    config.angle_max = 100.0
    config.size_min = 15.0
    config.size_max = 30.0
    config.color = '#666666'
    config.gravity = 40.0
    config.fade = true
    config.shrink = false
    config.drag = 0.5
    config
  end

  def self.sparkle
    config = EmitterConfig.new
    config.spawn_rate = 25.0
    config.max_particles = 60
    config.lifetime_min = 0.2
    config.lifetime_max = 0.5
    config.speed_min = 20.0
    config.speed_max = 60.0
    config.angle_min = 0.0
    config.angle_max = 360.0
    config.size_min = 3.0
    config.size_max = 8.0
    config.color = '#F1C40F'
    config.gravity = -30.0
    config.fade = true
    config.shrink = false
    config
  end

  def self.rain
    config = EmitterConfig.new
    config.spawn_rate = 80.0
    config.max_particles = 300
    config.lifetime_min = 0.8
    config.lifetime_max = 1.2
    config.speed_min = 400.0
    config.speed_max = 500.0
    config.angle_min = 260.0
    config.angle_max = 280.0
    config.size_min = 2.0
    config.size_max = 5.0
    config.color = '#3498DB'
    config.gravity = -200.0
    config.fade = false
    config.shrink = false
    config
  end

  def self.snow
    config = EmitterConfig.new
    config.spawn_rate = 30.0
    config.max_particles = 150
    config.lifetime_min = 3.0
    config.lifetime_max = 5.0
    config.speed_min = 30.0
    config.speed_max = 60.0
    config.angle_min = 250.0
    config.angle_max = 290.0
    config.size_min = 4.0
    config.size_max = 10.0
    config.color = '#FFFFFF'
    config.gravity = -20.0
    config.fade = false
    config.shrink = false
    config.drag = 0.3
    config
  end

  def self.explosion
    config = EmitterConfig.new
    config.spawn_rate = 1000.0
    config.max_particles = 80
    config.lifetime_min = 0.3
    config.lifetime_max = 0.6
    config.speed_min = 200.0
    config.speed_max = 400.0
    config.angle_min = 0.0
    config.angle_max = 360.0
    config.size_min = 6.0
    config.size_max = 15.0
    config.color = '#F39C12'
    config.gravity = -150.0
    config.fade = true
    config.shrink = true
    config
  end

  def self.get(name)
    case name
    when 'fire' then fire
    when 'smoke' then smoke
    when 'sparkle' then sparkle
    when 'rain' then rain
    when 'snow' then snow
    when 'explosion' then explosion
    else fire
    end
  end
end

def spawn_particle(ctx, x, y, config)
  angle = rand(config.angle_min..config.angle_max) * Math::PI / 180.0
  speed = rand(config.speed_min..config.speed_max)
  size = rand(config.size_min..config.size_max)
  lifetime = rand(config.lifetime_min..config.lifetime_max)

  ctx.spawn(
    Particle.new(
      lifetime: lifetime,
      age: 0.0,
      initial_size: size,
      shrink: config.shrink,
      fade: config.fade
    ),
    ParticleVelocity.new(
      x: Math.cos(angle) * speed,
      y: Math.sin(angle) * speed,
      gravity: config.gravity,
      drag: config.drag
    ),
    Bevy::Transform.from_xyz(x + rand(-5.0..5.0), y, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex(config.color),
      custom_size: Bevy::Vec2.new(size, size)
    )
  )
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Particle System - 1:Fire 2:Smoke 3:Sparkle 4:Rain 5:Snow SPACE:Explosion',
    width: 800.0,
    height: 600.0
  }
)

current_preset = { name: 'fire' }

app.add_startup_system do |ctx|
  ctx.spawn(
    ParticleEmitter.new(active: true, spawn_rate: 40.0, max_particles: 150, preset: 'fire'),
    Bevy::Transform.from_xyz(0.0, -200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#2C3E50'),
      custom_size: Bevy::Vec2.new(80.0, 20.0)
    )
  )
end

app.add_update_system do |ctx|
  if ctx.key_just_pressed?('1')
    current_preset[:name] = 'fire'
    ctx.world.each(ParticleEmitter) do |entity, emitter|
      emitter.preset = 'fire'
      emitter.spawn_rate = 40.0
      emitter.max_particles = 150
      ctx.world.insert_component(entity, emitter)
    end
  end

  if ctx.key_just_pressed?('2')
    current_preset[:name] = 'smoke'
    ctx.world.each(ParticleEmitter) do |entity, emitter|
      emitter.preset = 'smoke'
      emitter.spawn_rate = 15.0
      emitter.max_particles = 80
      ctx.world.insert_component(entity, emitter)
    end
  end

  if ctx.key_just_pressed?('3')
    current_preset[:name] = 'sparkle'
    ctx.world.each(ParticleEmitter) do |entity, emitter|
      emitter.preset = 'sparkle'
      emitter.spawn_rate = 25.0
      emitter.max_particles = 60
      ctx.world.insert_component(entity, emitter)
    end
  end

  if ctx.key_just_pressed?('4')
    current_preset[:name] = 'rain'
    ctx.world.each(ParticleEmitter) do |entity, emitter|
      emitter.preset = 'rain'
      emitter.spawn_rate = 80.0
      emitter.max_particles = 300
      ctx.world.insert_component(entity, emitter)
      new_pos = Bevy::Vec3.new(0.0, 280.0, 0.0)
      ctx.world.each(ParticleEmitter, Bevy::Transform) do |e, _em, transform|
        ctx.world.insert_component(e, transform.with_translation(new_pos)) if e.id == entity.id
      end
    end
  end

  if ctx.key_just_pressed?('5')
    current_preset[:name] = 'snow'
    ctx.world.each(ParticleEmitter) do |entity, emitter|
      emitter.preset = 'snow'
      emitter.spawn_rate = 30.0
      emitter.max_particles = 150
      ctx.world.insert_component(entity, emitter)
      new_pos = Bevy::Vec3.new(0.0, 280.0, 0.0)
      ctx.world.each(ParticleEmitter, Bevy::Transform) do |e, _em, transform|
        ctx.world.insert_component(e, transform.with_translation(new_pos)) if e.id == entity.id
      end
    end
  end

  if ctx.key_just_pressed?('SPACE')
    config = Presets.explosion
    40.times do
      spawn_particle(ctx, 0.0, 0.0, config)
    end
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta

  ctx.world.each(ParticleEmitter, Bevy::Transform) do |entity, emitter, transform|
    next unless emitter.active

    config = Presets.get(emitter.preset)
    emitter.spawn_timer += delta
    spawn_interval = 1.0 / emitter.spawn_rate

    while emitter.spawn_timer >= spawn_interval && emitter.particle_count < emitter.max_particles
      emitter.spawn_timer -= spawn_interval
      emitter.particle_count += 1
      spawn_particle(ctx, transform.translation.x, transform.translation.y, config)
    end

    ctx.world.insert_component(entity, emitter)
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta
  to_remove = []

  ctx.world.each(Particle, ParticleVelocity, Bevy::Transform,
                 Bevy::Sprite) do |entity, particle, vel, transform, sprite|
    particle.age += delta

    if particle.age >= particle.lifetime
      to_remove << entity
      next
    end

    vel.y += vel.gravity * delta

    if vel.drag > 0
      vel.x *= (1.0 - vel.drag * delta)
      vel.y *= (1.0 - vel.drag * delta)
    end

    new_x = transform.translation.x + vel.x * delta
    new_y = transform.translation.y + vel.y * delta
    new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
    ctx.world.insert_component(entity, vel)

    progress = particle.age / particle.lifetime

    new_alpha = particle.fade ? (1.0 - progress) : 1.0
    new_size = particle.shrink ? particle.initial_size * (1.0 - progress) : particle.initial_size

    new_sprite = sprite
                 .with_color(sprite.color.with_alpha(new_alpha))
                 .with_custom_size(Bevy::Vec2.new(new_size, new_size))
    ctx.world.insert_component(entity, new_sprite)
    ctx.world.insert_component(entity, particle)
  end

  to_remove.each do |e|
    ctx.world.despawn(e)
    ctx.world.each(ParticleEmitter) do |emitter_entity, emitter|
      emitter.particle_count = [emitter.particle_count - 1, 0].max
      ctx.world.insert_component(emitter_entity, emitter)
      break
    end
  end
end

app.add_update_system do |ctx|
  if %w[fire smoke sparkle].include?(current_preset[:name])
    ctx.world.each(ParticleEmitter, Bevy::Transform) do |entity, _emitter, transform|
      if transform.translation.y != -200.0
        new_pos = Bevy::Vec3.new(0.0, -200.0, 0.0)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
      end
    end
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Particle System Demo'
puts 'Controls:'
puts '  1 - Fire effect'
puts '  2 - Smoke effect'
puts '  3 - Sparkle effect'
puts '  4 - Rain effect'
puts '  5 - Snow effect'
puts '  SPACE - Explosion'
puts '  ESC - Exit'
app.run
