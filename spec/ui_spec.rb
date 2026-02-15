# frozen_string_literal: true

RSpec.describe Bevy::Val do
  describe '.px' do
    it 'creates a pixel value' do
      val = described_class.px(100)
      expect(val[:type]).to eq(:px)
      expect(val[:value]).to eq(100.0)
    end
  end

  describe '.percent' do
    it 'creates a percentage value' do
      val = described_class.percent(50)
      expect(val[:type]).to eq(:percent)
      expect(val[:value]).to eq(50.0)
    end
  end

  describe '.auto' do
    it 'creates an auto value' do
      val = described_class.auto
      expect(val[:type]).to eq(:auto)
    end
  end

  describe '.vw' do
    it 'creates a viewport width value' do
      val = described_class.vw(100)
      expect(val[:type]).to eq(:vw)
      expect(val[:value]).to eq(100.0)
    end
  end

  describe '.vh' do
    it 'creates a viewport height value' do
      val = described_class.vh(50)
      expect(val[:type]).to eq(:vh)
      expect(val[:value]).to eq(50.0)
    end
  end

  describe '.vmin' do
    it 'creates a viewport min value' do
      val = described_class.vmin(25)
      expect(val[:type]).to eq(:vmin)
      expect(val[:value]).to eq(25.0)
    end
  end

  describe '.vmax' do
    it 'creates a viewport max value' do
      val = described_class.vmax(75)
      expect(val[:type]).to eq(:vmax)
      expect(val[:value]).to eq(75.0)
    end
  end
end

RSpec.describe Bevy::FlexDirection do
  it 'defines ROW' do
    expect(described_class::ROW).to eq(:row)
  end

  it 'defines COLUMN' do
    expect(described_class::COLUMN).to eq(:column)
  end

  it 'defines ROW_REVERSE' do
    expect(described_class::ROW_REVERSE).to eq(:row_reverse)
  end

  it 'defines COLUMN_REVERSE' do
    expect(described_class::COLUMN_REVERSE).to eq(:column_reverse)
  end
end

RSpec.describe Bevy::JustifyContent do
  it 'defines layout constants' do
    expect(described_class::START).to eq(:start)
    expect(described_class::CENTER).to eq(:center)
    expect(described_class::SPACE_BETWEEN).to eq(:space_between)
    expect(described_class::SPACE_AROUND).to eq(:space_around)
    expect(described_class::SPACE_EVENLY).to eq(:space_evenly)
  end
end

RSpec.describe Bevy::AlignItems do
  it 'defines alignment constants' do
    expect(described_class::DEFAULT).to eq(:default)
    expect(described_class::START).to eq(:start)
    expect(described_class::CENTER).to eq(:center)
    expect(described_class::STRETCH).to eq(:stretch)
    expect(described_class::BASELINE).to eq(:baseline)
  end
end

RSpec.describe Bevy::Display do
  it 'defines display modes' do
    expect(described_class::FLEX).to eq(:flex)
    expect(described_class::GRID).to eq(:grid)
    expect(described_class::NONE).to eq(:none)
  end
end

RSpec.describe Bevy::PositionType do
  it 'defines position types' do
    expect(described_class::RELATIVE).to eq(:relative)
    expect(described_class::ABSOLUTE).to eq(:absolute)
  end
end

RSpec.describe Bevy::Overflow do
  it 'defines overflow modes' do
    expect(described_class::VISIBLE).to eq(:visible)
    expect(described_class::CLIP).to eq(:clip)
    expect(described_class::SCROLL).to eq(:scroll)
  end
end

RSpec.describe Bevy::UiRect do
  describe '.new' do
    it 'creates with default values' do
      rect = described_class.new
      expect(rect.left).to eq(Bevy::Val.px(0))
      expect(rect.right).to eq(Bevy::Val.px(0))
      expect(rect.top).to eq(Bevy::Val.px(0))
      expect(rect.bottom).to eq(Bevy::Val.px(0))
    end

    it 'creates with individual values' do
      rect = described_class.new(left: Bevy::Val.px(10), top: Bevy::Val.px(20))
      expect(rect.left).to eq(Bevy::Val.px(10))
      expect(rect.top).to eq(Bevy::Val.px(20))
    end

    it 'creates with all value' do
      rect = described_class.new(all: Bevy::Val.px(15))
      expect(rect.left).to eq(Bevy::Val.px(15))
      expect(rect.right).to eq(Bevy::Val.px(15))
      expect(rect.top).to eq(Bevy::Val.px(15))
      expect(rect.bottom).to eq(Bevy::Val.px(15))
    end

    it 'creates with horizontal/vertical values' do
      rect = described_class.new(horizontal: Bevy::Val.px(10), vertical: Bevy::Val.px(20))
      expect(rect.left).to eq(Bevy::Val.px(10))
      expect(rect.right).to eq(Bevy::Val.px(10))
      expect(rect.top).to eq(Bevy::Val.px(20))
      expect(rect.bottom).to eq(Bevy::Val.px(20))
    end
  end

  describe '.all' do
    it 'creates a UiRect with all sides equal' do
      rect = described_class.all(Bevy::Val.percent(50))
      expect(rect.left).to eq(Bevy::Val.percent(50))
      expect(rect.bottom).to eq(Bevy::Val.percent(50))
    end
  end

  describe '.horizontal' do
    it 'creates a UiRect with horizontal sides set' do
      rect = described_class.horizontal(Bevy::Val.px(25))
      expect(rect.left).to eq(Bevy::Val.px(25))
      expect(rect.right).to eq(Bevy::Val.px(25))
      expect(rect.top).to eq(Bevy::Val.px(0))
    end
  end

  describe '.axes' do
    it 'creates a UiRect with separate horizontal and vertical values' do
      rect = described_class.axes(Bevy::Val.px(10), Bevy::Val.px(20))
      expect(rect.left).to eq(Bevy::Val.px(10))
      expect(rect.right).to eq(Bevy::Val.px(10))
      expect(rect.top).to eq(Bevy::Val.px(20))
      expect(rect.bottom).to eq(Bevy::Val.px(20))
    end
  end

  describe '#to_h' do
    it 'converts to a hash' do
      rect = described_class.new(left: Bevy::Val.px(5))
      h = rect.to_h
      expect(h[:left]).to eq(Bevy::Val.px(5))
    end
  end
end

RSpec.describe Bevy::Style do
  describe '.new' do
    it 'creates with default values' do
      style = described_class.new
      expect(style.display).to eq(Bevy::Display::FLEX)
      expect(style.position_type).to eq(Bevy::PositionType::RELATIVE)
      expect(style.flex_direction).to eq(Bevy::FlexDirection::ROW)
      expect(style.flex_grow).to eq(0.0)
      expect(style.flex_shrink).to eq(1.0)
    end

    it 'creates with custom values' do
      style = described_class.new(
        display: Bevy::Display::GRID,
        flex_direction: Bevy::FlexDirection::COLUMN,
        width: Bevy::Val.percent(100),
        height: Bevy::Val.px(200)
      )
      expect(style.display).to eq(Bevy::Display::GRID)
      expect(style.flex_direction).to eq(Bevy::FlexDirection::COLUMN)
      expect(style.width).to eq(Bevy::Val.percent(100))
      expect(style.height).to eq(Bevy::Val.px(200))
    end

    it 'has default margin and padding' do
      style = described_class.new
      expect(style.margin).to be_a(Bevy::UiRect)
      expect(style.padding).to be_a(Bevy::UiRect)
      expect(style.border).to be_a(Bevy::UiRect)
    end
  end

  describe '#to_h' do
    it 'converts style to hash' do
      style = described_class.new(
        width: Bevy::Val.px(100),
        justify_content: Bevy::JustifyContent::CENTER
      )
      h = style.to_h
      expect(h[:width]).to eq(Bevy::Val.px(100))
      expect(h[:justify_content]).to eq(:center)
      expect(h[:margin]).to be_a(Hash)
    end
  end
end

RSpec.describe Bevy::Node do
  describe '.new' do
    it 'creates with default style' do
      node = described_class.new
      expect(node.style).to be_a(Bevy::Style)
    end

    it 'creates with custom style' do
      style = Bevy::Style.new(width: Bevy::Val.px(200))
      node = described_class.new(style: style)
      expect(node.style.width).to eq(Bevy::Val.px(200))
    end
  end

  describe '#type_name' do
    it 'returns Node' do
      node = described_class.new
      expect(node.type_name).to eq('Node')
    end
  end

  describe '#to_h' do
    it 'converts to hash with style' do
      node = described_class.new
      h = node.to_h
      expect(h[:style]).to be_a(Hash)
    end
  end
end

RSpec.describe Bevy::BackgroundColor do
  describe '.new' do
    it 'creates with default white color' do
      bg = described_class.new
      expect(bg.color).to be_a(Bevy::Color)
    end

    it 'creates with custom color' do
      color = Bevy::Color.red
      bg = described_class.new(color)
      expect(bg.color.r).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns BackgroundColor' do
      bg = described_class.new
      expect(bg.type_name).to eq('BackgroundColor')
    end
  end

  describe '#to_h' do
    it 'converts to hash with color array' do
      bg = described_class.new(Bevy::Color.blue)
      h = bg.to_h
      expect(h[:color]).to be_an(Array)
      expect(h[:color][2]).to eq(1.0)
    end
  end
end

RSpec.describe Bevy::BorderColor do
  describe '.new' do
    it 'creates with default transparent color' do
      border = described_class.new
      expect(border.color).to be_a(Bevy::Color)
    end

    it 'creates with custom color' do
      color = Bevy::Color.green
      border = described_class.new(color)
      expect(border.color.g).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns BorderColor' do
      border = described_class.new
      expect(border.type_name).to eq('BorderColor')
    end
  end
end

RSpec.describe Bevy::BorderRadius do
  describe '.new' do
    it 'creates with default zero radius' do
      radius = described_class.new
      expect(radius.top_left).to eq(Bevy::Val.px(0))
      expect(radius.top_right).to eq(Bevy::Val.px(0))
    end

    it 'creates with individual corners' do
      radius = described_class.new(
        top_left: Bevy::Val.px(5),
        bottom_right: Bevy::Val.px(10)
      )
      expect(radius.top_left).to eq(Bevy::Val.px(5))
      expect(radius.bottom_right).to eq(Bevy::Val.px(10))
    end

    it 'creates with all corners equal' do
      radius = described_class.new(all: Bevy::Val.px(8))
      expect(radius.top_left).to eq(Bevy::Val.px(8))
      expect(radius.bottom_left).to eq(Bevy::Val.px(8))
    end
  end

  describe '.all' do
    it 'creates a BorderRadius with all corners equal' do
      radius = described_class.all(Bevy::Val.percent(50))
      expect(radius.top_left).to eq(Bevy::Val.percent(50))
      expect(radius.bottom_right).to eq(Bevy::Val.percent(50))
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      radius = described_class.new(top_left: Bevy::Val.px(5))
      h = radius.to_h
      expect(h[:top_left]).to eq(Bevy::Val.px(5))
    end
  end
end

RSpec.describe Bevy::Interaction do
  it 'defines interaction states' do
    expect(described_class::NONE).to eq(:none)
    expect(described_class::PRESSED).to eq(:pressed)
    expect(described_class::HOVERED).to eq(:hovered)
  end
end

RSpec.describe Bevy::Button do
  describe '.new' do
    it 'creates with NONE interaction' do
      button = described_class.new
      expect(button.interaction).to eq(Bevy::Interaction::NONE)
    end
  end

  describe '#pressed?' do
    it 'returns false for new button' do
      button = described_class.new
      expect(button.pressed?).to be false
    end

    it 'returns true when pressed' do
      button = described_class.new
      button.interaction = Bevy::Interaction::PRESSED
      expect(button.pressed?).to be true
    end
  end

  describe '#hovered?' do
    it 'returns false for new button' do
      button = described_class.new
      expect(button.hovered?).to be false
    end

    it 'returns true when hovered' do
      button = described_class.new
      button.interaction = Bevy::Interaction::HOVERED
      expect(button.hovered?).to be true
    end
  end

  describe '#none?' do
    it 'returns true for new button' do
      button = described_class.new
      expect(button.none?).to be true
    end
  end

  describe '#type_name' do
    it 'returns Button' do
      button = described_class.new
      expect(button.type_name).to eq('Button')
    end
  end
end

RSpec.describe Bevy::UiImage do
  describe '.new' do
    it 'creates with default values' do
      image = described_class.new
      expect(image.texture).to be_nil
      expect(image.flip_x).to be false
      expect(image.flip_y).to be false
    end

    it 'creates with custom values' do
      image = described_class.new(
        texture: 'sprite.png',
        flip_x: true,
        color: Bevy::Color.red
      )
      expect(image.texture).to eq('sprite.png')
      expect(image.flip_x).to be true
      expect(image.color.r).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns UiImage' do
      image = described_class.new
      expect(image.type_name).to eq('UiImage')
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      image = described_class.new(texture: 'test.png', flip_x: true)
      h = image.to_h
      expect(h[:texture]).to eq('test.png')
      expect(h[:flip_x]).to be true
    end
  end
end

RSpec.describe Bevy::ButtonBundle do
  describe '.new' do
    it 'creates with default values' do
      bundle = described_class.new
      expect(bundle.node).to be_a(Bevy::Node)
      expect(bundle.button).to be_a(Bevy::Button)
      expect(bundle.style).to be_a(Bevy::Style)
      expect(bundle.background_color).to be_a(Bevy::BackgroundColor)
    end

    it 'creates with custom style' do
      style = Bevy::Style.new(width: Bevy::Val.px(150))
      bundle = described_class.new(style: style)
      expect(bundle.style.width).to eq(Bevy::Val.px(150))
    end

    it 'creates with custom background color' do
      bundle = described_class.new(background_color: Bevy::BackgroundColor.new(Bevy::Color.green))
      expect(bundle.background_color.color.g).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns ButtonBundle' do
      bundle = described_class.new
      expect(bundle.type_name).to eq('ButtonBundle')
    end
  end
end

RSpec.describe Bevy::NodeBundle do
  describe '.new' do
    it 'creates with default values' do
      bundle = described_class.new
      expect(bundle.node).to be_a(Bevy::Node)
      expect(bundle.style).to be_a(Bevy::Style)
      expect(bundle.z_index).to eq(0)
    end

    it 'creates with custom style and z_index' do
      style = Bevy::Style.new(display: Bevy::Display::GRID)
      bundle = described_class.new(style: style, z_index: 10)
      expect(bundle.style.display).to eq(Bevy::Display::GRID)
      expect(bundle.z_index).to eq(10)
    end
  end

  describe '#type_name' do
    it 'returns NodeBundle' do
      bundle = described_class.new
      expect(bundle.type_name).to eq('NodeBundle')
    end
  end
end

RSpec.describe Bevy::ImageBundle do
  describe '.new' do
    it 'creates with default values' do
      bundle = described_class.new
      expect(bundle.node).to be_a(Bevy::Node)
      expect(bundle.image).to be_a(Bevy::UiImage)
    end

    it 'creates with custom image' do
      image = Bevy::UiImage.new(texture: 'icon.png')
      bundle = described_class.new(image: image)
      expect(bundle.image.texture).to eq('icon.png')
    end
  end

  describe '#type_name' do
    it 'returns ImageBundle' do
      bundle = described_class.new
      expect(bundle.type_name).to eq('ImageBundle')
    end
  end
end

RSpec.describe Bevy::TextBundle do
  describe '.new' do
    it 'creates with text' do
      text = Bevy::Text2d.new('Hello')
      bundle = described_class.new(text: text)
      expect(bundle.text.content).to eq('Hello')
    end

    it 'creates with custom style' do
      text = Bevy::Text2d.new('World')
      style = Bevy::Style.new(margin: Bevy::UiRect.all(Bevy::Val.px(10)))
      bundle = described_class.new(text: text, style: style)
      expect(bundle.style.margin.left).to eq(Bevy::Val.px(10))
    end
  end

  describe '#type_name' do
    it 'returns TextBundle' do
      text = Bevy::Text2d.new('Test')
      bundle = described_class.new(text: text)
      expect(bundle.type_name).to eq('TextBundle')
    end
  end
end
