# frozen_string_literal: true

RSpec.describe Bevy::RigidBodyType do
  it 'defines body types' do
    expect(described_class::DYNAMIC).to eq(:dynamic)
    expect(described_class::STATIC).to eq(:static)
    expect(described_class::KINEMATIC).to eq(:kinematic)
  end
end

RSpec.describe Bevy::RigidBody do
  describe '.new' do
    it 'creates with default values' do
      body = described_class.new
      expect(body.body_type).to eq(Bevy::RigidBodyType::DYNAMIC)
      expect(body.mass).to eq(1.0)
      expect(body.gravity_scale).to eq(1.0)
    end

    it 'creates with custom values' do
      body = described_class.new(body_type: Bevy::RigidBodyType::STATIC, mass: 5.0)
      expect(body.body_type).to eq(Bevy::RigidBodyType::STATIC)
      expect(body.mass).to eq(5.0)
    end
  end

  describe '#dynamic?' do
    it 'returns true for dynamic bodies' do
      body = described_class.new(body_type: Bevy::RigidBodyType::DYNAMIC)
      expect(body.dynamic?).to be true
    end

    it 'returns false for static bodies' do
      body = described_class.new(body_type: Bevy::RigidBodyType::STATIC)
      expect(body.dynamic?).to be false
    end
  end

  describe '#static?' do
    it 'returns true for static bodies' do
      body = described_class.new(body_type: Bevy::RigidBodyType::STATIC)
      expect(body.static?).to be true
    end
  end

  describe '#apply_impulse' do
    it 'changes velocity for dynamic bodies' do
      body = described_class.new(mass: 2.0)
      body.apply_impulse(Bevy::Vec3.new(4.0, 0.0, 0.0))
      expect(body.linear_velocity.x).to eq(2.0)
    end

    it 'does nothing for static bodies' do
      body = described_class.new(body_type: Bevy::RigidBodyType::STATIC)
      body.apply_impulse(Bevy::Vec3.new(10.0, 0.0, 0.0))
      expect(body.linear_velocity.x).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns RigidBody' do
      expect(described_class.new.type_name).to eq('RigidBody')
    end
  end
end

RSpec.describe Bevy::Collider do
  describe '.new' do
    it 'creates with default values' do
      collider = described_class.new
      expect(collider.shape).to eq(Bevy::ColliderShape::BOX)
      expect(collider.friction).to eq(0.5)
      expect(collider.restitution).to eq(0.0)
    end
  end

  describe '.ball' do
    it 'creates ball collider' do
      collider = described_class.ball(5.0)
      expect(collider.shape).to eq(Bevy::ColliderShape::BALL)
      expect(collider.radius).to eq(5.0)
    end
  end

  describe '.box' do
    it 'creates box collider' do
      collider = described_class.box(Bevy::Vec3.new(2.0, 3.0, 4.0))
      expect(collider.shape).to eq(Bevy::ColliderShape::BOX)
      expect(collider.size.x).to eq(2.0)
    end
  end

  describe '.capsule' do
    it 'creates capsule collider' do
      collider = described_class.capsule(1.0, 2.0)
      expect(collider.shape).to eq(Bevy::ColliderShape::CAPSULE)
      expect(collider.radius).to eq(1.0)
      expect(collider.height).to eq(2.0)
    end
  end

  describe '#sensor?' do
    it 'returns sensor status' do
      sensor_collider = described_class.new(sensor: true)
      expect(sensor_collider.sensor?).to be true

      normal_collider = described_class.new
      expect(normal_collider.sensor?).to be false
    end
  end

  describe '#type_name' do
    it 'returns Collider' do
      expect(described_class.new.type_name).to eq('Collider')
    end
  end
end

RSpec.describe Bevy::CollisionEvent do
  describe '.new' do
    it 'creates collision event' do
      entity_a = double('entity_a')
      entity_b = double('entity_b')
      event = described_class.new(entity_a, entity_b, :started)

      expect(event.entity_a).to eq(entity_a)
      expect(event.entity_b).to eq(entity_b)
      expect(event.started?).to be true
    end
  end

  describe '#started?' do
    it 'returns true for started events' do
      event = described_class.new(nil, nil, :started)
      expect(event.started?).to be true
      expect(event.stopped?).to be false
    end
  end

  describe '#stopped?' do
    it 'returns true for stopped events' do
      event = described_class.new(nil, nil, :stopped)
      expect(event.stopped?).to be true
      expect(event.started?).to be false
    end
  end
end

RSpec.describe Bevy::Velocity do
  describe '.new' do
    it 'creates with default zero values' do
      vel = described_class.new
      expect(vel.linear.x).to eq(0.0)
      expect(vel.angular.x).to eq(0.0)
    end

    it 'creates with custom values' do
      vel = described_class.new(linear: Bevy::Vec3.new(1.0, 2.0, 3.0))
      expect(vel.linear.x).to eq(1.0)
    end
  end

  describe '#type_name' do
    it 'returns Velocity' do
      expect(described_class.new.type_name).to eq('Velocity')
    end
  end
end

RSpec.describe Bevy::ExternalForce do
  describe '.new' do
    it 'creates with zero force' do
      ef = described_class.new
      expect(ef.force.x).to eq(0.0)
    end
  end

  describe '#apply' do
    it 'adds to force' do
      ef = described_class.new
      ef.apply(Bevy::Vec3.new(10.0, 0.0, 0.0))
      expect(ef.force.x).to eq(10.0)
      ef.apply(Bevy::Vec3.new(5.0, 0.0, 0.0))
      expect(ef.force.x).to eq(15.0)
    end
  end

  describe '#clear' do
    it 'resets force to zero' do
      ef = described_class.new(force: Bevy::Vec3.new(10.0, 10.0, 10.0))
      ef.clear
      expect(ef.force.x).to eq(0.0)
    end
  end
end

RSpec.describe Bevy::PhysicsWorld do
  describe '.new' do
    it 'creates with default gravity' do
      world = described_class.new
      expect(world.gravity.y).to be_within(0.01).of(-9.81)
    end

    it 'creates with custom gravity' do
      world = described_class.new(gravity: Bevy::Vec3.new(0.0, -20.0, 0.0))
      expect(world.gravity.y).to eq(-20.0)
    end
  end

  describe '#add_collision' do
    it 'stores collisions' do
      world = described_class.new
      collision = Bevy::Collision.new(nil, nil)
      world.add_collision(collision)
      expect(world.collisions.size).to eq(1)
    end
  end

  describe '#clear_collisions' do
    it 'removes all collisions' do
      world = described_class.new
      world.add_collision(Bevy::Collision.new(nil, nil))
      world.clear_collisions
      expect(world.collisions).to be_empty
    end
  end
end

RSpec.describe Bevy::RayCast do
  describe '.new' do
    it 'creates raycast' do
      ray = described_class.new(
        origin: Bevy::Vec3.new(0.0, 0.0, 0.0),
        direction: Bevy::Vec3.new(1.0, 0.0, 0.0),
        max_distance: 100.0
      )
      expect(ray.origin.x).to eq(0.0)
      expect(ray.max_distance).to eq(100.0)
    end
  end

  describe '#type_name' do
    it 'returns RayCast' do
      ray = described_class.new(origin: Bevy::Vec3.zero, direction: Bevy::Vec3.new(1.0, 0.0, 0.0))
      expect(ray.type_name).to eq('RayCast')
    end
  end
end
