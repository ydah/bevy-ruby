# frozen_string_literal: true

RSpec.describe Bevy::Vec2 do
  describe '.new' do
    it 'creates a Vec2 with x and y' do
      v = described_class.new(3.0, 4.0)
      expect(v.x).to eq(3.0)
      expect(v.y).to eq(4.0)
    end
  end

  describe '.zero' do
    it 'creates a zero vector' do
      v = described_class.zero
      expect(v.x).to eq(0.0)
      expect(v.y).to eq(0.0)
    end
  end

  describe '.one' do
    it 'creates a one vector' do
      v = described_class.one
      expect(v.x).to eq(1.0)
      expect(v.y).to eq(1.0)
    end
  end

  describe '#length' do
    it 'calculates the length' do
      v = described_class.new(3.0, 4.0)
      expect(v.length).to eq(5.0)
    end
  end

  describe '#normalize' do
    it 'returns a unit vector' do
      v = described_class.new(3.0, 4.0)
      n = v.normalize
      expect(n.length).to be_within(0.001).of(1.0)
    end
  end

  describe '#dot' do
    it 'calculates the dot product' do
      v1 = described_class.new(1.0, 2.0)
      v2 = described_class.new(3.0, 4.0)
      expect(v1.dot(v2)).to eq(11.0)
    end
  end

  describe 'arithmetic operations' do
    it 'adds vectors' do
      v1 = described_class.new(1.0, 2.0)
      v2 = described_class.new(3.0, 4.0)
      result = v1 + v2
      expect(result.x).to eq(4.0)
      expect(result.y).to eq(6.0)
    end

    it 'subtracts vectors' do
      v1 = described_class.new(5.0, 7.0)
      v2 = described_class.new(2.0, 3.0)
      result = v1 - v2
      expect(result.x).to eq(3.0)
      expect(result.y).to eq(4.0)
    end

    it 'multiplies by scalar' do
      v = described_class.new(2.0, 3.0)
      result = v * 2.0
      expect(result.x).to eq(4.0)
      expect(result.y).to eq(6.0)
    end

    it 'divides by scalar' do
      v = described_class.new(4.0, 6.0)
      result = v / 2.0
      expect(result.x).to eq(2.0)
      expect(result.y).to eq(3.0)
    end
  end

  describe '#to_a' do
    it 'converts to array' do
      v = described_class.new(1.0, 2.0)
      expect(v.to_a).to eq([1.0, 2.0])
    end
  end
end

RSpec.describe Bevy::Vec3 do
  describe '.new' do
    it 'creates a Vec3 with x, y, z' do
      v = described_class.new(1.0, 2.0, 3.0)
      expect(v.x).to eq(1.0)
      expect(v.y).to eq(2.0)
      expect(v.z).to eq(3.0)
    end
  end

  describe '.zero' do
    it 'creates a zero vector' do
      v = described_class.zero
      expect(v.x).to eq(0.0)
      expect(v.y).to eq(0.0)
      expect(v.z).to eq(0.0)
    end
  end

  describe '.one' do
    it 'creates a one vector' do
      v = described_class.one
      expect(v.x).to eq(1.0)
      expect(v.y).to eq(1.0)
      expect(v.z).to eq(1.0)
    end
  end

  describe '#length' do
    it 'calculates the length' do
      v = described_class.new(2.0, 3.0, 6.0)
      expect(v.length).to eq(7.0)
    end
  end

  describe '#cross' do
    it 'calculates the cross product' do
      v1 = described_class.new(1.0, 0.0, 0.0)
      v2 = described_class.new(0.0, 1.0, 0.0)
      result = v1.cross(v2)
      expect(result.x).to eq(0.0)
      expect(result.y).to eq(0.0)
      expect(result.z).to eq(1.0)
    end
  end

  describe 'arithmetic operations' do
    it 'adds vectors' do
      v1 = described_class.new(1.0, 2.0, 3.0)
      v2 = described_class.new(4.0, 5.0, 6.0)
      result = v1 + v2
      expect(result.x).to eq(5.0)
      expect(result.y).to eq(7.0)
      expect(result.z).to eq(9.0)
    end
  end

  describe '#to_a' do
    it 'converts to array' do
      v = described_class.new(1.0, 2.0, 3.0)
      expect(v.to_a).to eq([1.0, 2.0, 3.0])
    end
  end
end

RSpec.describe Bevy::Quat do
  describe '.identity' do
    it 'creates an identity quaternion' do
      q = described_class.identity
      expect(q.x).to eq(0.0)
      expect(q.y).to eq(0.0)
      expect(q.z).to eq(0.0)
      expect(q.w).to eq(1.0)
    end
  end

  describe '.from_rotation_z' do
    it 'creates a rotation around Z axis' do
      q = described_class.from_rotation_z(Math::PI / 2)
      expect(q.w).to be_within(0.001).of(Math.cos(Math::PI / 4))
      expect(q.z).to be_within(0.001).of(Math.sin(Math::PI / 4))
    end
  end

  describe '#normalize' do
    it 'returns a normalized quaternion' do
      q = described_class.from_euler(0.1, 0.2, 0.3)
      n = q.normalize
      length = Math.sqrt(n.x**2 + n.y**2 + n.z**2 + n.w**2)
      expect(length).to be_within(0.001).of(1.0)
    end
  end

  describe '#inverse' do
    it 'returns the inverse quaternion' do
      q = described_class.from_rotation_z(Math::PI / 4)
      inv = q.inverse
      result = q * inv
      expect(result.w).to be_within(0.001).of(1.0)
    end
  end

  describe '#mul_vec3' do
    it 'rotates a vector' do
      q = described_class.from_rotation_z(Math::PI / 2)
      v = Bevy::Vec3.new(1.0, 0.0, 0.0)
      result = q.mul_vec3(v)
      expect(result.x).to be_within(0.001).of(0.0)
      expect(result.y).to be_within(0.001).of(1.0)
      expect(result.z).to be_within(0.001).of(0.0)
    end
  end

  describe '#to_a' do
    it 'converts to array' do
      q = described_class.identity
      expect(q.to_a).to eq([0.0, 0.0, 0.0, 1.0])
    end
  end
end
