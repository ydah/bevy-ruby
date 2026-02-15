# frozen_string_literal: true

RSpec.describe Bevy::Camera2d do
  describe '.new' do
    it 'creates a Camera2d with default values' do
      c = described_class.new
      expect(c.order).to eq(0)
      expect(c.clear_color).to be_a(Bevy::Color)
    end

    it 'creates a Camera2d with custom order' do
      c = described_class.new(order: 1)
      expect(c.order).to eq(1)
    end

    it 'creates a Camera2d with custom clear color' do
      color = Bevy::Color.red
      c = described_class.new(clear_color: color)
      expect(c.clear_color.r).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns Camera2d' do
      c = described_class.new
      expect(c.type_name).to eq('Camera2d')
    end
  end

  describe '#with_order' do
    it 'returns a new camera with updated order' do
      c = described_class.new(order: 0)
      c2 = c.with_order(5)
      expect(c2.order).to eq(5)
      expect(c.order).to eq(0)
    end
  end

  describe '#with_clear_color' do
    it 'returns a new camera with updated clear color' do
      c = described_class.new
      c2 = c.with_clear_color(Bevy::Color.blue)
      expect(c2.clear_color.b).to eq(1.0)
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      c = described_class.new(order: 2, clear_color: Bevy::Color.green)
      native = c.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native.type_name).to eq('Camera2d')
      expect(native['order']).to eq(2)
      expect(native['clear_color_g']).to eq(1.0)
    end
  end

  describe '.from_native' do
    it 'creates a Camera2d from a native Component' do
      native = Bevy::Component.new('Camera2d')
      native['order'] = 3
      native['clear_color_r'] = 0.5
      native['clear_color_g'] = 0.5
      native['clear_color_b'] = 0.5
      native['clear_color_a'] = 1.0

      c = described_class.from_native(native)
      expect(c.order).to eq(3)
      expect(c.clear_color.r).to be_within(0.001).of(0.5)
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      c = described_class.new(order: 1)
      h = c.to_h
      expect(h[:order]).to eq(1)
      expect(h[:clear_color]).to be_an(Array)
    end
  end
end

RSpec.describe Bevy::Camera3d do
  describe '.new' do
    it 'creates a Camera3d with default values' do
      c = described_class.new
      expect(c.order).to eq(0)
      expect(c.fov).to eq(45.0)
      expect(c.near).to eq(0.1)
      expect(c.far).to eq(1000.0)
    end

    it 'creates a Camera3d with custom values' do
      c = described_class.new(fov: 60.0, near: 0.5, far: 500.0)
      expect(c.fov).to eq(60.0)
      expect(c.near).to eq(0.5)
      expect(c.far).to eq(500.0)
    end
  end

  describe '#type_name' do
    it 'returns Camera3d' do
      c = described_class.new
      expect(c.type_name).to eq('Camera3d')
    end
  end

  describe '#with_fov' do
    it 'returns a new camera with updated fov' do
      c = described_class.new
      c2 = c.with_fov(90.0)
      expect(c2.fov).to eq(90.0)
      expect(c.fov).to eq(45.0)
    end
  end

  describe '#with_near' do
    it 'returns a new camera with updated near plane' do
      c = described_class.new
      c2 = c.with_near(1.0)
      expect(c2.near).to eq(1.0)
    end
  end

  describe '#with_far' do
    it 'returns a new camera with updated far plane' do
      c = described_class.new
      c2 = c.with_far(2000.0)
      expect(c2.far).to eq(2000.0)
    end
  end

  describe '#to_native' do
    it 'converts to a Component' do
      c = described_class.new(fov: 75.0, near: 0.2, far: 800.0)
      native = c.to_native
      expect(native).to be_a(Bevy::Component)
      expect(native.type_name).to eq('Camera3d')
      expect(native['fov']).to eq(75.0)
      expect(native['near']).to eq(0.2)
      expect(native['far']).to eq(800.0)
    end
  end

  describe '.from_native' do
    it 'creates a Camera3d from a native Component' do
      native = Bevy::Component.new('Camera3d')
      native['order'] = 1
      native['fov'] = 60.0
      native['near'] = 0.5
      native['far'] = 500.0

      c = described_class.from_native(native)
      expect(c.order).to eq(1)
      expect(c.fov).to eq(60.0)
      expect(c.near).to eq(0.5)
      expect(c.far).to eq(500.0)
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      c = described_class.new(fov: 50.0)
      h = c.to_h
      expect(h[:fov]).to eq(50.0)
      expect(h[:near]).to eq(0.1)
      expect(h[:far]).to eq(1000.0)
    end
  end
end

RSpec.describe Bevy::Viewport do
  describe '.new' do
    it 'creates a viewport with position and size' do
      viewport = described_class.new(10, 20, 800, 600)
      expect(viewport.x).to eq(10)
      expect(viewport.y).to eq(20)
      expect(viewport.width).to eq(800)
      expect(viewport.height).to eq(600)
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      viewport = described_class.new(0, 0, 1920, 1080)
      h = viewport.to_h
      expect(h[:x]).to eq(0)
      expect(h[:width]).to eq(1920)
    end
  end
end

RSpec.describe Bevy::SmoothFollow do
  describe '.new' do
    it 'creates with default values' do
      sf = described_class.new
      expect(sf.smoothness).to eq(5.0)
      expect(sf.enabled).to be true
      expect(sf.target).to be_nil
    end

    it 'creates with custom smoothness' do
      sf = described_class.new(smoothness: 10.0)
      expect(sf.smoothness).to eq(10.0)
    end
  end

  describe '#follow' do
    it 'sets the target' do
      sf = described_class.new
      target = Bevy::Vec3.new(100.0, 50.0, 0.0)
      sf.follow(target)
      expect(sf.target).to eq(target)
    end
  end

  describe '#lerp_position' do
    it 'returns current position when no target' do
      sf = described_class.new
      current = Bevy::Vec3.new(0.0, 0.0, 0.0)
      result = sf.lerp_position(current, 0.016)
      expect(result.x).to eq(0.0)
    end

    it 'interpolates towards target' do
      sf = described_class.new(smoothness: 5.0)
      sf.follow(Bevy::Vec3.new(100.0, 0.0, 0.0))
      current = Bevy::Vec3.new(0.0, 0.0, 0.0)
      result = sf.lerp_position(current, 0.05)
      expect(result.x).to be > 0.0
      expect(result.x).to be < 100.0
    end

    it 'returns current when disabled' do
      sf = described_class.new(enabled: false)
      sf.follow(Bevy::Vec3.new(100.0, 0.0, 0.0))
      current = Bevy::Vec3.new(0.0, 0.0, 0.0)
      result = sf.lerp_position(current, 0.1)
      expect(result.x).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns SmoothFollow' do
      sf = described_class.new
      expect(sf.type_name).to eq('SmoothFollow')
    end
  end
end

RSpec.describe Bevy::CameraShake do
  describe '.new' do
    it 'creates with default values' do
      shake = described_class.new
      expect(shake.intensity).to eq(0.0)
      expect(shake.frequency).to eq(20.0)
      expect(shake.active?).to be false
    end
  end

  describe '#trigger' do
    it 'starts a camera shake' do
      shake = described_class.new
      shake.trigger(5.0, 0.5)
      expect(shake.intensity).to eq(5.0)
      expect(shake.duration).to eq(0.5)
      expect(shake.active?).to be true
    end
  end

  describe '#update' do
    it 'returns zero offset when not active' do
      shake = described_class.new
      offset = shake.update(0.016)
      expect(offset.x).to eq(0.0)
      expect(offset.y).to eq(0.0)
    end

    it 'returns non-zero offset when active' do
      shake = described_class.new
      shake.trigger(10.0, 1.0)
      offset = shake.update(0.016)
      expect(offset.x.abs + offset.y.abs).to be > 0.0
    end

    it 'becomes inactive after duration' do
      shake = described_class.new
      shake.trigger(5.0, 0.1)
      shake.update(0.2)
      expect(shake.active?).to be false
    end
  end

  describe '#stop' do
    it 'stops the shake immediately' do
      shake = described_class.new
      shake.trigger(5.0, 1.0)
      shake.stop
      expect(shake.active?).to be false
    end
  end
end

RSpec.describe Bevy::CameraBounds do
  describe '.new' do
    it 'creates with default values (disabled)' do
      bounds = described_class.new
      expect(bounds.enabled).to be false
    end

    it 'creates with bounds and enables automatically' do
      bounds = described_class.new(min_x: -100.0, max_x: 100.0)
      expect(bounds.enabled).to be true
      expect(bounds.min_x).to eq(-100.0)
      expect(bounds.max_x).to eq(100.0)
    end
  end

  describe '#clamp' do
    it 'returns position unchanged when disabled' do
      bounds = described_class.new
      pos = Bevy::Vec3.new(500.0, 500.0, 0.0)
      result = bounds.clamp(pos)
      expect(result.x).to eq(500.0)
    end

    it 'clamps position within bounds' do
      bounds = described_class.new(min_x: -100.0, max_x: 100.0, min_y: -50.0, max_y: 50.0)
      pos = Bevy::Vec3.new(200.0, -100.0, 10.0)
      result = bounds.clamp(pos)
      expect(result.x).to eq(100.0)
      expect(result.y).to eq(-50.0)
      expect(result.z).to eq(10.0)
    end
  end

  describe '#type_name' do
    it 'returns CameraBounds' do
      bounds = described_class.new
      expect(bounds.type_name).to eq('CameraBounds')
    end
  end
end

RSpec.describe Bevy::CameraZoom do
  describe '.new' do
    it 'creates with default values' do
      zoom = described_class.new
      expect(zoom.current).to eq(1.0)
      expect(zoom.min).to eq(0.1)
      expect(zoom.max).to eq(10.0)
    end

    it 'creates with custom initial value' do
      zoom = described_class.new(initial: 2.0)
      expect(zoom.current).to eq(2.0)
    end
  end

  describe '#zoom_in' do
    it 'decreases zoom level' do
      zoom = described_class.new(initial: 1.0)
      zoom.zoom_in(0.2)
      expect(zoom.current).to be < 1.0
    end

    it 'respects min limit' do
      zoom = described_class.new(initial: 0.2, min: 0.1)
      zoom.zoom_in(0.5)
      expect(zoom.current).to eq(0.1)
    end
  end

  describe '#zoom_out' do
    it 'increases zoom level' do
      zoom = described_class.new(initial: 1.0)
      zoom.zoom_out(0.2)
      expect(zoom.current).to be > 1.0
    end

    it 'respects max limit' do
      zoom = described_class.new(initial: 9.5, max: 10.0)
      zoom.zoom_out(1.0)
      expect(zoom.current).to eq(10.0)
    end
  end

  describe '#set' do
    it 'sets zoom value directly' do
      zoom = described_class.new
      zoom.set(3.0)
      expect(zoom.current).to eq(3.0)
    end

    it 'clamps to limits' do
      zoom = described_class.new(min: 0.5, max: 5.0)
      zoom.set(10.0)
      expect(zoom.current).to eq(5.0)
    end
  end
end

RSpec.describe 'Camera2d with Viewport' do
  it 'creates camera with viewport' do
    viewport = Bevy::Viewport.new(0, 0, 800, 600)
    camera = Bevy::Camera2d.new(viewport: viewport)
    expect(camera.viewport).to eq(viewport)
  end

  it 'includes viewport in to_native' do
    viewport = Bevy::Viewport.new(10, 20, 640, 480)
    camera = Bevy::Camera2d.new(viewport: viewport)
    native = camera.to_native
    expect(native['viewport_x']).to eq(10)
    expect(native['viewport_width']).to eq(640)
  end
end

RSpec.describe 'World with Camera' do
  let(:world) { Bevy::World.new }

  describe '#spawn_entity with Camera2d' do
    it 'spawns an entity with a Camera2d component' do
      camera = Bevy::Camera2d.new(order: 1)
      entity = world.spawn_entity(camera)
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#spawn_entity with Camera3d' do
    it 'spawns an entity with a Camera3d component' do
      camera = Bevy::Camera3d.new(fov: 60.0)
      entity = world.spawn_entity(camera)
      expect(entity).to be_a(Bevy::Entity)
    end
  end

  describe '#get_component with Camera2d' do
    it 'retrieves a Camera2d component' do
      camera = Bevy::Camera2d.new(order: 5, clear_color: Bevy::Color.red)
      entity = world.spawn_entity(camera)

      retrieved = world.get_component(entity, Bevy::Camera2d)
      expect(retrieved).to be_a(Bevy::Camera2d)
      expect(retrieved.order).to eq(5)
      expect(retrieved.clear_color.r).to eq(1.0)
    end
  end

  describe '#get_component with Camera3d' do
    it 'retrieves a Camera3d component' do
      camera = Bevy::Camera3d.new(fov: 90.0, near: 0.5, far: 2000.0)
      entity = world.spawn_entity(camera)

      retrieved = world.get_component(entity, Bevy::Camera3d)
      expect(retrieved).to be_a(Bevy::Camera3d)
      expect(retrieved.fov).to eq(90.0)
      expect(retrieved.near).to eq(0.5)
      expect(retrieved.far).to eq(2000.0)
    end
  end

  describe '#has? with Camera' do
    it 'checks if entity has Camera2d' do
      camera = Bevy::Camera2d.new
      entity = world.spawn_entity(camera)
      expect(world.has?(entity, Bevy::Camera2d)).to be true
      expect(world.has?(entity, Bevy::Camera3d)).to be false
    end
  end
end
