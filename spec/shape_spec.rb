# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bevy::Shape do
  describe Bevy::Shape::Rectangle do
    it 'creates a rectangle with dimensions' do
      rect = Bevy::Shape::Rectangle.new(width: 100, height: 50)
      expect(rect.width).to eq(100.0)
      expect(rect.height).to eq(50.0)
    end

    it 'converts to sprite' do
      rect = Bevy::Shape::Rectangle.new(width: 100, height: 50, color: Bevy::Color.red)
      sprite = rect.to_sprite
      expect(sprite).to be_a(Bevy::Sprite)
      expect(sprite.custom_size.x).to eq(100.0)
      expect(sprite.custom_size.y).to eq(50.0)
    end
  end

  describe Bevy::Shape::Circle do
    it 'creates a circle with radius' do
      circle = Bevy::Shape::Circle.new(radius: 50)
      expect(circle.radius).to eq(50.0)
      expect(circle.diameter).to eq(100.0)
    end

    it 'converts to sprite' do
      circle = Bevy::Shape::Circle.new(radius: 25, color: Bevy::Color.blue)
      sprite = circle.to_sprite
      expect(sprite.custom_size.x).to eq(50.0)
      expect(sprite.custom_size.y).to eq(50.0)
    end
  end

  describe Bevy::Shape::Line do
    it 'creates a line between two points' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = Bevy::Shape::Line.new(start_point: start_pt, end_point: end_pt)

      expect(line.length).to eq(100.0)
      expect(line.angle).to eq(0.0)
    end

    it 'calculates center point' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 100)
      line = Bevy::Shape::Line.new(start_point: start_pt, end_point: end_pt)

      center = line.center
      expect(center.x).to eq(50.0)
      expect(center.y).to eq(50.0)
    end

    it 'calculates angle for diagonal line' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 100)
      line = Bevy::Shape::Line.new(start_point: start_pt, end_point: end_pt)

      expect(line.angle).to be_within(0.01).of(Math::PI / 4)
    end

    it 'converts to sprite and transform' do
      start_pt = Bevy::Vec2.new(0, 0)
      end_pt = Bevy::Vec2.new(100, 0)
      line = Bevy::Shape::Line.new(start_point: start_pt, end_point: end_pt, thickness: 5)

      sprite = line.to_sprite
      expect(sprite.custom_size.x).to eq(100.0)
      expect(sprite.custom_size.y).to eq(5.0)

      transform = line.to_transform
      expect(transform.translation.x).to eq(50.0)
      expect(transform.translation.y).to eq(0.0)
    end
  end

  describe Bevy::Shape::Polygon do
    it 'creates a polygon from points' do
      points = [
        Bevy::Vec2.new(0, 0),
        Bevy::Vec2.new(100, 0),
        Bevy::Vec2.new(50, 100)
      ]
      polygon = Bevy::Shape::Polygon.new(points: points)

      expect(polygon.points.length).to eq(3)
    end

    it 'calculates centroid' do
      points = [
        Bevy::Vec2.new(0, 0),
        Bevy::Vec2.new(100, 0),
        Bevy::Vec2.new(50, 100)
      ]
      polygon = Bevy::Shape::Polygon.new(points: points)

      centroid = polygon.centroid
      expect(centroid.x).to eq(50.0)
      expect(centroid.y).to be_within(0.1).of(33.33)
    end

    it 'calculates bounding box' do
      points = [
        Bevy::Vec2.new(10, 20),
        Bevy::Vec2.new(110, 20),
        Bevy::Vec2.new(60, 120)
      ]
      polygon = Bevy::Shape::Polygon.new(points: points)

      bbox = polygon.bounding_box
      expect(bbox[:min].x).to eq(10.0)
      expect(bbox[:min].y).to eq(20.0)
      expect(bbox[:max].x).to eq(110.0)
      expect(bbox[:max].y).to eq(120.0)
    end
  end

  describe Bevy::Shape::RegularPolygon do
    it 'creates a regular polygon with specified sides' do
      poly = Bevy::Shape::RegularPolygon.new(radius: 50, sides: 6)
      expect(poly.radius).to eq(50.0)
      expect(poly.sides).to eq(6)
      expect(poly.points.length).to eq(6)
    end

    it 'enforces minimum of 3 sides' do
      poly = Bevy::Shape::RegularPolygon.new(radius: 50, sides: 1)
      expect(poly.sides).to eq(3)
    end
  end

  describe Bevy::Shape::Triangle do
    it 'creates a triangle' do
      tri = Bevy::Shape::Triangle.new(radius: 50)
      expect(tri.sides).to eq(3)
      expect(tri.points.length).to eq(3)
    end
  end

  describe Bevy::Shape::Hexagon do
    it 'creates a hexagon' do
      hex = Bevy::Shape::Hexagon.new(radius: 50)
      expect(hex.sides).to eq(6)
      expect(hex.points.length).to eq(6)
    end
  end
end
