# frozen_string_literal: true

RSpec.describe Bevy::Font do
  describe '.new' do
    it 'creates with path' do
      font = described_class.new(path: 'fonts/arial.ttf')
      expect(font.path).to eq('fonts/arial.ttf')
    end

    it 'returns false for loaded? when no data' do
      font = described_class.new(path: 'test.ttf')
      expect(font.loaded?).to be false
    end

    it 'returns true for loaded? when data exists' do
      font = described_class.new(data: 'binary data')
      expect(font.loaded?).to be true
    end
  end

  describe '#type_name' do
    it 'returns Font' do
      expect(described_class.new.type_name).to eq('Font')
    end
  end
end

RSpec.describe Bevy::FontAtlas do
  describe '.new' do
    it 'creates with font and size' do
      font = Bevy::Font.new(path: 'test.ttf')
      atlas = described_class.new(font: font, size: 24.0)
      expect(atlas.font).to eq(font)
      expect(atlas.size).to eq(24.0)
    end
  end

  describe '#add_glyph and #get_glyph' do
    it 'stores and retrieves glyphs' do
      atlas = described_class.new(font: Bevy::Font.new, size: 16.0)
      glyph = Bevy::GlyphInfo.new(
        char: 'A',
        rect: Bevy::Rect.new(min: Bevy::Vec2.zero, max: Bevy::Vec2.new(10.0, 16.0)),
        bearing: Bevy::Vec2.new(1.0, 14.0),
        advance: 12.0
      )
      atlas.add_glyph('A', glyph)
      expect(atlas.get_glyph('A')).to eq(glyph)
      expect(atlas.has_glyph?('A')).to be true
    end
  end

  describe '#type_name' do
    it 'returns FontAtlas' do
      atlas = described_class.new(font: Bevy::Font.new, size: 16.0)
      expect(atlas.type_name).to eq('FontAtlas')
    end
  end
end

RSpec.describe Bevy::TextStyle do
  describe '.new' do
    it 'creates with default values' do
      style = described_class.new
      expect(style.font_size).to eq(16.0)
    end

    it 'creates with custom values' do
      style = described_class.new(font_size: 24.0)
      expect(style.font_size).to eq(24.0)
    end
  end

  describe '#with_font_size' do
    it 'returns new style with different size' do
      style = described_class.new(font_size: 16.0)
      new_style = style.with_font_size(32.0)
      expect(new_style.font_size).to eq(32.0)
      expect(style.font_size).to eq(16.0)
    end
  end

  describe '#with_color' do
    it 'returns new style with different color' do
      style = described_class.new
      red = Bevy::Color.rgba(1.0, 0.0, 0.0, 1.0)
      new_style = style.with_color(red)
      expect(new_style.color.r).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns TextStyle' do
      expect(described_class.new.type_name).to eq('TextStyle')
    end
  end
end

RSpec.describe Bevy::Text do
  describe '.new' do
    it 'creates from string' do
      text = described_class.new('Hello World')
      expect(text.full_text).to eq('Hello World')
    end

    it 'creates from sections' do
      sections = [
        Bevy::TextSection.new(value: 'Hello '),
        Bevy::TextSection.new(value: 'World')
      ]
      text = described_class.new(sections)
      expect(text.full_text).to eq('Hello World')
    end
  end

  describe '#add_section' do
    it 'adds section to text' do
      text = described_class.new('Hello')
      text.add_section(Bevy::TextSection.new(value: ' World'))
      expect(text.full_text).to eq('Hello World')
    end
  end

  describe '#with_justify' do
    it 'sets justification' do
      text = described_class.new('Test')
      text.with_justify(Bevy::JustifyText::CENTER)
      expect(text.justify).to eq(:center)
    end
  end

  describe '#type_name' do
    it 'returns Text' do
      expect(described_class.new.type_name).to eq('Text')
    end
  end
end

RSpec.describe Bevy::TextSection do
  describe '.new' do
    it 'creates with value and style' do
      style = Bevy::TextStyle.new(font_size: 24.0)
      section = described_class.new(value: 'Hello', style: style)
      expect(section.value).to eq('Hello')
      expect(section.style.font_size).to eq(24.0)
    end
  end

  describe '#type_name' do
    it 'returns TextSection' do
      expect(described_class.new.type_name).to eq('TextSection')
    end
  end
end

RSpec.describe Bevy::TextBundle do
  describe '.new' do
    it 'creates with text' do
      text = Bevy::Text.new('Custom Text')
      bundle = described_class.new(text: text)
      expect(bundle.text.full_text).to eq('Custom Text')
    end

    it 'creates with style' do
      text = Bevy::Text.new('Test')
      style = Bevy::Style.new
      bundle = described_class.new(text: text, style: style)
      expect(bundle.style).to eq(style)
    end
  end

  describe '#type_name' do
    it 'returns TextBundle' do
      text = Bevy::Text.new('Test')
      expect(described_class.new(text: text).type_name).to eq('TextBundle')
    end
  end
end

RSpec.describe Bevy::RichText do
  describe '.new' do
    it 'creates empty' do
      rich = described_class.new
      expect(rich.sections).to be_empty
    end
  end

  describe '#push' do
    it 'adds text section' do
      rich = described_class.new
      rich.push('Hello')
      expect(rich.sections.size).to eq(1)
    end
  end

  describe '#bold' do
    it 'adds bold text' do
      rich = described_class.new
      rich.bold('Bold Text')
      expect(rich.sections.first.style.bold?).to be true
    end
  end

  describe '#italic' do
    it 'adds italic text' do
      rich = described_class.new
      rich.italic('Italic Text')
      expect(rich.sections.first.style.italic?).to be true
    end
  end

  describe '#colored' do
    it 'adds colored text' do
      rich = described_class.new
      red = Bevy::Color.rgba(1.0, 0.0, 0.0, 1.0)
      rich.colored('Red Text', red)
      expect(rich.sections.first.style.color.r).to eq(1.0)
    end
  end

  describe '#to_text' do
    it 'converts to Text' do
      rich = described_class.new
      rich.push('Hello ')
      rich.push('World')
      text = rich.to_text
      expect(text).to be_a(Bevy::Text)
      expect(text.full_text).to eq('Hello World')
    end
  end

  describe '#type_name' do
    it 'returns RichText' do
      expect(described_class.new.type_name).to eq('RichText')
    end
  end
end

RSpec.describe Bevy::RichTextStyle do
  describe '.new' do
    it 'creates with style options' do
      base = Bevy::TextStyle.new
      style = described_class.new(base: base, weight: :bold, slant: :italic)
      expect(style.bold?).to be true
      expect(style.italic?).to be true
    end
  end

  describe '#underlined? and #strikethrough?' do
    it 'returns text decoration status' do
      base = Bevy::TextStyle.new
      style = described_class.new(base: base, underline: true, strikethrough: true)
      expect(style.underlined?).to be true
      expect(style.strikethrough?).to be true
    end
  end

  describe '#type_name' do
    it 'returns RichTextStyle' do
      base = Bevy::TextStyle.new
      expect(described_class.new(base: base).type_name).to eq('RichTextStyle')
    end
  end
end

RSpec.describe Bevy::TextPipeline do
  describe '.new' do
    it 'creates empty pipeline' do
      pipeline = described_class.new
      expect(pipeline.fonts).to be_empty
    end
  end

  describe '#register_font' do
    it 'registers and retrieves fonts' do
      pipeline = described_class.new
      font = Bevy::Font.new(path: 'arial.ttf')
      pipeline.register_font('arial', font)
      expect(pipeline.get_font('arial')).to eq(font)
    end
  end

  describe '#type_name' do
    it 'returns TextPipeline' do
      expect(described_class.new.type_name).to eq('TextPipeline')
    end
  end
end

RSpec.describe Bevy::TextMeasure do
  describe '.measure' do
    it 'measures text size' do
      style = Bevy::TextStyle.new(font_size: 16.0)
      text = Bevy::Text.new('Hello')
      size = described_class.measure(text, style)
      expect(size.x).to be > 0
      expect(size.y).to be > 0
    end

    it 'handles multiline text' do
      style = Bevy::TextStyle.new(font_size: 16.0)
      text = "Line 1\nLine 2\nLine 3"
      size = described_class.measure(text, style)
      expect(size.y).to be > 16.0
    end
  end
end

RSpec.describe Bevy::TypewriterEffect do
  describe '.new' do
    it 'creates with text' do
      effect = described_class.new(text: 'Hello World')
      expect(effect.text).to eq('Hello World')
      expect(effect.visible_chars).to eq(0)
    end
  end

  describe '#update' do
    it 'reveals characters over time' do
      effect = described_class.new(text: 'Hello', chars_per_second: 10.0)
      effect.update(0.2)
      expect(effect.visible_chars).to eq(2)
      expect(effect.visible_text).to eq('He')
    end
  end

  describe '#finished?' do
    it 'returns true when all characters visible' do
      effect = described_class.new(text: 'Hi', chars_per_second: 100.0)
      effect.update(1.0)
      expect(effect.finished?).to be true
    end
  end

  describe '#skip' do
    it 'shows all text immediately' do
      effect = described_class.new(text: 'Hello World')
      effect.skip
      expect(effect.visible_text).to eq('Hello World')
    end
  end

  describe '#reset' do
    it 'resets to beginning' do
      effect = described_class.new(text: 'Hello', chars_per_second: 100.0)
      effect.update(1.0)
      effect.reset
      expect(effect.visible_chars).to eq(0)
    end
  end

  describe '#type_name' do
    it 'returns TypewriterEffect' do
      expect(described_class.new(text: 'test').type_name).to eq('TypewriterEffect')
    end
  end
end

RSpec.describe Bevy::TextBlink do
  describe '.new' do
    it 'creates with interval' do
      blink = described_class.new(interval: 0.5)
      expect(blink.interval).to eq(0.5)
      expect(blink.visible).to be true
    end
  end

  describe '#update' do
    it 'toggles visibility' do
      blink = described_class.new(interval: 0.5)
      blink.update(0.6)
      expect(blink.visible).to be false
      blink.update(0.6)
      expect(blink.visible).to be true
    end
  end

  describe '#type_name' do
    it 'returns TextBlink' do
      expect(described_class.new.type_name).to eq('TextBlink')
    end
  end
end

RSpec.describe Bevy::ZIndex do
  describe '.new' do
    it 'creates with default values' do
      z = described_class.new
      expect(z.value).to eq(0)
      expect(z.local?).to be true
    end

    it 'creates with custom values' do
      z = described_class.new(value: 10, mode: Bevy::ZIndex::GLOBAL)
      expect(z.value).to eq(10)
      expect(z.global?).to be true
    end
  end

  describe '#type_name' do
    it 'returns ZIndex' do
      expect(described_class.new.type_name).to eq('ZIndex')
    end
  end
end
