# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Physics System Demo',
    width: 900.0,
    height: 700.0
  }
)

class PhysicsObject
  attr_accessor :position, :velocity, :acceleration, :mass, :radius, :color, :body_type, :grounded

  def initialize(position:, velocity: nil, mass: 1.0, radius: 20.0, color:, body_type: :dynamic)
    @position = position
    @velocity = velocity || Bevy::Vec3.new(0.0, 0.0, 0.0)
    @acceleration = Bevy::Vec3.new(0.0, 0.0, 0.0)
    @mass = mass
    @radius = radius
    @color = color
    @body_type = body_type
    @grounded = false
  end

  def dynamic?
    @body_type == :dynamic
  end

  def static?
    @body_type == :static
  end

  def apply_force(force)
    return unless dynamic?

    @acceleration = Bevy::Vec3.new(
      @acceleration.x + force.x / @mass,
      @acceleration.y + force.y / @mass,
      @acceleration.z + force.z / @mass
    )
  end

  def update(dt, gravity)
    return unless dynamic?

    @velocity = Bevy::Vec3.new(
      @velocity.x + (@acceleration.x + gravity.x) * dt,
      @velocity.y + (@acceleration.y + gravity.y) * dt,
      @velocity.z + (@acceleration.z + gravity.z) * dt
    )

    @position = Bevy::Vec3.new(
      @position.x + @velocity.x * dt,
      @position.y + @velocity.y * dt,
      @position.z + @velocity.z * dt
    )

    @acceleration = Bevy::Vec3.new(0.0, 0.0, 0.0)
  end
end

gravity = Bevy::Vec3.new(0.0, -500.0, 0.0)
objects = []
object_entities = {}
ground_y = -250.0
restitution = 0.7

spawn_timer = 0.0
spawn_interval = 1.5

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Physics System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, ground_y - 25.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 800.0, height: 50.0, color: Bevy::Color.from_hex('#2d4a3e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-375.0, ground_y + 75.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 50.0, height: 200.0, color: Bevy::Color.from_hex('#3d5a4e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(375.0, ground_y + 75.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 50.0, height: 200.0, color: Bevy::Color.from_hex('#3d5a4e'))
  )

  [-100.0, 100.0].each do |x|
    ctx.spawn(
      Bevy::Transform.from_xyz(x, ground_y + 50.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 100.0, height: 30.0, color: Bevy::Color.from_hex('#4a6a5e'))
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[SPACE] Spawn ball  [R] Reset  [G] Toggle gravity', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -320.0, 0.0),
    Bevy::Text2d.new('Balls bounce with restitution 0.7 | Press ESC to exit', font_size: 14.0, color: Bevy::Color.from_hex('#666666'))
  )

  colors = ['#E74C3C', '#3498DB', '#2ECC71', '#F39C12', '#9B59B6']
  3.times do |i|
    x = -150.0 + i * 150.0
    color = Bevy::Color.from_hex(colors[i % colors.size])
    obj = PhysicsObject.new(
      position: Bevy::Vec3.new(x, 200.0, 0.0),
      velocity: Bevy::Vec3.new(rand(-50.0..50.0), 0.0, 0.0),
      mass: 1.0 + i * 0.5,
      radius: 20.0 + i * 5.0,
      color: color
    )
    objects << obj
  end
end

app.add_update_system do |ctx|
  delta = ctx.delta
  spawn_timer += delta

  if ctx.key_just_pressed?('SPACE') || spawn_timer >= spawn_interval
    spawn_timer = 0.0
    colors = ['#E74C3C', '#3498DB', '#2ECC71', '#F39C12', '#9B59B6', '#1ABC9C', '#E91E63']
    color = Bevy::Color.from_hex(colors.sample)
    obj = PhysicsObject.new(
      position: Bevy::Vec3.new(rand(-200.0..200.0), 250.0, 0.0),
      velocity: Bevy::Vec3.new(rand(-100.0..100.0), rand(-50.0..50.0), 0.0),
      mass: rand(0.5..2.0),
      radius: rand(15.0..35.0),
      color: color
    )
    objects << obj
  end

  if ctx.key_just_pressed?('R')
    objects.clear
    object_entities.each { |_, e| ctx.world.despawn(e) if e }
    object_entities.clear
  end

  objects.each do |obj|
    obj.update(delta, gravity)

    if obj.position.y - obj.radius < ground_y
      obj.position = Bevy::Vec3.new(obj.position.x, ground_y + obj.radius, obj.position.z)
      obj.velocity = Bevy::Vec3.new(obj.velocity.x * 0.98, -obj.velocity.y * restitution, obj.velocity.z)
      obj.grounded = obj.velocity.y.abs < 10.0
    end

    if obj.position.x - obj.radius < -350.0
      obj.position = Bevy::Vec3.new(-350.0 + obj.radius, obj.position.y, obj.position.z)
      obj.velocity = Bevy::Vec3.new(-obj.velocity.x * restitution, obj.velocity.y, obj.velocity.z)
    elsif obj.position.x + obj.radius > 350.0
      obj.position = Bevy::Vec3.new(350.0 - obj.radius, obj.position.y, obj.position.z)
      obj.velocity = Bevy::Vec3.new(-obj.velocity.x * restitution, obj.velocity.y, obj.velocity.z)
    end
  end

  objects.reject! { |obj| obj.position.y < -400.0 }

  object_entities.each { |_, e| ctx.world.despawn(e) if e }
  object_entities.clear

  objects.each_with_index do |obj, i|
    entity = ctx.spawn(
      Bevy::Transform.from_xyz(obj.position.x, obj.position.y, 1.0),
      Bevy::Mesh::Circle.new(radius: obj.radius, color: obj.color)
    )
    object_entities[i] = entity
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Physics System Demo'
puts ''
puts 'Features:'
puts '  - Dynamic rigid bodies with gravity'
puts '  - Collision detection with ground and walls'
puts '  - Bounce physics with restitution'
puts ''
puts 'Controls:'
puts '  [SPACE] Spawn new ball'
puts '  [R] Reset all balls'
puts '  [ESC] Exit'

app.run
