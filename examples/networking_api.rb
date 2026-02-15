# frozen_string_literal: true

require_relative '../lib/bevy'

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Networking System Demo',
    width: 900.0,
    height: 700.0
  }
)

class NetworkNode
  attr_accessor :position, :target_position, :color, :size, :name, :connected, :latency

  def initialize(position:, name:, color:, size: 30.0)
    @position = position
    @target_position = position
    @name = name
    @color = color
    @size = size
    @connected = false
    @latency = rand(10..100)
  end

  def update(delta, interpolation_speed: 5.0)
    dx = @target_position.x - @position.x
    dy = @target_position.y - @position.y

    @position = Bevy::Vec3.new(
      @position.x + dx * delta * interpolation_speed,
      @position.y + dy * delta * interpolation_speed,
      0.0
    )
  end
end

server = NetworkNode.new(
  position: Bevy::Vec3.new(0.0, 150.0, 0.0),
  name: 'Server',
  color: Bevy::Color.from_hex('#FFD700'),
  size: 50.0
)
server.connected = true

clients = [
  NetworkNode.new(position: Bevy::Vec3.new(-250.0, -50.0, 0.0), name: 'Client 1', color: Bevy::Color.from_hex('#3498DB')),
  NetworkNode.new(position: Bevy::Vec3.new(0.0, -100.0, 0.0), name: 'Client 2', color: Bevy::Color.from_hex('#2ECC71')),
  NetworkNode.new(position: Bevy::Vec3.new(250.0, -50.0, 0.0), name: 'Client 3', color: Bevy::Color.from_hex('#E74C3C'))
]

messages = []
entity_cache = {}
status_entity = nil
message_log = []
time_elapsed = 0.0
message_timer = 0.0

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -10.0),
    Bevy::Mesh::Rectangle.new(width: 1000.0, height: 800.0, color: Bevy::Color.from_hex('#1a1a2e'))
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 320.0, 0.0),
    Bevy::Text2d.new('Networking System Demo', font_size: 28.0, color: Bevy::Color.white)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 280.0, 0.0),
    Bevy::Text2d.new('[1-3] Toggle Client  [SPACE] Broadcast  [M] Send Message', font_size: 14.0, color: Bevy::Color.from_hex('#888888'))
  )

  status_entity = ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -300.0, 0.0),
    Bevy::Text2d.new('Connected Clients: 0 | Messages: 0', font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  time_elapsed += delta
  message_timer += delta

  if ctx.key_just_pressed?('KEY1') || ctx.key_just_pressed?('1')
    clients[0].connected = !clients[0].connected
    action = clients[0].connected ? 'connected' : 'disconnected'
    message_log << { text: "Client 1 #{action}", time: time_elapsed }
  elsif ctx.key_just_pressed?('KEY2') || ctx.key_just_pressed?('2')
    clients[1].connected = !clients[1].connected
    action = clients[1].connected ? 'connected' : 'disconnected'
    message_log << { text: "Client 2 #{action}", time: time_elapsed }
  elsif ctx.key_just_pressed?('KEY3') || ctx.key_just_pressed?('3')
    clients[2].connected = !clients[2].connected
    action = clients[2].connected ? 'connected' : 'disconnected'
    message_log << { text: "Client 3 #{action}", time: time_elapsed }
  end

  if ctx.key_just_pressed?('SPACE')
    clients.each_with_index do |client, i|
      next unless client.connected

      messages << {
        from: server.position.dup,
        to: client.position.dup,
        progress: 0.0,
        color: Bevy::Color.from_hex('#FFFF00'),
        type: :broadcast
      }
    end
    message_log << { text: 'Server broadcast', time: time_elapsed }
  end

  if ctx.key_just_pressed?('M')
    connected_clients = clients.select(&:connected)
    if connected_clients.any?
      client = connected_clients.sample
      messages << {
        from: client.position.dup,
        to: server.position.dup,
        progress: 0.0,
        color: client.color,
        type: :request
      }
      message_log << { text: "#{client.name} -> Server", time: time_elapsed }
    end
  end

  messages.each do |msg|
    msg[:progress] += delta * 2.0
  end
  messages.reject! { |msg| msg[:progress] >= 1.0 }

  clients.each_with_index do |client, i|
    if client.connected
      offset_x = Math.sin(time_elapsed * 0.5 + i) * 20.0
      offset_y = Math.cos(time_elapsed * 0.7 + i) * 10.0
      base_positions = [
        Bevy::Vec3.new(-250.0, -50.0, 0.0),
        Bevy::Vec3.new(0.0, -100.0, 0.0),
        Bevy::Vec3.new(250.0, -50.0, 0.0)
      ]
      client.target_position = Bevy::Vec3.new(
        base_positions[i].x + offset_x,
        base_positions[i].y + offset_y,
        0.0
      )
    end
    client.update(delta)
  end

  message_log.reject! { |log| time_elapsed - log[:time] > 5.0 }

  entity_cache.each { |_, e| ctx.world.despawn(e) if e }
  entity_cache.clear

  clients.each_with_index do |client, i|
    next unless client.connected

    from_pos = server.position
    to_pos = client.position
    mid_x = (from_pos.x + to_pos.x) / 2.0
    mid_y = (from_pos.y + to_pos.y) / 2.0
    dx = to_pos.x - from_pos.x
    dy = to_pos.y - from_pos.y
    length = Math.sqrt(dx * dx + dy * dy)

    line_entity = ctx.spawn(
      Bevy::Transform.from_xyz(mid_x, mid_y, 0.5),
      Bevy::Mesh::Rectangle.new(width: [length, 2.0].max, height: 2.0, color: Bevy::Color.from_hex('#444466'))
    )
    entity_cache["line_#{i}"] = line_entity
  end

  server_entity = ctx.spawn(
    Bevy::Transform.from_xyz(server.position.x, server.position.y, 2.0),
    Bevy::Mesh::RegularPolygon.new(radius: server.size, sides: 6, color: server.color)
  )
  entity_cache[:server] = server_entity

  server_label = ctx.spawn(
    Bevy::Transform.from_xyz(server.position.x, server.position.y - server.size - 20.0, 3.0),
    Bevy::Text2d.new('Server', font_size: 14.0, color: Bevy::Color.white)
  )
  entity_cache[:server_label] = server_label

  clients.each_with_index do |client, i|
    alpha = client.connected ? 1.0 : 0.3
    client_color = Bevy::Color.rgba(client.color.r, client.color.g, client.color.b, alpha)

    client_entity = ctx.spawn(
      Bevy::Transform.from_xyz(client.position.x, client.position.y, 2.0),
      Bevy::Mesh::Circle.new(radius: client.size, color: client_color)
    )
    entity_cache["client_#{i}"] = client_entity

    status_text = client.connected ? "#{client.latency}ms" : 'Offline'
    label_color = client.connected ? Bevy::Color.white : Bevy::Color.from_hex('#666666')
    client_label = ctx.spawn(
      Bevy::Transform.from_xyz(client.position.x, client.position.y - client.size - 15.0, 3.0),
      Bevy::Text2d.new("#{client.name} (#{status_text})", font_size: 11.0, color: label_color)
    )
    entity_cache["client_label_#{i}"] = client_label
  end

  messages.each_with_index do |msg, i|
    progress = msg[:progress]
    current_x = msg[:from].x + (msg[:to].x - msg[:from].x) * progress
    current_y = msg[:from].y + (msg[:to].y - msg[:from].y) * progress

    msg_entity = ctx.spawn(
      Bevy::Transform.from_xyz(current_x, current_y, 4.0),
      Bevy::Mesh::Circle.new(radius: 8.0, color: msg[:color])
    )
    entity_cache["msg_#{i}"] = msg_entity
  end

  message_log.each_with_index do |log, i|
    y = -220.0 - i * 18.0
    age = time_elapsed - log[:time]
    alpha = [[1.0 - age / 5.0, 1.0].min, 0.0].max
    log_entity = ctx.spawn(
      Bevy::Transform.from_xyz(-350.0, y, 5.0),
      Bevy::Text2d.new(log[:text], font_size: 11.0, color: Bevy::Color.rgba(0.7, 0.7, 0.7, alpha))
    )
    entity_cache["log_#{i}"] = log_entity
  end

  if status_entity
    connected_count = clients.count(&:connected)
    total_messages = message_log.size
    status_text = "Connected Clients: #{connected_count}/#{clients.size} | Messages: #{total_messages}"
    new_text = Bevy::Text2d.new(status_text, font_size: 16.0, color: Bevy::Color.from_hex('#FFD700'))
    ctx.world.insert_component(status_entity, new_text)
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Networking System Demo'
puts ''
puts 'Simulates a client-server network:'
puts '  - Server (gold hexagon) at center'
puts '  - 3 Clients that can connect/disconnect'
puts '  - Visual message passing'
puts ''
puts 'Controls:'
puts '  [1-3] Toggle client connection'
puts '  [SPACE] Server broadcast to all clients'
puts '  [M] Random client sends message to server'
puts '  [ESC] Exit'

app.run
