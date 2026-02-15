# frozen_string_literal: true

RSpec.describe Bevy::Easing do
  describe '.linear' do
    it 'returns t unchanged' do
      expect(described_class.linear(0.0)).to eq(0.0)
      expect(described_class.linear(0.5)).to eq(0.5)
      expect(described_class.linear(1.0)).to eq(1.0)
    end
  end

  describe '.ease_in_quad' do
    it 'returns t squared' do
      expect(described_class.ease_in_quad(0.0)).to eq(0.0)
      expect(described_class.ease_in_quad(0.5)).to eq(0.25)
      expect(described_class.ease_in_quad(1.0)).to eq(1.0)
    end
  end

  describe '.ease_out_quad' do
    it 'returns eased value' do
      expect(described_class.ease_out_quad(0.0)).to eq(0.0)
      expect(described_class.ease_out_quad(1.0)).to eq(1.0)
      expect(described_class.ease_out_quad(0.5)).to be > 0.5
    end
  end

  describe '.ease_in_out_quad' do
    it 'starts slow, speeds up, then slows' do
      expect(described_class.ease_in_out_quad(0.0)).to eq(0.0)
      expect(described_class.ease_in_out_quad(0.5)).to eq(0.5)
      expect(described_class.ease_in_out_quad(1.0)).to eq(1.0)
    end
  end

  describe '.ease_out_bounce' do
    it 'creates bounce effect' do
      expect(described_class.ease_out_bounce(0.0)).to eq(0.0)
      expect(described_class.ease_out_bounce(1.0)).to eq(1.0)
    end
  end

  describe '.apply' do
    it 'applies easing by symbol' do
      expect(described_class.apply(:linear, 0.5)).to eq(0.5)
      expect(described_class.apply(:ease_in_quad, 0.5)).to eq(0.25)
    end

    it 'applies custom easing proc' do
      custom = ->(t) { t * t * t }
      expect(described_class.apply(custom, 0.5)).to eq(0.125)
    end

    it 'defaults to linear for unknown easing' do
      expect(described_class.apply(:unknown, 0.5)).to eq(0.5)
    end
  end
end

RSpec.describe Bevy::Keyframe do
  describe '.new' do
    it 'creates keyframe with time and value' do
      kf = described_class.new(1.0, 100)
      expect(kf.time).to eq(1.0)
      expect(kf.value).to eq(100)
      expect(kf.easing).to eq(:linear)
    end

    it 'creates keyframe with easing' do
      kf = described_class.new(1.0, 100, easing: :ease_out_quad)
      expect(kf.easing).to eq(:ease_out_quad)
    end
  end

  describe '#interpolate_to' do
    it 'interpolates numeric values' do
      kf1 = described_class.new(0.0, 0.0)
      kf2 = described_class.new(1.0, 100.0)

      expect(kf1.interpolate_to(kf2, 0.0)).to eq(0.0)
      expect(kf1.interpolate_to(kf2, 0.5)).to eq(50.0)
      expect(kf1.interpolate_to(kf2, 1.0)).to eq(100.0)
    end

    it 'interpolates Vec2 values' do
      kf1 = described_class.new(0.0, Bevy::Vec2.new(0.0, 0.0))
      kf2 = described_class.new(1.0, Bevy::Vec2.new(100.0, 200.0))

      result = kf1.interpolate_to(kf2, 0.5)
      expect(result.x).to eq(50.0)
      expect(result.y).to eq(100.0)
    end

    it 'interpolates Vec3 values' do
      kf1 = described_class.new(0.0, Bevy::Vec3.new(0.0, 0.0, 0.0))
      kf2 = described_class.new(1.0, Bevy::Vec3.new(10.0, 20.0, 30.0))

      result = kf1.interpolate_to(kf2, 0.5)
      expect(result.x).to eq(5.0)
      expect(result.y).to eq(10.0)
      expect(result.z).to eq(15.0)
    end

    it 'interpolates Color values' do
      kf1 = described_class.new(0.0, Bevy::Color.rgba(0.0, 0.0, 0.0, 1.0))
      kf2 = described_class.new(1.0, Bevy::Color.rgba(1.0, 1.0, 1.0, 1.0))

      result = kf1.interpolate_to(kf2, 0.5)
      expect(result.r).to eq(0.5)
      expect(result.g).to eq(0.5)
      expect(result.b).to eq(0.5)
    end

    it 'interpolates Array values' do
      kf1 = described_class.new(0.0, [0.0, 0.0])
      kf2 = described_class.new(1.0, [100.0, 200.0])

      result = kf1.interpolate_to(kf2, 0.5)
      expect(result).to eq([50.0, 100.0])
    end

    it 'applies easing during interpolation' do
      kf1 = described_class.new(0.0, 0.0, easing: :ease_in_quad)
      kf2 = described_class.new(1.0, 100.0)

      result = kf1.interpolate_to(kf2, 0.5)
      expect(result).to eq(25.0)
    end
  end
end

RSpec.describe Bevy::AnimationTrack do
  describe '.new' do
    it 'creates track for property' do
      track = described_class.new(:position_x)
      expect(track.property).to eq(:position_x)
      expect(track.keyframes).to be_empty
    end
  end

  describe '#add_keyframe' do
    it 'adds keyframes in order' do
      track = described_class.new(:x)
      track.add_keyframe(1.0, 100)
      track.add_keyframe(0.0, 0)
      track.add_keyframe(0.5, 50)

      expect(track.keyframes.map(&:time)).to eq([0.0, 0.5, 1.0])
    end

    it 'returns self for chaining' do
      track = described_class.new(:x)
      result = track.add_keyframe(0.0, 0)
      expect(result).to eq(track)
    end
  end

  describe '#duration' do
    it 'returns 0 for empty track' do
      track = described_class.new(:x)
      expect(track.duration).to eq(0.0)
    end

    it 'returns time of last keyframe' do
      track = described_class.new(:x)
      track.add_keyframe(0.0, 0)
      track.add_keyframe(2.0, 100)
      expect(track.duration).to eq(2.0)
    end
  end

  describe '#sample' do
    let(:track) do
      t = described_class.new(:x)
      t.add_keyframe(0.0, 0.0)
      t.add_keyframe(1.0, 100.0)
      t.add_keyframe(2.0, 50.0)
      t
    end

    it 'returns nil for empty track' do
      empty_track = described_class.new(:x)
      expect(empty_track.sample(0.5)).to be_nil
    end

    it 'returns first value before first keyframe' do
      expect(track.sample(-1.0)).to eq(0.0)
      expect(track.sample(0.0)).to eq(0.0)
    end

    it 'returns last value after last keyframe' do
      expect(track.sample(2.0)).to eq(50.0)
      expect(track.sample(3.0)).to eq(50.0)
    end

    it 'interpolates between keyframes' do
      expect(track.sample(0.5)).to eq(50.0)
      expect(track.sample(1.5)).to eq(75.0)
    end
  end
end

RSpec.describe Bevy::AnimationClip do
  describe '.new' do
    it 'creates clip with name' do
      clip = described_class.new('walk')
      expect(clip.name).to eq('walk')
      expect(clip.tracks).to be_empty
      expect(clip.repeat_mode).to eq(:once)
    end

    it 'creates clip with repeat mode' do
      clip = described_class.new('run', repeat_mode: :loop)
      expect(clip.repeat_mode).to eq(:loop)
    end
  end

  describe '#add_track' do
    it 'creates and returns a track' do
      clip = described_class.new('anim')
      track = clip.add_track(:position)
      expect(track).to be_a(Bevy::AnimationTrack)
      expect(clip.tracks[:position]).to eq(track)
    end
  end

  describe '#duration' do
    it 'returns max duration of all tracks' do
      clip = described_class.new('anim')
      clip.add_track(:x).add_keyframe(0.0, 0).add_keyframe(1.0, 100)
      clip.add_track(:y).add_keyframe(0.0, 0).add_keyframe(2.0, 100)
      expect(clip.duration).to eq(2.0)
    end
  end

  describe '#sample' do
    it 'samples all tracks at time' do
      clip = described_class.new('anim')
      clip.add_track(:x).add_keyframe(0.0, 0).add_keyframe(1.0, 100)
      clip.add_track(:y).add_keyframe(0.0, 0).add_keyframe(1.0, 200)

      result = clip.sample(0.5)
      expect(result[:x]).to eq(50.0)
      expect(result[:y]).to eq(100.0)
    end
  end

  describe '#type_name' do
    it 'returns AnimationClip' do
      clip = described_class.new('test')
      expect(clip.type_name).to eq('AnimationClip')
    end
  end
end

RSpec.describe Bevy::AnimationPlayer do
  let(:clip) do
    c = Bevy::AnimationClip.new('test')
    c.add_track(:x).add_keyframe(0.0, 0).add_keyframe(1.0, 100)
    c
  end

  describe '.new' do
    it 'creates player with no clips' do
      player = described_class.new
      expect(player.current_clip).to be_nil
      expect(player.elapsed).to eq(0.0)
      expect(player.speed).to eq(1.0)
    end
  end

  describe '#add_clip' do
    it 'adds a clip' do
      player = described_class.new
      player.add_clip(clip)
      expect(player.play('test').current_clip).to eq('test')
    end
  end

  describe '#play' do
    it 'starts playing a clip' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      expect(player.current_clip).to eq('test')
      expect(player.playing?).to be true
    end

    it 'restarts when restart: true' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.update(0.5)
      player.play('test', restart: true)
      expect(player.elapsed).to eq(0.0)
    end
  end

  describe '#pause and #resume' do
    it 'pauses and resumes playback' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.pause
      expect(player.playing?).to be false

      player.resume
      expect(player.playing?).to be true
    end
  end

  describe '#stop' do
    it 'stops playback' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.stop
      expect(player.current_clip).to be_nil
      expect(player.elapsed).to eq(0.0)
    end
  end

  describe '#update' do
    it 'advances elapsed time' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.update(0.3)
      expect(player.elapsed).to eq(0.3)
    end

    it 'respects speed' do
      player = described_class.new
      player.add_clip(clip)
      player.set_speed(2.0)
      player.play('test')
      player.update(0.25)
      expect(player.elapsed).to eq(0.5)
    end

    it 'stops at end for once mode' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.update(2.0)
      expect(player.current_clip).to be_nil
      expect(player.elapsed).to eq(1.0)
    end

    it 'loops for loop mode' do
      loop_clip = Bevy::AnimationClip.new('loop', repeat_mode: :loop)
      loop_clip.add_track(:x).add_keyframe(0.0, 0).add_keyframe(1.0, 100)

      player = described_class.new
      player.add_clip(loop_clip)
      player.play('loop')
      player.update(1.5)
      expect(player.elapsed).to eq(0.5)
      expect(player.current_clip).to eq('loop')
    end
  end

  describe '#sample' do
    it 'returns current values' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.update(0.5)

      result = player.sample
      expect(result[:x]).to eq(50.0)
    end
  end

  describe '#progress' do
    it 'returns progress as 0-1' do
      player = described_class.new
      player.add_clip(clip)
      player.play('test')
      player.update(0.5)
      expect(player.progress).to eq(0.5)
    end
  end

  describe '#on_finish' do
    it 'calls callback when animation finishes' do
      finished = false
      player = described_class.new
      player.add_clip(clip)
      player.on_finish { finished = true }
      player.play('test')
      player.update(2.0)
      expect(finished).to be true
    end
  end

  describe '#type_name' do
    it 'returns AnimationPlayer' do
      player = described_class.new
      expect(player.type_name).to eq('AnimationPlayer')
    end
  end
end

RSpec.describe Bevy::Tween do
  describe '.new' do
    it 'creates tween with from, to, duration' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      expect(tween.from).to eq(0.0)
      expect(tween.to).to eq(100.0)
      expect(tween.duration).to eq(1.0)
    end

    it 'creates tween with easing' do
      tween = described_class.new(from: 0, to: 100, duration: 1, easing: :ease_out_quad)
      expect(tween.easing).to eq(:ease_out_quad)
    end
  end

  describe '#update' do
    it 'advances elapsed time' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.update(0.3)
      expect(tween.progress).to be_within(0.01).of(0.3)
    end

    it 'respects delay' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0, delay: 0.5)
      tween.update(0.3)
      expect(tween.started?).to be false
      tween.update(0.3)
      expect(tween.started?).to be true
    end

    it 'marks as finished at end' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.update(2.0)
      expect(tween.finished?).to be true
    end

    it 'loops for loop mode' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0, repeat_mode: :loop)
      tween.update(1.5)
      expect(tween.finished?).to be false
      expect(tween.progress).to be_within(0.01).of(0.5)
    end
  end

  describe '#current_value' do
    it 'returns interpolated value' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.update(0.5)
      expect(tween.current_value).to eq(50.0)
    end

    it 'applies easing' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0, easing: :ease_in_quad)
      tween.update(0.5)
      expect(tween.current_value).to eq(25.0)
    end

    it 'interpolates Vec3' do
      tween = described_class.new(
        from: Bevy::Vec3.new(0.0, 0.0, 0.0),
        to: Bevy::Vec3.new(100.0, 200.0, 300.0),
        duration: 1.0
      )
      tween.update(0.5)
      result = tween.current_value
      expect(result.x).to eq(50.0)
      expect(result.y).to eq(100.0)
      expect(result.z).to eq(150.0)
    end
  end

  describe '#on_update' do
    it 'calls callback with current value' do
      values = []
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.on_update { |v| values << v }
      tween.update(0.5)
      expect(values.last).to eq(50.0)
    end
  end

  describe '#on_complete' do
    it 'calls callback when finished' do
      completed = false
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.on_complete { completed = true }
      tween.update(2.0)
      expect(completed).to be true
    end
  end

  describe '#reset' do
    it 'resets tween to initial state' do
      tween = described_class.new(from: 0.0, to: 100.0, duration: 1.0)
      tween.update(1.0)
      expect(tween.finished?).to be true
      tween.reset
      expect(tween.finished?).to be false
      expect(tween.progress).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns Tween' do
      tween = described_class.new(from: 0, to: 100, duration: 1)
      expect(tween.type_name).to eq('Tween')
    end
  end
end

RSpec.describe Bevy::TweenSequence do
  describe '.new' do
    it 'creates empty sequence' do
      seq = described_class.new
      expect(seq.finished?).to be false
    end
  end

  describe '#add' do
    it 'adds tweens to sequence' do
      seq = described_class.new
      seq.add(Bevy::Tween.new(from: 0, to: 100, duration: 1))
      seq.add(Bevy::Tween.new(from: 100, to: 200, duration: 1))
      expect(seq.finished?).to be false
    end
  end

  describe '#update' do
    it 'plays tweens in sequence' do
      seq = described_class.new
      seq.add(Bevy::Tween.new(from: 0.0, to: 100.0, duration: 1.0))
      seq.add(Bevy::Tween.new(from: 100.0, to: 200.0, duration: 1.0))

      seq.update(0.5)
      expect(seq.current_value).to eq(50.0)

      seq.update(0.6)
      expect(seq.current_value).to be_within(0.1).of(100.0)

      seq.update(0.5)
      expect(seq.current_value).to eq(150.0)
    end

    it 'marks as finished when all done' do
      seq = described_class.new
      seq.add(Bevy::Tween.new(from: 0, to: 100, duration: 1))
      seq.update(2.0)
      expect(seq.finished?).to be true
    end
  end

  describe '#type_name' do
    it 'returns TweenSequence' do
      seq = described_class.new
      expect(seq.type_name).to eq('TweenSequence')
    end
  end
end

RSpec.describe Bevy::TweenGroup do
  describe '.new' do
    it 'creates empty group' do
      group = described_class.new
      expect(group.finished?).to be true
    end
  end

  describe '#update' do
    it 'updates all tweens in parallel' do
      group = described_class.new
      group.add(Bevy::Tween.new(from: 0.0, to: 100.0, duration: 1.0))
      group.add(Bevy::Tween.new(from: 0.0, to: 50.0, duration: 1.0))

      group.update(0.5)
      values = group.values
      expect(values[0]).to eq(50.0)
      expect(values[1]).to eq(25.0)
    end
  end

  describe '#finished?' do
    it 'returns true when all tweens finished' do
      group = described_class.new
      group.add(Bevy::Tween.new(from: 0, to: 100, duration: 1))
      group.add(Bevy::Tween.new(from: 0, to: 100, duration: 2))

      group.update(1.5)
      expect(group.finished?).to be false

      group.update(1.0)
      expect(group.finished?).to be true
    end
  end

  describe '#type_name' do
    it 'returns TweenGroup' do
      group = described_class.new
      expect(group.type_name).to eq('TweenGroup')
    end
  end
end
