# frozen_string_literal: true

RSpec.describe Bevy::Mesh do
  describe 'shape type constants' do
    it 'defines shape type constants' do
      expect(Bevy::Mesh::SHAPE_RECTANGLE).to eq(0)
      expect(Bevy::Mesh::SHAPE_CIRCLE).to eq(1)
      expect(Bevy::Mesh::SHAPE_REGULAR_POLYGON).to eq(2)
      expect(Bevy::Mesh::SHAPE_LINE).to eq(3)
      expect(Bevy::Mesh::SHAPE_ELLIPSE).to eq(4)
    end
  end
end

RSpec.describe Bevy::Mesh::Rectangle do
  describe '.new' do
    it 'creates a rectangle with width and height' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.width).to eq(100.0)
      expect(rect.height).to eq(50.0)
    end

    it 'has default color white' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.color.r).to eq(1.0)
      expect(rect.color.g).to eq(1.0)
      expect(rect.color.b).to eq(1.0)
      expect(rect.color.a).to eq(1.0)
    end

    it 'accepts custom color' do
      color = Bevy::Color.new(1.0, 0.0, 0.0, 1.0)
      rect = described_class.new(width: 100, height: 50, color: color)
      expect(rect.color.r).to eq(1.0)
      expect(rect.color.g).to eq(0.0)
    end

    it 'has fill enabled by default' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.fill).to be true
    end

    it 'accepts fill option' do
      rect = described_class.new(width: 100, height: 50, fill: false)
      expect(rect.fill).to be false
    end

    it 'has default thickness of 2.0' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.thickness).to eq(2.0)
    end
  end

  describe '#shape_type' do
    it 'returns SHAPE_RECTANGLE' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.shape_type).to eq(Bevy::Mesh::SHAPE_RECTANGLE)
    end
  end

  describe '#to_mesh_data' do
    it 'returns mesh data hash' do
      rect = described_class.new(width: 100, height: 50)
      data = rect.to_mesh_data

      expect(data[:shape_type]).to eq(Bevy::Mesh::SHAPE_RECTANGLE)
      expect(data[:width]).to eq(100.0)
      expect(data[:height]).to eq(50.0)
      expect(data[:color_r]).to eq(1.0)
      expect(data[:fill]).to be true
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Rectangle' do
      rect = described_class.new(width: 100, height: 50)
      expect(rect.type_name).to eq('Mesh::Rectangle')
    end
  end
end

RSpec.describe Bevy::Mesh::Circle do
  describe '.new' do
    it 'creates a circle with radius' do
      circle = described_class.new(radius: 50)
      expect(circle.radius).to eq(50.0)
    end

    it 'has default color white' do
      circle = described_class.new(radius: 50)
      expect(circle.color.r).to eq(1.0)
    end
  end

  describe '#diameter' do
    it 'returns radius * 2' do
      circle = described_class.new(radius: 50)
      expect(circle.diameter).to eq(100.0)
    end
  end

  describe '#shape_type' do
    it 'returns SHAPE_CIRCLE' do
      circle = described_class.new(radius: 50)
      expect(circle.shape_type).to eq(Bevy::Mesh::SHAPE_CIRCLE)
    end
  end

  describe '#to_mesh_data' do
    it 'returns mesh data hash' do
      circle = described_class.new(radius: 50)
      data = circle.to_mesh_data

      expect(data[:shape_type]).to eq(Bevy::Mesh::SHAPE_CIRCLE)
      expect(data[:radius]).to eq(50.0)
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Circle' do
      circle = described_class.new(radius: 50)
      expect(circle.type_name).to eq('Mesh::Circle')
    end
  end
end

RSpec.describe Bevy::Mesh::RegularPolygon do
  describe '.new' do
    it 'creates a polygon with radius and sides' do
      polygon = described_class.new(radius: 50, sides: 6)
      expect(polygon.radius).to eq(50.0)
      expect(polygon.sides).to eq(6)
    end

    it 'enforces minimum of 3 sides' do
      polygon = described_class.new(radius: 50, sides: 2)
      expect(polygon.sides).to eq(3)
    end
  end

  describe '#shape_type' do
    it 'returns SHAPE_REGULAR_POLYGON' do
      polygon = described_class.new(radius: 50, sides: 6)
      expect(polygon.shape_type).to eq(Bevy::Mesh::SHAPE_REGULAR_POLYGON)
    end
  end

  describe '#to_mesh_data' do
    it 'returns mesh data hash with sides' do
      polygon = described_class.new(radius: 50, sides: 8)
      data = polygon.to_mesh_data

      expect(data[:shape_type]).to eq(Bevy::Mesh::SHAPE_REGULAR_POLYGON)
      expect(data[:radius]).to eq(50.0)
      expect(data[:sides]).to eq(8)
    end
  end

  describe '#type_name' do
    it 'returns Mesh::RegularPolygon' do
      polygon = described_class.new(radius: 50, sides: 6)
      expect(polygon.type_name).to eq('Mesh::RegularPolygon')
    end
  end
end

RSpec.describe Bevy::Mesh::Triangle do
  describe '.new' do
    it 'creates a triangle (3-sided polygon)' do
      triangle = described_class.new(radius: 50)
      expect(triangle.sides).to eq(3)
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Triangle' do
      triangle = described_class.new(radius: 50)
      expect(triangle.type_name).to eq('Mesh::Triangle')
    end
  end
end

RSpec.describe Bevy::Mesh::Hexagon do
  describe '.new' do
    it 'creates a hexagon (6-sided polygon)' do
      hexagon = described_class.new(radius: 50)
      expect(hexagon.sides).to eq(6)
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Hexagon' do
      hexagon = described_class.new(radius: 50)
      expect(hexagon.type_name).to eq('Mesh::Hexagon')
    end
  end
end

RSpec.describe Bevy::Mesh::Line do
  describe '.new' do
    it 'creates a line with start and end points' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.start_point.x).to eq(0)
      expect(line.end_point.x).to eq(100)
    end

    it 'has default thickness of 2.0' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.thickness).to eq(2.0)
    end
  end

  describe '#length' do
    it 'calculates line length' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(3, 4)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.length).to eq(5.0)
    end
  end

  describe '#angle' do
    it 'calculates line angle' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.angle).to eq(0.0)
    end
  end

  describe '#center' do
    it 'calculates line center' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 100)
      line = described_class.new(start_point: start_pt, end_point: end_pt)
      center = line.center

      expect(center.x).to eq(50.0)
      expect(center.y).to eq(50.0)
    end
  end

  describe '#shape_type' do
    it 'returns SHAPE_LINE' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.shape_type).to eq(Bevy::Mesh::SHAPE_LINE)
    end
  end

  describe '#to_mesh_data' do
    it 'returns mesh data hash with line coordinates' do
      start_pt = Bevy::Vec2.new(10, 20)
      end_pt = Bevy::Vec2.new(30, 40)
      line = described_class.new(start_point: start_pt, end_point: end_pt)
      data = line.to_mesh_data

      expect(data[:shape_type]).to eq(Bevy::Mesh::SHAPE_LINE)
      expect(data[:line_start_x]).to eq(10.0)
      expect(data[:line_start_y]).to eq(20.0)
      expect(data[:line_end_x]).to eq(30.0)
      expect(data[:line_end_y]).to eq(40.0)
      expect(data[:fill]).to be false
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Line' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = described_class.new(start_point: start_pt, end_point: end_pt)

      expect(line.type_name).to eq('Mesh::Line')
    end
  end
end

RSpec.describe Bevy::Mesh::Ellipse do
  describe '.new' do
    it 'creates an ellipse with width and height' do
      ellipse = described_class.new(width: 100, height: 50)
      expect(ellipse.width).to eq(100.0)
      expect(ellipse.height).to eq(50.0)
    end
  end

  describe '#shape_type' do
    it 'returns SHAPE_ELLIPSE' do
      ellipse = described_class.new(width: 100, height: 50)
      expect(ellipse.shape_type).to eq(Bevy::Mesh::SHAPE_ELLIPSE)
    end
  end

  describe '#to_mesh_data' do
    it 'returns mesh data hash' do
      ellipse = described_class.new(width: 100, height: 50)
      data = ellipse.to_mesh_data

      expect(data[:shape_type]).to eq(Bevy::Mesh::SHAPE_ELLIPSE)
      expect(data[:width]).to eq(100.0)
      expect(data[:height]).to eq(50.0)
    end
  end

  describe '#type_name' do
    it 'returns Mesh::Ellipse' do
      ellipse = described_class.new(width: 100, height: 50)
      expect(ellipse.type_name).to eq('Mesh::Ellipse')
    end
  end
end
