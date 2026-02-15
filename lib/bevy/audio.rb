# frozen_string_literal: true

module Bevy
  class AudioSource
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def type_name
      'AudioSource'
    end

    def to_native
      native = Component.new('AudioSource')
      native['path'] = @path
      native
    end

    def self.from_native(native)
      new(native['path'])
    end
  end

  module PlaybackMode
    ONCE = 'Once'
    LOOP = 'Loop'
    DESPAWN = 'Despawn'
  end

  class PlaybackSettings
    attr_reader :mode, :volume, :speed, :paused

    def initialize(mode: PlaybackMode::ONCE, volume: 1.0, speed: 1.0, paused: false)
      @mode = mode
      @volume = volume.clamp(0.0, 1.0)
      @speed = speed.clamp(0.1, 10.0)
      @paused = paused
    end

    def self.once
      new(mode: PlaybackMode::ONCE)
    end

    def self.loop
      new(mode: PlaybackMode::LOOP)
    end

    def self.despawn
      new(mode: PlaybackMode::DESPAWN)
    end

    def with_volume(volume)
      self.class.new(mode: @mode, volume: volume, speed: @speed, paused: @paused)
    end

    def with_speed(speed)
      self.class.new(mode: @mode, volume: @volume, speed: speed, paused: @paused)
    end

    def with_paused(paused)
      self.class.new(mode: @mode, volume: @volume, speed: @speed, paused: paused)
    end

    def paused?
      @paused
    end

    def looping?
      @mode == PlaybackMode::LOOP
    end

    def to_native
      native = Component.new('PlaybackSettings')
      native['mode'] = @mode
      native['volume'] = @volume
      native['speed'] = @speed
      native['paused'] = @paused
      native
    end

    def self.from_native(native)
      new(
        mode: native['mode'] || PlaybackMode::ONCE,
        volume: native['volume'] || 1.0,
        speed: native['speed'] || 1.0,
        paused: native['paused'] || false
      )
    end

    def to_h
      {
        mode: @mode,
        volume: @volume,
        speed: @speed,
        paused: @paused
      }
    end
  end

  class AudioPlayer
    attr_reader :source, :settings

    def initialize(source:, settings: nil)
      @source = source.is_a?(String) ? AudioSource.new(source) : source
      @settings = settings || PlaybackSettings.once
    end

    def type_name
      'AudioPlayer'
    end

    def with_settings(settings)
      self.class.new(source: @source, settings: settings)
    end

    def with_volume(volume)
      with_settings(@settings.with_volume(volume))
    end

    def with_speed(speed)
      with_settings(@settings.with_speed(speed))
    end

    def to_native
      native = Component.new('AudioPlayer')
      native['source_path'] = @source.path
      native['mode'] = @settings.mode
      native['volume'] = @settings.volume
      native['speed'] = @settings.speed
      native['paused'] = @settings.paused
      native
    end

    def self.from_native(native)
      source = AudioSource.new(native['source_path'])
      settings = PlaybackSettings.new(
        mode: native['mode'] || PlaybackMode::ONCE,
        volume: native['volume'] || 1.0,
        speed: native['speed'] || 1.0,
        paused: native['paused'] || false
      )
      new(source: source, settings: settings)
    end

    def to_h
      {
        source: @source.path,
        settings: @settings.to_h
      }
    end
  end

  class AudioBundle
    attr_reader :player

    def initialize(source:, settings: nil)
      @player = AudioPlayer.new(source: source, settings: settings)
    end

    def self.from_source(path, settings: nil)
      source = AudioSource.new(path)
      new(source: source, settings: settings)
    end

    def components
      [@player]
    end
  end

  class GlobalVolume
    attr_reader :volume

    def initialize(volume: 1.0)
      @volume = volume.clamp(0.0, 1.0)
    end

    def with_volume(volume)
      self.class.new(volume: volume)
    end

    def muted?
      @volume == 0.0
    end

    def to_h
      { volume: @volume }
    end
  end

  class SpatialAudioSettings
    attr_reader :max_distance, :reference_distance, :rolloff_factor
    attr_reader :cone_inner_angle, :cone_outer_angle, :cone_outer_gain

    def initialize(
      max_distance: 100.0,
      reference_distance: 1.0,
      rolloff_factor: 1.0,
      cone_inner_angle: 360.0,
      cone_outer_angle: 360.0,
      cone_outer_gain: 0.0
    )
      @max_distance = max_distance
      @reference_distance = reference_distance
      @rolloff_factor = rolloff_factor
      @cone_inner_angle = cone_inner_angle
      @cone_outer_angle = cone_outer_angle
      @cone_outer_gain = cone_outer_gain
    end

    def with_max_distance(distance)
      dup.tap { |s| s.instance_variable_set(:@max_distance, distance) }
    end

    def with_reference_distance(distance)
      dup.tap { |s| s.instance_variable_set(:@reference_distance, distance) }
    end

    def with_rolloff_factor(factor)
      dup.tap { |s| s.instance_variable_set(:@rolloff_factor, factor) }
    end

    def with_cone(inner, outer, outer_gain)
      dup.tap do |s|
        s.instance_variable_set(:@cone_inner_angle, inner.clamp(0.0, 360.0))
        s.instance_variable_set(:@cone_outer_angle, outer.clamp(0.0, 360.0))
        s.instance_variable_set(:@cone_outer_gain, outer_gain.clamp(0.0, 1.0))
      end
    end

    def calculate_attenuation(distance)
      return 1.0 if distance <= @reference_distance
      return 0.0 if distance >= @max_distance

      d = [[distance, @reference_distance].max, @max_distance].min
      @reference_distance / (@reference_distance + @rolloff_factor * (d - @reference_distance))
    end

    def to_native
      native = Component.new('SpatialAudioSettings')
      native['max_distance'] = @max_distance
      native['reference_distance'] = @reference_distance
      native['rolloff_factor'] = @rolloff_factor
      native['cone_inner_angle'] = @cone_inner_angle
      native['cone_outer_angle'] = @cone_outer_angle
      native['cone_outer_gain'] = @cone_outer_gain
      native
    end

    def self.from_native(native)
      new(
        max_distance: native['max_distance'] || 100.0,
        reference_distance: native['reference_distance'] || 1.0,
        rolloff_factor: native['rolloff_factor'] || 1.0,
        cone_inner_angle: native['cone_inner_angle'] || 360.0,
        cone_outer_angle: native['cone_outer_angle'] || 360.0,
        cone_outer_gain: native['cone_outer_gain'] || 0.0
      )
    end

    def to_h
      {
        max_distance: @max_distance,
        reference_distance: @reference_distance,
        rolloff_factor: @rolloff_factor,
        cone_inner_angle: @cone_inner_angle,
        cone_outer_angle: @cone_outer_angle,
        cone_outer_gain: @cone_outer_gain
      }
    end
  end

  class FadeSettings
    attr_accessor :duration, :elapsed, :target_volume

    def initialize(duration, target_volume: 1.0)
      @duration = duration
      @elapsed = 0.0
      @target_volume = target_volume
    end

    def progress
      return 1.0 if @duration <= 0.0

      (@elapsed / @duration).clamp(0.0, 1.0)
    end

    def complete?
      @elapsed >= @duration
    end

    def update(delta)
      @elapsed += delta
    end
  end

  class AudioTrack
    attr_reader :path
    attr_accessor :settings, :current_time, :duration

    def initialize(path, settings: nil)
      @path = path
      @settings = settings || PlaybackSettings.once
      @current_time = 0.0
      @duration = nil
      @current_fade = nil
    end

    def fade_in(duration)
      @current_fade = { type: :in, settings: FadeSettings.new(duration) }
    end

    def fade_out(duration)
      @current_fade = { type: :out, settings: FadeSettings.new(duration, target_volume: 0.0) }
    end

    def update(delta)
      return unless @current_fade

      @current_fade[:settings].update(delta)
      @current_fade = nil if @current_fade[:settings].complete?
    end

    def effective_volume
      base = @settings.volume
      return base unless @current_fade

      case @current_fade[:type]
      when :in
        base * @current_fade[:settings].progress
      when :out
        base * (1.0 - @current_fade[:settings].progress)
      else
        base
      end
    end

    def fading?
      !@current_fade.nil?
    end
  end

  class AudioChannel
    attr_accessor :name, :volume, :muted

    def initialize(name, volume: 1.0)
      @name = name
      @volume = volume.clamp(0.0, 2.0)
      @muted = false
      @track_ids = []
    end

    def mute
      @muted = true
    end

    def unmute
      @muted = false
    end

    def effective_volume
      @muted ? 0.0 : @volume
    end

    def track_ids
      @track_ids.dup
    end

    def add_track(id)
      @track_ids << id
    end

    def remove_track(id)
      @track_ids.delete(id)
    end
  end

  class AudioMixer
    attr_accessor :master_volume, :muted

    def initialize
      @master_volume = 1.0
      @muted = false
      @channels = {}
      @tracks = {}
      @next_track_id = 0
      add_channel('music')
      add_channel('sfx')
      add_channel('voice')
    end

    def add_channel(name, volume: 1.0)
      @channels[name] ||= AudioChannel.new(name, volume: volume)
    end

    def channel(name)
      @channels[name]
    end

    def set_channel_volume(name, volume)
      @channels[name]&.tap { |c| c.volume = volume.clamp(0.0, 2.0) }
    end

    def mute_channel(name)
      @channels[name]&.mute
    end

    def unmute_channel(name)
      @channels[name]&.unmute
    end

    def play(path, channel: 'sfx', settings: nil)
      track_id = @next_track_id
      @next_track_id += 1

      track = AudioTrack.new(path, settings: settings)
      @tracks[track_id] = { track: track, channel: channel }
      @channels[channel]&.add_track(track_id)

      track_id
    end

    def stop(track_id)
      entry = @tracks.delete(track_id)
      return unless entry

      @channels[entry[:channel]]&.remove_track(track_id)
    end

    def stop_with_fade(track_id, duration)
      entry = @tracks[track_id]
      return unless entry

      entry[:track].fade_out(duration)
    end

    def pause(track_id)
      entry = @tracks[track_id]
      return unless entry

      entry[:track].settings = entry[:track].settings.with_paused(true)
    end

    def resume(track_id)
      entry = @tracks[track_id]
      return unless entry

      entry[:track].settings = entry[:track].settings.with_paused(false)
    end

    def track(track_id)
      @tracks[track_id]&.dig(:track)
    end

    def update(delta)
      completed = []
      @tracks.each do |id, entry|
        entry[:track].update(delta)
        if entry[:track].fading? && entry[:track].effective_volume <= 0.0
          completed << id
        end
      end
      completed.each { |id| stop(id) }
    end

    def effective_volume(track_id)
      return 0.0 if @muted

      entry = @tracks[track_id]
      return 0.0 unless entry

      channel_vol = @channels[entry[:channel]]&.effective_volume || 1.0
      track_vol = entry[:track].effective_volume

      @master_volume * channel_vol * track_vol
    end
  end

  class AudioQueue
    attr_accessor :loop_queue, :shuffle
    attr_reader :current_index

    def initialize
      @tracks = []
      @current_index = 0
      @loop_queue = false
      @shuffle = false
    end

    def add(path)
      @tracks << path
    end

    def add_all(paths)
      @tracks.concat(paths)
    end

    def current
      @tracks[@current_index]
    end

    def next
      return nil if @tracks.empty?

      @current_index += 1
      if @current_index >= @tracks.size
        return nil unless @loop_queue

        @current_index = 0
      end
      current
    end

    def previous
      return nil if @tracks.empty?

      if @current_index.zero?
        return nil unless @loop_queue

        @current_index = @tracks.size - 1
      else
        @current_index -= 1
      end
      current
    end

    def clear
      @tracks.clear
      @current_index = 0
    end

    def size
      @tracks.size
    end

    def empty?
      @tracks.empty?
    end

    def to_a
      @tracks.dup
    end
  end
end
