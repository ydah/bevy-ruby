# frozen_string_literal: true

module Bevy
  module RigidBodyType
    DYNAMIC = :dynamic
    STATIC = :static
    KINEMATIC = :kinematic
  end

  class RigidBody
    attr_accessor :body_type, :mass, :gravity_scale, :linear_damping, :angular_damping
    attr_accessor :linear_velocity, :angular_velocity
    attr_accessor :locked_axes, :can_sleep, :sleeping

    def initialize(
      body_type: RigidBodyType::DYNAMIC,
      mass: 1.0,
      gravity_scale: 1.0,
      linear_damping: 0.0,
      angular_damping: 0.0
    )
      @body_type = body_type
      @mass = mass.to_f
      @gravity_scale = gravity_scale.to_f
      @linear_damping = linear_damping.to_f
      @angular_damping = angular_damping.to_f
      @linear_velocity = Vec3.zero
      @angular_velocity = Vec3.zero
      @locked_axes = []
      @can_sleep = true
      @sleeping = false
    end

    def dynamic?
      @body_type == RigidBodyType::DYNAMIC
    end

    def static?
      @body_type == RigidBodyType::STATIC
    end

    def kinematic?
      @body_type == RigidBodyType::KINEMATIC
    end

    def apply_impulse(impulse)
      return unless dynamic?

      @linear_velocity = Vec3.new(
        @linear_velocity.x + impulse.x / @mass,
        @linear_velocity.y + impulse.y / @mass,
        @linear_velocity.z + impulse.z / @mass
      )
    end

    def apply_force(force, delta)
      return unless dynamic?

      acceleration = Vec3.new(
        force.x / @mass,
        force.y / @mass,
        force.z / @mass
      )
      @linear_velocity = Vec3.new(
        @linear_velocity.x + acceleration.x * delta,
        @linear_velocity.y + acceleration.y * delta,
        @linear_velocity.z + acceleration.z * delta
      )
    end

    def type_name
      'RigidBody'
    end

    def to_h
      {
        body_type: @body_type,
        mass: @mass,
        gravity_scale: @gravity_scale,
        linear_damping: @linear_damping,
        angular_damping: @angular_damping,
        linear_velocity: [@linear_velocity.x, @linear_velocity.y, @linear_velocity.z],
        angular_velocity: [@angular_velocity.x, @angular_velocity.y, @angular_velocity.z]
      }
    end
  end

  module ColliderShape
    BALL = :ball
    BOX = :box
    CAPSULE = :capsule
    CYLINDER = :cylinder
    CONVEX_HULL = :convex_hull
    TRIANGLE_MESH = :triangle_mesh
  end

  class Collider
    attr_accessor :shape, :size, :radius, :height, :friction, :restitution
    attr_accessor :sensor, :collision_groups

    def initialize(
      shape: ColliderShape::BOX,
      size: nil,
      radius: nil,
      height: nil,
      friction: 0.5,
      restitution: 0.0,
      sensor: false
    )
      @shape = shape
      @size = size || Vec3.new(1.0, 1.0, 1.0)
      @radius = radius || 0.5
      @height = height || 1.0
      @friction = friction.to_f
      @restitution = restitution.to_f
      @sensor = sensor
      @collision_groups = 0xFFFFFFFF
    end

    def self.ball(radius)
      new(shape: ColliderShape::BALL, radius: radius)
    end

    def self.box(half_extents)
      new(shape: ColliderShape::BOX, size: half_extents)
    end

    def self.capsule(radius, height)
      new(shape: ColliderShape::CAPSULE, radius: radius, height: height)
    end

    def self.cylinder(radius, height)
      new(shape: ColliderShape::CYLINDER, radius: radius, height: height)
    end

    def sensor?
      @sensor
    end

    def type_name
      'Collider'
    end

    def to_h
      {
        shape: @shape,
        size: [@size.x, @size.y, @size.z],
        radius: @radius,
        height: @height,
        friction: @friction,
        restitution: @restitution,
        sensor: @sensor
      }
    end
  end

  class CollisionEvent
    attr_reader :entity_a, :entity_b, :collision_type

    def initialize(entity_a, entity_b, collision_type = :started)
      @entity_a = entity_a
      @entity_b = entity_b
      @collision_type = collision_type
    end

    def started?
      @collision_type == :started
    end

    def stopped?
      @collision_type == :stopped
    end

    def type_name
      'CollisionEvent'
    end
  end

  class ContactPoint
    attr_reader :position, :normal, :depth

    def initialize(position:, normal:, depth: 0.0)
      @position = position
      @normal = normal
      @depth = depth.to_f
    end

    def type_name
      'ContactPoint'
    end
  end

  class Collision
    attr_reader :entity_a, :entity_b, :contacts

    def initialize(entity_a, entity_b, contacts = [])
      @entity_a = entity_a
      @entity_b = entity_b
      @contacts = contacts
    end

    def type_name
      'Collision'
    end
  end

  class Velocity
    attr_accessor :linear, :angular

    def initialize(linear: nil, angular: nil)
      @linear = linear || Vec3.zero
      @angular = angular || Vec3.zero
    end

    def type_name
      'Velocity'
    end

    def to_h
      {
        linear: [@linear.x, @linear.y, @linear.z],
        angular: [@angular.x, @angular.y, @angular.z]
      }
    end
  end

  class ExternalForce
    attr_accessor :force, :torque

    def initialize(force: nil, torque: nil)
      @force = force || Vec3.zero
      @torque = torque || Vec3.zero
    end

    def apply(force_vec)
      @force = Vec3.new(
        @force.x + force_vec.x,
        @force.y + force_vec.y,
        @force.z + force_vec.z
      )
    end

    def apply_torque(torque_vec)
      @torque = Vec3.new(
        @torque.x + torque_vec.x,
        @torque.y + torque_vec.y,
        @torque.z + torque_vec.z
      )
    end

    def clear
      @force = Vec3.zero
      @torque = Vec3.zero
    end

    def type_name
      'ExternalForce'
    end
  end

  class ExternalImpulse
    attr_accessor :impulse, :torque_impulse

    def initialize(impulse: nil, torque_impulse: nil)
      @impulse = impulse || Vec3.zero
      @torque_impulse = torque_impulse || Vec3.zero
    end

    def apply(impulse_vec)
      @impulse = Vec3.new(
        @impulse.x + impulse_vec.x,
        @impulse.y + impulse_vec.y,
        @impulse.z + impulse_vec.z
      )
    end

    def clear
      @impulse = Vec3.zero
      @torque_impulse = Vec3.zero
    end

    def type_name
      'ExternalImpulse'
    end
  end

  class GravityScale
    attr_accessor :scale

    def initialize(scale = 1.0)
      @scale = scale.to_f
    end

    def type_name
      'GravityScale'
    end
  end

  class LockedAxes
    attr_accessor :translation_locked, :rotation_locked

    def initialize(translation_locked: [], rotation_locked: [])
      @translation_locked = translation_locked
      @rotation_locked = rotation_locked
    end

    def lock_translation_x
      @translation_locked << :x unless @translation_locked.include?(:x)
      self
    end

    def lock_translation_y
      @translation_locked << :y unless @translation_locked.include?(:y)
      self
    end

    def lock_translation_z
      @translation_locked << :z unless @translation_locked.include?(:z)
      self
    end

    def lock_rotation_x
      @rotation_locked << :x unless @rotation_locked.include?(:x)
      self
    end

    def lock_rotation_y
      @rotation_locked << :y unless @rotation_locked.include?(:y)
      self
    end

    def lock_rotation_z
      @rotation_locked << :z unless @rotation_locked.include?(:z)
      self
    end

    def type_name
      'LockedAxes'
    end
  end

  class PhysicsWorld
    attr_accessor :gravity, :timestep

    def initialize(gravity: nil, timestep: 1.0 / 60.0)
      @gravity = gravity || Vec3.new(0.0, -9.81, 0.0)
      @timestep = timestep.to_f
      @collisions = []
    end

    def add_collision(collision)
      @collisions << collision
    end

    def collisions
      @collisions.dup
    end

    def clear_collisions
      @collisions.clear
    end

    def type_name
      'PhysicsWorld'
    end
  end

  class RayCast
    attr_reader :origin, :direction, :max_distance

    def initialize(origin:, direction:, max_distance: Float::INFINITY)
      @origin = origin
      @direction = direction.normalize
      @max_distance = max_distance
    end

    def type_name
      'RayCast'
    end
  end

  class RayCastHit
    attr_reader :entity, :point, :normal, :distance

    def initialize(entity:, point:, normal:, distance:)
      @entity = entity
      @point = point
      @normal = normal
      @distance = distance.to_f
    end

    def type_name
      'RayCastHit'
    end
  end
end
