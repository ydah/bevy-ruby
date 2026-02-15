# frozen_string_literal: true

require 'bevy'

class AudioVisualizerBar < Bevy::ComponentDSL
  attribute :channel, String, default: 'music'
  attribute :index, Integer, default: 0
end

class VolumeSlider < Bevy::ComponentDSL
  attribute :channel, String, default: 'master'
end

class PlaybackIndicator < Bevy::ComponentDSL
  attribute :track_index, Integer, default: 0
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Audio Advanced Demo - Mixer, Channels, Queue, Fade',
    width: 900.0,
    height: 700.0
  }
)

mixer = Bevy::AudioMixer.new
mixer.add_channel(Bevy::AudioChannel.new('music', volume: 0.8))
mixer.add_channel(Bevy::AudioChannel.new('sfx', volume: 1.0))
mixer.add_channel(Bevy::AudioChannel.new('voice', volume: 0.9))

queue = Bevy::AudioQueue.new
queue.add('Track 1: Epic Adventure')
queue.add('Track 2: Calm Forest')
queue.add('Track 3: Battle Theme')
queue.add('Track 4: Victory Fanfare')

playback_state = {
  playing: false,
  current_time: 0.0,
  fade: nil,
  visualization: Array.new(16, 0.0)
}

app.add_startup_system do |ctx|
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 300.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 800.0, height: 60.0, color: Bevy::Color.from_hex('#2C3E50'))
  )

  16.times do |i|
    ctx.spawn(
      AudioVisualizerBar.new(channel: 'music', index: i),
      Bevy::Transform.from_xyz(-350.0 + i * 45.0, 100.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 35.0, height: 50.0, color: Bevy::Color.from_hex('#3498DB'))
    )
  end

  channels = %w[master music sfx voice]
  channels.each_with_index do |channel, idx|
    ctx.spawn(
      VolumeSlider.new(channel: channel),
      Bevy::Transform.from_xyz(-300.0 + idx * 150.0, -50.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 120.0, height: 30.0, color: Bevy::Color.from_hex('#27AE60'))
    )
    ctx.spawn(
      Bevy::Transform.from_xyz(-300.0 + idx * 150.0, -100.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 120.0, height: 15.0, color: Bevy::Color.from_hex('#1ABC9C'))
    )
  end

  4.times do |i|
    color = i.zero? ? Bevy::Color.from_hex('#E74C3C') : Bevy::Color.from_hex('#34495E')
    ctx.spawn(
      PlaybackIndicator.new(track_index: i),
      Bevy::Transform.from_xyz(-250.0 + i * 170.0, -200.0, 0.0),
      Bevy::Mesh::Rectangle.new(width: 150.0, height: 40.0, color: color)
    )
  end

  ctx.spawn(
    Bevy::Transform.from_xyz(-100.0, -280.0, 0.0),
    Bevy::Mesh::Triangle.new(radius: 25.0, color: Bevy::Color.from_hex('#2ECC71'))
  )
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, -280.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 40.0, height: 40.0, color: Bevy::Color.from_hex('#E74C3C'))
  )
  ctx.spawn(
    Bevy::Transform.from_xyz(100.0, -280.0, 0.0),
    Bevy::Mesh::Rectangle.new(width: 50.0, height: 40.0, color: Bevy::Color.from_hex('#3498DB'))
  )
end

app.add_update_system do |ctx|
  delta = ctx.delta
  elapsed = ctx.elapsed

  if playback_state[:playing]
    playback_state[:current_time] += delta

    16.times do |i|
      freq = 0.5 + i * 0.3
      phase = i * 0.5
      playback_state[:visualization][i] = (Math.sin(elapsed * freq + phase) + 1.0) * 0.5
    end
  else
    16.times do |i|
      playback_state[:visualization][i] *= 0.95
    end
  end

  if playback_state[:fade]
    playback_state[:fade].update(delta)
    if playback_state[:fade].complete?
      playback_state[:fade] = nil
      puts 'Fade complete'
    end
  end
end

app.add_update_system do |ctx|
  elapsed = ctx.elapsed

  ctx.world.each(AudioVisualizerBar, Bevy::Transform) do |entity, bar, transform|
    height = 20.0 + playback_state[:visualization][bar.index] * 150.0

    hue = (bar.index / 16.0 + elapsed * 0.1) % 1.0
    r = [(hue * 6.0 - 3.0).abs - 1.0, 0.0].max
    r = [r, 1.0].min
    g = [2.0 - (hue * 6.0 - 2.0).abs, 0.0].max
    g = [g, 1.0].min
    b = [2.0 - (hue * 6.0 - 4.0).abs, 0.0].max
    b = [b, 1.0].min

    new_y = 100.0 + (height - 50.0) / 2.0
    new_transform = Bevy::Transform.from_xyz(transform.translation.x, new_y, 0.0)
    ctx.world.insert_component(entity, new_transform)
  end

  current_index = queue.current_index
  ctx.world.each(PlaybackIndicator, Bevy::Transform) do |entity, indicator, transform|
    color = if indicator.track_index == current_index
              Bevy::Color.from_hex('#E74C3C')
            else
              Bevy::Color.from_hex('#34495E')
            end
  end
end

app.add_update_system do |ctx|
  if ctx.key_just_pressed?('SPACE')
    playback_state[:playing] = !playback_state[:playing]
    puts playback_state[:playing] ? 'Playing' : 'Paused'
  end

  if ctx.key_just_pressed?('N')
    next_track = queue.next
    puts "Next: #{next_track || 'End of queue'}"
  end

  if ctx.key_just_pressed?('P')
    prev_track = queue.previous
    puts "Previous: #{prev_track || 'Beginning of queue'}"
  end

  if ctx.key_just_pressed?('F')
    playback_state[:fade] = Bevy::FadeSettings.new(2.0, target_volume: 0.0)
    puts 'Fading out over 2 seconds...'
  end

  if ctx.key_just_pressed?('M')
    current = mixer.get_channel('music')
    if current
      if current.muted
        current.unmute
        puts 'Music unmuted'
      else
        current.mute
        puts 'Music muted'
      end
    end
  end

  if ctx.key_just_pressed?('UP')
    mixer.master_volume = [mixer.master_volume + 0.1, 1.0].min
    puts "Master volume: #{(mixer.master_volume * 100).round}%"
  end

  if ctx.key_just_pressed?('DOWN')
    mixer.master_volume = [mixer.master_volume - 0.1, 0.0].max
    puts "Master volume: #{(mixer.master_volume * 100).round}%"
  end

  if ctx.key_just_pressed?('L')
    queue.loop_queue = !queue.loop_queue
    puts "Loop: #{queue.loop_queue ? 'ON' : 'OFF'}"
  end

  if ctx.key_just_pressed?('S')
    queue.shuffle = !queue.shuffle
    puts "Shuffle: #{queue.shuffle ? 'ON' : 'OFF'}"
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Audio Advanced Demo'
puts ''
puts 'Controls:'
puts '  SPACE     - Play/Pause'
puts '  N         - Next track'
puts '  P         - Previous track'
puts '  F         - Fade out'
puts '  M         - Mute/Unmute music channel'
puts '  UP/DOWN   - Master volume'
puts '  L         - Toggle loop queue'
puts '  S         - Toggle shuffle'
puts '  ESC       - Exit'
puts ''
puts 'Features:'
puts '  - AudioMixer with multiple channels'
puts '  - AudioQueue for playlist management'
puts '  - FadeSettings for volume transitions'
puts '  - Visual audio spectrum analyzer'

app.run
