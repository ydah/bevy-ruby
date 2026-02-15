# frozen_string_literal: true

RSpec.describe Bevy::State do
  describe '.new' do
    it 'creates with initial state' do
      state = described_class.new(:main_menu)
      expect(state.current).to eq(:main_menu)
      expect(state.previous).to be_nil
    end
  end

  describe '#set' do
    it 'sets pending state' do
      state = described_class.new(:menu)
      state.set(:game)
      expect(state.pending).to eq(:game)
      expect(state.current).to eq(:menu)
    end

    it 'does not set pending if same as current' do
      state = described_class.new(:menu)
      state.set(:menu)
      expect(state.pending).to be_nil
    end
  end

  describe '#is?' do
    it 'returns true if current state matches' do
      state = described_class.new(:playing)
      expect(state.is?(:playing)).to be true
      expect(state.is?(:paused)).to be false
    end
  end

  describe '#was?' do
    it 'returns true if previous state matches' do
      state = described_class.new(:menu)
      state.set(:game)
      state.apply_transition
      expect(state.was?(:menu)).to be true
    end
  end

  describe '#changed?' do
    it 'returns true initially (no previous state)' do
      state = described_class.new(:menu)
      expect(state.changed?).to be true
    end

    it 'returns false after clearing change' do
      state = described_class.new(:menu)
      state.clear_change
      expect(state.changed?).to be false
    end

    it 'returns true after transition' do
      state = described_class.new(:menu)
      state.clear_change
      state.set(:game)
      state.apply_transition
      expect(state.changed?).to be true
    end
  end

  describe '#just_entered?' do
    it 'returns true for newly entered state' do
      state = described_class.new(:menu)
      state.set(:game)
      state.apply_transition
      expect(state.just_entered?(:game)).to be true
      expect(state.just_entered?(:menu)).to be false
    end
  end

  describe '#just_exited?' do
    it 'returns true for just exited state' do
      state = described_class.new(:menu)
      state.set(:game)
      state.apply_transition
      expect(state.just_exited?(:menu)).to be true
      expect(state.just_exited?(:game)).to be false
    end
  end

  describe '#on_enter' do
    it 'registers callback for state entry' do
      state = described_class.new(:menu)
      entered = false
      state.on_enter(:game) { entered = true }
      state.set(:game)
      state.apply_transition
      expect(entered).to be true
    end

    it 'passes context to callback' do
      state = described_class.new(:menu)
      received_context = nil
      state.on_enter(:game) { |ctx| received_context = ctx }
      state.set(:game)
      state.apply_transition('test_context')
      expect(received_context).to eq('test_context')
    end
  end

  describe '#on_exit' do
    it 'registers callback for state exit' do
      state = described_class.new(:menu)
      exited = false
      state.on_exit(:menu) { exited = true }
      state.set(:game)
      state.apply_transition
      expect(exited).to be true
    end
  end

  describe '#apply_transition' do
    it 'returns false when no pending state' do
      state = described_class.new(:menu)
      expect(state.apply_transition).to be false
    end

    it 'transitions to pending state' do
      state = described_class.new(:menu)
      state.set(:game)
      expect(state.apply_transition).to be true
      expect(state.current).to eq(:game)
      expect(state.previous).to eq(:menu)
      expect(state.pending).to be_nil
    end

    it 'calls exit then enter callbacks in order' do
      state = described_class.new(:menu)
      order = []
      state.on_exit(:menu) { order << :exit_menu }
      state.on_enter(:game) { order << :enter_game }
      state.set(:game)
      state.apply_transition
      expect(order).to eq(%i[exit_menu enter_game])
    end
  end

  describe '#clear_change' do
    it 'makes changed? return false' do
      state = described_class.new(:menu)
      state.set(:game)
      state.apply_transition
      expect(state.changed?).to be true
      state.clear_change
      expect(state.changed?).to be false
    end
  end

  describe '#type_name' do
    it 'returns State' do
      state = described_class.new(:menu)
      expect(state.type_name).to eq('State')
    end
  end
end

RSpec.describe Bevy::NextState do
  describe '.new' do
    it 'creates with nil state by default' do
      next_state = described_class.new
      expect(next_state.state).to be_nil
    end

    it 'creates with initial state' do
      next_state = described_class.new(:game)
      expect(next_state.state).to eq(:game)
    end
  end

  describe '#set' do
    it 'sets the next state' do
      next_state = described_class.new
      next_state.set(:paused)
      expect(next_state.state).to eq(:paused)
    end
  end

  describe '#clear' do
    it 'clears the pending state' do
      next_state = described_class.new(:game)
      next_state.clear
      expect(next_state.state).to be_nil
    end
  end

  describe '#pending?' do
    it 'returns true when state is set' do
      next_state = described_class.new(:game)
      expect(next_state.pending?).to be true
    end

    it 'returns false when state is nil' do
      next_state = described_class.new
      expect(next_state.pending?).to be false
    end
  end

  describe '#take' do
    it 'returns and clears the state' do
      next_state = described_class.new(:game)
      taken = next_state.take
      expect(taken).to eq(:game)
      expect(next_state.state).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns NextState' do
      next_state = described_class.new
      expect(next_state.type_name).to eq('NextState')
    end
  end
end

RSpec.describe Bevy::StateStack do
  describe '.new' do
    it 'creates empty stack by default' do
      stack = described_class.new
      expect(stack.empty?).to be true
    end

    it 'creates with initial state' do
      stack = described_class.new(:menu)
      expect(stack.current).to eq(:menu)
      expect(stack.size).to eq(1)
    end
  end

  describe '#push' do
    it 'adds state to stack' do
      stack = described_class.new(:menu)
      stack.push(:game)
      expect(stack.current).to eq(:game)
      expect(stack.size).to eq(2)
    end

    it 'calls on_push callbacks' do
      stack = described_class.new
      pushed = false
      stack.on_push(:game) { pushed = true }
      stack.push(:game)
      expect(pushed).to be true
    end
  end

  describe '#pop' do
    it 'removes and returns top state' do
      stack = described_class.new(:menu)
      stack.push(:game)
      popped = stack.pop
      expect(popped).to eq(:game)
      expect(stack.current).to eq(:menu)
    end

    it 'returns nil for empty stack' do
      stack = described_class.new
      expect(stack.pop).to be_nil
    end

    it 'calls on_pop callbacks' do
      stack = described_class.new(:menu)
      popped = false
      stack.on_pop(:menu) { popped = true }
      stack.pop
      expect(popped).to be true
    end
  end

  describe '#replace' do
    it 'replaces current state' do
      stack = described_class.new(:menu)
      stack.replace(:game)
      expect(stack.current).to eq(:game)
      expect(stack.size).to eq(1)
    end
  end

  describe '#clear' do
    it 'removes all states' do
      stack = described_class.new(:menu)
      stack.push(:game)
      stack.push(:paused)
      stack.clear
      expect(stack.empty?).to be true
    end
  end

  describe '#include?' do
    it 'returns true if state is in stack' do
      stack = described_class.new(:menu)
      stack.push(:game)
      expect(stack.include?(:menu)).to be true
      expect(stack.include?(:game)).to be true
      expect(stack.include?(:paused)).to be false
    end
  end

  describe '#type_name' do
    it 'returns StateStack' do
      stack = described_class.new
      expect(stack.type_name).to eq('StateStack')
    end
  end
end

RSpec.describe Bevy::StateMachine do
  describe '.new' do
    it 'creates empty state machine' do
      sm = described_class.new
      expect(sm.current_state).to be_nil
      expect(sm.states).to be_empty
    end
  end

  describe '#add_state' do
    it 'adds a state' do
      sm = described_class.new
      sm.add_state(:menu)
      expect(sm.states).to have_key(:menu)
    end

    it 'chains for fluent API' do
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
      expect(sm.states.keys).to contain_exactly(:menu, :game)
    end
  end

  describe '#add_transition' do
    it 'defines a transition' do
      sm = described_class.new
      sm.add_transition(:menu, :start, :game)
      expect(sm.transitions[:menu][:start]).to eq(:game)
    end
  end

  describe '#set_initial' do
    it 'sets the initial state' do
      sm = described_class.new
             .add_state(:menu)
             .set_initial(:menu)
      expect(sm.current_state).to eq(:menu)
    end
  end

  describe '#trigger' do
    it 'transitions via event' do
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
             .add_transition(:menu, :start, :game)
             .set_initial(:menu)
      expect(sm.trigger(:start)).to be true
      expect(sm.current_state).to eq(:game)
    end

    it 'returns false for unknown event' do
      sm = described_class.new
             .add_state(:menu)
             .set_initial(:menu)
      expect(sm.trigger(:unknown)).to be false
    end
  end

  describe '#transition_to' do
    it 'directly transitions to state' do
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
             .set_initial(:menu)
      expect(sm.transition_to(:game)).to be true
      expect(sm.current_state).to eq(:game)
    end

    it 'returns false for unknown state' do
      sm = described_class.new
             .add_state(:menu)
             .set_initial(:menu)
      expect(sm.transition_to(:unknown)).to be false
    end

    it 'returns false for same state' do
      sm = described_class.new
             .add_state(:menu)
             .set_initial(:menu)
      expect(sm.transition_to(:menu)).to be false
    end

    it 'calls exit and enter callbacks' do
      order = []
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
             .on_exit(:menu) { order << :exit_menu }
             .on_enter(:game) { order << :enter_game }
             .set_initial(:menu)
      sm.transition_to(:game)
      expect(order).to eq(%i[exit_menu enter_game])
    end
  end

  describe '#update' do
    it 'calls on_update callbacks for current state' do
      updated = false
      sm = described_class.new
             .add_state(:menu)
             .on_update(:menu) { updated = true }
             .set_initial(:menu)
      sm.update
      expect(updated).to be true
    end

    it 'passes context to update callback' do
      received = nil
      sm = described_class.new
             .add_state(:game)
             .on_update(:game) { |ctx| received = ctx }
             .set_initial(:game)
      sm.update('context_value')
      expect(received).to eq('context_value')
    end
  end

  describe '#can_trigger?' do
    it 'returns true for valid event' do
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
             .add_transition(:menu, :start, :game)
             .set_initial(:menu)
      expect(sm.can_trigger?(:start)).to be true
      expect(sm.can_trigger?(:unknown)).to be false
    end
  end

  describe '#available_events' do
    it 'returns list of available events' do
      sm = described_class.new
             .add_state(:menu)
             .add_state(:game)
             .add_state(:options)
             .add_transition(:menu, :start, :game)
             .add_transition(:menu, :options, :options)
             .set_initial(:menu)
      expect(sm.available_events).to contain_exactly(:start, :options)
    end

    it 'returns empty array when no state' do
      sm = described_class.new
      expect(sm.available_events).to eq([])
    end
  end

  describe '#is?' do
    it 'checks current state' do
      sm = described_class.new
             .add_state(:menu)
             .set_initial(:menu)
      expect(sm.is?(:menu)).to be true
      expect(sm.is?(:game)).to be false
    end
  end

  describe '#type_name' do
    it 'returns StateMachine' do
      sm = described_class.new
      expect(sm.type_name).to eq('StateMachine')
    end
  end
end

RSpec.describe 'State integration with App' do
  it 'can use State as a resource' do
    app = Bevy::App.new
    game_state = Bevy::State.new(:menu)
    app.insert_resource(game_state)

    expect(app.resources.get(Bevy::State)).to eq(game_state)
  end

  it 'can transition states during system execution' do
    entered_game = false
    exited_menu = false

    game_state = Bevy::State.new(:menu)
    game_state.on_exit(:menu) { exited_menu = true }
    game_state.on_enter(:game) { entered_game = true }

    app = Bevy::App.new
    app.insert_resource(game_state)

    app.add_startup_system do |ctx|
      state = ctx.resource(Bevy::State)
      state.set(:game)
    end

    app.add_update_system do |ctx|
      state = ctx.resource(Bevy::State)
      state.apply_transition(ctx)
    end

    app.run_once

    expect(game_state.current).to eq(:game)
    expect(entered_game).to be true
    expect(exited_menu).to be true
  end
end
