# frozen_string_literal: true

RSpec.describe Bevy::PointLight do
  describe '.new' do
    it 'creates with default values' do
      light = described_class.new
      expect(light.color).to be_a(Bevy::Color)
      expect(light.intensity).to eq(800.0)
      expect(light.range).to eq(20.0)
      expect(light.shadows_enabled).to be true
    end

    it 'creates with custom values' do
      light = described_class.new(
        color: Bevy::Color.red,
        intensity: 1000.0,
        range: 30.0,
        shadows_enabled: false
      )
      expect(light.color.r).to eq(1.0)
      expect(light.intensity).to eq(1000.0)
      expect(light.range).to eq(30.0)
      expect(light.shadows_enabled).to be false
    end
  end

  describe '#with_color' do
    it 'returns new light with updated color' do
      light = described_class.new
      new_light = light.with_color(Bevy::Color.blue)
      expect(new_light.color.b).to eq(1.0)
      expect(light.color.b).to eq(1.0)
    end
  end

  describe '#with_intensity' do
    it 'returns new light with updated intensity' do
      light = described_class.new
      new_light = light.with_intensity(500.0)
      expect(new_light.intensity).to eq(500.0)
    end
  end

  describe '#with_range' do
    it 'returns new light with updated range' do
      light = described_class.new
      new_light = light.with_range(50.0)
      expect(new_light.range).to eq(50.0)
    end
  end

  describe '#type_name' do
    it 'returns PointLight' do
      expect(described_class.new.type_name).to eq('PointLight')
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      light = described_class.new(intensity: 600.0)
      h = light.to_h
      expect(h[:intensity]).to eq(600.0)
      expect(h[:color]).to be_an(Array)
    end
  end

  describe '#to_native' do
    it 'converts to Component' do
      light = described_class.new(intensity: 900.0, range: 25.0)
      native = light.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native['intensity']).to eq(900.0)
      expect(native['range']).to eq(25.0)
    end
  end

  describe '.from_native' do
    it 'creates from native Component' do
      native = Bevy::Component.new('PointLight')
      native['color_r'] = 1.0
      native['color_g'] = 0.5
      native['color_b'] = 0.0
      native['color_a'] = 1.0
      native['intensity'] = 750.0
      native['range'] = 15.0
      native['shadows_enabled'] = false

      light = described_class.from_native(native)
      expect(light.color.r).to eq(1.0)
      expect(light.color.g).to eq(0.5)
      expect(light.intensity).to eq(750.0)
      expect(light.shadows_enabled).to be false
    end
  end
end

RSpec.describe Bevy::DirectionalLight do
  describe '.new' do
    it 'creates with default values' do
      light = described_class.new
      expect(light.color).to be_a(Bevy::Color)
      expect(light.illuminance).to eq(100_000.0)
      expect(light.shadows_enabled).to be true
    end

    it 'creates with custom values' do
      light = described_class.new(
        color: Bevy::Color.from_hex('#FFD700'),
        illuminance: 50_000.0
      )
      expect(light.illuminance).to eq(50_000.0)
    end
  end

  describe '#with_color' do
    it 'returns new light with updated color' do
      light = described_class.new
      new_light = light.with_color(Bevy::Color.rgba(1.0, 1.0, 0.0, 1.0))
      expect(new_light.color.r).to eq(1.0)
      expect(new_light.color.g).to eq(1.0)
    end
  end

  describe '#with_illuminance' do
    it 'returns new light with updated illuminance' do
      light = described_class.new
      new_light = light.with_illuminance(75_000.0)
      expect(new_light.illuminance).to eq(75_000.0)
    end
  end

  describe '#type_name' do
    it 'returns DirectionalLight' do
      expect(described_class.new.type_name).to eq('DirectionalLight')
    end
  end

  describe '#to_native' do
    it 'converts to Component' do
      light = described_class.new(illuminance: 80_000.0)
      native = light.to_native
      expect(native['illuminance']).to eq(80_000.0)
    end
  end

  describe '.from_native' do
    it 'creates from native Component' do
      native = Bevy::Component.new('DirectionalLight')
      native['color_r'] = 1.0
      native['color_g'] = 1.0
      native['color_b'] = 0.9
      native['color_a'] = 1.0
      native['illuminance'] = 120_000.0

      light = described_class.from_native(native)
      expect(light.illuminance).to eq(120_000.0)
      expect(light.color.b).to be_within(0.01).of(0.9)
    end
  end
end

RSpec.describe Bevy::SpotLight do
  describe '.new' do
    it 'creates with default values' do
      light = described_class.new
      expect(light.intensity).to eq(800.0)
      expect(light.range).to eq(20.0)
      expect(light.inner_angle).to eq(0.0)
      expect(light.outer_angle).to be_within(0.01).of(Math::PI / 4.0)
    end

    it 'creates with custom angles' do
      light = described_class.new(
        inner_angle: 0.1,
        outer_angle: 0.5
      )
      expect(light.inner_angle).to eq(0.1)
      expect(light.outer_angle).to eq(0.5)
    end
  end

  describe '#with_color' do
    it 'returns new light with updated color' do
      light = described_class.new
      new_light = light.with_color(Bevy::Color.green)
      expect(new_light.color.g).to eq(1.0)
    end
  end

  describe '#with_intensity' do
    it 'returns new light with updated intensity' do
      light = described_class.new
      new_light = light.with_intensity(1200.0)
      expect(new_light.intensity).to eq(1200.0)
    end
  end

  describe '#with_angles' do
    it 'returns new light with updated angles' do
      light = described_class.new
      new_light = light.with_angles(0.2, 0.8)
      expect(new_light.inner_angle).to eq(0.2)
      expect(new_light.outer_angle).to eq(0.8)
    end
  end

  describe '#type_name' do
    it 'returns SpotLight' do
      expect(described_class.new.type_name).to eq('SpotLight')
    end
  end

  describe '#to_h' do
    it 'includes all properties' do
      light = described_class.new
      h = light.to_h
      expect(h).to have_key(:color)
      expect(h).to have_key(:intensity)
      expect(h).to have_key(:inner_angle)
      expect(h).to have_key(:outer_angle)
    end
  end

  describe '#to_native' do
    it 'converts to Component' do
      light = described_class.new(intensity: 1000.0)
      native = light.to_native
      expect(native['intensity']).to eq(1000.0)
    end
  end

  describe '.from_native' do
    it 'creates from native Component' do
      native = Bevy::Component.new('SpotLight')
      native['color_r'] = 1.0
      native['color_g'] = 1.0
      native['color_b'] = 1.0
      native['color_a'] = 1.0
      native['intensity'] = 500.0
      native['inner_angle'] = 0.1
      native['outer_angle'] = 0.4

      light = described_class.from_native(native)
      expect(light.intensity).to eq(500.0)
      expect(light.inner_angle).to eq(0.1)
      expect(light.outer_angle).to eq(0.4)
    end
  end
end

RSpec.describe Bevy::AmbientLight do
  describe '.new' do
    it 'creates with default values' do
      light = described_class.new
      expect(light.color).to be_a(Bevy::Color)
      expect(light.brightness).to eq(0.05)
    end

    it 'creates with custom values' do
      light = described_class.new(
        color: Bevy::Color.from_hex('#87CEEB'),
        brightness: 0.1
      )
      expect(light.brightness).to eq(0.1)
    end
  end

  describe '#with_color' do
    it 'returns new light with updated color' do
      light = described_class.new
      new_light = light.with_color(Bevy::Color.rgba(0.0, 1.0, 1.0, 1.0))
      expect(new_light.color.g).to eq(1.0)
      expect(new_light.color.b).to eq(1.0)
    end
  end

  describe '#with_brightness' do
    it 'returns new light with updated brightness' do
      light = described_class.new
      new_light = light.with_brightness(0.2)
      expect(new_light.brightness).to eq(0.2)
    end
  end

  describe '#type_name' do
    it 'returns AmbientLight' do
      expect(described_class.new.type_name).to eq('AmbientLight')
    end
  end

  describe '#to_native' do
    it 'converts to Component' do
      light = described_class.new(brightness: 0.15)
      native = light.to_native
      expect(native['brightness']).to eq(0.15)
    end
  end

  describe '.from_native' do
    it 'creates from native Component' do
      native = Bevy::Component.new('AmbientLight')
      native['color_r'] = 0.9
      native['color_g'] = 0.9
      native['color_b'] = 1.0
      native['color_a'] = 1.0
      native['brightness'] = 0.08

      light = described_class.from_native(native)
      expect(light.brightness).to eq(0.08)
      expect(light.color.b).to eq(1.0)
    end
  end
end

RSpec.describe Bevy::EnvironmentMapLight do
  describe '.new' do
    it 'creates with default values' do
      light = described_class.new
      expect(light.diffuse_map).to be_nil
      expect(light.specular_map).to be_nil
      expect(light.intensity).to eq(1.0)
    end

    it 'creates with maps' do
      light = described_class.new(
        diffuse_map: 'diffuse.hdr',
        specular_map: 'specular.hdr',
        intensity: 2.0
      )
      expect(light.diffuse_map).to eq('diffuse.hdr')
      expect(light.specular_map).to eq('specular.hdr')
      expect(light.intensity).to eq(2.0)
    end
  end

  describe '#type_name' do
    it 'returns EnvironmentMapLight' do
      expect(described_class.new.type_name).to eq('EnvironmentMapLight')
    end
  end
end

RSpec.describe Bevy::CascadeShadowConfig do
  describe '.new' do
    it 'creates with default values' do
      config = described_class.new
      expect(config.num_cascades).to eq(4)
      expect(config.minimum_distance).to eq(0.1)
      expect(config.maximum_distance).to eq(1000.0)
    end

    it 'creates with custom values' do
      config = described_class.new(
        num_cascades: 3,
        maximum_distance: 500.0
      )
      expect(config.num_cascades).to eq(3)
      expect(config.maximum_distance).to eq(500.0)
    end
  end

  describe '#type_name' do
    it 'returns CascadeShadowConfig' do
      expect(described_class.new.type_name).to eq('CascadeShadowConfig')
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      config = described_class.new
      h = config.to_h
      expect(h).to have_key(:num_cascades)
      expect(h).to have_key(:minimum_distance)
      expect(h).to have_key(:maximum_distance)
    end
  end
end

RSpec.describe Bevy::LightBundle do
  describe '.new' do
    it 'creates bundle with light' do
      light = Bevy::PointLight.new
      bundle = described_class.new(light: light)
      expect(bundle.light).to eq(light)
      expect(bundle.transform).to be_a(Bevy::Transform)
      expect(bundle.visibility).to be true
    end

    it 'creates bundle with custom transform' do
      light = Bevy::SpotLight.new
      transform = Bevy::Transform.from_xyz(10.0, 20.0, 30.0)
      bundle = described_class.new(light: light, transform: transform)
      expect(bundle.transform.translation.x).to eq(10.0)
    end
  end

  describe '#type_name' do
    it 'returns light type bundle name' do
      point_bundle = described_class.new(light: Bevy::PointLight.new)
      expect(point_bundle.type_name).to eq('PointLightBundle')

      spot_bundle = described_class.new(light: Bevy::SpotLight.new)
      expect(spot_bundle.type_name).to eq('SpotLightBundle')
    end
  end
end
