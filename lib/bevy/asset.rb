# frozen_string_literal: true

module Bevy
  module AssetState
    NOT_LOADED = 'NotLoaded'
    LOADING = 'Loading'
    LOADED = 'Loaded'
    FAILED = 'Failed'
  end

  class Handle
    attr_reader :id, :type_name, :path

    def initialize(id:, type_name:, path: nil)
      @id = id
      @type_name = type_name
      @path = path
    end

    def strong?
      true
    end

    def weak?
      false
    end

    def ==(other)
      return false unless other.is_a?(Handle)

      @id == other.id && @type_name == other.type_name
    end

    def eql?(other)
      self == other
    end

    def hash
      [@id, @type_name].hash
    end

    def to_s
      "Handle<#{@type_name}>(#{@id})"
    end

    def inspect
      "#<#{self.class} id=#{@id} type=#{@type_name} path=#{@path.inspect}>"
    end
  end

  class AssetServer
    def initialize
      @next_id = 0
      @assets = {}
      @handles = {}
      @states = {}
    end

    def load(path, type_name = nil)
      type_name ||= infer_type(path)
      return @handles[path] if @handles.key?(path)

      id = generate_id
      handle = Handle.new(id: id, type_name: type_name, path: path)
      @handles[path] = handle
      @states[id] = AssetState::NOT_LOADED
      handle
    end

    def load_async(path, type_name = nil)
      handle = load(path, type_name)
      @states[handle.id] = AssetState::LOADING
      handle
    end

    def get(handle)
      @assets[handle.id]
    end

    def get_state(handle)
      @states[handle.id] || AssetState::NOT_LOADED
    end

    def loaded?(handle)
      get_state(handle) == AssetState::LOADED
    end

    def loading?(handle)
      get_state(handle) == AssetState::LOADING
    end

    def failed?(handle)
      get_state(handle) == AssetState::FAILED
    end

    def set_loaded(handle, asset)
      @assets[handle.id] = asset
      @states[handle.id] = AssetState::LOADED
    end

    def set_failed(handle)
      @states[handle.id] = AssetState::FAILED
    end

    def get_handle(path)
      @handles[path]
    end

    def all_handles
      @handles.values
    end

    def loaded_handles
      @handles.values.select { |h| loaded?(h) }
    end

    def pending_handles
      @handles.values.select { |h| loading?(h) }
    end

    private

    def generate_id
      id = @next_id
      @next_id += 1
      id
    end

    def infer_type(path)
      ext = File.extname(path).downcase
      case ext
      when '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'
        'Image'
      when '.ogg', '.wav', '.mp3', '.flac'
        'AudioSource'
      when '.ttf', '.otf'
        'Font'
      when '.gltf', '.glb'
        'Gltf'
      when '.json'
        'JsonAsset'
      when '.ron'
        'RonAsset'
      else
        'Unknown'
      end
    end
  end

  class Assets
    def initialize(type_name)
      @type_name = type_name
      @assets = {}
    end

    def add(asset)
      id = @assets.length
      handle = Handle.new(id: id, type_name: @type_name)
      @assets[id] = asset
      handle
    end

    def get(handle)
      return nil unless handle.type_name == @type_name

      @assets[handle.id]
    end

    def get_mut(handle)
      get(handle)
    end

    def remove(handle)
      @assets.delete(handle.id)
    end

    def contains?(handle)
      @assets.key?(handle.id)
    end

    def iter
      @assets.map { |id, asset| [Handle.new(id: id, type_name: @type_name), asset] }
    end

    def each(&block)
      iter.each(&block)
    end

    def len
      @assets.length
    end

    def empty?
      @assets.empty?
    end
  end

  class AssetPath
    attr_reader :path, :label

    def initialize(path, label: nil)
      @path = path
      @label = label
    end

    def self.parse(asset_path)
      if asset_path.include?('#')
        path, label = asset_path.split('#', 2)
        new(path, label: label)
      else
        new(asset_path)
      end
    end

    def full_path
      @label ? "#{@path}##{@label}" : @path
    end

    def extension
      File.extname(@path).delete_prefix('.')
    end

    def file_name
      File.basename(@path)
    end

    def parent
      File.dirname(@path)
    end

    def ==(other)
      return false unless other.is_a?(AssetPath)

      @path == other.path && @label == other.label
    end

    def to_s
      full_path
    end
  end

  class AssetEvent
    attr_reader :type, :handle

    CREATED = :created
    MODIFIED = :modified
    REMOVED = :removed
    LOADED = :loaded
    FAILED = :failed

    def initialize(type, handle)
      @type = type
      @handle = handle
    end

    def created?
      @type == CREATED
    end

    def modified?
      @type == MODIFIED
    end

    def removed?
      @type == REMOVED
    end

    def loaded?
      @type == LOADED
    end

    def failed?
      @type == FAILED
    end
  end

  class AssetLoader
    attr_reader :extensions

    def initialize(extensions: [])
      @extensions = extensions
    end

    def load(path)
      raise NotImplementedError, 'Subclasses must implement #load'
    end

    def can_load?(path)
      ext = File.extname(path).delete_prefix('.').downcase
      @extensions.include?(ext)
    end
  end

  class ImageAsset
    attr_reader :path, :width, :height, :data

    def initialize(path:, width: 0, height: 0, data: nil)
      @path = path
      @width = width
      @height = height
      @data = data
    end

    def loaded?
      !@data.nil?
    end

    def aspect_ratio
      return 1.0 if @height.zero?

      @width.to_f / @height.to_f
    end
  end

  class FontAsset
    attr_reader :path, :family

    def initialize(path:, family: nil)
      @path = path
      @family = family || File.basename(path, '.*')
    end
  end

  class AudioAsset
    attr_reader :path, :duration

    def initialize(path:, duration: 0.0)
      @path = path
      @duration = duration
    end
  end

  class ImageLoader < AssetLoader
    def initialize
      super(extensions: %w[png jpg jpeg gif bmp webp])
    end

    def load(path)
      return nil unless File.exist?(path)

      ImageAsset.new(path: path)
    end
  end

  class FontLoader < AssetLoader
    def initialize
      super(extensions: %w[ttf otf woff woff2])
    end

    def load(path)
      return nil unless File.exist?(path)

      FontAsset.new(path: path)
    end
  end

  class AudioLoader < AssetLoader
    def initialize
      super(extensions: %w[ogg wav mp3 flac])
    end

    def load(path)
      return nil unless File.exist?(path)

      AudioAsset.new(path: path)
    end
  end

  class AssetManager
    def initialize
      @asset_server = AssetServer.new
      @loaders = {
        'Image' => ImageLoader.new,
        'Font' => FontLoader.new,
        'AudioSource' => AudioLoader.new
      }
      @hot_reload_enabled = false
      @file_watcher = FileWatcher.new
      @reload_callbacks = {}
      @dependencies = {}
    end

    attr_reader :asset_server
    attr_reader :hot_reload_enabled

    def register_loader(type_name, loader)
      @loaders[type_name] = loader
    end

    def enable_hot_reload
      @hot_reload_enabled = true
    end

    def disable_hot_reload
      @hot_reload_enabled = false
    end

    def on_reload(handle, &callback)
      @reload_callbacks[handle.id] ||= []
      @reload_callbacks[handle.id] << callback
    end

    def add_dependency(asset_handle, dependency_handle)
      @dependencies[asset_handle.id] ||= []
      @dependencies[asset_handle.id] << dependency_handle.id
    end

    def load(path)
      handle = @asset_server.load(path)
      type_name = handle.type_name

      if @loaders.key?(type_name)
        loader = @loaders[type_name]
        asset = loader.load(path)

        if asset
          @asset_server.set_loaded(handle, asset)
          @file_watcher.watch(path) if @hot_reload_enabled
        else
          @asset_server.set_failed(handle)
        end
      end

      handle
    end

    def load_async(path, &callback)
      handle = @asset_server.load_async(path)

      Thread.new do
        type_name = handle.type_name

        if @loaders.key?(type_name)
          loader = @loaders[type_name]
          asset = loader.load(path)

          if asset
            @asset_server.set_loaded(handle, asset)
            @file_watcher.watch(path) if @hot_reload_enabled
            callback&.call(handle, :loaded)
          else
            @asset_server.set_failed(handle)
            callback&.call(handle, :failed)
          end
        end
      end

      handle
    end

    def reload(handle)
      path = handle.path
      return false unless path

      type_name = handle.type_name
      return false unless @loaders.key?(type_name)

      loader = @loaders[type_name]
      asset = loader.load(path)

      if asset
        @asset_server.set_loaded(handle, asset)
        notify_reload(handle)
        reload_dependents(handle)
        true
      else
        false
      end
    end

    def check_for_changes
      return [] unless @hot_reload_enabled

      changes = @file_watcher.check_changes
      reloaded = []

      changes.each do |path, change_type|
        handle = @asset_server.get_handle(path)
        next unless handle

        case change_type
        when :modified
          if reload(handle)
            reloaded << AssetEvent.new(AssetEvent::MODIFIED, handle)
          end
        when :deleted
          reloaded << AssetEvent.new(AssetEvent::REMOVED, handle)
        end
      end

      reloaded
    end

    def get(handle)
      @asset_server.get(handle)
    end

    def loaded?(handle)
      @asset_server.loaded?(handle)
    end

    def loading?(handle)
      @asset_server.loading?(handle)
    end

    def failed?(handle)
      @asset_server.failed?(handle)
    end

    def get_state(handle)
      @asset_server.get_state(handle)
    end

    def unload(handle)
      @file_watcher.unwatch(handle.path) if handle.path
      @reload_callbacks.delete(handle.id)
      @dependencies.delete(handle.id)
    end

    private

    def notify_reload(handle)
      callbacks = @reload_callbacks[handle.id]
      return unless callbacks

      callbacks.each { |cb| cb.call(handle) }
    end

    def reload_dependents(handle)
      @dependencies.each do |asset_id, deps|
        next unless deps.include?(handle.id)

        dependent_handle = find_handle_by_id(asset_id)
        reload(dependent_handle) if dependent_handle
      end
    end

    def find_handle_by_id(id)
      @asset_server.all_handles.find { |h| h.id == id }
    end
  end

  class FileWatcher
    def initialize
      @watched = {}
      @poll_interval = 1.0
    end

    attr_accessor :poll_interval

    def watch(path)
      return unless File.exist?(path)

      @watched[path] = File.mtime(path)
    end

    def unwatch(path)
      @watched.delete(path)
    end

    def check_changes
      changes = []
      to_remove = []

      @watched.each do |path, last_mtime|
        if File.exist?(path)
          current_mtime = File.mtime(path)
          if current_mtime > last_mtime
            changes << [path, :modified]
            @watched[path] = current_mtime
          end
        else
          changes << [path, :deleted]
          to_remove << path
        end
      end

      to_remove.each { |p| @watched.delete(p) }
      changes
    end

    def watched_count
      @watched.size
    end

    def watching?(path)
      @watched.key?(path)
    end
  end

  class HotReloadPlugin
    def initialize(poll_interval: 1.0)
      @poll_interval = poll_interval
      @last_check = ::Time.now
    end

    def build(app)
      app.asset_manager.enable_hot_reload
      app.asset_manager.instance_variable_get(:@file_watcher).poll_interval = @poll_interval
    end

    def update(app, _delta)
      now = ::Time.now
      return if now - @last_check < @poll_interval

      @last_check = now
      events = app.asset_manager.check_for_changes
      events.each do |event|
        puts "[HotReload] #{event.type}: #{event.handle.path}" if ENV['BEVY_DEBUG']
      end
    end
  end
end
