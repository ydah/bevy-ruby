# frozen_string_literal: true

RSpec.describe Bevy::ShaderSource do
  describe '.new' do
    it 'creates with vertex and fragment sources' do
      source = described_class.new(vertex: 'vert', fragment: 'frag')
      expect(source.vertex).to eq('vert')
      expect(source.fragment).to eq('frag')
      expect(source.compute).to be_nil
    end

    it 'creates compute shader' do
      source = described_class.new(compute: 'compute_code')
      expect(source.compute).to eq('compute_code')
    end
  end

  describe '#has_vertex?' do
    it 'returns true when vertex source exists' do
      source = described_class.new(vertex: 'code')
      expect(source.has_vertex?).to be true
    end

    it 'returns false when no vertex source' do
      source = described_class.new
      expect(source.has_vertex?).to be false
    end
  end

  describe '#has_fragment?' do
    it 'returns true when fragment source exists' do
      source = described_class.new(fragment: 'code')
      expect(source.has_fragment?).to be true
    end
  end

  describe '#has_compute?' do
    it 'returns true when compute source exists' do
      source = described_class.new(compute: 'code')
      expect(source.has_compute?).to be true
    end
  end

  describe '#type_name' do
    it 'returns ShaderSource' do
      expect(described_class.new.type_name).to eq('ShaderSource')
    end
  end
end

RSpec.describe Bevy::Shader do
  describe '.new' do
    it 'creates shader with name and source' do
      source = Bevy::ShaderSource.new(fragment: 'frag')
      shader = described_class.new(name: 'my_shader', source: source)
      expect(shader.name).to eq('my_shader')
      expect(shader.source).to eq(source)
    end

    it 'creates shader with path' do
      shader = described_class.new(name: 'my_shader', path: 'shaders/custom.wgsl')
      expect(shader.path).to eq('shaders/custom.wgsl')
    end
  end

  describe '.from_wgsl' do
    it 'creates shader from WGSL source' do
      shader = described_class.from_wgsl('test', '@fragment fn main() {}')
      expect(shader.name).to eq('test')
      expect(shader.source).to be_a(Bevy::ShaderSource)
    end
  end

  describe '.from_file' do
    it 'creates shader from file path' do
      shader = described_class.from_file('test', 'shaders/test.wgsl')
      expect(shader.name).to eq('test')
      expect(shader.path).to eq('shaders/test.wgsl')
    end
  end

  describe '#loaded?' do
    it 'returns truthy when source or path exists' do
      shader = described_class.new(name: 'test', path: 'test.wgsl')
      expect(shader.loaded?).to be_truthy
    end

    it 'returns falsy when neither exists' do
      shader = described_class.new(name: 'test')
      expect(shader.loaded?).to be_falsy
    end
  end

  describe '#type_name' do
    it 'returns Shader' do
      expect(described_class.new(name: 'test').type_name).to eq('Shader')
    end
  end
end

RSpec.describe Bevy::ShaderDefVal do
  describe '.new' do
    it 'creates shader definition' do
      def_val = described_class.new('MAX_LIGHTS', 16)
      expect(def_val.key).to eq('MAX_LIGHTS')
      expect(def_val.value).to eq(16)
    end
  end

  describe '.bool' do
    it 'creates boolean definition' do
      def_val = described_class.bool('ENABLE_SHADOWS', true)
      expect(def_val.value).to eq(1)
    end

    it 'converts false to 0' do
      def_val = described_class.bool('ENABLE_SHADOWS', false)
      expect(def_val.value).to eq(0)
    end
  end

  describe '.int' do
    it 'creates integer definition' do
      def_val = described_class.int('COUNT', 42)
      expect(def_val.value).to eq(42)
    end
  end

  describe '.uint' do
    it 'creates unsigned integer definition' do
      def_val = described_class.uint('SIZE', -5)
      expect(def_val.value).to eq(5)
    end
  end

  describe '#type_name' do
    it 'returns ShaderDefVal' do
      expect(described_class.new('key', 1).type_name).to eq('ShaderDefVal')
    end
  end
end

RSpec.describe Bevy::ShaderDefs do
  describe '.new' do
    it 'creates empty definitions' do
      defs = described_class.new
      expect(defs.to_h).to be_empty
    end
  end

  describe '#set' do
    it 'sets definition value' do
      defs = described_class.new
      defs.set('MAX_LIGHTS', 16)
      expect(defs.get('MAX_LIGHTS')).to eq(16)
    end

    it 'returns self for chaining' do
      defs = described_class.new
      result = defs.set('A', 1)
      expect(result).to eq(defs)
    end
  end

  describe '#remove' do
    it 'removes definition' do
      defs = described_class.new
      defs.set('A', 1)
      defs.remove('A')
      expect(defs.get('A')).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns ShaderDefs' do
      expect(described_class.new.type_name).to eq('ShaderDefs')
    end
  end
end

RSpec.describe Bevy::PostProcessSettings do
  describe '.new' do
    it 'creates enabled settings' do
      settings = described_class.new
      expect(settings.enabled).to be true
      expect(settings.intensity).to eq(1.0)
    end

    it 'accepts custom values' do
      settings = described_class.new(enabled: false, intensity: 0.5)
      expect(settings.enabled).to be false
      expect(settings.intensity).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns PostProcessSettings' do
      expect(described_class.new.type_name).to eq('PostProcessSettings')
    end
  end
end

RSpec.describe Bevy::Bloom do
  describe '.new' do
    it 'creates with default values' do
      bloom = described_class.new
      expect(bloom.intensity).to eq(0.5)
      expect(bloom.threshold).to eq(1.0)
      expect(bloom.composite_mode).to eq(:additive)
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      bloom = described_class.new
      hash = bloom.to_h
      expect(hash).to have_key(:intensity)
      expect(hash).to have_key(:threshold)
    end
  end

  describe '#type_name' do
    it 'returns Bloom' do
      expect(described_class.new.type_name).to eq('Bloom')
    end
  end
end

RSpec.describe Bevy::ChromaticAberration do
  describe '.new' do
    it 'creates with default values' do
      ca = described_class.new
      expect(ca.intensity).to eq(0.02)
      expect(ca.max_samples).to eq(8)
    end
  end

  describe '#type_name' do
    it 'returns ChromaticAberration' do
      expect(described_class.new.type_name).to eq('ChromaticAberration')
    end
  end
end

RSpec.describe Bevy::Vignette do
  describe '.new' do
    it 'creates with default values' do
      vignette = described_class.new
      expect(vignette.intensity).to eq(0.5)
      expect(vignette.radius).to eq(0.5)
      expect(vignette.color).to be_a(Bevy::Color)
    end
  end

  describe '#type_name' do
    it 'returns Vignette' do
      expect(described_class.new.type_name).to eq('Vignette')
    end
  end
end

RSpec.describe Bevy::FilmGrain do
  describe '.new' do
    it 'creates with default values' do
      fg = described_class.new
      expect(fg.intensity).to eq(0.1)
      expect(fg.response).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns FilmGrain' do
      expect(described_class.new.type_name).to eq('FilmGrain')
    end
  end
end

RSpec.describe Bevy::Tonemapping do
  describe '.new' do
    it 'creates with default mode' do
      tm = described_class.new
      expect(tm.mode).to eq(:tony_mc_mapface)
    end

    it 'accepts custom mode' do
      tm = described_class.new(mode: :aces_fitted)
      expect(tm.mode).to eq(:aces_fitted)
    end
  end

  describe 'MODES' do
    it 'defines available modes' do
      expect(Bevy::Tonemapping::MODES).to include(:none, :reinhard, :aces_fitted)
    end
  end

  describe '#type_name' do
    it 'returns Tonemapping' do
      expect(described_class.new.type_name).to eq('Tonemapping')
    end
  end
end

RSpec.describe Bevy::ColorGrading do
  describe '.new' do
    it 'creates with default values' do
      cg = described_class.new
      expect(cg.exposure).to eq(0.0)
      expect(cg.gamma).to eq(1.0)
      expect(cg.saturation).to eq(1.0)
      expect(cg.contrast).to eq(1.0)
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      cg = described_class.new
      expect(cg.to_h).to have_key(:exposure)
    end
  end

  describe '#type_name' do
    it 'returns ColorGrading' do
      expect(described_class.new.type_name).to eq('ColorGrading')
    end
  end
end

RSpec.describe Bevy::DepthOfField do
  describe '.new' do
    it 'creates with default values' do
      dof = described_class.new
      expect(dof.focal_distance).to eq(10.0)
      expect(dof.focal_length).to eq(50.0)
      expect(dof.aperture_f_stops).to eq(2.8)
    end
  end

  describe '#type_name' do
    it 'returns DepthOfField' do
      expect(described_class.new.type_name).to eq('DepthOfField')
    end
  end
end

RSpec.describe Bevy::MotionBlur do
  describe '.new' do
    it 'creates with default values' do
      mb = described_class.new
      expect(mb.shutter_angle).to eq(0.5)
      expect(mb.samples).to eq(4)
    end
  end

  describe '#type_name' do
    it 'returns MotionBlur' do
      expect(described_class.new.type_name).to eq('MotionBlur')
    end
  end
end

RSpec.describe Bevy::Fxaa do
  describe '.new' do
    it 'creates enabled FXAA' do
      fxaa = described_class.new
      expect(fxaa.enabled).to be true
      expect(fxaa.edge_threshold).to eq(:high)
    end
  end

  describe '#type_name' do
    it 'returns Fxaa' do
      expect(described_class.new.type_name).to eq('Fxaa')
    end
  end
end

RSpec.describe Bevy::Smaa do
  describe '.new' do
    it 'creates with default preset' do
      smaa = described_class.new
      expect(smaa.preset).to eq(:high)
    end

    it 'accepts custom preset' do
      smaa = described_class.new(preset: :ultra)
      expect(smaa.preset).to eq(:ultra)
    end
  end

  describe 'PRESETS' do
    it 'defines available presets' do
      expect(Bevy::Smaa::PRESETS).to include(:low, :medium, :high, :ultra)
    end
  end

  describe '#type_name' do
    it 'returns Smaa' do
      expect(described_class.new.type_name).to eq('Smaa')
    end
  end
end
