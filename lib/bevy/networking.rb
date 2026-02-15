# frozen_string_literal: true

module Bevy
  class NetworkResource
    attr_accessor :connected, :client_id

    def initialize
      @connected = false
      @client_id = nil
      @message_queue = []
    end

    def connect(address)
      @connected = true
      @client_id = generate_client_id
    end

    def disconnect
      @connected = false
      @client_id = nil
    end

    def send_message(message)
      return false unless @connected

      @message_queue << { type: :outgoing, message: message, timestamp: ::Time.now }
      true
    end

    def receive_messages
      @message_queue.select { |m| m[:type] == :incoming }.map { |m| m[:message] }
    end

    def clear_messages
      @message_queue = []
    end

    def type_name
      'NetworkResource'
    end

    private

    def generate_client_id
      rand(1_000_000..9_999_999)
    end
  end

  class NetworkMessage
    attr_reader :id, :sender, :payload, :timestamp
    attr_accessor :reliable, :channel

    def initialize(payload:, sender: nil, reliable: true, channel: 0)
      @id = generate_id
      @sender = sender
      @payload = payload
      @reliable = reliable
      @channel = channel
      @timestamp = ::Time.now
    end

    def type_name
      'NetworkMessage'
    end

    private

    def generate_id
      rand(1_000_000_000)
    end
  end

  class NetworkServer
    attr_reader :clients, :port
    attr_accessor :running

    def initialize(port: 7777)
      @port = port
      @running = false
      @clients = {}
      @message_handlers = {}
    end

    def start
      @running = true
    end

    def stop
      @running = false
      @clients = {}
    end

    def broadcast(message)
      return unless @running

      @clients.each_value do |client|
        client.send(message)
      end
    end

    def send_to(client_id, message)
      return unless @running

      client = @clients[client_id]
      client&.send(message)
    end

    def on_message(message_type, &handler)
      @message_handlers[message_type] = handler
    end

    def client_count
      @clients.size
    end

    def type_name
      'NetworkServer'
    end
  end

  class NetworkClient
    attr_reader :server_address, :client_id
    attr_accessor :connected

    def initialize
      @connected = false
      @server_address = nil
      @client_id = nil
      @message_queue = []
    end

    def connect(address)
      @server_address = address
      @connected = true
      @client_id = rand(1_000_000)
    end

    def disconnect
      @connected = false
      @server_address = nil
    end

    def send_message(message)
      return false unless @connected

      @message_queue << { direction: :out, message: message }
      true
    end

    def poll_messages
      incoming = @message_queue.select { |m| m[:direction] == :in }
      incoming.map { |m| m[:message] }
    end

    def type_name
      'NetworkClient'
    end
  end

  class Replication
    attr_reader :replicated_components

    def initialize
      @replicated_components = {}
    end

    def register(component_type, options = {})
      @replicated_components[component_type] = {
        priority: options[:priority] || 0,
        interpolate: options[:interpolate] || false,
        owner_only: options[:owner_only] || false
      }
      self
    end

    def is_replicated?(component_type)
      @replicated_components.key?(component_type)
    end

    def type_name
      'Replication'
    end
  end

  class NetworkedEntity
    attr_accessor :network_id, :owner_id, :authority

    AUTHORITY_SERVER = :server
    AUTHORITY_CLIENT = :client

    def initialize(network_id: nil, owner_id: nil, authority: AUTHORITY_SERVER)
      @network_id = network_id || rand(1_000_000_000)
      @owner_id = owner_id
      @authority = authority
    end

    def server_authority?
      @authority == AUTHORITY_SERVER
    end

    def client_authority?
      @authority == AUTHORITY_CLIENT
    end

    def owned_by?(client_id)
      @owner_id == client_id
    end

    def type_name
      'NetworkedEntity'
    end
  end

  class NetworkTransform
    attr_accessor :position, :rotation, :velocity
    attr_accessor :interpolation_speed, :sync_rate

    def initialize(sync_rate: 20.0, interpolation_speed: 10.0)
      @position = Vec3.zero
      @rotation = Quat.identity
      @velocity = Vec3.zero
      @sync_rate = sync_rate.to_f
      @interpolation_speed = interpolation_speed.to_f
      @target_position = nil
      @target_rotation = nil
    end

    def set_target(position:, rotation: nil)
      @target_position = position
      @target_rotation = rotation
    end

    def interpolate(delta)
      return unless @target_position

      t = [@interpolation_speed * delta, 1.0].min
      @position = Vec3.new(
        @position.x + (@target_position.x - @position.x) * t,
        @position.y + (@target_position.y - @position.y) * t,
        @position.z + (@target_position.z - @position.z) * t
      )
    end

    def type_name
      'NetworkTransform'
    end
  end

  class Rpc
    attr_reader :name, :target, :reliable

    TARGET_SERVER = :server
    TARGET_CLIENT = :client
    TARGET_ALL = :all

    def initialize(name:, target: TARGET_SERVER, reliable: true)
      @name = name
      @target = target
      @reliable = reliable
    end

    def server_rpc?
      @target == TARGET_SERVER
    end

    def client_rpc?
      @target == TARGET_CLIENT
    end

    def type_name
      'Rpc'
    end
  end

  class NetworkEvent
    attr_reader :event_type, :data, :timestamp

    CONNECTED = :connected
    DISCONNECTED = :disconnected
    MESSAGE_RECEIVED = :message_received
    CLIENT_CONNECTED = :client_connected
    CLIENT_DISCONNECTED = :client_disconnected

    def initialize(event_type:, data: nil)
      @event_type = event_type
      @data = data
      @timestamp = ::Time.now
    end

    def type_name
      'NetworkEvent'
    end
  end

  class Lobby
    attr_reader :id, :name, :players, :max_players, :host_id

    def initialize(name:, max_players: 8)
      @id = rand(1_000_000)
      @name = name
      @max_players = max_players
      @players = []
      @host_id = nil
    end

    def join(player_id)
      return false if full?

      @players << player_id
      @host_id ||= player_id
      true
    end

    def leave(player_id)
      @players.delete(player_id)
      @host_id = @players.first if player_id == @host_id
    end

    def full?
      @players.size >= @max_players
    end

    def player_count
      @players.size
    end

    def host?(player_id)
      @host_id == player_id
    end

    def type_name
      'Lobby'
    end
  end
end
