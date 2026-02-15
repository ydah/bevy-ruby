# frozen_string_literal: true

module Bevy
  class ScrollView
    attr_accessor :offset, :content_size, :viewport_size
    attr_accessor :scroll_x, :scroll_y, :overscroll_behavior

    OVERSCROLL_NONE = :none
    OVERSCROLL_CONTAIN = :contain
    OVERSCROLL_AUTO = :auto

    def initialize(
      scroll_x: true,
      scroll_y: true,
      overscroll_behavior: OVERSCROLL_CONTAIN
    )
      @offset = Vec2.zero
      @content_size = Vec2.zero
      @viewport_size = Vec2.zero
      @scroll_x = scroll_x
      @scroll_y = scroll_y
      @overscroll_behavior = overscroll_behavior
    end

    def scroll_by(delta)
      new_offset_x = @scroll_x ? @offset.x + delta.x : @offset.x
      new_offset_y = @scroll_y ? @offset.y + delta.y : @offset.y

      if @overscroll_behavior == OVERSCROLL_CONTAIN
        max_x = [@content_size.x - @viewport_size.x, 0.0].max
        max_y = [@content_size.y - @viewport_size.y, 0.0].max
        new_offset_x = [[new_offset_x, 0.0].max, max_x].min
        new_offset_y = [[new_offset_y, 0.0].max, max_y].min
      end

      @offset = Vec2.new(new_offset_x, new_offset_y)
    end

    def scroll_to(position)
      @offset = position
    end

    def scroll_to_top
      @offset = Vec2.new(@offset.x, 0.0)
    end

    def scroll_to_bottom
      max_y = [@content_size.y - @viewport_size.y, 0.0].max
      @offset = Vec2.new(@offset.x, max_y)
    end

    def scroll_percentage
      return Vec2.zero if @content_size.x <= @viewport_size.x && @content_size.y <= @viewport_size.y

      max_x = [@content_size.x - @viewport_size.x, 1.0].max
      max_y = [@content_size.y - @viewport_size.y, 1.0].max
      Vec2.new(@offset.x / max_x, @offset.y / max_y)
    end

    def type_name
      'ScrollView'
    end
  end

  class TextInput
    attr_accessor :value, :placeholder, :cursor_position, :selection_start, :selection_end
    attr_accessor :max_length, :multiline, :password, :readonly, :focused

    def initialize(
      value: '',
      placeholder: '',
      max_length: nil,
      multiline: false,
      password: false,
      readonly: false
    )
      @value = value
      @placeholder = placeholder
      @cursor_position = value.length
      @selection_start = nil
      @selection_end = nil
      @max_length = max_length
      @multiline = multiline
      @password = password
      @readonly = readonly
      @focused = false
    end

    def insert(text)
      return if @readonly
      return if @max_length && @value.length + text.length > @max_length

      delete_selection if has_selection?

      @value = @value[0...@cursor_position] + text + @value[@cursor_position..-1]
      @cursor_position += text.length
    end

    def delete_backward
      return if @readonly
      return if @cursor_position == 0 && !has_selection?

      if has_selection?
        delete_selection
      else
        @value = @value[0...(@cursor_position - 1)] + @value[@cursor_position..-1]
        @cursor_position -= 1
      end
    end

    def delete_forward
      return if @readonly
      return if @cursor_position >= @value.length && !has_selection?

      if has_selection?
        delete_selection
      else
        @value = @value[0...@cursor_position] + @value[(@cursor_position + 1)..-1]
      end
    end

    def move_cursor(direction)
      case direction
      when :left
        @cursor_position = [@cursor_position - 1, 0].max
      when :right
        @cursor_position = [@cursor_position + 1, @value.length].min
      when :home
        @cursor_position = 0
      when :end
        @cursor_position = @value.length
      end
      clear_selection
    end

    def select_all
      @selection_start = 0
      @selection_end = @value.length
      @cursor_position = @value.length
    end

    def clear_selection
      @selection_start = nil
      @selection_end = nil
    end

    def has_selection?
      @selection_start && @selection_end && @selection_start != @selection_end
    end

    def selected_text
      return '' unless has_selection?

      start_pos = [@selection_start, @selection_end].min
      end_pos = [@selection_start, @selection_end].max
      @value[start_pos...end_pos]
    end

    def display_value
      @password ? '*' * @value.length : @value
    end

    def type_name
      'TextInput'
    end

    private

    def delete_selection
      return unless has_selection?

      start_pos = [@selection_start, @selection_end].min
      end_pos = [@selection_start, @selection_end].max
      @value = @value[0...start_pos] + @value[end_pos..-1]
      @cursor_position = start_pos
      clear_selection
    end
  end

  class FocusState
    attr_reader :focused_entity, :focus_order

    def initialize
      @focused_entity = nil
      @focus_order = []
    end

    def focus(entity)
      @focused_entity = entity
    end

    def blur
      @focused_entity = nil
    end

    def focused?(entity)
      @focused_entity == entity
    end

    def register(entity, order: nil)
      if order
        @focus_order.insert(order, entity)
      else
        @focus_order << entity
      end
    end

    def unregister(entity)
      @focus_order.delete(entity)
      blur if @focused_entity == entity
    end

    def focus_next
      return if @focus_order.empty?

      current_index = @focused_entity ? @focus_order.index(@focused_entity) : -1
      next_index = (current_index + 1) % @focus_order.length
      @focused_entity = @focus_order[next_index]
    end

    def focus_previous
      return if @focus_order.empty?

      current_index = @focused_entity ? @focus_order.index(@focused_entity) : @focus_order.length
      prev_index = (current_index - 1) % @focus_order.length
      @focused_entity = @focus_order[prev_index]
    end

    def type_name
      'FocusState'
    end
  end

  class Slider
    attr_accessor :value, :min, :max, :step, :orientation, :disabled

    HORIZONTAL = :horizontal
    VERTICAL = :vertical

    def initialize(
      value: 0.0,
      min: 0.0,
      max: 1.0,
      step: nil,
      orientation: HORIZONTAL,
      disabled: false
    )
      @min = min.to_f
      @max = max.to_f
      @step = step
      @orientation = orientation
      @disabled = disabled
      self.value = value
    end

    def value=(val)
      clamped = [[val.to_f, @min].max, @max].min
      @value = @step ? (clamped / @step).round * @step : clamped
    end

    def normalized_value
      return 0.0 if @max == @min

      (@value - @min) / (@max - @min)
    end

    def set_from_normalized(normalized)
      self.value = @min + normalized * (@max - @min)
    end

    def increment
      return if @disabled

      self.value = @value + (@step || (@max - @min) / 10.0)
    end

    def decrement
      return if @disabled

      self.value = @value - (@step || (@max - @min) / 10.0)
    end

    def type_name
      'Slider'
    end
  end

  class Checkbox
    attr_accessor :checked, :disabled, :label

    def initialize(checked: false, disabled: false, label: nil)
      @checked = checked
      @disabled = disabled
      @label = label
    end

    def toggle
      return if @disabled

      @checked = !@checked
    end

    def type_name
      'Checkbox'
    end
  end

  class RadioGroup
    attr_reader :options, :selected_index, :name

    def initialize(name:, options: [])
      @name = name
      @options = options
      @selected_index = nil
    end

    def add_option(option)
      @options << option
      self
    end

    def select(index)
      return if index < 0 || index >= @options.length

      @selected_index = index
    end

    def select_value(value)
      index = @options.index(value)
      select(index) if index
    end

    def selected_value
      @selected_index ? @options[@selected_index] : nil
    end

    def selected?(index)
      @selected_index == index
    end

    def type_name
      'RadioGroup'
    end
  end

  class Dropdown
    attr_accessor :options, :selected_index, :open, :placeholder, :disabled

    def initialize(
      options: [],
      selected_index: nil,
      placeholder: 'Select...',
      disabled: false
    )
      @options = options
      @selected_index = selected_index
      @open = false
      @placeholder = placeholder
      @disabled = disabled
    end

    def toggle
      return if @disabled

      @open = !@open
    end

    def close
      @open = false
    end

    def select(index)
      return if index < 0 || index >= @options.length

      @selected_index = index
      @open = false
    end

    def selected_value
      @selected_index ? @options[@selected_index] : nil
    end

    def display_text
      selected_value || @placeholder
    end

    def type_name
      'Dropdown'
    end
  end

  class TabContainer
    attr_reader :tabs, :active_index

    def initialize
      @tabs = []
      @active_index = 0
    end

    def add_tab(title, content = nil)
      @tabs << { title: title, content: content }
      self
    end

    def remove_tab(index)
      return if index < 0 || index >= @tabs.length

      @tabs.delete_at(index)
      @active_index = [@active_index, @tabs.length - 1].min if @active_index >= @tabs.length
    end

    def select_tab(index)
      return if index < 0 || index >= @tabs.length

      @active_index = index
    end

    def active_tab
      @tabs[@active_index]
    end

    def tab_count
      @tabs.length
    end

    def type_name
      'TabContainer'
    end
  end

  class ProgressBar
    attr_accessor :value, :min, :max, :show_label

    def initialize(value: 0.0, min: 0.0, max: 1.0, show_label: false)
      @min = min.to_f
      @max = max.to_f
      @value = [[value.to_f, @min].max, @max].min
      @show_label = show_label
    end

    def percentage
      return 0.0 if @max == @min

      ((@value - @min) / (@max - @min)) * 100.0
    end

    def normalized
      return 0.0 if @max == @min

      (@value - @min) / (@max - @min)
    end

    def complete?
      @value >= @max
    end

    def type_name
      'ProgressBar'
    end
  end

  class Tooltip
    attr_accessor :text, :position, :visible, :delay

    def initialize(text:, delay: 0.5)
      @text = text
      @position = Vec2.zero
      @visible = false
      @delay = delay.to_f
      @hover_timer = 0.0
    end

    def update(delta, hovering)
      if hovering
        @hover_timer += delta
        @visible = @hover_timer >= @delay
      else
        @hover_timer = 0.0
        @visible = false
      end
    end

    def show_at(position)
      @position = position
      @visible = true
    end

    def hide
      @visible = false
      @hover_timer = 0.0
    end

    def type_name
      'Tooltip'
    end
  end

  class Modal
    attr_accessor :visible, :title, :content, :closable

    def initialize(title: nil, content: nil, closable: true)
      @visible = false
      @title = title
      @content = content
      @closable = closable
    end

    def open
      @visible = true
    end

    def close
      @visible = false if @closable
    end

    def toggle
      @visible = !@visible
    end

    def type_name
      'Modal'
    end
  end

  class ContextMenu
    attr_reader :items, :position
    attr_accessor :visible

    def initialize
      @items = []
      @position = Vec2.zero
      @visible = false
    end

    def add_item(label, action = nil)
      @items << { label: label, action: action, enabled: true }
      self
    end

    def add_separator
      @items << { separator: true }
      self
    end

    def show_at(position)
      @position = position
      @visible = true
    end

    def hide
      @visible = false
    end

    def select(index)
      return if index < 0 || index >= @items.length

      item = @items[index]
      return if item[:separator] || !item[:enabled]

      item[:action]&.call
      hide
    end

    def type_name
      'ContextMenu'
    end
  end
end
