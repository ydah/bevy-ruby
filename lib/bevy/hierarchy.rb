# frozen_string_literal: true

module Bevy
  class Parent
    attr_reader :entity

    def initialize(entity)
      @entity = entity
    end

    def type_name
      'Parent'
    end
  end

  class Children
    attr_reader :entities

    def initialize(entities = [])
      @entities = entities.dup
    end

    def add(entity)
      @entities << entity unless @entities.include?(entity)
      self
    end

    def remove(entity)
      @entities.delete(entity)
      self
    end

    def include?(entity)
      @entities.include?(entity)
    end

    def count
      @entities.size
    end

    def empty?
      @entities.empty?
    end

    def each(&block)
      @entities.each(&block)
    end

    def type_name
      'Children'
    end
  end

  module BuildChildren
    def with_children(&block)
      builder = ChildBuilder.new(self)
      block.call(builder)
      self
    end

    def add_child(child_entity)
      children_component = get_component(Children) rescue nil
      if children_component
        children_component.add(child_entity)
      else
        insert_component(Children.new([child_entity]))
      end
      self
    end

    def remove_child(child_entity)
      children_component = get_component(Children) rescue nil
      children_component&.remove(child_entity)
      self
    end

    def set_parent(parent_entity)
      insert_component(Parent.new(parent_entity))
      self
    end

    def remove_parent
      remove_component(Parent)
      self
    end
  end

  class ChildBuilder
    attr_reader :parent_entity

    def initialize(parent_entity)
      @parent_entity = parent_entity
      @world = nil
    end

    def spawn(*components)
      entity = @world.spawn_entity(*components)
      entity.set_parent(@parent_entity)
      @parent_entity.add_child(entity)
      entity
    end

    def with_world(world)
      @world = world
      self
    end
  end

  class GlobalTransform
    attr_accessor :translation, :rotation, :scale

    def initialize(translation: Vec3.zero, rotation: Quat.identity, scale: Vec3.one)
      @translation = translation
      @rotation = rotation
      @scale = scale
    end

    def self.identity
      new
    end

    def self.from_transform(transform)
      new(
        translation: Vec3.new(transform.translation.x, transform.translation.y, transform.translation.z),
        rotation: transform.rotation,
        scale: Vec3.new(transform.scale.x, transform.scale.y, transform.scale.z)
      )
    end

    def to_matrix
      Mat4.from_scale_rotation_translation(@scale, @rotation, @translation)
    end

    def transform_point(point)
      rotated = @rotation.mul_vec3(Vec3.new(
        point.x * @scale.x,
        point.y * @scale.y,
        point.z * @scale.z
      ))
      Vec3.new(
        rotated.x + @translation.x,
        rotated.y + @translation.y,
        rotated.z + @translation.z
      )
    end

    def inverse_transform_point(point)
      translated = Vec3.new(
        point.x - @translation.x,
        point.y - @translation.y,
        point.z - @translation.z
      )
      inv_rotation = @rotation.inverse
      rotated = inv_rotation.mul_vec3(translated)
      Vec3.new(
        rotated.x / @scale.x,
        rotated.y / @scale.y,
        rotated.z / @scale.z
      )
    end

    def type_name
      'GlobalTransform'
    end
  end

  class TransformBundle
    attr_reader :local, :global

    def initialize(transform: Transform.identity)
      @local = transform
      @global = GlobalTransform.from_transform(transform)
    end

    def components
      [@local, @global]
    end

    def type_name
      'TransformBundle'
    end
  end

  class SpatialBundle
    attr_reader :visibility, :inherited_visibility, :view_visibility
    attr_reader :transform, :global_transform

    def initialize(
      transform: Transform.identity,
      visibility: Visibility.new
    )
      @transform = transform
      @global_transform = GlobalTransform.from_transform(transform)
      @visibility = visibility
      @inherited_visibility = InheritedVisibility.new
      @view_visibility = ViewVisibility.new
    end

    def components
      [@transform, @global_transform, @visibility, @inherited_visibility, @view_visibility]
    end

    def type_name
      'SpatialBundle'
    end
  end

  class Visibility
    INHERITED = :inherited
    VISIBLE = :visible
    HIDDEN = :hidden

    attr_accessor :value

    def initialize(value = INHERITED)
      @value = value
    end

    def visible?
      @value == VISIBLE
    end

    def hidden?
      @value == HIDDEN
    end

    def inherited?
      @value == INHERITED
    end

    def type_name
      'Visibility'
    end
  end

  class InheritedVisibility
    attr_reader :visible

    def initialize(visible = true)
      @visible = visible
    end

    def visible?
      @visible
    end

    def type_name
      'InheritedVisibility'
    end
  end

  class ViewVisibility
    attr_accessor :visible

    def initialize(visible = true)
      @visible = visible
    end

    def visible?
      @visible
    end

    def type_name
      'ViewVisibility'
    end
  end

  module HierarchyQueryExt
    def iter_descendants(entity, &block)
      children = get_component(entity, Children) rescue nil
      return unless children

      children.each do |child|
        block.call(child)
        iter_descendants(child, &block)
      end
    end

    def iter_ancestors(entity, &block)
      parent = get_component(entity, Parent) rescue nil
      return unless parent

      block.call(parent.entity)
      iter_ancestors(parent.entity, &block)
    end

    def root_ancestor(entity)
      current = entity
      loop do
        parent = get_component(current, Parent) rescue nil
        break current unless parent
        current = parent.entity
      end
    end

    def is_ancestor_of?(ancestor, descendant)
      current = descendant
      loop do
        parent = get_component(current, Parent) rescue nil
        return false unless parent
        return true if parent.entity == ancestor
        current = parent.entity
      end
    end

    def is_descendant_of?(descendant, ancestor)
      is_ancestor_of?(ancestor, descendant)
    end
  end

  class TransformPropagation
    def self.propagate(world)
      propagator = new(world)
      propagator.propagate_from_roots
    end

    def initialize(world)
      @world = world
      @processed = {}
    end

    def propagate_from_roots
      roots = find_roots
      roots.each do |root|
        propagate_recursive(root, GlobalTransform.identity)
      end
    end

    private

    def find_roots
      roots = []
      @world.each(Transform) do |entity, _transform|
        parent = @world.get_component(entity, Parent) rescue nil
        roots << entity unless parent
      end
      roots
    end

    def propagate_recursive(entity, parent_global)
      return if @processed[entity]
      @processed[entity] = true

      local_transform = @world.get_component(entity, Transform) rescue nil
      return unless local_transform

      global = compute_global_transform(parent_global, local_transform)

      begin
        @world.insert_component(entity, global)
      rescue StandardError
        # Entity may not support GlobalTransform
      end

      children = @world.get_component(entity, Children) rescue nil
      return unless children

      children.each do |child|
        propagate_recursive(child, global)
      end
    end

    def compute_global_transform(parent_global, local_transform)
      parent_scale = parent_global.scale
      parent_rotation = parent_global.rotation

      scaled_local = Vec3.new(
        local_transform.translation.x * parent_scale.x,
        local_transform.translation.y * parent_scale.y,
        local_transform.translation.z * parent_scale.z
      )

      rotated = parent_rotation.mul_vec3(scaled_local)

      GlobalTransform.new(
        translation: Vec3.new(
          parent_global.translation.x + rotated.x,
          parent_global.translation.y + rotated.y,
          parent_global.translation.z + rotated.z
        ),
        rotation: parent_rotation * local_transform.rotation,
        scale: Vec3.new(
          parent_global.scale.x * local_transform.scale.x,
          parent_global.scale.y * local_transform.scale.y,
          parent_global.scale.z * local_transform.scale.z
        )
      )
    end
  end

  class DespawnRecursive
    def self.despawn(world, entity)
      despawner = new(world)
      despawner.despawn_recursive(entity)
    end

    def initialize(world)
      @world = world
    end

    def despawn_recursive(entity)
      children = @world.get_component(entity, Children) rescue nil
      if children
        children.entities.dup.each do |child|
          despawn_recursive(child)
        end
      end

      parent = @world.get_component(entity, Parent) rescue nil
      if parent
        parent_children = @world.get_component(parent.entity, Children) rescue nil
        parent_children&.remove(entity)
      end

      @world.despawn(entity)
    end
  end

  class HierarchyEvent
    CHILD_ADDED = :child_added
    CHILD_REMOVED = :child_removed
    CHILD_MOVED = :child_moved

    attr_reader :event_type, :parent, :child

    def initialize(event_type, parent:, child:)
      @event_type = event_type
      @parent = parent
      @child = child
    end

    def child_added?
      @event_type == CHILD_ADDED
    end

    def child_removed?
      @event_type == CHILD_REMOVED
    end

    def child_moved?
      @event_type == CHILD_MOVED
    end
  end
end
