# frozen_string_literal: true

RSpec.describe Bevy::Color do
  describe '.new' do
    it 'creates a Color with r, g, b, a' do
      c = described_class.new(1.0, 0.5, 0.25, 0.8)
      expect(c.r).to be_within(0.001).of(1.0)
      expect(c.g).to be_within(0.001).of(0.5)
      expect(c.b).to be_within(0.001).of(0.25)
      expect(c.a).to be_within(0.001).of(0.8)
    end
  end

  describe '.rgb' do
    it 'creates a Color with full alpha' do
      c = described_class.rgb(1.0, 0.5, 0.25)
      expect(c.r).to be_within(0.001).of(1.0)
      expect(c.g).to be_within(0.001).of(0.5)
      expect(c.b).to be_within(0.001).of(0.25)
      expect(c.a).to be_within(0.001).of(1.0)
    end
  end

  describe '.rgba' do
    it 'creates a Color with specified alpha' do
      c = described_class.rgba(0.5, 0.5, 0.5, 0.5)
      expect(c.a).to be_within(0.001).of(0.5)
    end
  end

  describe '.from_hex' do
    it 'creates a Color from hex string' do
      c = described_class.from_hex('#FF0000')
      expect(c.r).to be_within(0.001).of(1.0)
      expect(c.g).to be_within(0.001).of(0.0)
      expect(c.b).to be_within(0.001).of(0.0)
    end

    it 'raises ArgumentError for invalid hex' do
      expect { described_class.from_hex('invalid') }.to raise_error(ArgumentError)
    end
  end

  describe '.white' do
    it 'creates a white color' do
      c = described_class.white
      expect(c.r).to eq(1.0)
      expect(c.g).to eq(1.0)
      expect(c.b).to eq(1.0)
      expect(c.a).to eq(1.0)
    end
  end

  describe '.black' do
    it 'creates a black color' do
      c = described_class.black
      expect(c.r).to eq(0.0)
      expect(c.g).to eq(0.0)
      expect(c.b).to eq(0.0)
      expect(c.a).to eq(1.0)
    end
  end

  describe '.red' do
    it 'creates a red color' do
      c = described_class.red
      expect(c.r).to eq(1.0)
      expect(c.g).to eq(0.0)
      expect(c.b).to eq(0.0)
    end
  end

  describe '.green' do
    it 'creates a green color' do
      c = described_class.green
      expect(c.r).to eq(0.0)
      expect(c.g).to eq(1.0)
      expect(c.b).to eq(0.0)
    end
  end

  describe '.blue' do
    it 'creates a blue color' do
      c = described_class.blue
      expect(c.r).to eq(0.0)
      expect(c.g).to eq(0.0)
      expect(c.b).to eq(1.0)
    end
  end

  describe '.transparent' do
    it 'creates a transparent color' do
      c = described_class.transparent
      expect(c.a).to eq(0.0)
    end
  end

  describe 'setters' do
    it 'allows setting r, g, b, a' do
      c = described_class.black
      c.r = 0.5
      c.g = 0.6
      c.b = 0.7
      c.a = 0.8
      expect(c.r).to be_within(0.001).of(0.5)
      expect(c.g).to be_within(0.001).of(0.6)
      expect(c.b).to be_within(0.001).of(0.7)
      expect(c.a).to be_within(0.001).of(0.8)
    end
  end

  describe '#with_alpha' do
    it 'returns a new color with modified alpha' do
      c = described_class.white
      c2 = c.with_alpha(0.5)
      expect(c2.a).to be_within(0.001).of(0.5)
      expect(c.a).to eq(1.0)
    end
  end

  describe '#to_a' do
    it 'converts to array' do
      c = described_class.new(0.1, 0.2, 0.3, 0.4)
      arr = c.to_a
      expect(arr.length).to eq(4)
      expect(arr[0]).to be_within(0.001).of(0.1)
      expect(arr[1]).to be_within(0.001).of(0.2)
      expect(arr[2]).to be_within(0.001).of(0.3)
      expect(arr[3]).to be_within(0.001).of(0.4)
    end
  end
end
