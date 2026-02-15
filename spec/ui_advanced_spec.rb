# frozen_string_literal: true

RSpec.describe Bevy::ScrollView do
  describe '.new' do
    it 'creates with default values' do
      scroll = described_class.new
      expect(scroll.scroll_x).to be true
      expect(scroll.scroll_y).to be true
      expect(scroll.offset.x).to eq(0.0)
    end
  end

  describe '#scroll_by' do
    it 'scrolls by delta' do
      scroll = described_class.new
      scroll.content_size = Bevy::Vec2.new(1000.0, 1000.0)
      scroll.viewport_size = Bevy::Vec2.new(100.0, 100.0)
      scroll.scroll_by(Bevy::Vec2.new(50.0, 30.0))
      expect(scroll.offset.x).to eq(50.0)
      expect(scroll.offset.y).to eq(30.0)
    end

    it 'respects overscroll contain' do
      scroll = described_class.new(overscroll_behavior: Bevy::ScrollView::OVERSCROLL_CONTAIN)
      scroll.content_size = Bevy::Vec2.new(200.0, 200.0)
      scroll.viewport_size = Bevy::Vec2.new(100.0, 100.0)
      scroll.scroll_by(Bevy::Vec2.new(-50.0, 200.0))
      expect(scroll.offset.x).to eq(0.0)
      expect(scroll.offset.y).to eq(100.0)
    end
  end

  describe '#scroll_to_top and #scroll_to_bottom' do
    it 'scrolls to top' do
      scroll = described_class.new
      scroll.content_size = Bevy::Vec2.new(100.0, 500.0)
      scroll.viewport_size = Bevy::Vec2.new(100.0, 100.0)
      scroll.scroll_by(Bevy::Vec2.new(0.0, 100.0))
      scroll.scroll_to_top
      expect(scroll.offset.y).to eq(0.0)
    end

    it 'scrolls to bottom' do
      scroll = described_class.new
      scroll.content_size = Bevy::Vec2.new(100.0, 500.0)
      scroll.viewport_size = Bevy::Vec2.new(100.0, 100.0)
      scroll.scroll_to_bottom
      expect(scroll.offset.y).to eq(400.0)
    end
  end

  describe '#scroll_percentage' do
    it 'returns scroll percentage' do
      scroll = described_class.new
      scroll.content_size = Bevy::Vec2.new(200.0, 200.0)
      scroll.viewport_size = Bevy::Vec2.new(100.0, 100.0)
      scroll.scroll_by(Bevy::Vec2.new(50.0, 50.0))
      pct = scroll.scroll_percentage
      expect(pct.x).to eq(0.5)
      expect(pct.y).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns ScrollView' do
      expect(described_class.new.type_name).to eq('ScrollView')
    end
  end
end

RSpec.describe Bevy::TextInput do
  describe '.new' do
    it 'creates with default values' do
      input = described_class.new
      expect(input.value).to eq('')
      expect(input.cursor_position).to eq(0)
      expect(input.password).to be false
    end

    it 'creates with initial value' do
      input = described_class.new(value: 'Hello')
      expect(input.value).to eq('Hello')
      expect(input.cursor_position).to eq(5)
    end
  end

  describe '#insert' do
    it 'inserts text at cursor' do
      input = described_class.new(value: 'Hello')
      input.cursor_position = 5
      input.insert(' World')
      expect(input.value).to eq('Hello World')
    end

    it 'respects max_length' do
      input = described_class.new(max_length: 5)
      input.insert('Hello World')
      expect(input.value).to eq('')
    end

    it 'ignores when readonly' do
      input = described_class.new(value: 'Test', readonly: true)
      input.insert('More')
      expect(input.value).to eq('Test')
    end
  end

  describe '#delete_backward' do
    it 'deletes character before cursor' do
      input = described_class.new(value: 'Hello')
      input.delete_backward
      expect(input.value).to eq('Hell')
    end
  end

  describe '#delete_forward' do
    it 'deletes character after cursor' do
      input = described_class.new(value: 'Hello')
      input.cursor_position = 0
      input.delete_forward
      expect(input.value).to eq('ello')
    end
  end

  describe '#move_cursor' do
    it 'moves cursor left' do
      input = described_class.new(value: 'Hello')
      input.move_cursor(:left)
      expect(input.cursor_position).to eq(4)
    end

    it 'moves cursor to home' do
      input = described_class.new(value: 'Hello')
      input.move_cursor(:home)
      expect(input.cursor_position).to eq(0)
    end
  end

  describe '#select_all' do
    it 'selects all text' do
      input = described_class.new(value: 'Hello')
      input.select_all
      expect(input.has_selection?).to be true
      expect(input.selected_text).to eq('Hello')
    end
  end

  describe '#display_value' do
    it 'masks password input' do
      input = described_class.new(value: 'secret', password: true)
      expect(input.display_value).to eq('******')
    end
  end

  describe '#type_name' do
    it 'returns TextInput' do
      expect(described_class.new.type_name).to eq('TextInput')
    end
  end
end

RSpec.describe Bevy::FocusState do
  describe '.new' do
    it 'creates with no focused entity' do
      focus = described_class.new
      expect(focus.focused_entity).to be_nil
    end
  end

  describe '#focus and #blur' do
    it 'focuses and blurs entity' do
      focus = described_class.new
      entity = double('entity')
      focus.focus(entity)
      expect(focus.focused?(entity)).to be true
      focus.blur
      expect(focus.focused?(entity)).to be false
    end
  end

  describe '#focus_next and #focus_previous' do
    it 'cycles through focus order' do
      focus = described_class.new
      e1 = double('entity1')
      e2 = double('entity2')
      e3 = double('entity3')
      focus.register(e1)
      focus.register(e2)
      focus.register(e3)

      focus.focus_next
      expect(focus.focused_entity).to eq(e1)
      focus.focus_next
      expect(focus.focused_entity).to eq(e2)
      focus.focus_previous
      expect(focus.focused_entity).to eq(e1)
    end
  end

  describe '#type_name' do
    it 'returns FocusState' do
      expect(described_class.new.type_name).to eq('FocusState')
    end
  end
end

RSpec.describe Bevy::Slider do
  describe '.new' do
    it 'creates with default values' do
      slider = described_class.new
      expect(slider.value).to eq(0.0)
      expect(slider.min).to eq(0.0)
      expect(slider.max).to eq(1.0)
    end

    it 'clamps value to range' do
      slider = described_class.new(value: 2.0, max: 1.0)
      expect(slider.value).to eq(1.0)
    end
  end

  describe '#normalized_value' do
    it 'returns 0-1 normalized value' do
      slider = described_class.new(value: 50.0, min: 0.0, max: 100.0)
      expect(slider.normalized_value).to eq(0.5)
    end
  end

  describe '#set_from_normalized' do
    it 'sets value from normalized' do
      slider = described_class.new(min: 0.0, max: 100.0)
      slider.set_from_normalized(0.75)
      expect(slider.value).to eq(75.0)
    end
  end

  describe '#increment and #decrement' do
    it 'increments by step' do
      slider = described_class.new(value: 5.0, min: 0.0, max: 10.0, step: 1.0)
      slider.increment
      expect(slider.value).to eq(6.0)
      slider.decrement
      expect(slider.value).to eq(5.0)
    end
  end

  describe '#type_name' do
    it 'returns Slider' do
      expect(described_class.new.type_name).to eq('Slider')
    end
  end
end

RSpec.describe Bevy::Checkbox do
  describe '.new' do
    it 'creates with default values' do
      checkbox = described_class.new
      expect(checkbox.checked).to be false
      expect(checkbox.disabled).to be false
    end
  end

  describe '#toggle' do
    it 'toggles checked state' do
      checkbox = described_class.new
      checkbox.toggle
      expect(checkbox.checked).to be true
      checkbox.toggle
      expect(checkbox.checked).to be false
    end

    it 'does not toggle when disabled' do
      checkbox = described_class.new(disabled: true)
      checkbox.toggle
      expect(checkbox.checked).to be false
    end
  end

  describe '#type_name' do
    it 'returns Checkbox' do
      expect(described_class.new.type_name).to eq('Checkbox')
    end
  end
end

RSpec.describe Bevy::RadioGroup do
  describe '.new' do
    it 'creates with options' do
      radio = described_class.new(name: 'size', options: ['S', 'M', 'L'])
      expect(radio.options).to eq(['S', 'M', 'L'])
      expect(radio.selected_index).to be_nil
    end
  end

  describe '#select' do
    it 'selects option by index' do
      radio = described_class.new(name: 'size', options: ['S', 'M', 'L'])
      radio.select(1)
      expect(radio.selected_value).to eq('M')
    end
  end

  describe '#select_value' do
    it 'selects option by value' do
      radio = described_class.new(name: 'size', options: ['S', 'M', 'L'])
      radio.select_value('L')
      expect(radio.selected_index).to eq(2)
    end
  end

  describe '#type_name' do
    it 'returns RadioGroup' do
      expect(described_class.new(name: 'test').type_name).to eq('RadioGroup')
    end
  end
end

RSpec.describe Bevy::Dropdown do
  describe '.new' do
    it 'creates with options' do
      dropdown = described_class.new(options: ['Red', 'Green', 'Blue'])
      expect(dropdown.options.size).to eq(3)
      expect(dropdown.open).to be false
    end
  end

  describe '#toggle' do
    it 'toggles open state' do
      dropdown = described_class.new
      dropdown.toggle
      expect(dropdown.open).to be true
    end
  end

  describe '#select' do
    it 'selects option and closes' do
      dropdown = described_class.new(options: ['A', 'B', 'C'])
      dropdown.toggle
      dropdown.select(1)
      expect(dropdown.selected_value).to eq('B')
      expect(dropdown.open).to be false
    end
  end

  describe '#display_text' do
    it 'returns placeholder when nothing selected' do
      dropdown = described_class.new(placeholder: 'Choose...')
      expect(dropdown.display_text).to eq('Choose...')
    end

    it 'returns selected value' do
      dropdown = described_class.new(options: ['A', 'B'], selected_index: 0)
      expect(dropdown.display_text).to eq('A')
    end
  end

  describe '#type_name' do
    it 'returns Dropdown' do
      expect(described_class.new.type_name).to eq('Dropdown')
    end
  end
end

RSpec.describe Bevy::TabContainer do
  describe '.new' do
    it 'creates empty container' do
      tabs = described_class.new
      expect(tabs.tab_count).to eq(0)
    end
  end

  describe '#add_tab' do
    it 'adds tabs' do
      tabs = described_class.new
      tabs.add_tab('Tab 1').add_tab('Tab 2')
      expect(tabs.tab_count).to eq(2)
    end
  end

  describe '#select_tab' do
    it 'selects tab by index' do
      tabs = described_class.new
      tabs.add_tab('Tab 1').add_tab('Tab 2')
      tabs.select_tab(1)
      expect(tabs.active_tab[:title]).to eq('Tab 2')
    end
  end

  describe '#type_name' do
    it 'returns TabContainer' do
      expect(described_class.new.type_name).to eq('TabContainer')
    end
  end
end

RSpec.describe Bevy::ProgressBar do
  describe '.new' do
    it 'creates with default values' do
      bar = described_class.new
      expect(bar.value).to eq(0.0)
      expect(bar.min).to eq(0.0)
      expect(bar.max).to eq(1.0)
    end
  end

  describe '#percentage' do
    it 'returns percentage complete' do
      bar = described_class.new(value: 0.5)
      expect(bar.percentage).to eq(50.0)
    end
  end

  describe '#complete?' do
    it 'returns true when at max' do
      bar = described_class.new(value: 1.0)
      expect(bar.complete?).to be true
    end
  end

  describe '#type_name' do
    it 'returns ProgressBar' do
      expect(described_class.new.type_name).to eq('ProgressBar')
    end
  end
end

RSpec.describe Bevy::Tooltip do
  describe '.new' do
    it 'creates with text' do
      tooltip = described_class.new(text: 'Help text')
      expect(tooltip.text).to eq('Help text')
      expect(tooltip.visible).to be false
    end
  end

  describe '#update' do
    it 'shows after delay' do
      tooltip = described_class.new(text: 'Help', delay: 0.5)
      tooltip.update(0.3, true)
      expect(tooltip.visible).to be false
      tooltip.update(0.3, true)
      expect(tooltip.visible).to be true
    end

    it 'hides when not hovering' do
      tooltip = described_class.new(text: 'Help', delay: 0.5)
      tooltip.update(1.0, true)
      tooltip.update(0.1, false)
      expect(tooltip.visible).to be false
    end
  end

  describe '#type_name' do
    it 'returns Tooltip' do
      expect(described_class.new(text: 'Test').type_name).to eq('Tooltip')
    end
  end
end

RSpec.describe Bevy::Modal do
  describe '.new' do
    it 'creates hidden modal' do
      modal = described_class.new(title: 'Confirm')
      expect(modal.visible).to be false
      expect(modal.title).to eq('Confirm')
    end
  end

  describe '#open and #close' do
    it 'toggles visibility' do
      modal = described_class.new
      modal.open
      expect(modal.visible).to be true
      modal.close
      expect(modal.visible).to be false
    end
  end

  describe '#type_name' do
    it 'returns Modal' do
      expect(described_class.new.type_name).to eq('Modal')
    end
  end
end

RSpec.describe Bevy::ContextMenu do
  describe '.new' do
    it 'creates empty menu' do
      menu = described_class.new
      expect(menu.items).to be_empty
      expect(menu.visible).to be false
    end
  end

  describe '#add_item' do
    it 'adds menu items' do
      menu = described_class.new
      menu.add_item('Copy').add_item('Paste')
      expect(menu.items.size).to eq(2)
    end
  end

  describe '#show_at and #hide' do
    it 'shows at position' do
      menu = described_class.new
      menu.show_at(Bevy::Vec2.new(100.0, 200.0))
      expect(menu.visible).to be true
      expect(menu.position.x).to eq(100.0)
      menu.hide
      expect(menu.visible).to be false
    end
  end

  describe '#type_name' do
    it 'returns ContextMenu' do
      expect(described_class.new.type_name).to eq('ContextMenu')
    end
  end
end
