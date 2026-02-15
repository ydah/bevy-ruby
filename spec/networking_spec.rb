# frozen_string_literal: true

RSpec.describe Bevy::NetworkResource do
  describe '.new' do
    it 'creates disconnected resource' do
      resource = described_class.new
      expect(resource.connected).to be false
      expect(resource.client_id).to be_nil
    end
  end

  describe '#connect' do
    it 'connects and generates client id' do
      resource = described_class.new
      resource.connect('localhost:7777')
      expect(resource.connected).to be true
      expect(resource.client_id).to be_a(Integer)
    end
  end

  describe '#disconnect' do
    it 'disconnects and clears client id' do
      resource = described_class.new
      resource.connect('localhost:7777')
      resource.disconnect
      expect(resource.connected).to be false
      expect(resource.client_id).to be_nil
    end
  end

  describe '#send_message' do
    it 'returns true when connected' do
      resource = described_class.new
      resource.connect('localhost:7777')
      expect(resource.send_message('hello')).to be true
    end

    it 'returns false when disconnected' do
      resource = described_class.new
      expect(resource.send_message('hello')).to be false
    end
  end

  describe '#type_name' do
    it 'returns NetworkResource' do
      expect(described_class.new.type_name).to eq('NetworkResource')
    end
  end
end

RSpec.describe Bevy::NetworkMessage do
  describe '.new' do
    it 'creates message with payload' do
      msg = described_class.new(payload: { action: 'move' })
      expect(msg.payload).to eq({ action: 'move' })
      expect(msg.reliable).to be true
      expect(msg.channel).to eq(0)
    end

    it 'accepts custom options' do
      msg = described_class.new(payload: 'data', reliable: false, channel: 1)
      expect(msg.reliable).to be false
      expect(msg.channel).to eq(1)
    end
  end

  describe '#id' do
    it 'generates unique id' do
      msg = described_class.new(payload: 'test')
      expect(msg.id).to be_a(Integer)
    end
  end

  describe '#type_name' do
    it 'returns NetworkMessage' do
      expect(described_class.new(payload: 'test').type_name).to eq('NetworkMessage')
    end
  end
end

RSpec.describe Bevy::NetworkServer do
  describe '.new' do
    it 'creates stopped server' do
      server = described_class.new
      expect(server.running).to be false
      expect(server.port).to eq(7777)
    end

    it 'accepts custom port' do
      server = described_class.new(port: 8888)
      expect(server.port).to eq(8888)
    end
  end

  describe '#start' do
    it 'starts the server' do
      server = described_class.new
      server.start
      expect(server.running).to be true
    end
  end

  describe '#stop' do
    it 'stops the server and clears clients' do
      server = described_class.new
      server.start
      server.stop
      expect(server.running).to be false
      expect(server.clients).to be_empty
    end
  end

  describe '#client_count' do
    it 'returns number of clients' do
      server = described_class.new
      expect(server.client_count).to eq(0)
    end
  end

  describe '#type_name' do
    it 'returns NetworkServer' do
      expect(described_class.new.type_name).to eq('NetworkServer')
    end
  end
end

RSpec.describe Bevy::NetworkClient do
  describe '.new' do
    it 'creates disconnected client' do
      client = described_class.new
      expect(client.connected).to be false
      expect(client.server_address).to be_nil
    end
  end

  describe '#connect' do
    it 'connects to server' do
      client = described_class.new
      client.connect('localhost:7777')
      expect(client.connected).to be true
      expect(client.server_address).to eq('localhost:7777')
      expect(client.client_id).to be_a(Integer)
    end
  end

  describe '#disconnect' do
    it 'disconnects from server' do
      client = described_class.new
      client.connect('localhost:7777')
      client.disconnect
      expect(client.connected).to be false
      expect(client.server_address).to be_nil
    end
  end

  describe '#send_message' do
    it 'returns true when connected' do
      client = described_class.new
      client.connect('localhost:7777')
      expect(client.send_message('test')).to be true
    end

    it 'returns false when disconnected' do
      client = described_class.new
      expect(client.send_message('test')).to be false
    end
  end

  describe '#type_name' do
    it 'returns NetworkClient' do
      expect(described_class.new.type_name).to eq('NetworkClient')
    end
  end
end

RSpec.describe Bevy::Replication do
  describe '.new' do
    it 'creates with empty replicated components' do
      repl = described_class.new
      expect(repl.replicated_components).to be_empty
    end
  end

  describe '#register' do
    it 'registers component type for replication' do
      repl = described_class.new
      repl.register(Bevy::Transform, priority: 1, interpolate: true)
      expect(repl.is_replicated?(Bevy::Transform)).to be true
    end

    it 'returns self for chaining' do
      repl = described_class.new
      result = repl.register(Bevy::Transform)
      expect(result).to eq(repl)
    end
  end

  describe '#is_replicated?' do
    it 'returns false for unregistered type' do
      repl = described_class.new
      expect(repl.is_replicated?(Bevy::Sprite)).to be false
    end
  end

  describe '#type_name' do
    it 'returns Replication' do
      expect(described_class.new.type_name).to eq('Replication')
    end
  end
end

RSpec.describe Bevy::NetworkedEntity do
  describe '.new' do
    it 'creates with server authority by default' do
      entity = described_class.new
      expect(entity.authority).to eq(Bevy::NetworkedEntity::AUTHORITY_SERVER)
      expect(entity.network_id).to be_a(Integer)
    end

    it 'accepts custom values' do
      entity = described_class.new(
        network_id: 12345,
        owner_id: 1,
        authority: Bevy::NetworkedEntity::AUTHORITY_CLIENT
      )
      expect(entity.network_id).to eq(12345)
      expect(entity.owner_id).to eq(1)
      expect(entity.authority).to eq(Bevy::NetworkedEntity::AUTHORITY_CLIENT)
    end
  end

  describe '#server_authority?' do
    it 'returns true for server authority' do
      entity = described_class.new(authority: Bevy::NetworkedEntity::AUTHORITY_SERVER)
      expect(entity.server_authority?).to be true
    end
  end

  describe '#client_authority?' do
    it 'returns true for client authority' do
      entity = described_class.new(authority: Bevy::NetworkedEntity::AUTHORITY_CLIENT)
      expect(entity.client_authority?).to be true
    end
  end

  describe '#owned_by?' do
    it 'checks owner id' do
      entity = described_class.new(owner_id: 42)
      expect(entity.owned_by?(42)).to be true
      expect(entity.owned_by?(99)).to be false
    end
  end

  describe '#type_name' do
    it 'returns NetworkedEntity' do
      expect(described_class.new.type_name).to eq('NetworkedEntity')
    end
  end
end

RSpec.describe Bevy::NetworkTransform do
  describe '.new' do
    it 'creates with default values' do
      nt = described_class.new
      expect(nt.sync_rate).to eq(20.0)
      expect(nt.interpolation_speed).to eq(10.0)
      expect(nt.position).to be_a(Bevy::Vec3)
    end

    it 'accepts custom values' do
      nt = described_class.new(sync_rate: 30.0, interpolation_speed: 5.0)
      expect(nt.sync_rate).to eq(30.0)
      expect(nt.interpolation_speed).to eq(5.0)
    end
  end

  describe '#set_target' do
    it 'sets target position' do
      nt = described_class.new
      target = Bevy::Vec3.new(10.0, 10.0, 0.0)
      nt.set_target(position: target)
      expect(nt.instance_variable_get(:@target_position)).to eq(target)
    end
  end

  describe '#interpolate' do
    it 'moves position toward target' do
      nt = described_class.new
      nt.set_target(position: Bevy::Vec3.new(10.0, 0.0, 0.0))
      nt.interpolate(0.1)
      expect(nt.position.x).to be > 0
    end
  end

  describe '#type_name' do
    it 'returns NetworkTransform' do
      expect(described_class.new.type_name).to eq('NetworkTransform')
    end
  end
end

RSpec.describe Bevy::Rpc do
  describe '.new' do
    it 'creates server RPC by default' do
      rpc = described_class.new(name: 'move')
      expect(rpc.name).to eq('move')
      expect(rpc.target).to eq(Bevy::Rpc::TARGET_SERVER)
      expect(rpc.reliable).to be true
    end

    it 'accepts custom target' do
      rpc = described_class.new(name: 'update', target: Bevy::Rpc::TARGET_CLIENT)
      expect(rpc.target).to eq(Bevy::Rpc::TARGET_CLIENT)
    end
  end

  describe '#server_rpc?' do
    it 'returns true for server target' do
      rpc = described_class.new(name: 'test', target: Bevy::Rpc::TARGET_SERVER)
      expect(rpc.server_rpc?).to be true
    end
  end

  describe '#client_rpc?' do
    it 'returns true for client target' do
      rpc = described_class.new(name: 'test', target: Bevy::Rpc::TARGET_CLIENT)
      expect(rpc.client_rpc?).to be true
    end
  end

  describe '#type_name' do
    it 'returns Rpc' do
      expect(described_class.new(name: 'test').type_name).to eq('Rpc')
    end
  end
end

RSpec.describe Bevy::NetworkEvent do
  describe '.new' do
    it 'creates event with type' do
      event = described_class.new(event_type: Bevy::NetworkEvent::CONNECTED)
      expect(event.event_type).to eq(:connected)
      expect(event.timestamp).to be_a(Time)
    end

    it 'accepts data' do
      event = described_class.new(event_type: Bevy::NetworkEvent::MESSAGE_RECEIVED, data: { msg: 'hello' })
      expect(event.data).to eq({ msg: 'hello' })
    end
  end

  describe 'constants' do
    it 'defines event types' do
      expect(Bevy::NetworkEvent::CONNECTED).to eq(:connected)
      expect(Bevy::NetworkEvent::DISCONNECTED).to eq(:disconnected)
      expect(Bevy::NetworkEvent::MESSAGE_RECEIVED).to eq(:message_received)
      expect(Bevy::NetworkEvent::CLIENT_CONNECTED).to eq(:client_connected)
      expect(Bevy::NetworkEvent::CLIENT_DISCONNECTED).to eq(:client_disconnected)
    end
  end

  describe '#type_name' do
    it 'returns NetworkEvent' do
      event = described_class.new(event_type: :connected)
      expect(event.type_name).to eq('NetworkEvent')
    end
  end
end

RSpec.describe Bevy::Lobby do
  describe '.new' do
    it 'creates empty lobby' do
      lobby = described_class.new(name: 'Game Room')
      expect(lobby.name).to eq('Game Room')
      expect(lobby.max_players).to eq(8)
      expect(lobby.player_count).to eq(0)
    end

    it 'accepts custom max players' do
      lobby = described_class.new(name: 'Small Room', max_players: 4)
      expect(lobby.max_players).to eq(4)
    end
  end

  describe '#join' do
    it 'adds player to lobby' do
      lobby = described_class.new(name: 'Test')
      expect(lobby.join(1)).to be true
      expect(lobby.player_count).to eq(1)
    end

    it 'sets first player as host' do
      lobby = described_class.new(name: 'Test')
      lobby.join(1)
      expect(lobby.host?(1)).to be true
    end

    it 'returns false when full' do
      lobby = described_class.new(name: 'Test', max_players: 1)
      lobby.join(1)
      expect(lobby.join(2)).to be false
    end
  end

  describe '#leave' do
    it 'removes player from lobby' do
      lobby = described_class.new(name: 'Test')
      lobby.join(1)
      lobby.leave(1)
      expect(lobby.player_count).to eq(0)
    end

    it 'transfers host when host leaves' do
      lobby = described_class.new(name: 'Test')
      lobby.join(1)
      lobby.join(2)
      lobby.leave(1)
      expect(lobby.host?(2)).to be true
    end
  end

  describe '#full?' do
    it 'returns true when at capacity' do
      lobby = described_class.new(name: 'Test', max_players: 2)
      lobby.join(1)
      lobby.join(2)
      expect(lobby.full?).to be true
    end
  end

  describe '#type_name' do
    it 'returns Lobby' do
      expect(described_class.new(name: 'Test').type_name).to eq('Lobby')
    end
  end
end
