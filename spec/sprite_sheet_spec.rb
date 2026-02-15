# frozen_string_literal: true

RSpec.describe Bevy::TextureAtlasLayout do
  describe '.new' do
    it 'creates layout with tile size and grid' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      expect(layout.tile_size.x).to eq(32.0)
      expect(layout.columns).to eq(4)
      expect(layout.rows).to eq(2)
      expect(layout.tile_count).to eq(8)
    end

    it 'calculates size correctly' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      expect(layout.size.x).to eq(128.0)
      expect(layout.size.y).to eq(64.0)
    end

    it 'handles padding' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 2,
        rows: 2,
        padding: Bevy::Vec2.new(2.0, 2.0)
      )
      expect(layout.size.x).to eq(66.0)
      expect(layout.size.y).to eq(66.0)
    end
  end

  describe '.from_grid' do
    it 'creates layout from grid parameters' do
      layout = described_class.from_grid(
        tile_size: Bevy::Vec2.new(16.0, 16.0),
        columns: 8,
        rows: 4
      )
      expect(layout.tile_count).to eq(32)
    end
  end

  describe '#get_texture_rect' do
    it 'returns correct rect for index' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      rect = layout.get_texture_rect(0)
      expect(rect.min.x).to eq(0.0)
      expect(rect.min.y).to eq(0.0)
      expect(rect.max.x).to eq(32.0)
      expect(rect.max.y).to eq(32.0)

      rect = layout.get_texture_rect(5)
      expect(rect.min.x).to eq(32.0)
      expect(rect.min.y).to eq(32.0)
    end

    it 'returns nil for invalid index' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 2,
        rows: 2
      )
      expect(layout.get_texture_rect(-1)).to be_nil
      expect(layout.get_texture_rect(4)).to be_nil
    end
  end

  describe '#index_for' do
    it 'returns index for column and row' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      expect(layout.index_for(0, 0)).to eq(0)
      expect(layout.index_for(1, 0)).to eq(1)
      expect(layout.index_for(0, 1)).to eq(4)
      expect(layout.index_for(3, 1)).to eq(7)
    end

    it 'returns nil for invalid coordinates' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 2,
        rows: 2
      )
      expect(layout.index_for(-1, 0)).to be_nil
      expect(layout.index_for(2, 0)).to be_nil
    end
  end

  describe '#column_row_for' do
    it 'returns column and row for index' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      expect(layout.column_row_for(0)).to eq([0, 0])
      expect(layout.column_row_for(5)).to eq([1, 1])
      expect(layout.column_row_for(7)).to eq([3, 1])
    end
  end

  describe '#type_name' do
    it 'returns TextureAtlasLayout' do
      layout = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      expect(layout.type_name).to eq('TextureAtlasLayout')
    end
  end
end

RSpec.describe Bevy::TextureAtlas do
  describe '.new' do
    it 'creates atlas with layout and image' do
      layout = Bevy::TextureAtlasLayout.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 2
      )
      atlas = described_class.new(layout: layout, image: 'sprites.png')
      expect(atlas.layout).to eq(layout)
      expect(atlas.image).to eq('sprites.png')
      expect(atlas.tile_count).to eq(8)
    end
  end

  describe '#type_name' do
    it 'returns TextureAtlas' do
      layout = Bevy::TextureAtlasLayout.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 1,
        rows: 1
      )
      atlas = described_class.new(layout: layout, image: 'test.png')
      expect(atlas.type_name).to eq('TextureAtlas')
    end
  end
end

RSpec.describe Bevy::TextureAtlasSprite do
  describe '.new' do
    it 'creates with default values' do
      sprite = described_class.new
      expect(sprite.index).to eq(0)
      expect(sprite.flip_x).to be false
      expect(sprite.flip_y).to be false
    end

    it 'creates with custom values' do
      sprite = described_class.new(
        index: 5,
        flip_x: true,
        custom_size: Bevy::Vec2.new(64.0, 64.0)
      )
      expect(sprite.index).to eq(5)
      expect(sprite.flip_x).to be true
      expect(sprite.custom_size.x).to eq(64.0)
    end
  end

  describe '#type_name' do
    it 'returns TextureAtlasSprite' do
      expect(described_class.new.type_name).to eq('TextureAtlasSprite')
    end
  end
end

RSpec.describe Bevy::SpriteSheetBundle do
  describe '.new' do
    it 'creates with default values' do
      bundle = described_class.new
      expect(bundle.sprite).to be_a(Bevy::TextureAtlasSprite)
      expect(bundle.transform).to be_a(Bevy::Transform)
      expect(bundle.global_transform).to be_a(Bevy::GlobalTransform)
    end

    it 'creates with custom values' do
      sprite = Bevy::TextureAtlasSprite.new(index: 3)
      layout = Bevy::TextureAtlasLayout.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        columns: 4,
        rows: 4
      )
      atlas = Bevy::TextureAtlas.new(layout: layout, image: 'spritesheet.png')
      bundle = described_class.new(sprite: sprite, atlas: atlas)

      expect(bundle.sprite.index).to eq(3)
      expect(bundle.atlas).to eq(atlas)
    end
  end

  describe '#components' do
    it 'returns array of components' do
      bundle = described_class.new
      expect(bundle.components.size).to be >= 3
    end
  end

  describe '#type_name' do
    it 'returns SpriteSheetBundle' do
      expect(described_class.new.type_name).to eq('SpriteSheetBundle')
    end
  end
end

RSpec.describe Bevy::AnimatedSprite do
  describe '.new' do
    it 'creates with default values' do
      anim = described_class.new
      expect(anim.frames).to be_empty
      expect(anim.current_frame).to eq(0)
      expect(anim.looping).to be true
      expect(anim.playing).to be true
    end

    it 'creates with custom values' do
      anim = described_class.new(
        frames: [0, 1, 2, 3],
        frame_duration: 0.2,
        looping: false
      )
      expect(anim.frames).to eq([0, 1, 2, 3])
      expect(anim.frame_duration).to eq(0.2)
      expect(anim.looping).to be false
    end
  end

  describe '#update' do
    it 'advances frame when timer exceeds duration' do
      anim = described_class.new(frames: [0, 1, 2], frame_duration: 0.1)
      anim.update(0.15)
      expect(anim.current_frame).to eq(1)
    end

    it 'loops when reaching end' do
      anim = described_class.new(frames: [0, 1], frame_duration: 0.1, looping: true)
      anim.update(0.25)
      expect(anim.current_frame).to eq(0)
    end

    it 'stops at last frame when not looping' do
      anim = described_class.new(frames: [0, 1], frame_duration: 0.1, looping: false)
      anim.update(0.25)
      expect(anim.current_frame).to eq(1)
      expect(anim.playing).to be false
    end
  end

  describe '#fps' do
    it 'returns frames per second' do
      anim = described_class.new(frame_duration: 0.1)
      expect(anim.fps).to eq(10.0)
    end

    it 'can be set' do
      anim = described_class.new
      anim.fps = 30
      expect(anim.frame_duration).to be_within(0.001).of(1.0 / 30)
    end
  end

  describe '#play and #pause' do
    it 'controls playback' do
      anim = described_class.new(frames: [0, 1, 2])
      anim.pause
      expect(anim.playing).to be false

      anim.play
      expect(anim.playing).to be true
    end
  end

  describe '#stop' do
    it 'stops and resets' do
      anim = described_class.new(frames: [0, 1, 2], frame_duration: 0.1)
      anim.update(0.15)
      anim.stop
      expect(anim.playing).to be false
      expect(anim.current_frame).to eq(0)
      expect(anim.timer).to eq(0.0)
    end
  end

  describe '#current_index' do
    it 'returns current frame index' do
      anim = described_class.new(frames: [5, 6, 7, 8])
      expect(anim.current_index).to eq(5)
      anim.update(0.15)
      expect(anim.current_index).to eq(6)
    end
  end

  describe '#type_name' do
    it 'returns AnimatedSprite' do
      expect(described_class.new.type_name).to eq('AnimatedSprite')
    end
  end
end

RSpec.describe Bevy::SpriteSheetAnimation do
  describe '.new' do
    it 'creates animation definition' do
      anim = described_class.new(
        name: 'walk',
        frames: [0, 1, 2, 3],
        frame_duration: 0.1
      )
      expect(anim.name).to eq('walk')
      expect(anim.frames).to eq([0, 1, 2, 3])
    end
  end

  describe '#to_animated_sprite' do
    it 'creates AnimatedSprite from definition' do
      anim = described_class.new(
        name: 'run',
        frames: [4, 5, 6, 7],
        frame_duration: 0.05
      )
      sprite = anim.to_animated_sprite
      expect(sprite).to be_a(Bevy::AnimatedSprite)
      expect(sprite.frames).to eq([4, 5, 6, 7])
      expect(sprite.frame_duration).to eq(0.05)
    end
  end

  describe '#type_name' do
    it 'returns SpriteSheetAnimation' do
      anim = described_class.new(name: 'test', frames: [0])
      expect(anim.type_name).to eq('SpriteSheetAnimation')
    end
  end
end

RSpec.describe Bevy::AnimationLibrary do
  describe '.new' do
    it 'creates empty library' do
      lib = described_class.new
      expect(lib.animations).to be_empty
    end
  end

  describe '#add' do
    it 'adds animation to library' do
      lib = described_class.new
      anim = Bevy::SpriteSheetAnimation.new(name: 'idle', frames: [0, 1])
      lib.add(anim)
      expect(lib.get('idle')).to eq(anim)
    end

    it 'returns self for chaining' do
      lib = described_class.new
      result = lib.add(Bevy::SpriteSheetAnimation.new(name: 'idle', frames: [0]))
      expect(result).to eq(lib)
    end
  end

  describe '#names' do
    it 'returns all animation names' do
      lib = described_class.new
      lib.add(Bevy::SpriteSheetAnimation.new(name: 'idle', frames: [0]))
      lib.add(Bevy::SpriteSheetAnimation.new(name: 'walk', frames: [1, 2]))
      expect(lib.names).to contain_exactly('idle', 'walk')
    end
  end

  describe '#type_name' do
    it 'returns AnimationLibrary' do
      expect(described_class.new.type_name).to eq('AnimationLibrary')
    end
  end
end

RSpec.describe Bevy::Rect do
  describe '.new' do
    it 'creates rect with min and max' do
      rect = described_class.new(
        min: Bevy::Vec2.new(10.0, 20.0),
        max: Bevy::Vec2.new(50.0, 60.0)
      )
      expect(rect.min.x).to eq(10.0)
      expect(rect.max.x).to eq(50.0)
    end
  end

  describe '#width and #height' do
    it 'calculates dimensions' do
      rect = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 50.0)
      )
      expect(rect.width).to eq(100.0)
      expect(rect.height).to eq(50.0)
    end
  end

  describe '#size' do
    it 'returns size as Vec2' do
      rect = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 50.0)
      )
      size = rect.size
      expect(size.x).to eq(100.0)
      expect(size.y).to eq(50.0)
    end
  end

  describe '#center' do
    it 'returns center point' do
      rect = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 50.0)
      )
      center = rect.center
      expect(center.x).to eq(50.0)
      expect(center.y).to eq(25.0)
    end
  end

  describe '#contains?' do
    it 'returns true if point is inside' do
      rect = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 100.0)
      )
      expect(rect.contains?(Bevy::Vec2.new(50.0, 50.0))).to be true
      expect(rect.contains?(Bevy::Vec2.new(150.0, 50.0))).to be false
    end
  end

  describe '#intersects?' do
    it 'returns true if rects overlap' do
      rect1 = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 100.0)
      )
      rect2 = described_class.new(
        min: Bevy::Vec2.new(50.0, 50.0),
        max: Bevy::Vec2.new(150.0, 150.0)
      )
      rect3 = described_class.new(
        min: Bevy::Vec2.new(200.0, 200.0),
        max: Bevy::Vec2.new(300.0, 300.0)
      )
      expect(rect1.intersects?(rect2)).to be true
      expect(rect1.intersects?(rect3)).to be false
    end
  end

  describe '#type_name' do
    it 'returns Rect' do
      rect = described_class.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(1.0, 1.0)
      )
      expect(rect.type_name).to eq('Rect')
    end
  end
end

RSpec.describe Bevy::NineSlice do
  describe '.new' do
    it 'creates with border values' do
      nine_slice = described_class.new(
        border_left: 10.0,
        border_right: 10.0,
        border_top: 20.0,
        border_bottom: 20.0
      )
      expect(nine_slice.border_left).to eq(10.0)
      expect(nine_slice.border_top).to eq(20.0)
    end
  end

  describe '.from_single_border' do
    it 'creates with same border on all sides' do
      nine_slice = described_class.from_single_border(16.0)
      expect(nine_slice.border_left).to eq(16.0)
      expect(nine_slice.border_right).to eq(16.0)
      expect(nine_slice.border_top).to eq(16.0)
      expect(nine_slice.border_bottom).to eq(16.0)
    end
  end

  describe '#slices_for' do
    it 'returns all nine slices' do
      nine_slice = described_class.from_single_border(10.0)
      source = Bevy::Rect.new(
        min: Bevy::Vec2.new(0.0, 0.0),
        max: Bevy::Vec2.new(100.0, 100.0)
      )
      slices = nine_slice.slices_for(source, Bevy::Vec2.new(200.0, 200.0))

      expect(slices.keys).to contain_exactly(
        :top_left, :top, :top_right,
        :left, :center, :right,
        :bottom_left, :bottom, :bottom_right
      )
    end
  end

  describe '#type_name' do
    it 'returns NineSlice' do
      expect(described_class.new.type_name).to eq('NineSlice')
    end
  end
end

RSpec.describe Bevy::TiledSprite do
  describe '.new' do
    it 'creates with tile configuration' do
      tiled = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        repeat_x: 4,
        repeat_y: 3
      )
      expect(tiled.tile_size.x).to eq(32.0)
      expect(tiled.repeat_x).to eq(4)
      expect(tiled.repeat_y).to eq(3)
    end
  end

  describe '#total_size' do
    it 'calculates total size' do
      tiled = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        repeat_x: 4,
        repeat_y: 3
      )
      size = tiled.total_size
      expect(size.x).to eq(128.0)
      expect(size.y).to eq(96.0)
    end

    it 'accounts for spacing' do
      tiled = described_class.new(
        tile_size: Bevy::Vec2.new(32.0, 32.0),
        repeat_x: 2,
        repeat_y: 2,
        spacing: Bevy::Vec2.new(4.0, 4.0)
      )
      size = tiled.total_size
      expect(size.x).to eq(68.0)
      expect(size.y).to eq(68.0)
    end
  end

  describe '#tile_count' do
    it 'returns total tiles' do
      tiled = described_class.new(
        tile_size: Bevy::Vec2.new(16.0, 16.0),
        repeat_x: 5,
        repeat_y: 3
      )
      expect(tiled.tile_count).to eq(15)
    end
  end

  describe '#type_name' do
    it 'returns TiledSprite' do
      tiled = described_class.new(tile_size: Bevy::Vec2.new(16.0, 16.0))
      expect(tiled.type_name).to eq('TiledSprite')
    end
  end
end
