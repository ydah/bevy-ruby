# frozen_string_literal: true

# Asset Loading Demo
# Demonstrates the AssetManager for loading images, fonts, and audio.
# Shows sync/async loading patterns and asset state management.

require 'bevy'
require 'tempfile'

class AssetStatus < Bevy::ComponentDSL
  attribute :label, String, default: ''
  attribute :status, String, default: 'pending'
end

class AssetInfo < Bevy::ComponentDSL
  attribute :asset_type, String, default: ''
  attribute :path, String, default: ''
  attribute :handle, Object, default: nil
end

DEMO_ASSETS = []

def create_temp_assets
  png_file = Tempfile.new(['demo_image', '.png'])
  png_file.write("\x89PNG\r\n\x1a\n" + ('x' * 100))
  png_file.close
  DEMO_ASSETS << { file: png_file, type: 'Image', label: 'PNG Image' }

  jpg_file = Tempfile.new(['demo_photo', '.jpg'])
  jpg_file.write("\xFF\xD8\xFF" + ('y' * 100))
  jpg_file.close
  DEMO_ASSETS << { file: jpg_file, type: 'Image', label: 'JPG Photo' }

  ttf_file = Tempfile.new(['demo_font', '.ttf'])
  ttf_file.write('font data...')
  ttf_file.close
  DEMO_ASSETS << { file: ttf_file, type: 'Font', label: 'TTF Font' }

  ogg_file = Tempfile.new(['demo_audio', '.ogg'])
  ogg_file.write('OggS' + ('z' * 100))
  ogg_file.close
  DEMO_ASSETS << { file: ogg_file, type: 'Audio', label: 'OGG Audio' }
end

def cleanup_temp_assets
  DEMO_ASSETS.each do |asset|
    asset[:file].unlink
  rescue StandardError
    nil
  end
end

at_exit { cleanup_temp_assets }

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Asset Loading Demo',
    width: 800.0,
    height: 600.0
  }
)

asset_manager = Bevy::AssetManager.new
loaded_handles = []
async_status = { completed: 0, total: 0 }

app.add_startup_system do |ctx|
  create_temp_assets

  ctx.spawn(
    Bevy::Text2d.new('Asset Loading Demo', font_size: 42.0, color: Bevy::Color.from_hex('#3498DB')),
    Bevy::Transform.from_xyz(0.0, 250.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Synchronous Loading:', font_size: 24.0, color: Bevy::Color.from_hex('#ECF0F1')),
    Bevy::Transform.from_xyz(-200.0, 180.0, 0.0)
  )

  y_pos = 130.0
  DEMO_ASSETS.each_with_index do |asset_info, _index|
    handle = asset_manager.load(asset_info[:file].path)
    loaded_handles << handle

    status = if asset_manager.loaded?(handle)
               'Loaded'
             elsif asset_manager.failed?(handle)
               'Failed'
             else
               'Pending'
             end

    color = case status
            when 'Loaded' then Bevy::Color.from_hex('#2ECC71')
            when 'Failed' then Bevy::Color.from_hex('#E74C3C')
            else Bevy::Color.from_hex('#F39C12')
            end

    status_text = "#{asset_info[:label]}: #{status} (#{handle.type_name})"

    ctx.spawn(
      Bevy::Text2d.new(status_text, font_size: 18.0, color: color),
      AssetStatus.new(label: asset_info[:label], status: status),
      Bevy::Transform.from_xyz(-200.0, y_pos, 0.0)
    )

    y_pos -= 30.0
  end

  ctx.spawn(
    Bevy::Text2d.new('Async Loading Example:', font_size: 24.0, color: Bevy::Color.from_hex('#ECF0F1')),
    Bevy::Transform.from_xyz(-200.0, -20.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Press SPACE to start async loading', font_size: 18.0, color: Bevy::Color.from_hex('#7F8C8D')),
    AssetInfo.new(asset_type: 'async_status', path: '', handle: nil),
    Bevy::Transform.from_xyz(-200.0, -60.0, 0.0)
  )

  ctx.spawn(
    Bevy::Text2d.new('Asset Details:', font_size: 24.0, color: Bevy::Color.from_hex('#ECF0F1')),
    Bevy::Transform.from_xyz(-200.0, -120.0, 0.0)
  )

  detail_y = -160.0
  loaded_handles.each do |handle|
    next unless asset_manager.loaded?(handle)

    asset = asset_manager.get(handle)
    detail = case asset
             when Bevy::ImageAsset
               "Image: #{File.basename(asset.path)} (#{asset.width}x#{asset.height})"
             when Bevy::FontAsset
               "Font: #{asset.family}"
             when Bevy::AudioAsset
               "Audio: #{File.basename(asset.path)} (#{asset.duration}s)"
             else
               'Unknown asset type'
             end

    ctx.spawn(
      Bevy::Text2d.new(detail, font_size: 16.0, color: Bevy::Color.from_hex('#BDC3C7')),
      Bevy::Transform.from_xyz(-200.0, detail_y, 0.0)
    )
    detail_y -= 25.0
  end

  ctx.spawn(
    Bevy::Text2d.new('Press ESC to exit', font_size: 16.0, color: Bevy::Color.from_hex('#7F8C8D')),
    Bevy::Transform.from_xyz(0.0, -270.0, 0.0)
  )

  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 0.0, -1.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#1a1a2e'),
      custom_size: Bevy::Vec2.new(800.0, 600.0)
    )
  )
end

async_loading_started = false
async_handles = []

app.add_update_system do |ctx|
  if ctx.key_pressed?('SPACE') && !async_loading_started
    async_loading_started = true
    async_status[:total] = DEMO_ASSETS.length

    DEMO_ASSETS.each do |asset_info|
      handle = asset_manager.load_async(asset_info[:file].path) do |_h, result|
        async_status[:completed] += 1 if result == :loaded
      end
      async_handles << handle
    end
  end

  if async_loading_started
    status_text = "Async loading: #{async_status[:completed]}/#{async_status[:total]} completed"
    color = if async_status[:completed] == async_status[:total]
              Bevy::Color.from_hex('#2ECC71')
            else
              Bevy::Color.from_hex('#F39C12')
            end

    ctx.world.each(AssetInfo, Bevy::Text2d) do |entity, info, _text|
      next unless info.asset_type == 'async_status'

      new_text = Bevy::Text2d.new(status_text, font_size: 18.0, color: color)
      ctx.world.insert_component(entity, new_text)
    end
  end

  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Asset Loading Demo'
puts ''
puts 'Supported Asset Types:'
puts '  - Images: png, jpg, jpeg, gif, bmp, webp'
puts '  - Fonts: ttf, otf, woff, woff2'
puts '  - Audio: ogg, wav, mp3, flac'
puts ''
puts 'Loading Methods:'
puts '  - Synchronous: asset_manager.load(path)'
puts '  - Asynchronous: asset_manager.load_async(path) { |handle, result| ... }'
puts ''
puts 'Controls:'
puts '  SPACE - Start async loading demo'
puts '  ESC - Exit'
app.run
