# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Particle System Demo',
    width: 900.0,
    height: 700.0
  }
)

fire_emitter = Bevy::ParticleEmitter.new(
  position: Bevy::Vec3.new(-200.0, -200.0, 0.0),
  rate: 80.0,
  lifetime: 1.2,
  speed: 120.0,
  direction: Bevy::Vec3.new(0.0, 1.0, 0.0),
  spread: Math::PI / 6.0,
  gravity: Bevy::Vec3.new(0.0, 50.0, 0.0),
  start_size: 12.0,
  end_size: 2.0,
  start_color: Bevy::Color.rgba(1.0, 0.8, 0.0, 1.0),
  end_color: Bevy::Color.rgba(1.0, 0.0, 0.0, 0.0),
  max_particles: 300
)
fire_system = Bevy::ParticleSystem.new(emitter: fire_emitter)

fountain_emitter = Bevy::ParticleEmitter.new(
  position: Bevy::Vec3.new(0.0, -200.0, 0.0),
  rate: 60.0,
  lifetime: 2.0,
  speed: 200.0,
  direction: Bevy::Vec3.new(0.0, 1.0, 0.0),
  spread: Math::PI / 8.0,
  gravity: Bevy::Vec3.new(0.0, -150.0, 0.0),
  start_size: 8.0,
  end_size: 4.0,
  start_color: Bevy::Color.rgba(0.3, 0.7, 1.0, 1.0),
  end_color: Bevy::Color.rgba(0.1, 0.3, 0.8, 0.0),
  max_particles: 400
)
fountain_system = Bevy::ParticleSystem.new(emitter: fountain_emitter)

snow_emitter = Bevy::ParticleEmitter.new(
  position: Bevy::Vec3.new(200.0, 300.0, 0.0),
  rate: 30.0,
  lifetime: 4.0,
  speed: 30.0,
  direction: Bevy::Vec3.new(0.0, -1.0, 0.0),
  spread: Math::PI / 4.0,
  gravity: Bevy::Vec3.new(0.0, -20.0, 0.0),
  start_size: 6.0,
  end_size: 4.0,
  start_color: Bevy::Color.rgba(1.0, 1.0, 1.0, 0.9),
  end_color: Bevy::Color.rgba(0.9, 0.9, 1.0, 0.0),
  max_particles: 200
)
snow_system = Bevy::ParticleSystem.new(emitter: snow_emitter)

explosion_effect = Bevy::ParticleEffect.new(
  name: 'explosion',
  emitter_settings: {
    rate: 500.0,
    lifetime: 0.8,
    speed: 250.0,
    spread: Math::PI * 2,
    start_size: 10.0,
    end_size: 2.0,
    start_color: Bevy::Color.rgba(1.0, 0.6, 0.0, 1.0),
    end_color: Bevy::Color.rgba(0.5, 0.0, 0.0, 0.0)
  },
  duration: 0.2,
  looping: false
)

explosion_instances = []
particle_entities = {}

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#0a0a1a'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Particle System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-200.0, -280.0, 0.0),
    Bevy::Text2d.new('Fire', font_size: 16.0, color: Bevy::Color.from_hex('#FF6600'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -280.0, 0.0),
    Bevy::Text2d.new('Fountain', font_size: 16.0, color: Bevy::Color.from_hex('#4DA6FF'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(200.0, 280.0, 0.0),
    Bevy::Text2d.new('Snow', font_size: 16.0, color: Bevy::Color.from_hex('#EEEEFF'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -320.0, 0.0),
    Bevy::Text2d.new('Click anywhere to create explosion! Press ESC to exit', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  fire_system.update(delta)
  fountain_system.update(delta)
  snow_system.update(delta)

  explosion_instances.each { |inst| inst.update(delta) }
  explosion_instances.reject!(&:finished)

  if ctx.mouse_just_pressed?(:left)
    mouse_pos = ctx.mouse_position
    if mouse_pos
      instance = Bevy::ParticleEffectInstance.new(explosion_effect)
      instance.instance_variable_set(:@position, Bevy::Vec3.new(mouse_pos.x - 450, 350 - mouse_pos.y, 0.0))
      explosion_instances << instance
    end
  end

  particle_entities.each do |id, entity|
    ctx.world.despawn(entity) if entity
  end
  particle_entities.clear

  [
    [fire_system, '#FF4400'],
    [fountain_system, '#4DA6FF'],
    [snow_system, '#FFFFFF']
  ].each do |system, base_color|
    system.particles.each_with_index do |particle, i|
      next unless particle.alive

      progress = particle.progress
      size = particle.size * (1.0 - progress * 0.5)
      alpha = 1.0 - progress

      color = particle.color
      entity = ctx.spawn(
        Bevy::Transform.from_xyz(particle.position.x, particle.position.y, 1.0),
        Bevy::Mesh::Circle.new(radius: size, color: Bevy::Color.rgba(color.r, color.g, color.b, alpha))
      )
      particle_entities["#{system.object_id}_#{i}"] = entity
    end
  end

  explosion_instances.each_with_index do |instance, idx|
    pos = instance.instance_variable_get(:@position) || Bevy::Vec3.new(0.0, 0.0, 0.0)
    instance.particles.each_with_index do |particle, i|
      next unless particle.alive

      progress = particle.progress
      size = particle.size * (1.0 - progress * 0.3)
      alpha = 1.0 - progress

      color = particle.color
      entity = ctx.spawn(
        Bevy::Transform.from_xyz(pos.x + particle.position.x, pos.y + particle.position.y, 2.0),
        Bevy::Mesh::Circle.new(radius: size, color: Bevy::Color.rgba(color.r, color.g, color.b, alpha))
      )
      particle_entities["explosion_#{idx}_#{i}"] = entity
    end
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Particle System Demo'
puts ''
puts 'Particle effects:'
puts '  - Fire effect (left) - upward flames'
puts '  - Fountain effect (center) - water spray with gravity'
puts '  - Snow effect (right) - falling snowflakes'
puts ''
puts 'Click anywhere to create explosion!'
puts 'Press ESC to exit'

app.run
