# frozen_string_literal: true

RSpec.describe Bevy::BlendMode do
  it 'defines blend modes' do
    expect(Bevy::BlendMode::OPAQUE).to eq(:opaque)
    expect(Bevy::BlendMode::BLEND).to eq(:blend)
    expect(Bevy::BlendMode::ADD).to eq(:add)
    expect(Bevy::BlendMode::MULTIPLY).to eq(:multiply)
  end
end

RSpec.describe Bevy::ColorMaterial do
  describe '.new' do
    it 'creates with default values' do
      mat = described_class.new
      expect(mat.color).to be_a(Bevy::Color)
      expect(mat.alpha_mode).to eq(Bevy::BlendMode::OPAQUE)
    end

    it 'creates with custom color' do
      color = Bevy::Color.new(1.0, 0.0, 0.0, 1.0)
      mat = described_class.new(color)
      expect(mat.color.r).to eq(1.0)
    end

    it 'sets blend mode automatically for transparent colors' do
      color = Bevy::Color.new(1.0, 0.0, 0.0, 0.5)
      mat = described_class.new(color)
      expect(mat.alpha_mode).to eq(Bevy::BlendMode::BLEND)
    end
  end

  describe '.from_rgb' do
    it 'creates from RGB values' do
      mat = described_class.from_rgb(0.5, 0.5, 0.5)
      expect(mat.color.r).to eq(0.5)
      expect(mat.color.a).to eq(1.0)
    end
  end

  describe '.from_rgba' do
    it 'creates from RGBA values' do
      mat = described_class.from_rgba(1.0, 0.0, 0.0, 0.8)
      expect(mat.color.r).to eq(1.0)
      expect(mat.color.a).to be_within(0.001).of(0.8)
    end
  end

  describe '#with_alpha_mode' do
    it 'returns new material with updated alpha mode' do
      mat = described_class.new
      new_mat = mat.with_alpha_mode(Bevy::BlendMode::ADD)
      expect(new_mat.alpha_mode).to eq(Bevy::BlendMode::ADD)
    end
  end

  describe '#type_name' do
    it 'returns ColorMaterial' do
      mat = described_class.new
      expect(mat.type_name).to eq('ColorMaterial')
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      color = Bevy::Color.new(0.5, 0.6, 0.7, 1.0)
      mat = described_class.new(color)
      native = mat.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native['color_r']).to be_within(0.001).of(0.5)
      expect(native['color_g']).to be_within(0.001).of(0.6)
    end
  end
end

RSpec.describe Bevy::StandardMaterial do
  describe '.new' do
    it 'creates with default values' do
      mat = described_class.new
      expect(mat.metallic).to eq(0.0)
      expect(mat.roughness).to eq(0.5)
      expect(mat.reflectance).to eq(0.5)
      expect(mat.unlit).to be false
      expect(mat.double_sided).to be false
    end

    it 'creates with custom values' do
      mat = described_class.new(
        metallic: 1.0,
        roughness: 0.2,
        unlit: true
      )
      expect(mat.metallic).to eq(1.0)
      expect(mat.roughness).to eq(0.2)
      expect(mat.unlit).to be true
    end
  end

  describe '.from_color' do
    it 'creates material from color' do
      color = Bevy::Color.red
      mat = described_class.from_color(color)
      expect(mat.base_color.r).to eq(1.0)
    end
  end

  describe '#with_metallic' do
    it 'returns new material with updated metallic' do
      mat = described_class.new
      new_mat = mat.with_metallic(0.8)
      expect(new_mat.metallic).to eq(0.8)
      expect(mat.metallic).to eq(0.0)
    end

    it 'clamps metallic to 0..1' do
      mat = described_class.new
      new_mat = mat.with_metallic(1.5)
      expect(new_mat.metallic).to eq(1.0)
    end
  end

  describe '#with_roughness' do
    it 'returns new material with updated roughness' do
      mat = described_class.new
      new_mat = mat.with_roughness(0.3)
      expect(new_mat.roughness).to eq(0.3)
    end
  end

  describe '#with_emissive' do
    it 'returns new material with emissive color' do
      mat = described_class.new
      emissive = Bevy::Color.new(1.0, 0.5, 0.0, 1.0)
      new_mat = mat.with_emissive(emissive)
      expect(new_mat.emissive.r).to eq(1.0)
    end
  end

  describe '#with_unlit' do
    it 'returns new unlit material' do
      mat = described_class.new
      new_mat = mat.with_unlit
      expect(new_mat.unlit).to be true
    end
  end

  describe '#with_double_sided' do
    it 'returns new double-sided material' do
      mat = described_class.new
      new_mat = mat.with_double_sided
      expect(new_mat.double_sided).to be true
    end
  end

  describe '#with_texture' do
    it 'returns new material with texture path' do
      mat = described_class.new
      new_mat = mat.with_texture('textures/diffuse.png')
      expect(new_mat.texture_path).to eq('textures/diffuse.png')
    end
  end

  describe '#with_normal_map' do
    it 'returns new material with normal map path' do
      mat = described_class.new
      new_mat = mat.with_normal_map('textures/normal.png')
      expect(new_mat.normal_map_path).to eq('textures/normal.png')
    end
  end

  describe '#type_name' do
    it 'returns StandardMaterial' do
      mat = described_class.new
      expect(mat.type_name).to eq('StandardMaterial')
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      mat = described_class.new(metallic: 0.5, roughness: 0.3)
      native = mat.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native['metallic']).to eq(0.5)
      expect(native['roughness']).to eq(0.3)
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      mat = described_class.new(metallic: 0.7)
      h = mat.to_h
      expect(h[:metallic]).to eq(0.7)
      expect(h[:roughness]).to eq(0.5)
    end
  end
end

RSpec.describe Bevy::MaterialBuilder do
  describe '#color' do
    it 'sets base color' do
      mat = described_class.new.color(1.0, 0.0, 0.0).build
      expect(mat.base_color.r).to eq(1.0)
    end

    it 'sets blend mode for transparent colors' do
      mat = described_class.new.color(1.0, 0.0, 0.0, 0.5).build
      expect(mat.alpha_mode).to eq(Bevy::BlendMode::BLEND)
    end
  end

  describe '#metallic' do
    it 'sets metallic value' do
      mat = described_class.new.metallic(0.9).build
      expect(mat.metallic).to eq(0.9)
    end
  end

  describe '#roughness' do
    it 'sets roughness value' do
      mat = described_class.new.roughness(0.2).build
      expect(mat.roughness).to eq(0.2)
    end
  end

  describe '#emissive' do
    it 'sets emissive color' do
      mat = described_class.new.emissive(1.0, 0.5, 0.0).build
      expect(mat.emissive.r).to eq(1.0)
      expect(mat.emissive.g).to eq(0.5)
    end
  end

  describe '#unlit' do
    it 'sets unlit flag' do
      mat = described_class.new.unlit.build
      expect(mat.unlit).to be true
    end
  end

  describe '#double_sided' do
    it 'sets double_sided flag' do
      mat = described_class.new.double_sided.build
      expect(mat.double_sided).to be true
    end
  end

  describe '#texture' do
    it 'sets texture path' do
      mat = described_class.new.texture('tex.png').build
      expect(mat.texture_path).to eq('tex.png')
    end
  end

  describe 'chaining' do
    it 'allows method chaining' do
      mat = described_class.new
                           .color(1.0, 0.0, 0.0)
                           .metallic(0.8)
                           .roughness(0.1)
                           .emissive(0.5, 0.0, 0.0)
                           .build

      expect(mat.base_color.r).to eq(1.0)
      expect(mat.metallic).to eq(0.8)
      expect(mat.roughness).to eq(0.1)
      expect(mat.emissive.r).to eq(0.5)
    end
  end
end
