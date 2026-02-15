# frozen_string_literal: true

RSpec.describe Bevy::Sprite do
  describe '.new' do
    it 'creates a Sprite with default values' do
      s = described_class.new
      expect(s.color.r).to eq(1.0)
      expect(s.color.g).to eq(1.0)
      expect(s.color.b).to eq(1.0)
      expect(s.flip_x).to be false
      expect(s.flip_y).to be false
      expect(s.custom_size).to be_nil
      expect(s.anchor.x).to eq(0.5)
      expect(s.anchor.y).to eq(0.5)
    end

    it 'creates a Sprite with custom color' do
      s = described_class.new(color: Bevy::Color.red)
      expect(s.color.r).to eq(1.0)
      expect(s.color.g).to eq(0.0)
    end

    it 'creates a Sprite with flip options' do
      s = described_class.new(flip_x: true, flip_y: true)
      expect(s.flip_x).to be true
      expect(s.flip_y).to be true
    end

    it 'creates a Sprite with custom size' do
      size = Bevy::Vec2.new(100.0, 50.0)
      s = described_class.new(custom_size: size)
      expect(s.custom_size.x).to eq(100.0)
      expect(s.custom_size.y).to eq(50.0)
    end

    it 'creates a Sprite with custom anchor' do
      anchor = Bevy::Vec2.new(0.0, 1.0)
      s = described_class.new(anchor: anchor)
      expect(s.anchor.x).to eq(0.0)
      expect(s.anchor.y).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns Sprite' do
      s = described_class.new
      expect(s.type_name).to eq('Sprite')
    end
  end

  describe '#with_color' do
    it 'returns a new sprite with updated color' do
      s = described_class.new
      s2 = s.with_color(Bevy::Color.blue)
      expect(s2.color.b).to eq(1.0)
      expect(s.color.b).to eq(1.0)
    end
  end

  describe '#with_flip_x' do
    it 'returns a new sprite with updated flip_x' do
      s = described_class.new
      s2 = s.with_flip_x(true)
      expect(s2.flip_x).to be true
      expect(s.flip_x).to be false
    end
  end

  describe '#with_flip_y' do
    it 'returns a new sprite with updated flip_y' do
      s = described_class.new
      s2 = s.with_flip_y(true)
      expect(s2.flip_y).to be true
      expect(s.flip_y).to be false
    end
  end

  describe '#with_custom_size' do
    it 'returns a new sprite with custom size' do
      s = described_class.new
      size = Bevy::Vec2.new(200.0, 100.0)
      s2 = s.with_custom_size(size)
      expect(s2.custom_size.x).to eq(200.0)
      expect(s.custom_size).to be_nil
    end
  end

  describe '#with_anchor' do
    it 'returns a new sprite with custom anchor' do
      s = described_class.new
      anchor = Bevy::Vec2.new(0.0, 0.0)
      s2 = s.with_anchor(anchor)
      expect(s2.anchor.x).to eq(0.0)
      expect(s.anchor.x).to eq(0.5)
    end
  end

  describe '#to_native' do
    it 'converts to a Component without custom size' do
      s = described_class.new(color: Bevy::Color.green, flip_x: true)
      native = s.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native.type_name).to eq('Sprite')
      expect(native['color_g']).to eq(1.0)
      expect(native['flip_x']).to be true
      expect(native['has_custom_size']).to be false
    end

    it 'converts to a Component with custom size' do
      size = Bevy::Vec2.new(64.0, 32.0)
      s = described_class.new(custom_size: size)
      native = s.to_native
      expect(native['has_custom_size']).to be true
      expect(native['custom_size_x']).to eq(64.0)
      expect(native['custom_size_y']).to eq(32.0)
    end
  end

  describe '.from_native' do
    it 'creates a Sprite from a native Component without custom size' do
      native = Bevy::Component.new('Sprite')
      native['color_r'] = 0.5
      native['color_g'] = 0.6
      native['color_b'] = 0.7
      native['color_a'] = 1.0
      native['flip_x'] = true
      native['flip_y'] = false
      native['anchor_x'] = 0.25
      native['anchor_y'] = 0.75
      native['has_custom_size'] = false

      s = described_class.from_native(native)
      expect(s.color.r).to be_within(0.001).of(0.5)
      expect(s.flip_x).to be true
      expect(s.flip_y).to be false
      expect(s.anchor.x).to be_within(0.001).of(0.25)
      expect(s.custom_size).to be_nil
    end

    it 'creates a Sprite from a native Component with custom size' do
      native = Bevy::Component.new('Sprite')
      native['color_r'] = 1.0
      native['color_g'] = 1.0
      native['color_b'] = 1.0
      native['color_a'] = 1.0
      native['flip_x'] = false
      native['flip_y'] = false
      native['anchor_x'] = 0.5
      native['anchor_y'] = 0.5
      native['has_custom_size'] = true
      native['custom_size_x'] = 128.0
      native['custom_size_y'] = 64.0

      s = described_class.from_native(native)
      expect(s.custom_size).not_to be_nil
      expect(s.custom_size.x).to eq(128.0)
      expect(s.custom_size.y).to eq(64.0)
    end
  end

  describe '#to_h' do
    it 'converts to a hash without custom size' do
      s = described_class.new(flip_x: true)
      h = s.to_h
      expect(h[:flip_x]).to be true
      expect(h[:flip_y]).to be false
      expect(h).not_to have_key(:custom_size)
    end

    it 'converts to a hash with custom size' do
      size = Bevy::Vec2.new(50.0, 50.0)
      s = described_class.new(custom_size: size)
      h = s.to_h
      expect(h[:custom_size]).to eq([50.0, 50.0])
    end
  end
end

RSpec.describe Bevy::SpriteBundle do
  describe '.new' do
    it 'creates a SpriteBundle with default values' do
      bundle = described_class.new
      expect(bundle.sprite).to be_a(Bevy::Sprite)
      expect(bundle.transform).to be_a(Bevy::Transform)
    end

    it 'creates a SpriteBundle with custom sprite and transform' do
      sprite = Bevy::Sprite.new(color: Bevy::Color.red)
      transform = Bevy::Transform.from_xyz(10.0, 20.0, 0.0)
      bundle = described_class.new(sprite: sprite, transform: transform)
      expect(bundle.sprite.color.r).to eq(1.0)
      expect(bundle.transform.translation.x).to eq(10.0)
    end
  end

  describe '#components' do
    it 'returns an array of components' do
      bundle = described_class.new
      components = bundle.components
      expect(components.length).to eq(2)
      expect(components[0]).to be_a(Bevy::Sprite)
      expect(components[1]).to be_a(Bevy::Transform)
    end
  end
end

RSpec.describe 'World with Sprite' do
  let(:world) { Bevy::World.new }

  describe '#spawn_entity with Sprite' do
    it 'spawns an entity with a Sprite component' do
      sprite = Bevy::Sprite.new(color: Bevy::Color.blue)
      entity = world.spawn_entity(sprite)
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#get_component with Sprite' do
    it 'retrieves a Sprite component' do
      sprite = Bevy::Sprite.new(color: Bevy::Color.green, flip_x: true)
      entity = world.spawn_entity(sprite)

      retrieved = world.get_component(entity, Bevy::Sprite)
      expect(retrieved).to be_a(Bevy::Sprite)
      expect(retrieved.color.g).to eq(1.0)
      expect(retrieved.flip_x).to be true
    end

    it 'retrieves a Sprite with custom size' do
      size = Bevy::Vec2.new(100.0, 50.0)
      sprite = Bevy::Sprite.new(custom_size: size)
      entity = world.spawn_entity(sprite)

      retrieved = world.get_component(entity, Bevy::Sprite)
      expect(retrieved.custom_size).not_to be_nil
      expect(retrieved.custom_size.x).to eq(100.0)
      expect(retrieved.custom_size.y).to eq(50.0)
    end
  end

  describe '#has? with Sprite' do
    it 'checks if entity has Sprite' do
      sprite = Bevy::Sprite.new
      entity = world.spawn_entity(sprite)
      expect(world.has?(entity, Bevy::Sprite)).to be true
    end
  end

  describe '#spawn_entity with SpriteBundle' do
    it 'spawns an entity with sprite and transform' do
      bundle = Bevy::SpriteBundle.new(
        sprite: Bevy::Sprite.new(color: Bevy::Color.red),
        transform: Bevy::Transform.from_xyz(5.0, 10.0, 0.0)
      )
      entity = world.spawn_entity(*bundle.components)
      expect(world.has?(entity, Bevy::Sprite)).to be true
      expect(world.has?(entity, Bevy::Transform)).to be true

      sprite = world.get_component(entity, Bevy::Sprite)
      transform = world.get_component(entity, Bevy::Transform)
      expect(sprite.color.r).to eq(1.0)
      expect(transform.translation.x).to eq(5.0)
    end
  end
end
