# frozen_string_literal: true

RSpec.describe Bevy::Aabb do
  describe '.new' do
    it 'creates AABB with center and half extents' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.center.x).to eq(0.0)
      expect(aabb.half_extents.x).to eq(1.0)
    end
  end

  describe '.from_min_max' do
    it 'creates AABB from min and max corners' do
      aabb = described_class.from_min_max(
        Bevy::Vec3.new(-1.0, -1.0, -1.0),
        Bevy::Vec3.new(1.0, 1.0, 1.0)
      )
      expect(aabb.center.x).to eq(0.0)
      expect(aabb.half_extents.x).to eq(1.0)
    end
  end

  describe '#min' do
    it 'returns minimum corner' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.min.x).to eq(-1.0)
    end
  end

  describe '#max' do
    it 'returns maximum corner' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.max.x).to eq(1.0)
    end
  end

  describe '#contains_point?' do
    it 'returns true for point inside' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.contains_point?(Bevy::Vec3.new(0.5, 0.5, 0.5))).to be true
    end

    it 'returns false for point outside' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.contains_point?(Bevy::Vec3.new(5.0, 0.0, 0.0))).to be false
    end
  end

  describe '#intersects?' do
    it 'returns true for overlapping AABBs' do
      aabb1 = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      aabb2 = described_class.new(center: Bevy::Vec3.new(1.0, 0.0, 0.0), half_extents: Bevy::Vec3.one)
      expect(aabb1.intersects?(aabb2)).to be true
    end

    it 'returns false for non-overlapping AABBs' do
      aabb1 = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      aabb2 = described_class.new(center: Bevy::Vec3.new(10.0, 0.0, 0.0), half_extents: Bevy::Vec3.one)
      expect(aabb1.intersects?(aabb2)).to be false
    end
  end

  describe '#merge' do
    it 'creates AABB containing both' do
      aabb1 = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      aabb2 = described_class.new(center: Bevy::Vec3.new(5.0, 0.0, 0.0), half_extents: Bevy::Vec3.one)
      merged = aabb1.merge(aabb2)
      expect(merged.min.x).to eq(-1.0)
      expect(merged.max.x).to eq(6.0)
    end
  end

  describe '#type_name' do
    it 'returns Aabb' do
      aabb = described_class.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(aabb.type_name).to eq('Aabb')
    end
  end
end

RSpec.describe Bevy::Frustum do
  describe '.new' do
    it 'creates frustum with planes' do
      frustum = described_class.new([])
      expect(frustum.planes).to be_empty
    end
  end

  describe '.from_view_projection' do
    it 'creates frustum from matrix' do
      frustum = described_class.from_view_projection(nil)
      expect(frustum).to be_a(described_class)
    end
  end

  describe '#contains_point?' do
    it 'returns true when no planes' do
      frustum = described_class.new([])
      expect(frustum.contains_point?(Bevy::Vec3.zero)).to be true
    end

    it 'checks all planes' do
      plane = Bevy::FrustumPlane.new(normal: Bevy::Vec3.new(1.0, 0.0, 0.0), distance: 0.0)
      frustum = described_class.new([plane])
      expect(frustum.contains_point?(Bevy::Vec3.new(1.0, 0.0, 0.0))).to be true
      expect(frustum.contains_point?(Bevy::Vec3.new(-1.0, 0.0, 0.0))).to be false
    end
  end

  describe '#type_name' do
    it 'returns Frustum' do
      expect(described_class.new([]).type_name).to eq('Frustum')
    end
  end
end

RSpec.describe Bevy::FrustumPlane do
  describe '.new' do
    it 'creates plane with normal and distance' do
      plane = described_class.new(normal: Bevy::Vec3.new(0.0, 1.0, 0.0), distance: 5.0)
      expect(plane.normal.y).to eq(1.0)
      expect(plane.distance).to eq(5.0)
    end
  end

  describe '#signed_distance' do
    it 'calculates signed distance to point' do
      plane = described_class.new(normal: Bevy::Vec3.new(0.0, 1.0, 0.0), distance: 0.0)
      expect(plane.signed_distance(Bevy::Vec3.new(0.0, 5.0, 0.0))).to eq(5.0)
      expect(plane.signed_distance(Bevy::Vec3.new(0.0, -5.0, 0.0))).to eq(-5.0)
    end
  end

  describe '#type_name' do
    it 'returns FrustumPlane' do
      plane = described_class.new(normal: Bevy::Vec3.new(1.0, 0.0, 0.0), distance: 0.0)
      expect(plane.type_name).to eq('FrustumPlane')
    end
  end
end

RSpec.describe Bevy::VisibleEntities do
  describe '.new' do
    it 'creates empty visible entities' do
      ve = described_class.new
      expect(ve.entities).to be_empty
      expect(ve.count).to eq(0)
    end
  end

  describe '#add' do
    it 'adds entity to visible set' do
      ve = described_class.new
      ve.add(1)
      ve.add(2)
      expect(ve.count).to eq(2)
    end

    it 'returns self for chaining' do
      ve = described_class.new
      result = ve.add(1)
      expect(result).to eq(ve)
    end
  end

  describe '#clear' do
    it 'removes all entities' do
      ve = described_class.new
      ve.add(1)
      ve.clear
      expect(ve.entities).to be_empty
    end
  end

  describe '#include?' do
    it 'checks if entity is visible' do
      ve = described_class.new
      ve.add(1)
      expect(ve.include?(1)).to be true
      expect(ve.include?(2)).to be false
    end
  end

  describe '#type_name' do
    it 'returns VisibleEntities' do
      expect(described_class.new.type_name).to eq('VisibleEntities')
    end
  end
end

RSpec.describe Bevy::RenderLayers do
  describe '.new' do
    it 'creates with default layer' do
      layers = described_class.new
      expect(layers.layers).to include(0)
    end

    it 'accepts custom layers' do
      layers = described_class.new([1, 2, 3])
      expect(layers.layers).to eq([1, 2, 3])
    end
  end

  describe '.layer' do
    it 'creates with single layer' do
      layers = described_class.layer(5)
      expect(layers.layers).to eq([5])
    end
  end

  describe '.all' do
    it 'creates with all layers 0-31' do
      layers = described_class.all
      expect(layers.layers.size).to eq(32)
    end
  end

  describe '.none' do
    it 'creates with no layers' do
      layers = described_class.none
      expect(layers.layers).to be_empty
    end
  end

  describe '#with' do
    it 'adds layer' do
      layers = described_class.new([0])
      new_layers = layers.with(1)
      expect(new_layers.layers).to include(0, 1)
    end
  end

  describe '#without' do
    it 'removes layer' do
      layers = described_class.new([0, 1, 2])
      new_layers = layers.without(1)
      expect(new_layers.layers).not_to include(1)
    end
  end

  describe '#intersects?' do
    it 'returns true when layers overlap' do
      layers1 = described_class.new([0, 1])
      layers2 = described_class.new([1, 2])
      expect(layers1.intersects?(layers2)).to be true
    end

    it 'returns false when layers do not overlap' do
      layers1 = described_class.new([0])
      layers2 = described_class.new([1])
      expect(layers1.intersects?(layers2)).to be false
    end
  end

  describe '#type_name' do
    it 'returns RenderLayers' do
      expect(described_class.new.type_name).to eq('RenderLayers')
    end
  end
end

RSpec.describe Bevy::OcclusionCulling do
  describe '.new' do
    it 'creates enabled culling' do
      culling = described_class.new
      expect(culling.enabled).to be true
    end

    it 'accepts enabled flag' do
      culling = described_class.new(enabled: false)
      expect(culling.enabled).to be false
    end
  end

  describe '#add_occluder' do
    it 'adds occluder AABB' do
      culling = described_class.new
      aabb = Bevy::Aabb.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      culling.add_occluder(aabb)
      expect(culling.instance_variable_get(:@occluders).size).to eq(1)
    end
  end

  describe '#clear_occluders' do
    it 'removes all occluders' do
      culling = described_class.new
      culling.add_occluder(Bevy::Aabb.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one))
      culling.clear_occluders
      expect(culling.instance_variable_get(:@occluders)).to be_empty
    end
  end

  describe '#is_occluded?' do
    it 'returns false when disabled' do
      culling = described_class.new(enabled: false)
      aabb = Bevy::Aabb.new(center: Bevy::Vec3.zero, half_extents: Bevy::Vec3.one)
      expect(culling.is_occluded?(aabb, Bevy::Vec3.new(10.0, 0.0, 0.0))).to be false
    end
  end

  describe '#type_name' do
    it 'returns OcclusionCulling' do
      expect(described_class.new.type_name).to eq('OcclusionCulling')
    end
  end
end

RSpec.describe Bevy::Lod do
  describe '.new' do
    it 'creates LOD with distance thresholds' do
      lod = described_class.new(distances: [10.0, 50.0, 100.0])
      expect(lod.distances).to eq([10.0, 50.0, 100.0])
      expect(lod.current_level).to eq(0)
    end
  end

  describe '#update' do
    it 'sets level based on distance' do
      lod = described_class.new(distances: [10.0, 50.0])
      lod.update(5.0)
      expect(lod.current_level).to eq(0)
      lod.update(30.0)
      expect(lod.current_level).to eq(1)
      lod.update(100.0)
      expect(lod.current_level).to eq(2)
    end
  end

  describe '#level_count' do
    it 'returns number of LOD levels' do
      lod = described_class.new(distances: [10.0, 50.0, 100.0])
      expect(lod.level_count).to eq(4)
    end
  end

  describe '#type_name' do
    it 'returns Lod' do
      expect(described_class.new(distances: []).type_name).to eq('Lod')
    end
  end
end
