# frozen_string_literal: true

RSpec.describe Bevy::Changed do
  describe '.new' do
    it 'creates filter with component type' do
      changed = described_class.new(Bevy::Transform)
      expect(changed.component_type).to eq(Bevy::Transform)
    end
  end

  describe '#type_name' do
    it 'returns Changed' do
      expect(described_class.new(Bevy::Transform).type_name).to eq('Changed')
    end
  end
end

RSpec.describe Bevy::Added do
  describe '.new' do
    it 'creates filter with component type' do
      added = described_class.new(Bevy::Transform)
      expect(added.component_type).to eq(Bevy::Transform)
    end
  end

  describe '#type_name' do
    it 'returns Added' do
      expect(described_class.new(Bevy::Transform).type_name).to eq('Added')
    end
  end
end

RSpec.describe Bevy::With do
  describe '.new' do
    it 'creates filter with single component type' do
      with = described_class.new(Bevy::Transform)
      expect(with.component_types).to eq([Bevy::Transform])
    end

    it 'creates filter with multiple component types' do
      with = described_class.new(Bevy::Transform, Bevy::Sprite)
      expect(with.component_types).to eq([Bevy::Transform, Bevy::Sprite])
    end
  end

  describe '#type_name' do
    it 'returns With' do
      expect(described_class.new(Bevy::Transform).type_name).to eq('With')
    end
  end
end

RSpec.describe Bevy::Without do
  describe '.new' do
    it 'creates filter with single component type' do
      without = described_class.new(Bevy::Transform)
      expect(without.component_types).to eq([Bevy::Transform])
    end

    it 'creates filter with multiple component types' do
      without = described_class.new(Bevy::Transform, Bevy::Sprite)
      expect(without.component_types).to eq([Bevy::Transform, Bevy::Sprite])
    end
  end

  describe '#type_name' do
    it 'returns Without' do
      expect(described_class.new(Bevy::Transform).type_name).to eq('Without')
    end
  end
end

RSpec.describe Bevy::Or do
  describe '.new' do
    it 'creates filter with multiple conditions' do
      changed = Bevy::Changed.new(Bevy::Transform)
      added = Bevy::Added.new(Bevy::Transform)
      or_filter = described_class.new(changed, added)
      expect(or_filter.filters).to eq([changed, added])
    end
  end

  describe '#type_name' do
    it 'returns Or' do
      expect(described_class.new.type_name).to eq('Or')
    end
  end
end

RSpec.describe Bevy::ChangeTrackers do
  describe '.new' do
    it 'creates tracker for entity and component' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      expect(tracker.entity).to eq(1)
      expect(tracker.component_type).to eq(Bevy::Transform)
    end
  end

  describe '#is_added?' do
    it 'returns true when component was added this tick' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      tracker.set_added(5)
      expect(tracker.is_added?(5)).to be true
    end

    it 'returns false when component was not added' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      expect(tracker.is_added?(5)).to be false
    end
  end

  describe '#is_changed?' do
    it 'returns true when component was changed this tick' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      tracker.set_changed(5)
      expect(tracker.is_changed?(5)).to be true
    end

    it 'returns false when component was not changed' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      expect(tracker.is_changed?(5)).to be false
    end
  end

  describe '#update_last_run' do
    it 'updates last run tick' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      tracker.set_added(3)
      tracker.update_last_run(5)
      expect(tracker.is_added?(6)).to be false
    end
  end

  describe '#type_name' do
    it 'returns ChangeTrackers' do
      tracker = described_class.new(entity: 1, component_type: Bevy::Transform)
      expect(tracker.type_name).to eq('ChangeTrackers')
    end
  end
end

RSpec.describe Bevy::ComponentTracker do
  describe '.new' do
    it 'creates tracker with zero tick' do
      tracker = described_class.new
      expect(tracker.current_tick).to eq(0)
    end
  end

  describe '#tick' do
    it 'increments current tick' do
      tracker = described_class.new
      tracker.tick
      tracker.tick
      expect(tracker.current_tick).to eq(2)
    end
  end

  describe '#track_add' do
    it 'tracks when component is added' do
      tracker = described_class.new
      tracker.tick
      tracker.track_add(1, Bevy::Transform)
      expect(tracker.added?(1, Bevy::Transform)).to be true
    end
  end

  describe '#track_change' do
    it 'tracks when component is changed' do
      tracker = described_class.new
      tracker.tick
      tracker.track_change(1, Bevy::Transform)
      expect(tracker.changed?(1, Bevy::Transform)).to be true
    end
  end

  describe '#added?' do
    it 'returns false for untracked entity' do
      tracker = described_class.new
      expect(tracker.added?(999, Bevy::Transform)).to be false
    end
  end

  describe '#changed?' do
    it 'returns false for untracked entity' do
      tracker = described_class.new
      expect(tracker.changed?(999, Bevy::Transform)).to be false
    end
  end

  describe '#type_name' do
    it 'returns ComponentTracker' do
      expect(described_class.new.type_name).to eq('ComponentTracker')
    end
  end
end

RSpec.describe Bevy::SystemSet do
  describe '.new' do
    it 'creates named system set' do
      set = described_class.new(:movement)
      expect(set.name).to eq(:movement)
      expect(set.systems).to be_empty
    end
  end

  describe '#add_system' do
    it 'adds system to set' do
      set = described_class.new(:movement)
      system = -> {}
      set.add_system(system)
      expect(set.systems).to include(system)
    end

    it 'returns self for chaining' do
      set = described_class.new(:movement)
      result = set.add_system(-> {})
      expect(result).to eq(set)
    end
  end

  describe '#run_if' do
    it 'sets run condition' do
      set = described_class.new(:movement)
      set.run_if { |_ctx| true }
      expect(set.should_run?(nil)).to be true
    end

    it 'returns self for chaining' do
      set = described_class.new(:movement)
      result = set.run_if { true }
      expect(result).to eq(set)
    end
  end

  describe '#should_run?' do
    it 'returns true when no condition set' do
      set = described_class.new(:movement)
      expect(set.should_run?(nil)).to be true
    end

    it 'evaluates run condition' do
      set = described_class.new(:movement)
      set.run_if { |ctx| ctx == :run }
      expect(set.should_run?(:run)).to be true
      expect(set.should_run?(:stop)).to be false
    end
  end

  describe '#type_name' do
    it 'returns SystemSet' do
      expect(described_class.new(:test).type_name).to eq('SystemSet')
    end
  end
end

RSpec.describe Bevy::RunCondition do
  describe '.resource_exists' do
    it 'returns condition that checks resource existence' do
      condition = described_class.resource_exists(:timer)
      ctx = double('Context', has_resource?: true)
      expect(condition.call(ctx)).to be true
    end
  end

  describe '.resource_equals' do
    it 'returns condition that checks resource value' do
      condition = described_class.resource_equals(:score, 100)
      ctx = double('Context', get_resource: 100)
      expect(condition.call(ctx)).to be true
    end
  end

  describe '.state_equals' do
    it 'returns condition that checks state value' do
      condition = described_class.state_equals(:game_state, :playing)
      ctx = double('Context', get_state: :playing)
      expect(condition.call(ctx)).to be true
    end
  end

  describe '.in_state' do
    it 'returns condition that checks current state' do
      condition = described_class.in_state(:playing)
      ctx = double('Context', current_state: :playing)
      expect(condition.call(ctx)).to be true
    end
  end

  describe '.run_once' do
    it 'returns condition that runs only once' do
      condition = described_class.run_once
      expect(condition.call(nil)).to be true
      expect(condition.call(nil)).to be false
      expect(condition.call(nil)).to be false
    end
  end

  describe '.not' do
    it 'negates a condition' do
      inner = ->(_) { true }
      condition = described_class.not(inner)
      expect(condition.call(nil)).to be false
    end
  end

  describe '.and' do
    it 'combines conditions with AND logic' do
      cond1 = ->(_) { true }
      cond2 = ->(_) { false }
      condition = described_class.and(cond1, cond2)
      expect(condition.call(nil)).to be false
    end
  end

  describe '.or' do
    it 'combines conditions with OR logic' do
      cond1 = ->(_) { true }
      cond2 = ->(_) { false }
      condition = described_class.or(cond1, cond2)
      expect(condition.call(nil)).to be true
    end
  end
end

RSpec.describe Bevy::Commands do
  let(:world) { Bevy::World.new }

  describe '.new' do
    it 'creates commands for world' do
      commands = described_class.new(world)
      expect(commands).to be_a(described_class)
    end
  end

  describe '#spawn' do
    it 'spawns entity and returns EntityCommands' do
      commands = described_class.new(world)
      entity_commands = commands.spawn(Bevy::Transform.new)
      expect(entity_commands).to be_a(Bevy::EntityCommands)
    end
  end

  describe '#entity' do
    it 'returns EntityCommands for existing entity' do
      entity = world.spawn_entity(Bevy::Transform.new)
      commands = described_class.new(world)
      entity_commands = commands.entity(entity)
      expect(entity_commands).to be_a(Bevy::EntityCommands)
    end
  end

  describe '#despawn' do
    it 'queues entity for despawn' do
      entity = world.spawn_entity(Bevy::Transform.new)
      commands = described_class.new(world)
      result = commands.despawn(entity)
      expect(result).to eq(commands)
    end
  end

  describe '#insert_resource' do
    it 'queues resource insertion' do
      commands = described_class.new(world)
      result = commands.insert_resource(Bevy::Time.new)
      expect(result).to eq(commands)
    end
  end

  describe '#apply' do
    it 'applies queued despawn commands' do
      world2 = Bevy::World.new
      entity2 = world2.spawn_entity(Bevy::Transform.new)
      commands = described_class.new(world2)
      commands.despawn(entity2)
      commands.apply
      expect(world2.despawned_entity_ids).to include(entity2.id)
    end
  end

  describe '#type_name' do
    it 'returns Commands' do
      expect(described_class.new(world).type_name).to eq('Commands')
    end
  end
end

RSpec.describe Bevy::EntityCommands do
  let(:world) { Bevy::World.new }
  let(:entity) { world.spawn_entity(Bevy::Transform.new) }

  describe '.new' do
    it 'creates entity commands' do
      entity_commands = described_class.new(entity, world)
      expect(entity_commands.id).to eq(entity)
    end
  end

  describe '#insert' do
    it 'inserts components into entity' do
      entity_commands = described_class.new(entity, world)
      entity_commands.insert(Bevy::Sprite.new)
      expect(world.get_component(entity, Bevy::Sprite)).not_to be_nil
    end

    it 'returns self for chaining' do
      entity_commands = described_class.new(entity, world)
      result = entity_commands.insert(Bevy::Sprite.new)
      expect(result).to eq(entity_commands)
    end
  end

  describe '#remove' do
    it 'removes hierarchy component from entity' do
      world2 = Bevy::World.new
      parent = Bevy::Parent.new(entity_id: 999)
      entity2 = world2.spawn_entity(Bevy::Transform.new, parent)
      entity_commands = described_class.new(entity2, world2)
      entity_commands.remove(Bevy::Parent)
      expect { world2.get_component(entity2, Bevy::Parent) }.to raise_error(Bevy::ComponentNotFoundError)
    end

    it 'returns self for chaining' do
      world2 = Bevy::World.new
      parent = Bevy::Parent.new(entity_id: 999)
      entity2 = world2.spawn_entity(Bevy::Transform.new, parent)
      entity_commands = described_class.new(entity2, world2)
      result = entity_commands.remove(Bevy::Parent)
      expect(result).to eq(entity_commands)
    end
  end

  describe '#despawn' do
    it 'despawns the entity' do
      world2 = Bevy::World.new
      entity2 = world2.spawn_entity(Bevy::Transform.new)
      entity_commands = described_class.new(entity2, world2)
      entity_commands.despawn
      expect(world2.despawned_entity_ids).to include(entity2.id)
    end
  end

  describe '#id' do
    it 'returns entity id' do
      entity_commands = described_class.new(entity, world)
      expect(entity_commands.id).to eq(entity)
    end
  end

  describe '#type_name' do
    it 'returns EntityCommands' do
      entity_commands = described_class.new(entity, world)
      expect(entity_commands.type_name).to eq('EntityCommands')
    end
  end
end
