# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'ECS Advanced Features Demo',
    width: 900.0,
    height: 700.0
  }
)

class EcsEntity
  attr_accessor :position, :velocity, :color, :size, :tag, :health, :changed_this_frame

  def initialize(position:, velocity: nil, color:, size: 20.0, tag: :none, health: 100)
    @position = position
    @velocity = velocity || Bevy::Vec3.new(0.0, 0.0, 0.0)
    @color = color
    @size = size
    @tag = tag
    @health = health
    @changed_this_frame = false
  end

  def player?
    @tag == :player
  end

  def enemy?
    @tag == :enemy
  end

  def update(delta, bounds)
    @position = Bevy::Vec3.new(
      @position.x + @velocity.x * delta,
      @position.y + @velocity.y * delta,
      @position.z
    )

    if @position.x < bounds[:min_x] || @position.x > bounds[:max_x]
      @velocity = Bevy::Vec3.new(-@velocity.x, @velocity.y, @velocity.z)
      @changed_this_frame = true
    end
    if @position.y < bounds[:min_y] || @position.y > bounds[:max_y]
      @velocity = Bevy::Vec3.new(@velocity.x, -@velocity.y, @velocity.z)
      @changed_this_frame = true
    end

    @position = Bevy::Vec3.new(
      [[@position.x, bounds[:min_x]].max, bounds[:max_x]].min,
      [[@position.y, bounds[:min_y]].max, bounds[:max_y]].min,
      @position.z
    )
  end
end

entities = []
entity_visuals = {}

player = EcsEntity.new(
  position: Bevy::Vec3.new(0.0, 0.0, 0.0),
  velocity: Bevy::Vec3.new(0.0, 0.0, 0.0),
  color: Bevy::Color.from_hex('#3498DB'),
  size: 30.0,
  tag: :player,
  health: 100
)
entities << player

5.times do |i|
  enemy = EcsEntity.new(
    position: Bevy::Vec3.new(rand(-300.0..300.0), rand(-200.0..200.0), 0.0),
    velocity: Bevy::Vec3.new(rand(-80.0..80.0), rand(-80.0..80.0), 0.0),
    color: Bevy::Color.from_hex('#E74C3C'),
    size: 20.0,
    tag: :enemy,
    health: 50
  )
  entities << enemy
end

3.times do |i|
  neutral = EcsEntity.new(
    position: Bevy::Vec3.new(rand(-300.0..300.0), rand(-200.0..200.0), 0.0),
    velocity: Bevy::Vec3.new(rand(-30.0..30.0), rand(-30.0..30.0), 0.0),
    color: Bevy::Color.from_hex('#2ECC71'),
    size: 15.0,
    tag: :neutral,
    health: 30
  )
  entities << neutral
end

current_filter = :all
filter_modes = [:all, :player_only, :enemies_only, :with_health_above_50, :changed_only]
filter_labels = {
  all: 'All Entities',
  player_only: 'Player Only (With<Player>)',
  enemies_only: 'Enemies Only (With<Enemy>)',
  with_health_above_50: 'Health > 50',
  changed_only: 'Changed This Frame'
}

bounds = { min_x: -380.0, max_x: 380.0, min_y: -220.0, max_y: 220.0 }
status_entity = nil
filter_entity = nil

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('ECS Advanced Features Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[1-5] Change Query Filter  [Arrow Keys] Move Player  [SPACE] Spawn Enemy', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -280.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 800.0, height: 3.0, color: Bevy::Color.from_hex('#333344'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 280.0, 0.0),
    Bevy::Text2d.new('Legend:', font_size: 12.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 260.0, 0.0),
    Bevy::Text2d.new('Blue = Player', font_size: 11.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 245.0, 0.0),
    Bevy::Text2d.new('Red = Enemy', font_size: 11.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 230.0, 0.0),
    Bevy::Text2d.new('Green = Neutral', font_size: 11.0, color: Bevy::Color.from_hex('#2ECC71'))
  )

  filter_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new("Filter: #{filter_labels[current_filter]}", font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -320.0, 0.0),
    Bevy::Text2d.new('Entities: 9 | Visible: 9', font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta

  entities.each { |e| e.changed_this_frame = false }

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    current_filter = :all
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    current_filter = :player_only
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    current_filter = :enemies_only
  elsif ctx.key_just_pressed?('KEY4') || ctx.key_just_pressed?('4')
    current_filter = :with_health_above_50
  elsif ctx.key_just_pressed?('KEY5') || ctx.key_just_pressed?('5')
    current_filter = :changed_only
  end

  move_speed = 200.0 * delta
  if ctx.key_pressed?('LEFT')
    player.velocity = Bevy::Vec3.new(-move_speed / delta, player.velocity.y, 0.0)
    player.changed_this_frame = true
  elsif ctx.key_pressed?('RIGHT')
    player.velocity = Bevy::Vec3.new(move_speed / delta, player.velocity.y, 0.0)
    player.changed_this_frame = true
  else
    player.velocity = Bevy::Vec3.new(player.velocity.x * 0.9, player.velocity.y, 0.0)
  end

  if ctx.key_pressed?('UP')
    player.velocity = Bevy::Vec3.new(player.velocity.x, move_speed / delta, 0.0)
    player.changed_this_frame = true
  elsif ctx.key_pressed?('DOWN')
    player.velocity = Bevy::Vec3.new(player.velocity.x, -move_speed / delta, 0.0)
    player.changed_this_frame = true
  else
    player.velocity = Bevy::Vec3.new(player.velocity.x, player.velocity.y * 0.9, 0.0)
  end

  if ctx.key_just_pressed?('SPACE')
    enemy = EcsEntity.new(
      position: Bevy::Vec3.new(rand(-300.0..300.0), rand(-200.0..200.0), 0.0),
      velocity: Bevy::Vec3.new(rand(-100.0..100.0), rand(-100.0..100.0), 0.0),
      color: Bevy::Color.from_hex('#E74C3C'),
      size: 20.0,
      tag: :enemy,
      health: 50
    )
    entities << enemy
  end

  entities.each { |e| e.update(delta, bounds) }

  visible_entities = case current_filter
                     when :all
                       entities
                     when :player_only
                       entities.select(&:player?)
                     when :enemies_only
                       entities.select(&:enemy?)
                     when :with_health_above_50
                       entities.select { |e| e.health > 50 }
                     when :changed_only
                       entities.select(&:changed_this_frame)
                     else
                       entities
                     end

  entity_visuals.each { |_, e| ctx.world.despawn(e) if e }
  entity_visuals.clear

  visible_entities.each_with_index do |entity, i|
    visual = ctx.spawn(
      Bevy::Transform.from_xyz(entity.position.x, entity.position.y, 1.0),
      Bevy::Mesh::Circle.new(radius: entity.size, color: entity.color)
    )
    entity_visuals[i] = visual
  end

  if filter_entity
    new_text = Bevy::Text2d.new("Filter: #{filter_labels[current_filter]}", font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(filter_entity, new_text)
  end

  if status_entity
    status_text = "Entities: #{entities.size} | Visible: #{visible_entities.size}"
    new_text = Bevy::Text2d.new(status_text, font_size: 14.0, color: Bevy::Color.from_hex('#AAAAAA'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'ECS Advanced Features Demo'
puts ''
puts 'Query Filters Demonstrated:'
puts '  [1] All - Show all entities'
puts '  [2] With<Player> - Show only player'
puts '  [3] With<Enemy> - Show only enemies'
puts '  [4] Health > 50 - Resource-based filter'
puts '  [5] Changed - Change detection filter'
puts ''
puts 'Controls:'
puts '  [Arrow Keys] Move player'
puts '  [SPACE] Spawn new enemy'
puts '  [ESC] Exit'

app.run
