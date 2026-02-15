# frozen_string_literal: true

module Bevy
  class State
    attr_reader :current, :previous, :pending

    def initialize(initial_state)
      @current = initial_state
      @previous = nil
      @pending = nil
      @on_enter_callbacks = Hash.new { |h, k| h[k] = [] }
      @on_exit_callbacks = Hash.new { |h, k| h[k] = [] }
    end

    def set(new_state)
      @pending = new_state unless new_state == @current
    end

    def is?(state)
      @current == state
    end

    def was?(state)
      @previous == state
    end

    def changed?
      @current != @previous
    end

    def just_entered?(state)
      changed? && @current == state
    end

    def just_exited?(state)
      changed? && @previous == state
    end

    def on_enter(state, &block)
      @on_enter_callbacks[state] << block
    end

    def on_exit(state, &block)
      @on_exit_callbacks[state] << block
    end

    def apply_transition(context = nil)
      return false unless @pending

      @previous = @current
      old_state = @current
      @current = @pending
      @pending = nil

      @on_exit_callbacks[old_state].each do |callback|
        if context
          callback.call(context)
        else
          callback.call
        end
      end

      @on_enter_callbacks[@current].each do |callback|
        if context
          callback.call(context)
        else
          callback.call
        end
      end

      true
    end

    def clear_change
      @previous = @current
    end

    def type_name
      'State'
    end
  end

  class NextState
    attr_accessor :state

    def initialize(state = nil)
      @state = state
    end

    def set(new_state)
      @state = new_state
    end

    def clear
      @state = nil
    end

    def pending?
      !@state.nil?
    end

    def take
      s = @state
      @state = nil
      s
    end

    def type_name
      'NextState'
    end
  end

  class StateStack
    def initialize(initial_state = nil)
      @stack = initial_state ? [initial_state] : []
      @on_push_callbacks = Hash.new { |h, k| h[k] = [] }
      @on_pop_callbacks = Hash.new { |h, k| h[k] = [] }
    end

    def current
      @stack.last
    end

    def empty?
      @stack.empty?
    end

    def size
      @stack.size
    end

    def push(state, context = nil)
      @stack.push(state)
      @on_push_callbacks[state].each do |callback|
        context ? callback.call(context) : callback.call
      end
    end

    def pop(context = nil)
      return nil if @stack.empty?

      state = @stack.pop
      @on_pop_callbacks[state].each do |callback|
        context ? callback.call(context) : callback.call
      end
      state
    end

    def replace(new_state, context = nil)
      pop(context)
      push(new_state, context)
    end

    def clear(context = nil)
      pop(context) until @stack.empty?
    end

    def on_push(state, &block)
      @on_push_callbacks[state] << block
    end

    def on_pop(state, &block)
      @on_pop_callbacks[state] << block
    end

    def include?(state)
      @stack.include?(state)
    end

    def type_name
      'StateStack'
    end
  end

  class StateMachine
    attr_reader :states, :current_state, :transitions

    def initialize
      @states = {}
      @current_state = nil
      @transitions = Hash.new { |h, k| h[k] = {} }
      @on_enter_callbacks = Hash.new { |h, k| h[k] = [] }
      @on_exit_callbacks = Hash.new { |h, k| h[k] = [] }
      @on_update_callbacks = Hash.new { |h, k| h[k] = [] }
    end

    def add_state(name, &block)
      @states[name] = block || -> {}
      self
    end

    def add_transition(from, event, to)
      @transitions[from][event] = to
      self
    end

    def set_initial(state)
      @current_state = state
      self
    end

    def trigger(event, context = nil)
      return false unless @current_state

      next_state = @transitions[@current_state][event]
      return false unless next_state

      transition_to(next_state, context)
    end

    def transition_to(new_state, context = nil)
      return false unless @states.key?(new_state)
      return false if new_state == @current_state

      old_state = @current_state

      @on_exit_callbacks[old_state].each do |callback|
        context ? callback.call(context) : callback.call
      end if old_state

      @current_state = new_state

      @on_enter_callbacks[new_state].each do |callback|
        context ? callback.call(context) : callback.call
      end

      true
    end

    def update(context = nil)
      return unless @current_state

      @on_update_callbacks[@current_state].each do |callback|
        context ? callback.call(context) : callback.call
      end
    end

    def on_enter(state, &block)
      @on_enter_callbacks[state] << block
      self
    end

    def on_exit(state, &block)
      @on_exit_callbacks[state] << block
      self
    end

    def on_update(state, &block)
      @on_update_callbacks[state] << block
      self
    end

    def can_trigger?(event)
      @current_state && @transitions[@current_state].key?(event)
    end

    def available_events
      return [] unless @current_state

      @transitions[@current_state].keys
    end

    def is?(state)
      @current_state == state
    end

    def type_name
      'StateMachine'
    end
  end

  module StatePlugin
    def self.build(app)
      app
    end
  end
end
