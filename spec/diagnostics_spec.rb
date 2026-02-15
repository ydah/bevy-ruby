# frozen_string_literal: true

RSpec.describe Bevy::DiagnosticsStore do
  describe '.new' do
    it 'creates empty store' do
      store = described_class.new
      expect(store.diagnostics).to be_empty
    end
  end

  describe '#add' do
    it 'adds diagnostic' do
      store = described_class.new
      diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS')
      store.add(diagnostic)
      expect(store.diagnostics.size).to eq(1)
    end

    it 'returns self for chaining' do
      store = described_class.new
      diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS')
      result = store.add(diagnostic)
      expect(result).to eq(store)
    end
  end

  describe '#get' do
    it 'retrieves diagnostic by id' do
      store = described_class.new
      diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS')
      store.add(diagnostic)
      expect(store.get('fps')).to eq(diagnostic)
    end

    it 'returns nil for unknown id' do
      store = described_class.new
      expect(store.get('unknown')).to be_nil
    end
  end

  describe '#remove' do
    it 'removes diagnostic by id' do
      store = described_class.new
      diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS')
      store.add(diagnostic)
      store.remove('fps')
      expect(store.diagnostics).to be_empty
    end
  end

  describe '#get_measurement' do
    it 'returns average measurement' do
      store = described_class.new
      diagnostic = Bevy::Diagnostic.new(id: 'fps', name: 'FPS')
      diagnostic.add_measurement(60.0)
      diagnostic.add_measurement(58.0)
      store.add(diagnostic)
      expect(store.get_measurement('fps')).to be_within(0.1).of(59.0)
    end

    it 'returns nil for unknown id' do
      store = described_class.new
      expect(store.get_measurement('unknown')).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns DiagnosticsStore' do
      expect(described_class.new.type_name).to eq('DiagnosticsStore')
    end
  end
end

RSpec.describe Bevy::Diagnostic do
  describe '.new' do
    it 'creates diagnostic with id and name' do
      d = described_class.new(id: 'fps', name: 'FPS')
      expect(d.id).to eq('fps')
      expect(d.name).to eq('FPS')
      expect(d.suffix).to eq('')
      expect(d.history).to be_empty
    end

    it 'accepts custom suffix' do
      d = described_class.new(id: 'fps', name: 'FPS', suffix: ' fps')
      expect(d.suffix).to eq(' fps')
    end
  end

  describe '#add_measurement' do
    it 'adds measurements to history' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(100.0)
      d.add_measurement(200.0)
      expect(d.history.size).to eq(2)
    end

    it 'respects max_history limit' do
      d = described_class.new(id: 'test', name: 'Test', max_history: 3)
      5.times { |i| d.add_measurement(i.to_f) }
      expect(d.history.size).to eq(3)
    end
  end

  describe '#value' do
    it 'returns most recent value' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(10.0)
      d.add_measurement(20.0)
      expect(d.value).to eq(20.0)
    end

    it 'returns nil when empty' do
      d = described_class.new(id: 'test', name: 'Test')
      expect(d.value).to be_nil
    end
  end

  describe '#average' do
    it 'calculates average of all measurements' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(60.0)
      d.add_measurement(40.0)
      expect(d.average).to eq(50.0)
    end

    it 'returns nil when empty' do
      d = described_class.new(id: 'test', name: 'Test')
      expect(d.average).to be_nil
    end
  end

  describe '#smoothed' do
    it 'returns smoothed value from last 10 measurements' do
      d = described_class.new(id: 'test', name: 'Test')
      15.times { |i| d.add_measurement(i.to_f) }
      expect(d.smoothed).to be_a(Float)
    end

    it 'returns nil with fewer than 2 measurements' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(50.0)
      expect(d.smoothed).to be_nil
    end
  end

  describe '#clear_history' do
    it 'clears all measurements' do
      d = described_class.new(id: 'test', name: 'Test')
      d.add_measurement(100.0)
      d.clear_history
      expect(d.history).to be_empty
    end
  end

  describe '#type_name' do
    it 'returns Diagnostic' do
      expect(described_class.new(id: 'test', name: 'Test').type_name).to eq('Diagnostic')
    end
  end
end

RSpec.describe Bevy::FrameTimeDiagnostics do
  describe '.new' do
    it 'creates frame time diagnostics' do
      ftd = described_class.new
      expect(ftd.fps).to be_a(Bevy::Diagnostic)
      expect(ftd.frame_time).to be_a(Bevy::Diagnostic)
      expect(ftd.frame_count).to eq(0)
    end
  end

  describe '#update' do
    it 'updates frame count and diagnostics' do
      ftd = described_class.new
      ftd.update
      expect(ftd.frame_count).to eq(1)
      expect(ftd.frame_time.value).not_to be_nil
    end

    it 'calculates fps from delta' do
      ftd = described_class.new
      sleep(0.01)
      ftd.update
      expect(ftd.fps.value).to be_a(Float)
    end
  end

  describe '#diagnostics' do
    it 'returns array of diagnostics' do
      ftd = described_class.new
      expect(ftd.diagnostics).to include(ftd.fps, ftd.frame_time)
    end
  end

  describe '#type_name' do
    it 'returns FrameTimeDiagnostics' do
      expect(described_class.new.type_name).to eq('FrameTimeDiagnostics')
    end
  end
end

RSpec.describe Bevy::EntityCountDiagnostics do
  describe '.new' do
    it 'creates entity count diagnostic' do
      ecd = described_class.new
      expect(ecd.entity_count).to be_a(Bevy::Diagnostic)
    end
  end

  describe '#update' do
    it 'updates entity count from world' do
      ecd = described_class.new
      world = double('World', entity_count: 42)
      ecd.update(world)
      expect(ecd.entity_count.value).to eq(42)
    end

    it 'handles world without entity_count method' do
      ecd = described_class.new
      world = Object.new
      ecd.update(world)
      expect(ecd.entity_count.value).to eq(0)
    end
  end

  describe '#diagnostics' do
    it 'returns array with entity count diagnostic' do
      ecd = described_class.new
      expect(ecd.diagnostics).to include(ecd.entity_count)
    end
  end

  describe '#type_name' do
    it 'returns EntityCountDiagnostics' do
      expect(described_class.new.type_name).to eq('EntityCountDiagnostics')
    end
  end
end

RSpec.describe Bevy::SystemDiagnostics do
  describe '.new' do
    it 'creates empty system timings' do
      sd = described_class.new
      expect(sd.system_timings).to be_empty
    end
  end

  describe '#start_system and #end_system' do
    it 'measures system execution time' do
      sd = described_class.new
      sd.start_system('movement')
      sleep(0.001)
      sd.end_system('movement')
      expect(sd.system_timings['movement'].value).to be >= 0
    end

    it 'creates diagnostic for new systems' do
      sd = described_class.new
      sd.start_system('physics')
      expect(sd.system_timings['physics']).to be_a(Bevy::Diagnostic)
    end
  end

  describe '#diagnostics' do
    it 'returns all system diagnostics' do
      sd = described_class.new
      sd.start_system('a')
      sd.end_system('a')
      sd.start_system('b')
      sd.end_system('b')
      expect(sd.diagnostics.size).to eq(2)
    end
  end

  describe '#type_name' do
    it 'returns SystemDiagnostics' do
      expect(described_class.new.type_name).to eq('SystemDiagnostics')
    end
  end
end

RSpec.describe Bevy::LogDiagnostics do
  describe '.new' do
    it 'creates enabled log diagnostics' do
      ld = described_class.new
      expect(ld.enabled).to be true
      expect(ld.wait_duration).to eq(1.0)
    end

    it 'accepts custom wait duration' do
      ld = described_class.new(wait_duration: 2.5)
      expect(ld.wait_duration).to eq(2.5)
    end
  end

  describe '#log' do
    it 'respects enabled flag' do
      ld = described_class.new
      ld.enabled = false
      store = Bevy::DiagnosticsStore.new
      expect { ld.log(store) }.not_to output.to_stdout
    end
  end

  describe '#type_name' do
    it 'returns LogDiagnostics' do
      expect(described_class.new.type_name).to eq('LogDiagnostics')
    end
  end
end

RSpec.describe Bevy::PerformanceMetrics do
  describe '.new' do
    it 'creates with zero values' do
      pm = described_class.new
      expect(pm.draw_calls).to eq(0)
      expect(pm.triangles).to eq(0)
      expect(pm.vertices).to eq(0)
      expect(pm.textures_bound).to eq(0)
    end
  end

  describe '#reset' do
    it 'resets all counters to zero' do
      pm = described_class.new
      pm.add_draw_call(triangles: 100, vertices: 300)
      pm.bind_texture
      pm.reset
      expect(pm.draw_calls).to eq(0)
      expect(pm.triangles).to eq(0)
      expect(pm.vertices).to eq(0)
      expect(pm.textures_bound).to eq(0)
    end
  end

  describe '#add_draw_call' do
    it 'increments draw calls and adds geometry counts' do
      pm = described_class.new
      pm.add_draw_call(triangles: 100, vertices: 300)
      pm.add_draw_call(triangles: 50, vertices: 150)
      expect(pm.draw_calls).to eq(2)
      expect(pm.triangles).to eq(150)
      expect(pm.vertices).to eq(450)
    end
  end

  describe '#bind_texture' do
    it 'increments texture bind count' do
      pm = described_class.new
      pm.bind_texture
      pm.bind_texture
      expect(pm.textures_bound).to eq(2)
    end
  end

  describe '#type_name' do
    it 'returns PerformanceMetrics' do
      expect(described_class.new.type_name).to eq('PerformanceMetrics')
    end
  end
end
