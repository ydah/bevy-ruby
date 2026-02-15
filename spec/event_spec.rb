# frozen_string_literal: true

class CollisionEvent < Bevy::EventDSL
  attribute :entity_a, :entity, default: nil
  attribute :entity_b, :entity, default: nil
  attribute :point_x, :float, default: 0.0
  attribute :point_y, :float, default: 0.0
end

class DamageEvent < Bevy::EventDSL
  attribute :target, :entity, default: nil
  attribute :amount, :integer, default: 0
  attribute :source, :string, default: 'unknown'
end

RSpec.describe Bevy::EventDSL do
  describe '.attribute' do
    it 'defines getters and setters' do
      event = CollisionEvent.new
      expect(event).to respond_to(:entity_a)
      expect(event).to respond_to(:entity_a=)
    end
  end

  describe '.new' do
    it 'creates an event with default values' do
      event = CollisionEvent.new
      expect(event.entity_a).to be_nil
      expect(event.point_x).to eq(0.0)
    end

    it 'creates an event with custom values' do
      event = DamageEvent.new(amount: 50, source: 'fireball')
      expect(event.amount).to eq(50)
      expect(event.source).to eq('fireball')
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      event = DamageEvent.new(amount: 25)
      h = event.to_h
      expect(h[:amount]).to eq(25)
      expect(h[:source]).to eq('unknown')
    end
  end

  describe '.event_name' do
    it 'returns the class name' do
      expect(CollisionEvent.event_name).to eq('CollisionEvent')
    end
  end
end

RSpec.describe Bevy::Events do
  let(:events) { described_class.new(CollisionEvent) }

  describe '#send' do
    it 'adds an event' do
      event = CollisionEvent.new(point_x: 10.0)
      events.send(event)
      expect(events.read.length).to eq(1)
    end

    it 'raises error for wrong event type' do
      event = DamageEvent.new
      expect { events.send(event) }.to raise_error(ArgumentError)
    end
  end

  describe '#read' do
    it 'returns all events including last frame' do
      events.send(CollisionEvent.new(point_x: 1.0))
      events.update
      events.send(CollisionEvent.new(point_x: 2.0))

      all = events.read
      expect(all.length).to eq(2)
    end
  end

  describe '#drain' do
    it 'returns and clears current events' do
      events.send(CollisionEvent.new)
      events.send(CollisionEvent.new)

      drained = events.drain
      expect(drained.length).to eq(2)
      expect(events.read.length).to eq(0)
    end
  end

  describe '#update' do
    it 'moves current events to last frame buffer' do
      events.send(CollisionEvent.new)
      events.update

      expect(events.read.length).to eq(1)
      events.update
      expect(events.read.length).to eq(0)
    end
  end

  describe '#empty?' do
    it 'checks if events are empty' do
      expect(events.empty?).to be true
      events.send(CollisionEvent.new)
      expect(events.empty?).to be false
    end
  end

  describe '#len' do
    it 'returns total event count' do
      events.send(CollisionEvent.new)
      events.update
      events.send(CollisionEvent.new)
      expect(events.len).to eq(2)
    end
  end
end

RSpec.describe Bevy::EventReader do
  let(:events) { Bevy::Events.new(CollisionEvent) }
  let(:reader) { described_class.new(events) }

  describe '#read' do
    it 'returns new events since last read' do
      events.send(CollisionEvent.new(point_x: 1.0))
      events.send(CollisionEvent.new(point_x: 2.0))

      read1 = reader.read
      expect(read1.length).to eq(2)

      events.send(CollisionEvent.new(point_x: 3.0))
      read2 = reader.read
      expect(read2.length).to eq(1)
      expect(read2.first.point_x).to eq(3.0)
    end
  end

  describe '#is_empty?' do
    it 'checks if there are unread events' do
      expect(reader.is_empty?).to be true

      events.send(CollisionEvent.new)
      expect(reader.is_empty?).to be false

      reader.read
      expect(reader.is_empty?).to be true
    end
  end

  describe '#len' do
    it 'returns count of unread events' do
      events.send(CollisionEvent.new)
      events.send(CollisionEvent.new)
      expect(reader.len).to eq(2)

      reader.read
      expect(reader.len).to eq(0)
    end
  end

  describe '#clear' do
    it 'marks all current events as read' do
      events.send(CollisionEvent.new)
      events.send(CollisionEvent.new)

      reader.clear
      expect(reader.len).to eq(0)
    end
  end
end

RSpec.describe Bevy::EventWriter do
  let(:events) { Bevy::Events.new(DamageEvent) }
  let(:writer) { described_class.new(events) }

  describe '#send' do
    it 'sends an event' do
      writer.send(DamageEvent.new(amount: 10))
      expect(events.read.length).to eq(1)
    end
  end

  describe '#send_batch' do
    it 'sends multiple events' do
      batch = [
        DamageEvent.new(amount: 10),
        DamageEvent.new(amount: 20),
        DamageEvent.new(amount: 30)
      ]
      writer.send_batch(batch)
      expect(events.read.length).to eq(3)
    end
  end

  describe '#send_default' do
    it 'sends a default event' do
      writer.send_default
      expect(events.read.length).to eq(1)
      expect(events.read.first.amount).to eq(0)
    end
  end
end

RSpec.describe Bevy::EventRegistry do
  let(:registry) { described_class.new }

  describe '#register' do
    it 'registers an event type' do
      registry.register(CollisionEvent)
      expect(registry.get_events(CollisionEvent)).not_to be_nil
    end
  end

  describe '#reader' do
    it 'returns an event reader' do
      registry.register(CollisionEvent)
      reader = registry.reader(CollisionEvent)
      expect(reader).to be_a(Bevy::EventReader)
    end

    it 'returns nil for unregistered event' do
      expect(registry.reader(CollisionEvent)).to be_nil
    end
  end

  describe '#writer' do
    it 'returns an event writer' do
      registry.register(DamageEvent)
      writer = registry.writer(DamageEvent)
      expect(writer).to be_a(Bevy::EventWriter)
    end
  end

  describe '#update_all' do
    it 'updates all event buffers' do
      registry.register(CollisionEvent)
      registry.register(DamageEvent)

      registry.writer(CollisionEvent).send(CollisionEvent.new)
      registry.writer(DamageEvent).send(DamageEvent.new)

      registry.update_all

      expect(registry.get_events(CollisionEvent).read.length).to eq(1)
      registry.update_all
      expect(registry.get_events(CollisionEvent).read.length).to eq(0)
    end
  end

  describe '#clear_all' do
    it 'clears all events' do
      registry.register(CollisionEvent)
      registry.writer(CollisionEvent).send(CollisionEvent.new)

      registry.clear_all
      expect(registry.get_events(CollisionEvent).empty?).to be true
    end
  end
end
