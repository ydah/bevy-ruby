# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Hierarchy System Demo',
    width: 900.0,
    height: 700.0
  }
)

class HierarchyNode
  attr_accessor :local_transform, :global_transform, :parent, :children, :color, :size, :name

  def initialize(name:, local_position:, color:, size: 30.0, parent: nil)
    @name = name
    @local_transform = Bevy::Transform.from_xyz(local_position.x, local_position.y, 0.0)
    @global_transform = Bevy::GlobalTransform.from_transform(@local_transform)
    @parent = parent
    @children = []
    @color = color
    @size = size
    parent&.children&.push(self)
  end

  def propagate_transform
    if @parent
      parent_global = @parent.global_transform
      local_pos = @local_transform.translation
      @global_transform = Bevy::GlobalTransform.new(
        translation: Bevy::Vec3.new(
          parent_global.translation.x + local_pos.x,
          parent_global.translation.y + local_pos.y,
          parent_global.translation.z + local_pos.z
        )
      )
    else
      @global_transform = Bevy::GlobalTransform.from_transform(@local_transform)
    end

    @children.each(&:propagate_transform)
  end

  def world_position
    @global_transform.translation
  end
end

root = HierarchyNode.new(
  name: 'Root',
  local_position: Bevy::Vec3.new(0.0, 50.0, 0.0),
  color: Bevy::Color.from_hex('#E74C3C'),
  size: 50.0
)

child1 = HierarchyNode.new(
  name: 'Child 1',
  local_position: Bevy::Vec3.new(-120.0, -80.0, 0.0),
  color: Bevy::Color.from_hex('#3498DB'),
  size: 40.0,
  parent: root
)

child2 = HierarchyNode.new(
  name: 'Child 2',
  local_position: Bevy::Vec3.new(120.0, -80.0, 0.0),
  color: Bevy::Color.from_hex('#2ECC71'),
  size: 40.0,
  parent: root
)

grandchild1 = HierarchyNode.new(
  name: 'Grandchild 1',
  local_position: Bevy::Vec3.new(-50.0, -60.0, 0.0),
  color: Bevy::Color.from_hex('#9B59B6'),
  size: 25.0,
  parent: child1
)

grandchild2 = HierarchyNode.new(
  name: 'Grandchild 2',
  local_position: Bevy::Vec3.new(50.0, -60.0, 0.0),
  color: Bevy::Color.from_hex('#F39C12'),
  size: 25.0,
  parent: child1
)

grandchild3 = HierarchyNode.new(
  name: 'Grandchild 3',
  local_position: Bevy::Vec3.new(0.0, -60.0, 0.0),
  color: Bevy::Color.from_hex('#1ABC9C'),
  size: 25.0,
  parent: child2
)

all_nodes = [root, child1, child2, grandchild1, grandchild2, grandchild3]
node_entities = {}
line_entities = []
time_elapsed = 0.0

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Hierarchy System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[Arrow Keys] Move Root  [R] Reset  [SPACE] Animate', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Children inherit parent transforms | Press ESC to exit', font_size: 14.0, color: Bevy::Color.from_hex('#666666'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 280.0, 0.0),
    Bevy::Text2d.new('Legend:', font_size: 14.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 255.0, 0.0),
    Bevy::Text2d.new('Root (Red)', font_size: 12.0, color: Bevy::Color.from_hex('#E74C3C'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 235.0, 0.0),
    Bevy::Text2d.new('Children (Blue/Green)', font_size: 12.0, color: Bevy::Color.from_hex('#3498DB'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(-380.0, 215.0, 0.0),
    Bevy::Text2d.new('Grandchildren (Others)', font_size: 12.0, color: Bevy::Color.from_hex('#9B59B6'))
  )
end

animating = false

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta

  move_speed = 150.0 * delta
  root_pos = root.local_transform.translation

  if ctx.key_pressed?('LEFT')
    root.local_transform = Bevy::Transform.from_xyz(root_pos.x - move_speed, root_pos.y, root_pos.z)
  elsif ctx.key_pressed?('RIGHT')
    root.local_transform = Bevy::Transform.from_xyz(root_pos.x + move_speed, root_pos.y, root_pos.z)
  end
  if ctx.key_pressed?('UP')
    root.local_transform = Bevy::Transform.from_xyz(root_pos.x, root_pos.y + move_speed, root_pos.z)
  elsif ctx.key_pressed?('DOWN')
    root.local_transform = Bevy::Transform.from_xyz(root_pos.x, root_pos.y - move_speed, root_pos.z)
  end

  if ctx.key_just_pressed?('R')
    root.local_transform = Bevy::Transform.from_xyz(0.0, 50.0, 0.0)
    animating = false
  end

  if ctx.key_just_pressed?('SPACE')
    animating = !animating
  end

  if animating
    orbit_radius = 50.0
    orbit_speed = 2.0
    angle = time_elapsed * orbit_speed

    root.local_transform = Bevy::Transform.from_xyz(
      Math.cos(angle) * orbit_radius,
      50.0 + Math.sin(angle * 0.5) * 30.0,
      0.0
    )
  end

  root.propagate_transform

  node_entities.each { |_, e| ctx.world.despawn(e) if e }
  node_entities.clear
  line_entities.each { |e| ctx.world.despawn(e) if e }
  line_entities.clear

  all_nodes.each do |node|
    if node.parent
      parent_pos = node.parent.world_position
      child_pos = node.world_position

      mid_x = (parent_pos.x + child_pos.x) / 2.0
      mid_y = (parent_pos.y + child_pos.y) / 2.0
      dx = child_pos.x - parent_pos.x
      dy = child_pos.y - parent_pos.y
      length = Math.sqrt(dx * dx + dy * dy)

      line_entity = ctx.spawn(
        Bevy::Transform.from_xyz(mid_x, mid_y, 0.0),
        Bevy::Mesh::Rectangle.new(width: [length, 4.0].max, height: 3.0, color: Bevy::Color.from_hex('#555555'))
      )
      line_entities << line_entity
    end
  end

  all_nodes.each_with_index do |node, i|
    pos = node.world_position
    entity = ctx.spawn(
      Bevy::Transform.from_xyz(pos.x, pos.y, 1.0),
      Bevy::Mesh::Circle.new(radius: node.size, color: node.color)
    )
    node_entities[i] = entity

    label_entity = ctx.spawn(
      Bevy::Transform.from_xyz(pos.x, pos.y - node.size - 15.0, 2.0),
      Bevy::Text2d.new(node.name, font_size: 11.0, color: Bevy::Color.white)
    )
    node_entities["label_#{i}"] = label_entity
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Hierarchy System Demo'
puts ''
puts 'Demonstrates parent-child transform relationships:'
puts '  - Root node (red) controls the entire hierarchy'
puts '  - Children inherit parent transforms'
puts '  - Moving the root moves all descendants'
puts ''
puts 'Controls:'
puts '  [Arrow Keys] Move root node'
puts '  [SPACE] Toggle orbit animation'
puts '  [R] Reset position'
puts '  [ESC] Exit'

app.run
