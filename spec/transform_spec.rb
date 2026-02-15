# frozen_string_literal: true

RSpec.describe Bevy::Transform do
  describe '.new' do
    it 'creates a Transform with default values' do
      t = described_class.new
      expect(t.translation.x).to eq(0.0)
      expect(t.translation.y).to eq(0.0)
      expect(t.translation.z).to eq(0.0)
      expect(t.rotation.w).to eq(1.0)
      expect(t.scale.x).to eq(1.0)
      expect(t.scale.y).to eq(1.0)
      expect(t.scale.z).to eq(1.0)
    end

    it 'creates a Transform with custom translation' do
      translation = Bevy::Vec3.new(1.0, 2.0, 3.0)
      t = described_class.new(translation: translation)
      expect(t.translation.x).to eq(1.0)
      expect(t.translation.y).to eq(2.0)
      expect(t.translation.z).to eq(3.0)
    end
  end

  describe '.from_xyz' do
    it 'creates a Transform from x, y, z coordinates' do
      t = described_class.from_xyz(5.0, 10.0, 15.0)
      expect(t.translation.x).to eq(5.0)
      expect(t.translation.y).to eq(10.0)
      expect(t.translation.z).to eq(15.0)
    end
  end

  describe '.from_translation' do
    it 'creates a Transform from a Vec3' do
      v = Bevy::Vec3.new(1.0, 2.0, 3.0)
      t = described_class.from_translation(v)
      expect(t.translation.x).to eq(1.0)
      expect(t.translation.y).to eq(2.0)
      expect(t.translation.z).to eq(3.0)
    end
  end

  describe '.from_scale' do
    it 'creates a Transform with custom scale' do
      v = Bevy::Vec3.new(2.0, 3.0, 4.0)
      t = described_class.from_scale(v)
      expect(t.scale.x).to eq(2.0)
      expect(t.scale.y).to eq(3.0)
      expect(t.scale.z).to eq(4.0)
    end
  end

  describe '.identity' do
    it 'creates an identity Transform' do
      t = described_class.identity
      expect(t.translation.x).to eq(0.0)
      expect(t.translation.y).to eq(0.0)
      expect(t.translation.z).to eq(0.0)
      expect(t.rotation.w).to eq(1.0)
      expect(t.scale.x).to eq(1.0)
      expect(t.scale.y).to eq(1.0)
      expect(t.scale.z).to eq(1.0)
    end
  end

  describe '#with_translation' do
    it 'returns a new Transform with updated translation' do
      t = described_class.identity
      new_t = t.with_translation(Bevy::Vec3.new(5.0, 5.0, 5.0))
      expect(new_t.translation.x).to eq(5.0)
      expect(t.translation.x).to eq(0.0)
    end
  end

  describe '#with_scale' do
    it 'returns a new Transform with updated scale' do
      t = described_class.identity
      new_t = t.with_scale(Bevy::Vec3.new(2.0, 2.0, 2.0))
      expect(new_t.scale.x).to eq(2.0)
      expect(t.scale.x).to eq(1.0)
    end
  end

  describe '#rotate_z' do
    it 'rotates around the Z axis' do
      t = described_class.identity
      rotated = t.rotate_z(Math::PI / 2)
      expect(rotated.rotation.z).to be_within(0.001).of(Math.sin(Math::PI / 4))
    end
  end

  describe '#forward' do
    it 'returns the forward direction vector' do
      t = described_class.identity
      f = t.forward
      expect(f.x).to be_within(0.001).of(0.0)
      expect(f.y).to be_within(0.001).of(0.0)
      expect(f.z).to be_within(0.001).of(-1.0)
    end
  end

  describe '#right' do
    it 'returns the right direction vector' do
      t = described_class.identity
      r = t.right
      expect(r.x).to be_within(0.001).of(1.0)
      expect(r.y).to be_within(0.001).of(0.0)
      expect(r.z).to be_within(0.001).of(0.0)
    end
  end

  describe '#up' do
    it 'returns the up direction vector' do
      t = described_class.identity
      u = t.up
      expect(u.x).to be_within(0.001).of(0.0)
      expect(u.y).to be_within(0.001).of(1.0)
      expect(u.z).to be_within(0.001).of(0.0)
    end
  end

  describe '#translate' do
    it 'mutates translation via block' do
      t = described_class.identity
      t.translate { |v| Bevy::Vec3.new(v.x + 1.0, v.y + 2.0, v.z + 3.0) }
      expect(t.translation.x).to eq(1.0)
      expect(t.translation.y).to eq(2.0)
      expect(t.translation.z).to eq(3.0)
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      t = described_class.from_xyz(1.0, 2.0, 3.0)
      native = t.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native.type_name).to eq('Transform')
      expect(native['translation_x']).to eq(1.0)
      expect(native['translation_y']).to eq(2.0)
      expect(native['translation_z']).to eq(3.0)
    end
  end

  describe '.from_native' do
    it 'creates a Transform from a native Component' do
      native = Bevy::Component.new('Transform')
      native['translation_x'] = 5.0
      native['translation_y'] = 10.0
      native['translation_z'] = 15.0
      native['scale_x'] = 2.0
      native['scale_y'] = 2.0
      native['scale_z'] = 2.0

      t = described_class.from_native(native)
      expect(t.translation.x).to eq(5.0)
      expect(t.translation.y).to eq(10.0)
      expect(t.translation.z).to eq(15.0)
      expect(t.scale.x).to eq(2.0)
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      t = described_class.from_xyz(1.0, 2.0, 3.0)
      h = t.to_h
      expect(h[:translation]).to eq([1.0, 2.0, 3.0])
      expect(h[:scale]).to eq([1.0, 1.0, 1.0])
    end
  end

  describe '#type_name' do
    it 'returns Transform' do
      t = described_class.identity
      expect(t.type_name).to eq('Transform')
    end
  end
end

RSpec.describe 'World with Transform' do
  let(:world) { Bevy::World.new }

  describe '#spawn_entity with Transform' do
    it 'spawns an entity with a Transform component' do
      transform = Bevy::Transform.from_xyz(1.0, 2.0, 3.0)
      entity = world.spawn_entity(transform)
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#get_component with Transform' do
    it 'retrieves a Transform component' do
      transform = Bevy::Transform.from_xyz(5.0, 10.0, 15.0)
      entity = world.spawn_entity(transform)

      retrieved = world.get_component(entity, Bevy::Transform)
      expect(retrieved).to be_a(Bevy::Transform)
      expect(retrieved.translation.x).to eq(5.0)
      expect(retrieved.translation.y).to eq(10.0)
      expect(retrieved.translation.z).to eq(15.0)
    end
  end

  describe '#has? with Transform' do
    it 'checks if entity has Transform' do
      transform = Bevy::Transform.from_xyz(1.0, 2.0, 3.0)
      entity = world.spawn_entity(transform)
      expect(world.has?(entity, Bevy::Transform)).to be true
    end
  end
end
