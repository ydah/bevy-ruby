# frozen_string_literal: true

require 'tempfile'

RSpec.describe Bevy::AssetState do
  it 'defines asset states' do
    expect(Bevy::AssetState::NOT_LOADED).to eq('NotLoaded')
    expect(Bevy::AssetState::LOADING).to eq('Loading')
    expect(Bevy::AssetState::LOADED).to eq('Loaded')
    expect(Bevy::AssetState::FAILED).to eq('Failed')
  end
end

RSpec.describe Bevy::Handle do
  describe '.new' do
    it 'creates a handle with id and type' do
      handle = described_class.new(id: 1, type_name: 'Image')
      expect(handle.id).to eq(1)
      expect(handle.type_name).to eq('Image')
    end

    it 'creates a handle with optional path' do
      handle = described_class.new(id: 1, type_name: 'Image', path: 'textures/player.png')
      expect(handle.path).to eq('textures/player.png')
    end
  end

  describe '#strong? and #weak?' do
    it 'defaults to strong handle' do
      handle = described_class.new(id: 1, type_name: 'Image')
      expect(handle.strong?).to be true
      expect(handle.weak?).to be false
    end
  end

  describe '#==' do
    it 'compares by id and type' do
      h1 = described_class.new(id: 1, type_name: 'Image')
      h2 = described_class.new(id: 1, type_name: 'Image')
      h3 = described_class.new(id: 2, type_name: 'Image')
      h4 = described_class.new(id: 1, type_name: 'AudioSource')

      expect(h1).to eq(h2)
      expect(h1).not_to eq(h3)
      expect(h1).not_to eq(h4)
    end
  end

  describe '#to_s' do
    it 'returns a string representation' do
      handle = described_class.new(id: 5, type_name: 'Image')
      expect(handle.to_s).to eq('Handle<Image>(5)')
    end
  end
end

RSpec.describe Bevy::AssetServer do
  let(:server) { described_class.new }

  describe '#load' do
    it 'creates a handle for the asset' do
      handle = server.load('textures/player.png')
      expect(handle).to be_a(Bevy::Handle)
      expect(handle.type_name).to eq('Image')
      expect(handle.path).to eq('textures/player.png')
    end

    it 'infers type from extension' do
      expect(server.load('music.ogg').type_name).to eq('AudioSource')
      expect(server.load('font.ttf').type_name).to eq('Font')
      expect(server.load('model.gltf').type_name).to eq('Gltf')
      expect(server.load('data.json').type_name).to eq('JsonAsset')
    end

    it 'returns the same handle for the same path' do
      h1 = server.load('test.png')
      h2 = server.load('test.png')
      expect(h1).to eq(h2)
    end

    it 'allows explicit type name' do
      handle = server.load('custom.dat', 'CustomAsset')
      expect(handle.type_name).to eq('CustomAsset')
    end
  end

  describe '#load_async' do
    it 'marks the asset as loading' do
      handle = server.load_async('test.png')
      expect(server.loading?(handle)).to be true
    end
  end

  describe '#get_state' do
    it 'returns the asset state' do
      handle = server.load('test.png')
      expect(server.get_state(handle)).to eq(Bevy::AssetState::NOT_LOADED)
    end
  end

  describe '#set_loaded' do
    it 'marks asset as loaded and stores the asset' do
      handle = server.load('test.png')
      asset = { data: 'image_data' }
      server.set_loaded(handle, asset)

      expect(server.loaded?(handle)).to be true
      expect(server.get(handle)).to eq(asset)
    end
  end

  describe '#set_failed' do
    it 'marks asset as failed' do
      handle = server.load('missing.png')
      server.set_failed(handle)
      expect(server.failed?(handle)).to be true
    end
  end

  describe '#get_handle' do
    it 'returns handle by path' do
      server.load('test.png')
      handle = server.get_handle('test.png')
      expect(handle).to be_a(Bevy::Handle)
    end

    it 'returns nil for unknown path' do
      expect(server.get_handle('unknown.png')).to be_nil
    end
  end

  describe '#all_handles' do
    it 'returns all handles' do
      server.load('a.png')
      server.load('b.ogg')
      expect(server.all_handles.length).to eq(2)
    end
  end

  describe '#loaded_handles' do
    it 'returns only loaded handles' do
      h1 = server.load('a.png')
      _h2 = server.load('b.png')
      server.set_loaded(h1, {})

      loaded = server.loaded_handles
      expect(loaded.length).to eq(1)
      expect(loaded.first).to eq(h1)
    end
  end

  describe '#pending_handles' do
    it 'returns only loading handles' do
      h1 = server.load_async('a.png')
      server.load('b.png')

      pending = server.pending_handles
      expect(pending.length).to eq(1)
      expect(pending.first).to eq(h1)
    end
  end
end

RSpec.describe Bevy::Assets do
  let(:assets) { described_class.new('TestAsset') }

  describe '#add' do
    it 'adds an asset and returns a handle' do
      handle = assets.add({ name: 'test' })
      expect(handle).to be_a(Bevy::Handle)
      expect(handle.type_name).to eq('TestAsset')
    end
  end

  describe '#get' do
    it 'retrieves an asset by handle' do
      asset = { name: 'test' }
      handle = assets.add(asset)
      expect(assets.get(handle)).to eq(asset)
    end

    it 'returns nil for wrong type' do
      handle = Bevy::Handle.new(id: 0, type_name: 'OtherType')
      assets.add({})
      expect(assets.get(handle)).to be_nil
    end
  end

  describe '#remove' do
    it 'removes an asset' do
      handle = assets.add({})
      assets.remove(handle)
      expect(assets.contains?(handle)).to be false
    end
  end

  describe '#contains?' do
    it 'checks if asset exists' do
      handle = assets.add({})
      expect(assets.contains?(handle)).to be true
    end
  end

  describe '#iter' do
    it 'iterates over all assets' do
      assets.add({ a: 1 })
      assets.add({ b: 2 })
      pairs = assets.iter
      expect(pairs.length).to eq(2)
      expect(pairs.first.first).to be_a(Bevy::Handle)
    end
  end

  describe '#each' do
    it 'yields handle and asset pairs' do
      assets.add({ x: 1 })
      count = 0
      assets.each { |_h, _a| count += 1 }
      expect(count).to eq(1)
    end
  end

  describe '#len and #empty?' do
    it 'returns count and empty status' do
      expect(assets.empty?).to be true
      expect(assets.len).to eq(0)

      assets.add({})
      expect(assets.empty?).to be false
      expect(assets.len).to eq(1)
    end
  end
end

RSpec.describe Bevy::AssetPath do
  describe '.new' do
    it 'creates a path without label' do
      path = described_class.new('textures/player.png')
      expect(path.path).to eq('textures/player.png')
      expect(path.label).to be_nil
    end

    it 'creates a path with label' do
      path = described_class.new('models/scene.gltf', label: 'Mesh0')
      expect(path.path).to eq('models/scene.gltf')
      expect(path.label).to eq('Mesh0')
    end
  end

  describe '.parse' do
    it 'parses path without label' do
      path = described_class.parse('textures/player.png')
      expect(path.path).to eq('textures/player.png')
      expect(path.label).to be_nil
    end

    it 'parses path with label' do
      path = described_class.parse('models/scene.gltf#Mesh0')
      expect(path.path).to eq('models/scene.gltf')
      expect(path.label).to eq('Mesh0')
    end
  end

  describe '#full_path' do
    it 'returns path without label' do
      path = described_class.new('test.png')
      expect(path.full_path).to eq('test.png')
    end

    it 'returns path with label' do
      path = described_class.new('test.gltf', label: 'Scene')
      expect(path.full_path).to eq('test.gltf#Scene')
    end
  end

  describe '#extension' do
    it 'returns the file extension' do
      path = described_class.new('textures/player.png')
      expect(path.extension).to eq('png')
    end
  end

  describe '#file_name' do
    it 'returns the file name' do
      path = described_class.new('textures/player.png')
      expect(path.file_name).to eq('player.png')
    end
  end

  describe '#parent' do
    it 'returns the parent directory' do
      path = described_class.new('textures/player.png')
      expect(path.parent).to eq('textures')
    end
  end

  describe '#==' do
    it 'compares paths' do
      p1 = described_class.new('test.png')
      p2 = described_class.new('test.png')
      p3 = described_class.new('other.png')
      p4 = described_class.new('test.png', label: 'Label')

      expect(p1).to eq(p2)
      expect(p1).not_to eq(p3)
      expect(p1).not_to eq(p4)
    end
  end

  describe '#to_s' do
    it 'returns the full path string' do
      path = described_class.new('test.gltf', label: 'Mesh')
      expect(path.to_s).to eq('test.gltf#Mesh')
    end
  end
end

RSpec.describe Bevy::AssetEvent do
  let(:handle) { Bevy::Handle.new(id: 1, type_name: 'Image') }

  describe '.new' do
    it 'creates an event with type and handle' do
      event = described_class.new(Bevy::AssetEvent::LOADED, handle)
      expect(event.type).to eq(:loaded)
      expect(event.handle).to eq(handle)
    end
  end

  describe 'type predicates' do
    it 'checks event type' do
      expect(described_class.new(Bevy::AssetEvent::CREATED, handle).created?).to be true
      expect(described_class.new(Bevy::AssetEvent::MODIFIED, handle).modified?).to be true
      expect(described_class.new(Bevy::AssetEvent::REMOVED, handle).removed?).to be true
      expect(described_class.new(Bevy::AssetEvent::LOADED, handle).loaded?).to be true
      expect(described_class.new(Bevy::AssetEvent::FAILED, handle).failed?).to be true
    end
  end
end

RSpec.describe Bevy::AssetLoader do
  describe '.new' do
    it 'creates a loader with extensions' do
      loader = described_class.new(extensions: %w[png jpg])
      expect(loader.extensions).to eq(%w[png jpg])
    end
  end

  describe '#can_load?' do
    it 'checks if loader can handle file type' do
      loader = described_class.new(extensions: %w[png jpg])
      expect(loader.can_load?('test.png')).to be true
      expect(loader.can_load?('test.PNG')).to be true
      expect(loader.can_load?('test.gif')).to be false
    end
  end

  describe '#load' do
    it 'raises NotImplementedError' do
      loader = described_class.new(extensions: ['png'])
      expect { loader.load('test.png') }.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe Bevy::ImageAsset do
  describe '.new' do
    it 'creates an image asset with path' do
      asset = described_class.new(path: 'textures/player.png')
      expect(asset.path).to eq('textures/player.png')
      expect(asset.width).to eq(0)
      expect(asset.height).to eq(0)
    end

    it 'creates an image asset with dimensions' do
      asset = described_class.new(path: 'test.png', width: 256, height: 128)
      expect(asset.width).to eq(256)
      expect(asset.height).to eq(128)
    end
  end

  describe '#loaded?' do
    it 'returns false when no data' do
      asset = described_class.new(path: 'test.png')
      expect(asset.loaded?).to be false
    end

    it 'returns true when data exists' do
      asset = described_class.new(path: 'test.png', data: 'binary_data')
      expect(asset.loaded?).to be true
    end
  end

  describe '#aspect_ratio' do
    it 'calculates aspect ratio' do
      asset = described_class.new(path: 'test.png', width: 1920, height: 1080)
      expect(asset.aspect_ratio).to be_within(0.01).of(1.78)
    end

    it 'returns 1.0 when height is zero' do
      asset = described_class.new(path: 'test.png', width: 100, height: 0)
      expect(asset.aspect_ratio).to eq(1.0)
    end
  end
end

RSpec.describe Bevy::FontAsset do
  describe '.new' do
    it 'creates a font asset with path' do
      asset = described_class.new(path: 'fonts/roboto.ttf')
      expect(asset.path).to eq('fonts/roboto.ttf')
      expect(asset.family).to eq('roboto')
    end

    it 'uses provided family name' do
      asset = described_class.new(path: 'fonts/roboto.ttf', family: 'Roboto')
      expect(asset.family).to eq('Roboto')
    end
  end
end

RSpec.describe Bevy::AudioAsset do
  describe '.new' do
    it 'creates an audio asset with path' do
      asset = described_class.new(path: 'sounds/music.ogg')
      expect(asset.path).to eq('sounds/music.ogg')
      expect(asset.duration).to eq(0.0)
    end

    it 'creates with duration' do
      asset = described_class.new(path: 'music.ogg', duration: 180.5)
      expect(asset.duration).to eq(180.5)
    end
  end
end

RSpec.describe Bevy::ImageLoader do
  let(:loader) { described_class.new }

  describe '#extensions' do
    it 'includes common image formats' do
      expect(loader.extensions).to include('png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp')
    end
  end

  describe '#can_load?' do
    it 'returns true for image files' do
      expect(loader.can_load?('test.png')).to be true
      expect(loader.can_load?('test.jpg')).to be true
    end

    it 'returns false for non-image files' do
      expect(loader.can_load?('test.ogg')).to be false
    end
  end

  describe '#load' do
    it 'returns nil for non-existent file' do
      expect(loader.load('nonexistent.png')).to be_nil
    end
  end
end

RSpec.describe Bevy::FontLoader do
  let(:loader) { described_class.new }

  describe '#extensions' do
    it 'includes common font formats' do
      expect(loader.extensions).to include('ttf', 'otf', 'woff', 'woff2')
    end
  end

  describe '#can_load?' do
    it 'returns true for font files' do
      expect(loader.can_load?('test.ttf')).to be true
      expect(loader.can_load?('test.otf')).to be true
    end
  end
end

RSpec.describe Bevy::AudioLoader do
  let(:loader) { described_class.new }

  describe '#extensions' do
    it 'includes common audio formats' do
      expect(loader.extensions).to include('ogg', 'wav', 'mp3', 'flac')
    end
  end

  describe '#can_load?' do
    it 'returns true for audio files' do
      expect(loader.can_load?('music.ogg')).to be true
      expect(loader.can_load?('sound.wav')).to be true
    end
  end
end

RSpec.describe Bevy::FileWatcher do
  let(:watcher) { described_class.new }
  let(:tmpfile) { Tempfile.new(['test', '.txt']) }

  after do
    tmpfile.close
    tmpfile.unlink
  end

  describe '.new' do
    it 'creates with default poll interval' do
      expect(watcher.poll_interval).to eq(1.0)
    end
  end

  describe '#poll_interval=' do
    it 'sets the poll interval' do
      watcher.poll_interval = 0.5
      expect(watcher.poll_interval).to eq(0.5)
    end
  end

  describe '#watch' do
    it 'adds a file to watch list' do
      watcher.watch(tmpfile.path)
      expect(watcher.watching?(tmpfile.path)).to be true
      expect(watcher.watched_count).to eq(1)
    end

    it 'does not watch non-existent files' do
      watcher.watch('/nonexistent/file.txt')
      expect(watcher.watched_count).to eq(0)
    end
  end

  describe '#unwatch' do
    it 'removes a file from watch list' do
      watcher.watch(tmpfile.path)
      watcher.unwatch(tmpfile.path)
      expect(watcher.watching?(tmpfile.path)).to be false
    end
  end

  describe '#check_changes' do
    it 'returns empty when no changes' do
      watcher.watch(tmpfile.path)
      changes = watcher.check_changes
      expect(changes).to be_empty
    end

    it 'detects file modification' do
      watcher.watch(tmpfile.path)
      sleep(0.1)
      File.write(tmpfile.path, 'updated content')

      changes = watcher.check_changes
      expect(changes.length).to eq(1)
      expect(changes.first[0]).to eq(tmpfile.path)
      expect(changes.first[1]).to eq(:modified)
    end

    it 'detects file deletion' do
      path = tmpfile.path
      watcher.watch(path)
      tmpfile.close
      tmpfile.unlink

      changes = watcher.check_changes
      expect(changes.length).to eq(1)
      expect(changes.first[0]).to eq(path)
      expect(changes.first[1]).to eq(:deleted)
    end
  end

  describe '#watched_count' do
    it 'returns number of watched files' do
      expect(watcher.watched_count).to eq(0)

      tmpfile2 = Tempfile.new(['test2', '.txt'])
      watcher.watch(tmpfile.path)
      watcher.watch(tmpfile2.path)
      expect(watcher.watched_count).to eq(2)
      tmpfile2.close
      tmpfile2.unlink
    end
  end

  describe '#watching?' do
    it 'checks if file is being watched' do
      expect(watcher.watching?(tmpfile.path)).to be false
      watcher.watch(tmpfile.path)
      expect(watcher.watching?(tmpfile.path)).to be true
    end
  end
end

RSpec.describe Bevy::AssetManager do
  let(:manager) { described_class.new }

  describe '.new' do
    it 'creates with default loaders' do
      expect(manager.asset_server).to be_a(Bevy::AssetServer)
    end
  end

  describe '#hot_reload_enabled' do
    it 'defaults to disabled' do
      expect(manager.hot_reload_enabled).to be false
    end
  end

  describe '#enable_hot_reload' do
    it 'enables hot reload' do
      manager.enable_hot_reload
      expect(manager.hot_reload_enabled).to be true
    end
  end

  describe '#disable_hot_reload' do
    it 'disables hot reload' do
      manager.enable_hot_reload
      manager.disable_hot_reload
      expect(manager.hot_reload_enabled).to be false
    end
  end

  describe '#register_loader' do
    it 'registers a custom loader' do
      custom_loader = Bevy::AssetLoader.new(extensions: ['custom'])
      manager.register_loader('Custom', custom_loader)
    end
  end

  describe '#load' do
    it 'returns a handle' do
      handle = manager.load('nonexistent.png')
      expect(handle).to be_a(Bevy::Handle)
    end

    it 'marks as failed for non-existent files' do
      handle = manager.load('nonexistent.png')
      expect(manager.failed?(handle)).to be true
    end
  end

  describe '#on_reload' do
    it 'registers a reload callback' do
      handle = manager.load('test.png')
      callback_called = false
      manager.on_reload(handle) { callback_called = true }
    end
  end

  describe '#add_dependency' do
    it 'adds a dependency between assets' do
      h1 = manager.load('texture.png')
      h2 = manager.load('material.json')
      manager.add_dependency(h2, h1)
    end
  end

  describe '#get' do
    it 'returns nil for non-existent asset' do
      handle = manager.load('missing.png')
      expect(manager.get(handle)).to be_nil
    end
  end

  describe '#loaded?' do
    it 'returns false for non-loaded assets' do
      handle = manager.load('missing.png')
      expect(manager.loaded?(handle)).to be false
    end
  end

  describe '#loading?' do
    it 'returns false for non-loading assets' do
      handle = manager.load('test.png')
      expect(manager.loading?(handle)).to be false
    end
  end

  describe '#get_state' do
    it 'returns the asset state' do
      handle = manager.load('test.png')
      state = manager.get_state(handle)
      expect([Bevy::AssetState::LOADED, Bevy::AssetState::FAILED]).to include(state)
    end
  end

  describe '#unload' do
    it 'unloads an asset' do
      handle = manager.load('test.png')
      manager.unload(handle)
    end
  end

  describe '#check_for_changes' do
    it 'returns empty when hot reload disabled' do
      events = manager.check_for_changes
      expect(events).to be_empty
    end

    it 'returns events when hot reload enabled' do
      manager.enable_hot_reload
      events = manager.check_for_changes
      expect(events).to be_an(Array)
    end
  end
end

RSpec.describe Bevy::HotReloadPlugin do
  describe '.new' do
    it 'creates with default poll interval' do
      plugin = described_class.new
      expect(plugin.instance_variable_get(:@poll_interval)).to eq(1.0)
    end

    it 'creates with custom poll interval' do
      plugin = described_class.new(poll_interval: 0.5)
      expect(plugin.instance_variable_get(:@poll_interval)).to eq(0.5)
    end
  end

  describe '#build' do
    it 'enables hot reload on the app asset manager' do
      app = double('App')
      asset_manager = Bevy::AssetManager.new
      file_watcher = asset_manager.instance_variable_get(:@file_watcher)

      allow(app).to receive(:asset_manager).and_return(asset_manager)

      plugin = described_class.new(poll_interval: 2.0)
      plugin.build(app)

      expect(asset_manager.hot_reload_enabled).to be true
      expect(file_watcher.poll_interval).to eq(2.0)
    end
  end

  describe '#update' do
    it 'checks for changes after poll interval' do
      app = double('App')
      asset_manager = Bevy::AssetManager.new
      asset_manager.enable_hot_reload

      allow(app).to receive(:asset_manager).and_return(asset_manager)
      allow(asset_manager).to receive(:check_for_changes).and_return([])

      plugin = described_class.new(poll_interval: 0.0)
      plugin.instance_variable_set(:@last_check, ::Time.now - 1)
      plugin.update(app, 0.016)
    end

    it 'skips check within poll interval' do
      app = double('App')
      asset_manager = Bevy::AssetManager.new

      allow(app).to receive(:asset_manager).and_return(asset_manager)
      expect(asset_manager).not_to receive(:check_for_changes)

      plugin = described_class.new(poll_interval: 10.0)
      plugin.update(app, 0.016)
    end
  end
end
