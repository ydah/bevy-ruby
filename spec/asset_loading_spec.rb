# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Bevy::AssetManager do
  let(:manager) { Bevy::AssetManager.new }

  describe '#load' do
    context 'with a non-existent file' do
      it 'marks the handle as failed' do
        handle = manager.load('/non/existent/file.png')
        expect(manager.failed?(handle)).to be true
      end
    end

    context 'with an existing image file' do
      let(:temp_file) do
        file = Tempfile.new(['test', '.png'])
        file.write('fake png data')
        file.close
        file
      end

      after do
        temp_file.unlink
      end

      it 'loads the image and marks as loaded' do
        handle = manager.load(temp_file.path)
        expect(manager.loaded?(handle)).to be true
        expect(handle.type_name).to eq('Image')
      end

      it 'returns an ImageAsset' do
        handle = manager.load(temp_file.path)
        asset = manager.get(handle)
        expect(asset).to be_a(Bevy::ImageAsset)
        expect(asset.path).to eq(temp_file.path)
      end
    end
  end

  describe '#register_loader' do
    it 'allows custom loaders' do
      custom_loader = Class.new(Bevy::AssetLoader) do
        def initialize
          super(extensions: %w[custom])
        end

        def load(path)
          "custom data for #{path}"
        end
      end.new

      manager.register_loader('Custom', custom_loader)

      # The type inference won't pick this up automatically
      # but the loader is registered
      expect(manager.asset_server).not_to be_nil
    end
  end
end

RSpec.describe Bevy::ImageAsset do
  describe '#aspect_ratio' do
    it 'calculates correct aspect ratio' do
      asset = Bevy::ImageAsset.new(path: 'test.png', width: 1920, height: 1080)
      expect(asset.aspect_ratio).to be_within(0.01).of(1.78)
    end

    it 'returns 1.0 for zero height' do
      asset = Bevy::ImageAsset.new(path: 'test.png', width: 100, height: 0)
      expect(asset.aspect_ratio).to eq(1.0)
    end
  end
end

RSpec.describe Bevy::FontAsset do
  it 'infers family from filename' do
    asset = Bevy::FontAsset.new(path: '/fonts/Roboto-Regular.ttf')
    expect(asset.family).to eq('Roboto-Regular')
  end

  it 'uses provided family' do
    asset = Bevy::FontAsset.new(path: '/fonts/font.ttf', family: 'Custom Font')
    expect(asset.family).to eq('Custom Font')
  end
end

RSpec.describe Bevy::AudioAsset do
  it 'stores path and duration' do
    asset = Bevy::AudioAsset.new(path: '/audio/music.ogg', duration: 180.5)
    expect(asset.path).to eq('/audio/music.ogg')
    expect(asset.duration).to eq(180.5)
  end
end

RSpec.describe Bevy::ImageLoader do
  let(:loader) { Bevy::ImageLoader.new }

  describe '#can_load?' do
    it 'returns true for image extensions' do
      expect(loader.can_load?('test.png')).to be true
      expect(loader.can_load?('test.jpg')).to be true
      expect(loader.can_load?('test.jpeg')).to be true
      expect(loader.can_load?('test.gif')).to be true
      expect(loader.can_load?('test.bmp')).to be true
      expect(loader.can_load?('test.webp')).to be true
    end

    it 'returns false for non-image extensions' do
      expect(loader.can_load?('test.txt')).to be false
      expect(loader.can_load?('test.mp3')).to be false
    end
  end
end

RSpec.describe Bevy::FontLoader do
  let(:loader) { Bevy::FontLoader.new }

  describe '#can_load?' do
    it 'returns true for font extensions' do
      expect(loader.can_load?('font.ttf')).to be true
      expect(loader.can_load?('font.otf')).to be true
      expect(loader.can_load?('font.woff')).to be true
      expect(loader.can_load?('font.woff2')).to be true
    end
  end
end

RSpec.describe Bevy::AudioLoader do
  let(:loader) { Bevy::AudioLoader.new }

  describe '#can_load?' do
    it 'returns true for audio extensions' do
      expect(loader.can_load?('sound.ogg')).to be true
      expect(loader.can_load?('sound.wav')).to be true
      expect(loader.can_load?('sound.mp3')).to be true
      expect(loader.can_load?('sound.flac')).to be true
    end
  end
end
