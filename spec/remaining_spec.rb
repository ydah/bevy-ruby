# frozen_string_literal: true

RSpec.describe Bevy::RenderGraph do
  describe '.new' do
    it 'creates empty graph' do
      graph = described_class.new
      expect(graph.node_count).to eq(0)
    end
  end

  describe '#add_node and #add_edge' do
    it 'adds nodes and edges' do
      graph = described_class.new
      graph.add_node('node1', Bevy::RenderGraphNode.new('node1'))
      graph.add_node('node2', Bevy::RenderGraphNode.new('node2'))
      graph.add_edge('node1', 'node2')
      expect(graph.node_count).to eq(2)
      expect(graph.edge_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns RenderGraph' do
      expect(described_class.new.type_name).to eq('RenderGraph')
    end
  end
end

RSpec.describe Bevy::Gizmos do
  describe '.new' do
    it 'creates enabled gizmos' do
      gizmos = described_class.new
      expect(gizmos.enabled).to be true
    end
  end

  describe '#line' do
    it 'adds line command' do
      gizmos = described_class.new
      gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.new(1.0, 0.0, 0.0))
      expect(gizmos.command_count).to eq(1)
    end
  end

  describe '#circle' do
    it 'adds circle command' do
      gizmos = described_class.new
      gizmos.circle(Bevy::Vec3.zero, 5.0)
      expect(gizmos.command_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns Gizmos' do
      expect(described_class.new.type_name).to eq('Gizmos')
    end
  end
end

RSpec.describe Bevy::Diagnostic do
  describe '.new' do
    it 'creates diagnostic' do
      d = described_class.new(id: 'fps', name: 'FPS')
      expect(d.name).to eq('FPS')
    end
  end

  describe '#add_measurement' do
    it 'adds and retrieves measurements' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(60.0)
      d.add_measurement(55.0)
      expect(d.value).to eq(55.0)
      expect(d.average).to be_within(0.1).of(57.5)
    end
  end

  describe '#type_name' do
    it 'returns Diagnostic' do
      expect(described_class.new(id: 'test', name: 'Test').type_name).to eq('Diagnostic')
    end
  end
end

RSpec.describe Bevy::Aabb do
  describe '.new' do
    it 'creates AABB' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.new(1.0, 1.0, 1.0))
      expect(aabb.center.x).to eq(0.0)
    end
  end

  describe '#contains_point?' do
    it 'checks point containment' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.new(1.0, 1.0, 1.0))
      expect(aabb.contains_point?(Bevy::Vec3.new(0.5, 0.5, 0.5))).to be true
      expect(aabb.contains_point?(Bevy::Vec3.new(2.0, 0.0, 0.0))).to be false
    end
  end

  describe '#type_name' do
    it 'returns Aabb' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.type_name).to eq('Aabb')
    end
  end
end

RSpec.describe Bevy::Skeleton do
  describe '.new' do
    it 'creates empty skeleton' do
      skeleton = described_class.new
      expect(skeleton.bone_count).to eq(0)
    end
  end

  describe '#add_bone' do
    it 'adds bones' do
      skeleton = described_class.new
      skeleton.add_bone(Bevy::Bone.new(name: 'root'))
      expect(skeleton.bone_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns Skeleton' do
      expect(described_class.new.type_name).to eq('Skeleton')
    end
  end
end

RSpec.describe Bevy::Reverb do
  describe '.new' do
    it 'creates with default values' do
      reverb = described_class.new
      expect(reverb.room_size).to eq(0.5)
      expect(reverb.enabled).to be true
    end
  end

  describe '#type_name' do
    it 'returns Reverb' do
      expect(described_class.new.type_name).to eq('Reverb')
    end
  end
end

RSpec.describe Bevy::Changed do
  describe '.new' do
    it 'creates filter' do
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

RSpec.describe Bevy::NavMesh do
  describe '.new' do
    it 'creates empty nav mesh' do
      mesh = described_class.new
      expect(mesh.polygon_count).to eq(0)
    end
  end

  describe '#add_vertex and #add_polygon' do
    it 'builds nav mesh' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      expect(mesh.polygon_count).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns NavMesh' do
      expect(described_class.new.type_name).to eq('NavMesh')
    end
  end
end

RSpec.describe Bevy::NavAgent do
  describe '.new' do
    it 'creates agent' do
      agent = described_class.new(speed: 5.0)
      expect(agent.speed).to eq(5.0)
    end
  end

  describe '#type_name' do
    it 'returns NavAgent' do
      expect(described_class.new.type_name).to eq('NavAgent')
    end
  end
end

RSpec.describe Bevy::NetworkClient do
  describe '.new' do
    it 'creates disconnected client' do
      client = described_class.new
      expect(client.connected).to be false
    end
  end

  describe '#connect and #disconnect' do
    it 'manages connection' do
      client = described_class.new
      client.connect('localhost:7777')
      expect(client.connected).to be true
      client.disconnect
      expect(client.connected).to be false
    end
  end

  describe '#type_name' do
    it 'returns NetworkClient' do
      expect(described_class.new.type_name).to eq('NetworkClient')
    end
  end
end

RSpec.describe Bevy::NetworkServer do
  describe '.new' do
    it 'creates stopped server' do
      server = described_class.new
      expect(server.running).to be false
    end
  end

  describe '#start and #stop' do
    it 'manages server state' do
      server = described_class.new
      server.start
      expect(server.running).to be true
      server.stop
      expect(server.running).to be false
    end
  end

  describe '#type_name' do
    it 'returns NetworkServer' do
      expect(described_class.new.type_name).to eq('NetworkServer')
    end
  end
end

RSpec.describe Bevy::Lobby do
  describe '.new' do
    it 'creates empty lobby' do
      lobby = described_class.new(name: 'Game Room')
      expect(lobby.name).to eq('Game Room')
      expect(lobby.player_count).to eq(0)
    end
  end

  describe '#join and #leave' do
    it 'manages players' do
      lobby = described_class.new(name: 'Test', max_players: 2)
      lobby.join(1)
      expect(lobby.player_count).to eq(1)
      expect(lobby.host?(1)).to be true
      lobby.join(2)
      expect(lobby.full?).to be true
      lobby.leave(1)
      expect(lobby.host?(2)).to be true
    end
  end

  describe '#type_name' do
    it 'returns Lobby' do
      expect(described_class.new(name: 'Test').type_name).to eq('Lobby')
    end
  end
end

RSpec.describe Bevy::RenderLayers do
  describe '.new' do
    it 'creates with default layer' do
      layers = described_class.new
      expect(layers.layers).to include(0)
    end
  end

  describe '#with and #without' do
    it 'adds and removes layers' do
      layers = described_class.new
      layers = layers.with(1).with(2)
      expect(layers.layers).to include(1)
      layers = layers.without(1)
      expect(layers.layers).not_to include(1)
    end
  end

  describe '#type_name' do
    it 'returns RenderLayers' do
      expect(described_class.new.type_name).to eq('RenderLayers')
    end
  end
end
