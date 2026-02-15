# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Navigation System Demo',
    width: 900.0,
    height: 700.0
  }
)

class NavAgent
  attr_accessor :position, :velocity, :target, :speed, :radius, :color, :path

  def initialize(position:, speed: 100.0, radius: 15.0, color:)
    @position = position
    @velocity = Bevy::Vec3.new(0.0, 0.0, 0.0)
    @target = nil
    @speed = speed
    @radius = radius
    @color = color
    @path = []
  end

  def set_destination(target)
    @target = target
    @path = []
  end

  def update(delta, obstacles)
    return unless @target

    dx = @target.x - @position.x
    dy = @target.y - @position.y
    distance = Math.sqrt(dx * dx + dy * dy)

    return if distance < 5.0

    dir_x = dx / distance
    dir_y = dy / distance

    obstacles.each do |obs|
      obs_dx = obs[:x] - @position.x
      obs_dy = obs[:y] - @position.y
      obs_dist = Math.sqrt(obs_dx * obs_dx + obs_dy * obs_dy)

      if obs_dist < obs[:radius] + @radius + 30.0
        avoid_x = -obs_dx / obs_dist
        avoid_y = -obs_dy / obs_dist
        strength = 1.0 - (obs_dist / (obs[:radius] + @radius + 30.0))
        dir_x += avoid_x * strength * 2.0
        dir_y += avoid_y * strength * 2.0
      end
    end

    length = Math.sqrt(dir_x * dir_x + dir_y * dir_y)
    if length > 0
      dir_x /= length
      dir_y /= length
    end

    @velocity = Bevy::Vec3.new(dir_x * @speed, dir_y * @speed, 0.0)
    @position = Bevy::Vec3.new(
      @position.x + @velocity.x * delta,
      @position.y + @velocity.y * delta,
      0.0
    )
  end

  def reached_destination?
    return false unless @target

    dx = @target.x - @position.x
    dy = @target.y - @position.y
    Math.sqrt(dx * dx + dy * dy) < 10.0
  end
end

agents = [
  NavAgent.new(position: Bevy::Vec3.new(-300.0, -150.0, 0.0), speed: 80.0, color: Bevy::Color.from_hex('#3498DB')),
  NavAgent.new(position: Bevy::Vec3.new(-250.0, 150.0, 0.0), speed: 100.0, color: Bevy::Color.from_hex('#2ECC71')),
  NavAgent.new(position: Bevy::Vec3.new(300.0, 0.0, 0.0), speed: 120.0, color: Bevy::Color.from_hex('#E74C3C'))
]

obstacles = [
  { x: -100.0, y: 50.0, radius: 40.0 },
  { x: 50.0, y: -80.0, radius: 50.0 },
  { x: 150.0, y: 100.0, radius: 35.0 },
  { x: -50.0, y: -150.0, radius: 45.0 }
]

target_position = Bevy::Vec3.new(0.0, 0.0, 0.0)
entity_cache = {}
status_entity = nil
current_behavior = :seek

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Navigation System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[Click] Set Target  [1] Seek  [2] Flee  [3] Wander  [R] Reset', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  obstacles.each do |obs|
    ctx.spawn(
      Bevy::Transform.from_xyz(obs[:x], obs[:y], 0.5),
      Bevy::Mesh::Circle.new(radius: obs[:radius], color: Bevy::Color.from_hex('#444455'))
    )
  end

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Behavior: Seek | Click to set target', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

wander_timer = 0.0

app.add_update_system do |ctx|
  delta = ctx.delta
  wander_timer += delta

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    current_behavior = :seek
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    current_behavior = :flee
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    current_behavior = :wander
  end

  if ctx.key_just_pressed?('R')
    agents[0].position = Bevy::Vec3.new(-300.0, -150.0, 0.0)
    agents[1].position = Bevy::Vec3.new(-250.0, 150.0, 0.0)
    agents[2].position = Bevy::Vec3.new(300.0, 0.0, 0.0)
    agents.each { |a| a.target = nil }
  end

  if ctx.mouse_just_pressed?(:left)
    mouse_pos = ctx.mouse_position
    if mouse_pos
      target_position = Bevy::Vec3.new(mouse_pos.x - 450, 350 - mouse_pos.y, 0.0)
      agents.each { |agent| agent.set_destination(target_position) }
    end
  end

  case current_behavior
  when :seek
    agents.each { |agent| agent.update(delta, obstacles) }

  when :flee
    agents.each do |agent|
      if agent.target
        dx = agent.position.x - agent.target.x
        dy = agent.position.y - agent.target.y
        distance = Math.sqrt(dx * dx + dy * dy)

        if distance < 200.0 && distance > 0
          flee_x = dx / distance * agent.speed
          flee_y = dy / distance * agent.speed
          agent.position = Bevy::Vec3.new(
            [[agent.position.x + flee_x * delta, -380.0].max, 380.0].min,
            [[agent.position.y + flee_y * delta, -220.0].max, 220.0].min,
            0.0
          )
        end
      end
    end

  when :wander
    if wander_timer > 1.0
      wander_timer = 0.0
      agents.each do |agent|
        random_target = Bevy::Vec3.new(
          rand(-350.0..350.0),
          rand(-200.0..200.0),
          0.0
        )
        agent.set_destination(random_target)
      end
    end
    agents.each { |agent| agent.update(delta, obstacles) }
  end

  agents.each do |agent|
    agent.position = Bevy::Vec3.new(
      [[agent.position.x, -380.0].max, 380.0].min,
      [[agent.position.y, -220.0].max, 220.0].min,
      0.0
    )
  end

  entity_cache.each { |_, e| ctx.world.despawn(e) if e }
  entity_cache.clear

  if agents.any? { |a| a.target }
    target = agents.first.target
    target_entity = ctx.spawn(
      Bevy::Transform.from_xyz(target.x, target.y, 1.0),
      Bevy::Mesh::RegularPolygon.new(radius: 12.0, sides: 4, color: Bevy::Color.from_hex('#FFD700'))
    )
    entity_cache[:target] = target_entity
  end

  agents.each_with_index do |agent, i|
    agent_entity = ctx.spawn(
      Bevy::Transform.from_xyz(agent.position.x, agent.position.y, 2.0),
      Bevy::Mesh::Circle.new(radius: agent.radius, color: agent.color)
    )
    entity_cache["agent_#{i}"] = agent_entity

    if agent.velocity.x.abs > 1 || agent.velocity.y.abs > 1
      vel_length = Math.sqrt(agent.velocity.x**2 + agent.velocity.y**2)
      if vel_length > 0
        dir_x = agent.velocity.x / vel_length * 25.0
        dir_y = agent.velocity.y / vel_length * 25.0
        direction_entity = ctx.spawn(
          Bevy::Transform.from_xyz(agent.position.x + dir_x / 2.0, agent.position.y + dir_y / 2.0, 3.0),
          Bevy::Mesh::Rectangle.new(width: 20.0, height: 3.0, color: Bevy::Color.white)
        )
        entity_cache["dir_#{i}"] = direction_entity
      end
    end
  end

  if status_entity
    behavior_name = current_behavior.to_s.capitalize
    status_text = "Behavior: #{behavior_name} | Agents: #{agents.size} | Obstacles: #{obstacles.size}"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Navigation System Demo'
puts ''
puts 'Steering Behaviors:'
puts '  [1] Seek - Move toward target'
puts '  [2] Flee - Move away from target'
puts '  [3] Wander - Random movement'
puts ''
puts 'Controls:'
puts '  [Click] Set target position'
puts '  [R] Reset agent positions'
puts '  [ESC] Exit'

app.run
