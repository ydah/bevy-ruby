# frozen_string_literal: true

RSpec.describe Bevy::AudioSource do
  describe '.new' do
    it 'creates an AudioSource with a path' do
      source = described_class.new('sounds/music.ogg')
      expect(source.path).to eq('sounds/music.ogg')
    end
  end

  describe '#type_name' do
    it 'returns AudioSource' do
      source = described_class.new('test.ogg')
      expect(source.type_name).to eq('AudioSource')
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      source = described_class.new('sounds/effect.wav')
      native = source.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native['path']).to eq('sounds/effect.wav')
    end
  end

  describe '.from_native' do
    it 'creates an AudioSource from native' do
      native = Bevy::Component.new('AudioSource')
      native['path'] = 'test.ogg'
      source = described_class.from_native(native)
      expect(source.path).to eq('test.ogg')
    end
  end
end

RSpec.describe Bevy::PlaybackMode do
  it 'defines playback modes' do
    expect(Bevy::PlaybackMode::ONCE).to eq('Once')
    expect(Bevy::PlaybackMode::LOOP).to eq('Loop')
    expect(Bevy::PlaybackMode::DESPAWN).to eq('Despawn')
  end
end

RSpec.describe Bevy::PlaybackSettings do
  describe '.new' do
    it 'creates settings with defaults' do
      settings = described_class.new
      expect(settings.mode).to eq(Bevy::PlaybackMode::ONCE)
      expect(settings.volume).to eq(1.0)
      expect(settings.speed).to eq(1.0)
      expect(settings.paused).to be false
    end

    it 'creates settings with custom values' do
      settings = described_class.new(
        mode: Bevy::PlaybackMode::LOOP,
        volume: 0.5,
        speed: 1.5,
        paused: true
      )
      expect(settings.mode).to eq(Bevy::PlaybackMode::LOOP)
      expect(settings.volume).to eq(0.5)
      expect(settings.speed).to eq(1.5)
      expect(settings.paused).to be true
    end
  end

  describe '.once' do
    it 'creates one-shot settings' do
      settings = described_class.once
      expect(settings.mode).to eq(Bevy::PlaybackMode::ONCE)
    end
  end

  describe '.loop' do
    it 'creates looping settings' do
      settings = described_class.loop
      expect(settings.mode).to eq(Bevy::PlaybackMode::LOOP)
      expect(settings.looping?).to be true
    end
  end

  describe '.despawn' do
    it 'creates despawn settings' do
      settings = described_class.despawn
      expect(settings.mode).to eq(Bevy::PlaybackMode::DESPAWN)
    end
  end

  describe '#with_volume' do
    it 'returns new settings with updated volume' do
      settings = described_class.new
      new_settings = settings.with_volume(0.7)
      expect(new_settings.volume).to eq(0.7)
      expect(settings.volume).to eq(1.0)
    end

    it 'clamps volume to 0..1' do
      settings = described_class.new(volume: 1.5)
      expect(settings.volume).to eq(1.0)

      settings = described_class.new(volume: -0.5)
      expect(settings.volume).to eq(0.0)
    end
  end

  describe '#with_speed' do
    it 'returns new settings with updated speed' do
      settings = described_class.new
      new_settings = settings.with_speed(2.0)
      expect(new_settings.speed).to eq(2.0)
    end

    it 'clamps speed to 0.1..10' do
      settings = described_class.new(speed: 0.01)
      expect(settings.speed).to eq(0.1)

      settings = described_class.new(speed: 15.0)
      expect(settings.speed).to eq(10.0)
    end
  end

  describe '#with_paused' do
    it 'returns new settings with updated paused state' do
      settings = described_class.new
      new_settings = settings.with_paused(true)
      expect(new_settings.paused?).to be true
    end
  end

  describe '#to_native and .from_native' do
    it 'round-trips through native' do
      settings = described_class.new(
        mode: Bevy::PlaybackMode::LOOP,
        volume: 0.8,
        speed: 1.2,
        paused: true
      )
      native = settings.to_native
      restored = described_class.from_native(native)
      expect(restored.mode).to eq(Bevy::PlaybackMode::LOOP)
      expect(restored.volume).to eq(0.8)
      expect(restored.speed).to eq(1.2)
      expect(restored.paused).to be true
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      settings = described_class.new(volume: 0.5)
      h = settings.to_h
      expect(h[:volume]).to eq(0.5)
      expect(h[:mode]).to eq(Bevy::PlaybackMode::ONCE)
    end
  end
end

RSpec.describe Bevy::AudioPlayer do
  let(:source) { Bevy::AudioSource.new('music.ogg') }

  describe '.new' do
    it 'creates an AudioPlayer with source and default settings' do
      player = described_class.new(source: source)
      expect(player.source.path).to eq('music.ogg')
      expect(player.settings.mode).to eq(Bevy::PlaybackMode::ONCE)
    end

    it 'creates an AudioPlayer with custom settings' do
      settings = Bevy::PlaybackSettings.loop
      player = described_class.new(source: source, settings: settings)
      expect(player.settings.looping?).to be true
    end
  end

  describe '#type_name' do
    it 'returns AudioPlayer' do
      player = described_class.new(source: source)
      expect(player.type_name).to eq('AudioPlayer')
    end
  end

  describe '#with_volume' do
    it 'returns a new player with updated volume' do
      player = described_class.new(source: source)
      new_player = player.with_volume(0.5)
      expect(new_player.settings.volume).to eq(0.5)
    end
  end

  describe '#with_speed' do
    it 'returns a new player with updated speed' do
      player = described_class.new(source: source)
      new_player = player.with_speed(1.5)
      expect(new_player.settings.speed).to eq(1.5)
    end
  end

  describe '#to_native and .from_native' do
    it 'round-trips through native' do
      settings = Bevy::PlaybackSettings.new(volume: 0.7, speed: 0.9)
      player = described_class.new(source: source, settings: settings)

      native = player.to_native
      restored = described_class.from_native(native)

      expect(restored.source.path).to eq('music.ogg')
      expect(restored.settings.volume).to eq(0.7)
      expect(restored.settings.speed).to eq(0.9)
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      player = described_class.new(source: source)
      h = player.to_h
      expect(h[:source]).to eq('music.ogg')
      expect(h[:settings]).to be_a(Hash)
    end
  end
end

RSpec.describe Bevy::AudioBundle do
  describe '.from_source' do
    it 'creates a bundle from a source path' do
      bundle = described_class.from_source('sounds/bgm.ogg')
      expect(bundle.player.source.path).to eq('sounds/bgm.ogg')
    end

    it 'creates a bundle with custom settings' do
      settings = Bevy::PlaybackSettings.loop
      bundle = described_class.from_source('music.ogg', settings: settings)
      expect(bundle.player.settings.looping?).to be true
    end
  end

  describe '#components' do
    it 'returns array of components' do
      bundle = described_class.from_source('test.ogg')
      components = bundle.components
      expect(components.length).to eq(1)
      expect(components[0]).to be_a(Bevy::AudioPlayer)
    end
  end
end

RSpec.describe Bevy::GlobalVolume do
  describe '.new' do
    it 'creates with default volume' do
      vol = described_class.new
      expect(vol.volume).to eq(1.0)
    end

    it 'creates with custom volume' do
      vol = described_class.new(volume: 0.5)
      expect(vol.volume).to eq(0.5)
    end

    it 'clamps volume to 0..1' do
      vol = described_class.new(volume: 1.5)
      expect(vol.volume).to eq(1.0)

      vol = described_class.new(volume: -0.5)
      expect(vol.volume).to eq(0.0)
    end
  end

  describe '#with_volume' do
    it 'returns a new GlobalVolume with updated volume' do
      vol = described_class.new(volume: 1.0)
      new_vol = vol.with_volume(0.5)
      expect(new_vol.volume).to eq(0.5)
      expect(vol.volume).to eq(1.0)
    end
  end

  describe '#muted?' do
    it 'returns true when volume is 0' do
      vol = described_class.new(volume: 0.0)
      expect(vol.muted?).to be true
    end

    it 'returns false when volume is not 0' do
      vol = described_class.new(volume: 0.1)
      expect(vol.muted?).to be false
    end
  end
end

RSpec.describe Bevy::SpatialAudioSettings do
  describe '.new' do
    it 'creates with defaults' do
      settings = described_class.new
      expect(settings.max_distance).to eq(100.0)
      expect(settings.rolloff_factor).to eq(1.0)
    end

    it 'creates with custom values' do
      settings = described_class.new(max_distance: 50.0, rolloff_factor: 2.0)
      expect(settings.max_distance).to eq(50.0)
      expect(settings.rolloff_factor).to eq(2.0)
    end
  end

  describe '#with_max_distance' do
    it 'returns new settings with updated max distance' do
      settings = described_class.new
      new_settings = settings.with_max_distance(200.0)
      expect(new_settings.max_distance).to eq(200.0)
    end
  end

  describe '#with_rolloff_factor' do
    it 'returns new settings with updated rolloff factor' do
      settings = described_class.new
      new_settings = settings.with_rolloff_factor(0.5)
      expect(new_settings.rolloff_factor).to eq(0.5)
    end
  end

  describe '#to_native and .from_native' do
    it 'round-trips through native' do
      settings = described_class.new(max_distance: 75.0, rolloff_factor: 1.5)
      native = settings.to_native
      restored = described_class.from_native(native)
      expect(restored.max_distance).to eq(75.0)
      expect(restored.rolloff_factor).to eq(1.5)
    end
  end
end

RSpec.describe Bevy::FadeSettings do
  describe '.new' do
    it 'creates with duration' do
      fade = described_class.new(1.0)
      expect(fade.duration).to eq(1.0)
      expect(fade.elapsed).to eq(0.0)
    end

    it 'creates with target volume' do
      fade = described_class.new(0.5, target_volume: 0.0)
      expect(fade.target_volume).to eq(0.0)
    end
  end

  describe '#progress' do
    it 'returns 0 at start' do
      fade = described_class.new(1.0)
      expect(fade.progress).to eq(0.0)
    end

    it 'returns 1 at end' do
      fade = described_class.new(1.0)
      fade.update(1.0)
      expect(fade.progress).to eq(1.0)
    end

    it 'returns fraction in between' do
      fade = described_class.new(1.0)
      fade.update(0.5)
      expect(fade.progress).to be_within(0.001).of(0.5)
    end
  end

  describe '#complete?' do
    it 'returns false when not complete' do
      fade = described_class.new(1.0)
      expect(fade.complete?).to be false
    end

    it 'returns true when complete' do
      fade = described_class.new(0.5)
      fade.update(0.6)
      expect(fade.complete?).to be true
    end
  end
end

RSpec.describe Bevy::AudioTrack do
  describe '.new' do
    it 'creates with path and default settings' do
      track = described_class.new('music.ogg')
      expect(track.path).to eq('music.ogg')
      expect(track.settings).to be_a(Bevy::PlaybackSettings)
    end
  end

  describe '#fade_in' do
    it 'starts a fade in' do
      track = described_class.new('test.ogg')
      track.fade_in(0.5)
      expect(track.fading?).to be true
    end
  end

  describe '#fade_out' do
    it 'starts a fade out' do
      track = described_class.new('test.ogg')
      track.fade_out(0.3)
      expect(track.fading?).to be true
    end
  end

  describe '#effective_volume' do
    it 'returns base volume when not fading' do
      settings = Bevy::PlaybackSettings.new(volume: 0.8)
      track = described_class.new('test.ogg', settings: settings)
      expect(track.effective_volume).to eq(0.8)
    end

    it 'returns reduced volume during fade in' do
      track = described_class.new('test.ogg')
      track.fade_in(1.0)
      expect(track.effective_volume).to eq(0.0)
      track.update(0.5)
      expect(track.effective_volume).to be > 0.0
      expect(track.effective_volume).to be < 1.0
    end
  end
end

RSpec.describe Bevy::AudioChannel do
  describe '.new' do
    it 'creates with name and default volume' do
      channel = described_class.new('music')
      expect(channel.name).to eq('music')
      expect(channel.volume).to eq(1.0)
      expect(channel.muted).to be false
    end
  end

  describe '#mute and #unmute' do
    it 'mutes and unmutes the channel' do
      channel = described_class.new('sfx')
      channel.mute
      expect(channel.muted).to be true
      expect(channel.effective_volume).to eq(0.0)

      channel.unmute
      expect(channel.muted).to be false
      expect(channel.effective_volume).to be > 0.0
    end
  end
end

RSpec.describe Bevy::AudioMixer do
  let(:mixer) { described_class.new }

  describe '.new' do
    it 'creates with default channels' do
      expect(mixer.channel('music')).to be_a(Bevy::AudioChannel)
      expect(mixer.channel('sfx')).to be_a(Bevy::AudioChannel)
      expect(mixer.channel('voice')).to be_a(Bevy::AudioChannel)
    end

    it 'has master volume of 1.0' do
      expect(mixer.master_volume).to eq(1.0)
    end
  end

  describe '#add_channel' do
    it 'adds a new channel' do
      mixer.add_channel('ambient')
      expect(mixer.channel('ambient')).to be_a(Bevy::AudioChannel)
    end
  end

  describe '#set_channel_volume' do
    it 'sets channel volume' do
      mixer.set_channel_volume('music', 0.5)
      expect(mixer.channel('music').volume).to eq(0.5)
    end
  end

  describe '#mute_channel and #unmute_channel' do
    it 'mutes and unmutes channel' do
      mixer.mute_channel('sfx')
      expect(mixer.channel('sfx').muted).to be true

      mixer.unmute_channel('sfx')
      expect(mixer.channel('sfx').muted).to be false
    end
  end

  describe '#play' do
    it 'plays a sound and returns track id' do
      id = mixer.play('explosion.ogg', channel: 'sfx')
      expect(id).to be_a(Integer)
      expect(mixer.track(id)).to be_a(Bevy::AudioTrack)
    end
  end

  describe '#stop' do
    it 'stops a playing track' do
      id = mixer.play('music.ogg', channel: 'music')
      mixer.stop(id)
      expect(mixer.track(id)).to be_nil
    end
  end

  describe '#pause and #resume' do
    it 'pauses and resumes a track' do
      id = mixer.play('music.ogg', channel: 'music')
      mixer.pause(id)
      expect(mixer.track(id).settings.paused).to be true

      mixer.resume(id)
      expect(mixer.track(id).settings.paused).to be false
    end
  end

  describe '#effective_volume' do
    it 'calculates combined volume' do
      mixer.master_volume = 0.5
      mixer.set_channel_volume('music', 0.8)
      id = mixer.play('test.ogg', channel: 'music', settings: Bevy::PlaybackSettings.new(volume: 0.5))
      vol = mixer.effective_volume(id)
      expect(vol).to be_within(0.001).of(0.5 * 0.8 * 0.5)
    end

    it 'returns 0 when muted' do
      mixer.muted = true
      id = mixer.play('test.ogg', channel: 'sfx')
      expect(mixer.effective_volume(id)).to eq(0.0)
    end
  end
end

RSpec.describe Bevy::AudioQueue do
  let(:queue) { described_class.new }

  describe '#add' do
    it 'adds tracks to queue' do
      queue.add('track1.ogg')
      queue.add('track2.ogg')
      expect(queue.size).to eq(2)
    end
  end

  describe '#current' do
    it 'returns current track' do
      queue.add('track1.ogg')
      expect(queue.current).to eq('track1.ogg')
    end
  end

  describe '#next' do
    it 'advances to next track' do
      queue.add('track1.ogg')
      queue.add('track2.ogg')
      result = queue.next
      expect(result).to eq('track2.ogg')
      expect(queue.current).to eq('track2.ogg')
    end

    it 'returns nil at end without looping' do
      queue.add('track1.ogg')
      queue.next
      expect(queue.next).to be_nil
    end

    it 'loops to start when loop_queue is true' do
      queue.add('track1.ogg')
      queue.add('track2.ogg')
      queue.loop_queue = true
      queue.next
      result = queue.next
      expect(result).to eq('track1.ogg')
    end
  end

  describe '#previous' do
    it 'goes to previous track' do
      queue.add('track1.ogg')
      queue.add('track2.ogg')
      queue.next
      result = queue.previous
      expect(result).to eq('track1.ogg')
    end
  end

  describe '#clear' do
    it 'clears all tracks' do
      queue.add('track1.ogg')
      queue.add('track2.ogg')
      queue.clear
      expect(queue.empty?).to be true
    end
  end
end

RSpec.describe 'World with Audio' do
  let(:world) { Bevy::World.new }
  let(:source) { Bevy::AudioSource.new('test.ogg') }

  describe '#spawn_entity with AudioPlayer' do
    it 'spawns an entity with audio' do
      player = Bevy::AudioPlayer.new(source: source)
      entity = world.spawn_entity(player)
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#get_component with AudioPlayer' do
    it 'retrieves an AudioPlayer' do
      settings = Bevy::PlaybackSettings.new(volume: 0.6, speed: 1.1)
      player = Bevy::AudioPlayer.new(source: source, settings: settings)
      entity = world.spawn_entity(player)

      retrieved = world.get_component(entity, Bevy::AudioPlayer)
      expect(retrieved).to be_a(Bevy::AudioPlayer)
      expect(retrieved.source.path).to eq('test.ogg')
      expect(retrieved.settings.volume).to eq(0.6)
    end
  end

  describe '#has? with AudioPlayer' do
    it 'checks if entity has AudioPlayer' do
      player = Bevy::AudioPlayer.new(source: source)
      entity = world.spawn_entity(player)
      expect(world.has?(entity, Bevy::AudioPlayer)).to be true
      expect(world.has?(entity, Bevy::SpatialAudioSettings)).to be false
    end
  end

  describe '#spawn_entity with SpatialAudioSettings' do
    it 'spawns an entity with spatial audio' do
      player = Bevy::AudioPlayer.new(source: source)
      spatial = Bevy::SpatialAudioSettings.new(max_distance: 50.0)
      entity = world.spawn_entity(player, spatial)
      expect(world.has?(entity, Bevy::AudioPlayer)).to be true
      expect(world.has?(entity, Bevy::SpatialAudioSettings)).to be true
    end
  end
end
