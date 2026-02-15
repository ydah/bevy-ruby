# frozen_string_literal: true

require 'bevy'
require 'tempfile'

module HotReloadDemo
  class JsonAssetLoader < Bevy::AssetLoader
    def initialize
      super(extensions: %w[json])
    end

    def load(path)
      return nil unless File.exist?(path)

      content = File.read(path)
      require 'json'
      JSON.parse(content)
    rescue JSON::ParserError
      nil
    end
  end

  def self.run
    puts '=== Hot Reload Demo ==='
    puts 'Demonstrating FileWatcher, AssetManager with hot reload, and HotReloadPlugin'
    puts

    puts '--- FileWatcher ---'

    watcher = Bevy::FileWatcher.new
    puts "FileWatcher created"
    puts "  poll_interval: #{watcher.poll_interval}s"
    puts "  watched_count: #{watcher.watched_count}"
    puts

    temp_file = Tempfile.new(['test_asset', '.txt'])
    temp_file.write('Initial content')
    temp_file.flush
    temp_path = temp_file.path

    puts "Created temp file: #{temp_path}"
    puts

    watcher.watch(temp_path)
    puts "Watching file..."
    puts "  watching?: #{watcher.watching?(temp_path)}"
    puts "  watched_count: #{watcher.watched_count}"
    puts

    changes = watcher.check_changes
    puts "Initial check (no changes): #{changes.empty? ? 'no changes' : changes}"
    puts

    sleep(0.1)
    File.write(temp_path, 'Modified content!')
    puts "Modified file content"

    changes = watcher.check_changes
    if changes.any?
      puts "Detected changes:"
      changes.each do |path, change_type|
        puts "  #{change_type}: #{File.basename(path)}"
      end
    end
    puts

    watcher.unwatch(temp_path)
    puts "Unwatched file, watched_count: #{watcher.watched_count}"
    puts

    puts '--- AssetManager with Hot Reload ---'

    manager = Bevy::AssetManager.new
    puts "AssetManager created"
    puts "  hot_reload_enabled: #{manager.hot_reload_enabled}"
    puts

    manager.enable_hot_reload
    puts "Hot reload enabled: #{manager.hot_reload_enabled}"
    puts

    puts "Loading assets:"

    image_handle = manager.load('textures/player.png')
    puts "  Loaded image: #{image_handle}"
    puts "    state: #{manager.get_state(image_handle)}"

    audio_handle = manager.load('sounds/jump.wav')
    puts "  Loaded audio: #{audio_handle}"
    puts "    state: #{manager.get_state(audio_handle)}"

    font_handle = manager.load('fonts/main.ttf')
    puts "  Loaded font: #{font_handle}"
    puts "    state: #{manager.get_state(font_handle)}"
    puts

    puts "Registering reload callbacks:"
    manager.on_reload(image_handle) do |handle|
      puts "  [Callback] Image reloaded: #{handle.path}"
    end
    puts "  Registered callback for image_handle"
    puts

    puts "Adding asset dependencies:"
    material_handle = manager.load('materials/player.json')
    manager.add_dependency(material_handle, image_handle)
    puts "  material depends on image (when image reloads, material will too)"
    puts

    puts "Checking for changes (simulated):"
    events = manager.check_for_changes
    puts "  Events: #{events.length} (#{events.empty? ? 'none' : events.map { |e| e.type }})"
    puts

    manager.disable_hot_reload
    puts "Hot reload disabled: #{manager.hot_reload_enabled}"
    puts

    puts '--- HotReloadPlugin ---'

    plugin = Bevy::HotReloadPlugin.new(poll_interval: 0.5)
    puts "HotReloadPlugin created"
    puts "  poll_interval: 0.5s"
    puts

    puts "Plugin workflow:"
    puts "  1. plugin.build(app) - enables hot reload on app's asset manager"
    puts "  2. plugin.update(app, delta) - checks for file changes periodically"
    puts "  3. Modified files trigger reload and callbacks"
    puts

    puts '--- Custom Asset Loader ---'

    puts "JsonAssetLoader defined (at module level)"
    puts "  extensions: #{JsonAssetLoader.new.extensions}"
    puts

    custom_manager = Bevy::AssetManager.new
    custom_manager.register_loader('JsonAsset', JsonAssetLoader.new)
    puts "Registered custom loader for 'JsonAsset' type"
    puts

    puts '--- Asset Loading States ---'
    puts "AssetState::NOT_LOADED = #{Bevy::AssetState::NOT_LOADED}"
    puts "AssetState::LOADING = #{Bevy::AssetState::LOADING}"
    puts "AssetState::LOADED = #{Bevy::AssetState::LOADED}"
    puts "AssetState::FAILED = #{Bevy::AssetState::FAILED}"
    puts

    puts '--- AssetEvent Types ---'
    puts "AssetEvent::CREATED = #{Bevy::AssetEvent::CREATED}"
    puts "AssetEvent::MODIFIED = #{Bevy::AssetEvent::MODIFIED}"
    puts "AssetEvent::REMOVED = #{Bevy::AssetEvent::REMOVED}"
    puts "AssetEvent::LOADED = #{Bevy::AssetEvent::LOADED}"
    puts "AssetEvent::FAILED = #{Bevy::AssetEvent::FAILED}"
    puts

    puts '--- AssetPath Parsing ---'
    path = Bevy::AssetPath.parse('models/scene.gltf#Mesh0')
    puts "AssetPath.parse('models/scene.gltf#Mesh0'):"
    puts "  path: #{path.path}"
    puts "  label: #{path.label}"
    puts "  full_path: #{path.full_path}"
    puts "  extension: #{path.extension}"
    puts "  file_name: #{path.file_name}"
    puts "  parent: #{path.parent}"
    puts

    temp_file.close
    temp_file.unlink

    puts '=== Demo Complete ==='
  end
end

HotReloadDemo.run
