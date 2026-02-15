# frozen_string_literal: true

RSpec.describe Bevy::Parent do
  describe '.new' do
    it 'creates with entity reference' do
      entity = double('entity')
      parent = described_class.new(entity)
      expect(parent.entity).to eq(entity)
    end
  end

  describe '#type_name' do
    it 'returns Parent' do
      expect(described_class.new(nil).type_name).to eq('Parent')
    end
  end
end

RSpec.describe Bevy::Children do
  describe '.new' do
    it 'creates with empty list by default' do
      children = described_class.new
      expect(children.entities).to be_empty
    end

    it 'creates with initial entities' do
      e1 = double('entity1')
      e2 = double('entity2')
      children = described_class.new([e1, e2])
      expect(children.count).to eq(2)
    end
  end

  describe '#add' do
    it 'adds entity to children' do
      children = described_class.new
      entity = double('entity')
      children.add(entity)
      expect(children.include?(entity)).to be true
    end

    it 'does not add duplicates' do
      entity = double('entity')
      children = described_class.new([entity])
      children.add(entity)
      expect(children.count).to eq(1)
    end

    it 'returns self for chaining' do
      children = described_class.new
      result = children.add(double('entity'))
      expect(result).to eq(children)
    end
  end

  describe '#remove' do
    it 'removes entity from children' do
      entity = double('entity')
      children = described_class.new([entity])
      children.remove(entity)
      expect(children.include?(entity)).to be false
    end
  end

  describe '#each' do
    it 'iterates over children' do
      e1 = double('entity1')
      e2 = double('entity2')
      children = described_class.new([e1, e2])
      collected = []
      children.each { |e| collected << e }
      expect(collected).to eq([e1, e2])
    end
  end

  describe '#type_name' do
    it 'returns Children' do
      expect(described_class.new.type_name).to eq('Children')
    end
  end
end

RSpec.describe Bevy::GlobalTransform do
  describe '.new' do
    it 'creates with default identity values' do
      gt = described_class.new
      expect(gt.translation.x).to eq(0.0)
      expect(gt.scale.x).to eq(1.0)
    end

    it 'creates with custom values' do
      gt = described_class.new(
        translation: Bevy::Vec3.new(10.0, 20.0, 30.0),
        scale: Bevy::Vec3.new(2.0, 2.0, 2.0)
      )
      expect(gt.translation.x).to eq(10.0)
      expect(gt.scale.x).to eq(2.0)
    end
  end

  describe '.identity' do
    it 'returns identity transform' do
      gt = described_class.identity
      expect(gt.translation.x).to eq(0.0)
      expect(gt.scale.x).to eq(1.0)
    end
  end

  describe '.from_transform' do
    it 'creates from local transform' do
      local = Bevy::Transform.new(translation: Bevy::Vec3.new(5.0, 10.0, 15.0))
      gt = described_class.from_transform(local)
      expect(gt.translation.x).to eq(5.0)
    end
  end

  describe '#transform_point' do
    it 'transforms point by translation' do
      gt = described_class.new(translation: Bevy::Vec3.new(10.0, 0.0, 0.0))
      result = gt.transform_point(Bevy::Vec3.new(5.0, 0.0, 0.0))
      expect(result.x).to eq(15.0)
    end

    it 'transforms point by scale' do
      gt = described_class.new(scale: Bevy::Vec3.new(2.0, 2.0, 2.0))
      result = gt.transform_point(Bevy::Vec3.new(5.0, 0.0, 0.0))
      expect(result.x).to eq(10.0)
    end
  end

  describe '#inverse_transform_point' do
    it 'reverses transformation' do
      gt = described_class.new(translation: Bevy::Vec3.new(10.0, 0.0, 0.0))
      result = gt.inverse_transform_point(Bevy::Vec3.new(15.0, 0.0, 0.0))
      expect(result.x).to eq(5.0)
    end
  end

  describe '#type_name' do
    it 'returns GlobalTransform' do
      expect(described_class.new.type_name).to eq('GlobalTransform')
    end
  end
end

RSpec.describe Bevy::TransformBundle do
  describe '.new' do
    it 'creates with default transform' do
      bundle = described_class.new
      expect(bundle.local).to be_a(Bevy::Transform)
      expect(bundle.global).to be_a(Bevy::GlobalTransform)
    end

    it 'creates with custom transform' do
      transform = Bevy::Transform.new(translation: Bevy::Vec3.new(5.0, 0.0, 0.0))
      bundle = described_class.new(transform: transform)
      expect(bundle.local.translation.x).to eq(5.0)
      expect(bundle.global.translation.x).to eq(5.0)
    end
  end

  describe '#components' do
    it 'returns array of components' do
      bundle = described_class.new
      expect(bundle.components.size).to eq(2)
    end
  end

  describe '#type_name' do
    it 'returns TransformBundle' do
      expect(described_class.new.type_name).to eq('TransformBundle')
    end
  end
end

RSpec.describe Bevy::Visibility do
  describe '.new' do
    it 'creates with inherited by default' do
      vis = described_class.new
      expect(vis.inherited?).to be true
    end

    it 'creates with custom value' do
      vis = described_class.new(Bevy::Visibility::HIDDEN)
      expect(vis.hidden?).to be true
    end
  end

  describe '#visible?' do
    it 'returns true when visible' do
      vis = described_class.new(Bevy::Visibility::VISIBLE)
      expect(vis.visible?).to be true
    end
  end

  describe '#type_name' do
    it 'returns Visibility' do
      expect(described_class.new.type_name).to eq('Visibility')
    end
  end
end

RSpec.describe Bevy::InheritedVisibility do
  describe '.new' do
    it 'creates visible by default' do
      iv = described_class.new
      expect(iv.visible?).to be true
    end

    it 'creates with custom value' do
      iv = described_class.new(false)
      expect(iv.visible?).to be false
    end
  end

  describe '#type_name' do
    it 'returns InheritedVisibility' do
      expect(described_class.new.type_name).to eq('InheritedVisibility')
    end
  end
end

RSpec.describe Bevy::SpatialBundle do
  describe '.new' do
    it 'creates with default values' do
      bundle = described_class.new
      expect(bundle.transform).to be_a(Bevy::Transform)
      expect(bundle.global_transform).to be_a(Bevy::GlobalTransform)
      expect(bundle.visibility).to be_a(Bevy::Visibility)
    end
  end

  describe '#components' do
    it 'returns all components' do
      bundle = described_class.new
      expect(bundle.components.size).to eq(5)
    end
  end

  describe '#type_name' do
    it 'returns SpatialBundle' do
      expect(described_class.new.type_name).to eq('SpatialBundle')
    end
  end
end

RSpec.describe Bevy::TransformPropagation do
  describe '.propagate' do
    it 'propagates transforms through hierarchy' do
      world = Bevy::World.new

      parent_transform = Bevy::Transform.new(translation: Bevy::Vec3.new(10.0, 0.0, 0.0))
      parent = world.spawn_entity(parent_transform)

      child_transform = Bevy::Transform.new(translation: Bevy::Vec3.new(5.0, 0.0, 0.0))
      child = world.spawn_entity(child_transform, Bevy::Parent.new(parent))

      world.insert_component(parent, Bevy::Children.new([child]))

      described_class.propagate(world)

      parent_global = world.get_component(parent, Bevy::GlobalTransform)
      child_global = world.get_component(child, Bevy::GlobalTransform)

      expect(parent_global.translation.x).to eq(10.0)
      expect(child_global.translation.x).to eq(15.0)
    end

    it 'propagates scale through hierarchy' do
      world = Bevy::World.new

      parent_transform = Bevy::Transform.new(scale: Bevy::Vec3.new(2.0, 2.0, 2.0))
      parent = world.spawn_entity(parent_transform)

      child_transform = Bevy::Transform.new(
        translation: Bevy::Vec3.new(5.0, 0.0, 0.0),
        scale: Bevy::Vec3.new(2.0, 2.0, 2.0)
      )
      child = world.spawn_entity(child_transform, Bevy::Parent.new(parent))

      world.insert_component(parent, Bevy::Children.new([child]))

      described_class.propagate(world)

      child_global = world.get_component(child, Bevy::GlobalTransform)
      expect(child_global.translation.x).to eq(10.0)
      expect(child_global.scale.x).to eq(4.0)
    end
  end
end

RSpec.describe Bevy::DespawnRecursive do
  describe '.despawn' do
    it 'despawns entity and all descendants' do
      world = Bevy::World.new

      parent = world.spawn_entity(Bevy::Transform.identity)
      child = world.spawn_entity(Bevy::Transform.identity, Bevy::Parent.new(parent))
      grandchild = world.spawn_entity(Bevy::Transform.identity, Bevy::Parent.new(child))

      world.insert_component(parent, Bevy::Children.new([child]))
      world.insert_component(child, Bevy::Children.new([grandchild]))

      described_class.despawn(world, parent)

      expect(world.despawned_entity_ids).to include(parent.id)
      expect(world.despawned_entity_ids).to include(child.id)
      expect(world.despawned_entity_ids).to include(grandchild.id)
    end
  end
end

RSpec.describe Bevy::HierarchyEvent do
  describe '.new' do
    it 'creates child added event' do
      parent = double('parent')
      child = double('child')
      event = described_class.new(Bevy::HierarchyEvent::CHILD_ADDED, parent: parent, child: child)

      expect(event.child_added?).to be true
      expect(event.parent).to eq(parent)
      expect(event.child).to eq(child)
    end

    it 'creates child removed event' do
      event = described_class.new(Bevy::HierarchyEvent::CHILD_REMOVED, parent: nil, child: nil)
      expect(event.child_removed?).to be true
    end

    it 'creates child moved event' do
      event = described_class.new(Bevy::HierarchyEvent::CHILD_MOVED, parent: nil, child: nil)
      expect(event.child_moved?).to be true
    end
  end
end
