# frozen_string_literal: true

RSpec.describe Bevy::NavMesh do
  describe '.new' do
    it 'creates empty nav mesh' do
      mesh = described_class.new
      expect(mesh.vertices).to be_empty
      expect(mesh.polygons).to be_empty
      expect(mesh.polygon_count).to eq(0)
    end
  end

  describe '#add_vertex' do
    it 'adds vertex and returns index' do
      mesh = described_class.new
      index = mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      expect(index).to eq(0)
      expect(mesh.vertices.size).to eq(1)
    end

    it 'returns sequential indices' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.zero)
      index = mesh.add_vertex(Bevy::Vec3.one)
      expect(index).to eq(1)
    end
  end

  describe '#add_polygon' do
    it 'adds polygon with vertex indices' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      expect(mesh.polygon_count).to eq(1)
    end

    it 'returns self for chaining' do
      mesh = described_class.new
      3.times { |i| mesh.add_vertex(Bevy::Vec3.new(i.to_f, 0.0, 0.0)) }
      result = mesh.add_polygon([0, 1, 2])
      expect(result).to eq(mesh)
    end
  end

  describe '#find_polygon_at' do
    it 'finds polygon containing point' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      poly = mesh.find_polygon_at(Bevy::Vec3.new(5.0, 3.0, 0.0))
      expect(poly).to be_a(Bevy::NavPolygon)
    end

    it 'returns nil when point is outside' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      poly = mesh.find_polygon_at(Bevy::Vec3.new(100.0, 100.0, 0.0))
      expect(poly).to be_nil
    end
  end

  describe '#find_path' do
    it 'finds path between two points in same polygon' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      path = mesh.find_path(Bevy::Vec3.new(3.0, 2.0, 0.0), Bevy::Vec3.new(7.0, 2.0, 0.0))
      expect(path).not_to be_nil
    end

    it 'returns nil when no path exists' do
      mesh = described_class.new
      mesh.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
      mesh.add_polygon([0, 1, 2])
      path = mesh.find_path(Bevy::Vec3.new(3.0, 2.0, 0.0), Bevy::Vec3.new(100.0, 100.0, 0.0))
      expect(path).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns NavMesh' do
      expect(described_class.new.type_name).to eq('NavMesh')
    end
  end
end

RSpec.describe Bevy::NavPolygon do
  let(:mesh) do
    m = Bevy::NavMesh.new
    m.add_vertex(Bevy::Vec3.new(0.0, 0.0, 0.0))
    m.add_vertex(Bevy::Vec3.new(10.0, 0.0, 0.0))
    m.add_vertex(Bevy::Vec3.new(5.0, 10.0, 0.0))
    m
  end

  describe '#vertices' do
    it 'returns polygon vertices' do
      poly = described_class.new(indices: [0, 1, 2], mesh: mesh)
      expect(poly.vertices.size).to eq(3)
    end
  end

  describe '#center' do
    it 'calculates polygon center' do
      poly = described_class.new(indices: [0, 1, 2], mesh: mesh)
      center = poly.center
      expect(center.x).to be_within(0.1).of(5.0)
      expect(center.y).to be_within(0.1).of(3.33)
    end
  end

  describe '#contains?' do
    it 'returns true for point inside' do
      poly = described_class.new(indices: [0, 1, 2], mesh: mesh)
      expect(poly.contains?(Bevy::Vec3.new(5.0, 3.0, 0.0))).to be true
    end

    it 'returns false for point outside' do
      poly = described_class.new(indices: [0, 1, 2], mesh: mesh)
      expect(poly.contains?(Bevy::Vec3.new(100.0, 100.0, 0.0))).to be false
    end
  end

  describe '#distance_to' do
    it 'calculates distance to another polygon' do
      mesh.add_vertex(Bevy::Vec3.new(15.0, 0.0, 0.0))
      mesh.add_vertex(Bevy::Vec3.new(20.0, 10.0, 0.0))
      poly1 = described_class.new(indices: [0, 1, 2], mesh: mesh)
      poly2 = described_class.new(indices: [1, 3, 4], mesh: mesh)
      expect(poly1.distance_to(poly2)).to be > 0
    end
  end

  describe '#type_name' do
    it 'returns NavPolygon' do
      poly = described_class.new(indices: [0, 1, 2], mesh: mesh)
      expect(poly.type_name).to eq('NavPolygon')
    end
  end
end

RSpec.describe Bevy::NavAgent do
  describe '.new' do
    it 'creates agent with default values' do
      agent = described_class.new
      expect(agent.speed).to eq(5.0)
      expect(agent.radius).to eq(0.5)
      expect(agent.path).to be_empty
    end

    it 'accepts custom values' do
      agent = described_class.new(speed: 10.0, radius: 1.0)
      expect(agent.speed).to eq(10.0)
      expect(agent.radius).to eq(1.0)
    end
  end

  describe '#set_destination' do
    it 'sets target position' do
      agent = described_class.new
      target = Bevy::Vec3.new(10.0, 10.0, 0.0)
      agent.set_destination(target)
      expect(agent.target).to eq(target)
    end
  end

  describe '#reached_destination?' do
    it 'returns false when no target' do
      agent = described_class.new
      expect(agent.reached_destination?).to be false
    end

    it 'returns true when at target' do
      agent = described_class.new(position: Bevy::Vec3.new(10.0, 10.0, 0.0))
      agent.set_destination(Bevy::Vec3.new(10.0, 10.0, 0.0))
      expect(agent.reached_destination?).to be true
    end
  end

  describe '#type_name' do
    it 'returns NavAgent' do
      expect(described_class.new.type_name).to eq('NavAgent')
    end
  end
end

RSpec.describe Bevy::SteeringBehavior do
  describe '.new' do
    it 'creates with default weight' do
      behavior = described_class.new
      expect(behavior.weight).to eq(1.0)
    end

    it 'accepts custom weight' do
      behavior = described_class.new(weight: 0.5)
      expect(behavior.weight).to eq(0.5)
    end
  end

  describe '#calculate' do
    it 'returns zero vector by default' do
      behavior = described_class.new
      agent = Bevy::NavAgent.new
      result = behavior.calculate(agent)
      expect(result.x).to eq(0.0)
      expect(result.y).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns SteeringBehavior' do
      expect(described_class.new.type_name).to eq('SteeringBehavior')
    end
  end
end

RSpec.describe Bevy::SeekBehavior do
  describe '.new' do
    it 'creates with target' do
      target = Bevy::Vec3.new(10.0, 10.0, 0.0)
      behavior = described_class.new(target: target)
      expect(behavior.target).to eq(target)
    end
  end

  describe '#calculate' do
    it 'returns direction toward target' do
      target = Bevy::Vec3.new(10.0, 0.0, 0.0)
      behavior = described_class.new(target: target)
      agent = Bevy::NavAgent.new(position: Bevy::Vec3.zero)
      result = behavior.calculate(agent)
      expect(result.x).to be > 0
    end

    it 'returns zero vector when no target' do
      behavior = described_class.new
      agent = Bevy::NavAgent.new
      result = behavior.calculate(agent)
      expect(result.x).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns SeekBehavior' do
      expect(described_class.new.type_name).to eq('SeekBehavior')
    end
  end
end

RSpec.describe Bevy::FleeBehavior do
  describe '.new' do
    it 'creates with target and panic distance' do
      target = Bevy::Vec3.new(10.0, 10.0, 0.0)
      behavior = described_class.new(target: target, panic_distance: 20.0)
      expect(behavior.target).to eq(target)
      expect(behavior.panic_distance).to eq(20.0)
    end
  end

  describe '#calculate' do
    it 'returns direction away from target when in panic range' do
      target = Bevy::Vec3.new(5.0, 0.0, 0.0)
      behavior = described_class.new(target: target, panic_distance: 10.0)
      agent = Bevy::NavAgent.new(position: Bevy::Vec3.zero)
      result = behavior.calculate(agent)
      expect(result.x).to be < 0
    end

    it 'returns zero vector when outside panic range' do
      target = Bevy::Vec3.new(100.0, 0.0, 0.0)
      behavior = described_class.new(target: target, panic_distance: 10.0)
      agent = Bevy::NavAgent.new(position: Bevy::Vec3.zero)
      result = behavior.calculate(agent)
      expect(result.x).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns FleeBehavior' do
      expect(described_class.new.type_name).to eq('FleeBehavior')
    end
  end
end

RSpec.describe Bevy::WanderBehavior do
  describe '.new' do
    it 'creates with default values' do
      behavior = described_class.new
      expect(behavior.radius).to eq(1.0)
      expect(behavior.distance).to eq(2.0)
      expect(behavior.jitter).to eq(0.5)
    end

    it 'accepts custom values' do
      behavior = described_class.new(radius: 2.0, distance: 3.0, jitter: 1.0)
      expect(behavior.radius).to eq(2.0)
      expect(behavior.distance).to eq(3.0)
      expect(behavior.jitter).to eq(1.0)
    end
  end

  describe '#calculate' do
    it 'returns normalized direction vector' do
      behavior = described_class.new
      agent = Bevy::NavAgent.new
      result = behavior.calculate(agent)
      length = Math.sqrt(result.x**2 + result.y**2 + result.z**2)
      expect(length).to be_within(0.01).of(1.0)
    end
  end

  describe '#type_name' do
    it 'returns WanderBehavior' do
      expect(described_class.new.type_name).to eq('WanderBehavior')
    end
  end
end
