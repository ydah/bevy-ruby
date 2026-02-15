# frozen_string_literal: true

# Practical Example: RPG Inventory System
# A visual inventory system with items, equipment slots, and interaction.
# Click on items to select, press 1-4 to add items, E to equip selected.

require 'bevy'

module ItemRarity
  COMMON = 'common'
  UNCOMMON = 'uncommon'
  RARE = 'rare'
  EPIC = 'epic'
  LEGENDARY = 'legendary'

  def self.color(rarity)
    case rarity
    when COMMON then '#CCCCCC'
    when UNCOMMON then '#1EFF00'
    when RARE then '#0070DD'
    when EPIC then '#A335EE'
    when LEGENDARY then '#FF8000'
    else '#CCCCCC'
    end
  end
end

module ItemType
  WEAPON = 'weapon'
  ARMOR = 'armor'
  CONSUMABLE = 'consumable'
  MATERIAL = 'material'
end

class ItemData
  attr_reader :id, :name, :type, :rarity, :stats, :icon_color

  def initialize(id:, name:, type:, rarity: ItemRarity::COMMON, stats: {}, icon_color: nil)
    @id = id
    @name = name
    @type = type
    @rarity = rarity
    @stats = stats
    @icon_color = icon_color || ItemRarity.color(rarity)
  end
end

class InventorySlot < Bevy::ComponentDSL
  attribute :index, Integer, default: 0
  attribute :item_id, String, default: nil
  attribute :quantity, Integer, default: 0
  attribute :selected, :boolean, default: false
end

class EquipmentSlot < Bevy::ComponentDSL
  attribute :slot_type, String, default: 'weapon'
  attribute :item_id, String, default: nil
end

class ItemIcon < Bevy::ComponentDSL
  attribute :slot_index, Integer, default: -1
end

class InventoryState < Bevy::ResourceDSL
  attribute :selected_slot, Integer, default: -1
  attribute :gold, Integer, default: 100
end

class ItemDatabase
  def initialize
    @items = {}
    register_items
  end

  def register_items
    register(ItemData.new(
               id: 'iron_sword',
               name: 'Iron Sword',
               type: ItemType::WEAPON,
               rarity: ItemRarity::COMMON,
               stats: { attack: 10 },
               icon_color: '#A0A0A0'
             ))

    register(ItemData.new(
               id: 'flame_blade',
               name: 'Flame Blade',
               type: ItemType::WEAPON,
               rarity: ItemRarity::RARE,
               stats: { attack: 25, fire: 10 },
               icon_color: '#FF6B35'
             ))

    register(ItemData.new(
               id: 'health_potion',
               name: 'Health Potion',
               type: ItemType::CONSUMABLE,
               rarity: ItemRarity::COMMON,
               stats: { heal: 50 },
               icon_color: '#E74C3C'
             ))

    register(ItemData.new(
               id: 'mana_potion',
               name: 'Mana Potion',
               type: ItemType::CONSUMABLE,
               rarity: ItemRarity::COMMON,
               stats: { mana: 30 },
               icon_color: '#3498DB'
             ))

    register(ItemData.new(
               id: 'leather_armor',
               name: 'Leather Armor',
               type: ItemType::ARMOR,
               rarity: ItemRarity::COMMON,
               stats: { defense: 5 },
               icon_color: '#8B4513'
             ))

    register(ItemData.new(
               id: 'dragon_scale',
               name: 'Dragon Scale',
               type: ItemType::ARMOR,
               rarity: ItemRarity::EPIC,
               stats: { defense: 30, fire_resist: 20 },
               icon_color: '#9B59B6'
             ))

    register(ItemData.new(
               id: 'gold_ore',
               name: 'Gold Ore',
               type: ItemType::MATERIAL,
               rarity: ItemRarity::UNCOMMON,
               icon_color: '#F1C40F'
             ))

    register(ItemData.new(
               id: 'legendary_staff',
               name: 'Staff of Ages',
               type: ItemType::WEAPON,
               rarity: ItemRarity::LEGENDARY,
               stats: { magic: 50, mana: 100 },
               icon_color: '#FF8000'
             ))
  end

  def register(item)
    @items[item.id] = item
  end

  def get(id)
    @items[id]
  end

  def all
    @items.values
  end
end

ITEM_DB = ItemDatabase.new

SLOT_SIZE = 50.0
SLOT_PADDING = 5.0
GRID_COLS = 5
GRID_ROWS = 4
INVENTORY_START_X = -200.0
INVENTORY_START_Y = 100.0

def slot_position(index)
  col = index % GRID_COLS
  row = index / GRID_COLS
  x = INVENTORY_START_X + col * (SLOT_SIZE + SLOT_PADDING)
  y = INVENTORY_START_Y - row * (SLOT_SIZE + SLOT_PADDING)
  [x, y]
end

def add_item_to_inventory(ctx, item_id)
  ctx.world.each(InventorySlot) do |entity, slot|
    next unless slot.item_id.nil?

    slot.item_id = item_id
    slot.quantity = 1
    ctx.world.insert_component(entity, slot)

    item = ITEM_DB.get(item_id)
    x, y = slot_position(slot.index)
    ctx.spawn(
      ItemIcon.new(slot_index: slot.index),
      Bevy::Transform.from_xyz(x, y, 1.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(item.icon_color),
        custom_size: Bevy::Vec2.new(SLOT_SIZE - 10, SLOT_SIZE - 10)
      )
    )
    return true
  end
  false
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Inventory System - 1-4: Add items, Click: Select, E: Equip',
    width: 800.0,
    height: 600.0
  }
)

app.insert_resource(InventoryState.new)

app.add_startup_system do |ctx|
  (GRID_COLS * GRID_ROWS).times do |i|
    x, y = slot_position(i)
    ctx.spawn(
      InventorySlot.new(index: i),
      Bevy::Transform.from_xyz(x, y, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#2C3E50'),
        custom_size: Bevy::Vec2.new(SLOT_SIZE, SLOT_SIZE)
      )
    )
  end

  equipment_slots = [
    { type: 'weapon', x: 200.0, y: 150.0, label: 'Weapon' },
    { type: 'armor', x: 200.0, y: 80.0, label: 'Armor' },
    { type: 'accessory', x: 200.0, y: 10.0, label: 'Accessory' }
  ]

  equipment_slots.each do |es|
    ctx.spawn(
      EquipmentSlot.new(slot_type: es[:type]),
      Bevy::Transform.from_xyz(es[:x], es[:y], 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex('#34495E'),
        custom_size: Bevy::Vec2.new(60.0, 60.0)
      )
    )
  end

  add_item_to_inventory(ctx, 'iron_sword')
  add_item_to_inventory(ctx, 'leather_armor')
  add_item_to_inventory(ctx, 'health_potion')
end

app.add_update_system do |ctx|
  add_item_to_inventory(ctx, 'health_potion') if ctx.key_just_pressed?('1')
  add_item_to_inventory(ctx, 'mana_potion') if ctx.key_just_pressed?('2')
  add_item_to_inventory(ctx, 'flame_blade') if ctx.key_just_pressed?('3')
  add_item_to_inventory(ctx, 'dragon_scale') if ctx.key_just_pressed?('4')
  add_item_to_inventory(ctx, 'legendary_staff') if ctx.key_just_pressed?('5')
  add_item_to_inventory(ctx, 'gold_ore') if ctx.key_just_pressed?('6')
end

app.add_update_system do |ctx|
  state = ctx.resource(InventoryState)

  if ctx.mouse_just_pressed?('LEFT')
    mouse_pos = ctx.mouse_position

    ctx.world.each(InventorySlot, Bevy::Transform) do |entity, slot, transform|
      dx = (mouse_pos.x - transform.translation.x).abs
      dy = (mouse_pos.y - transform.translation.y).abs

      next unless dx < SLOT_SIZE / 2 && dy < SLOT_SIZE / 2

      old_selected = state.selected_slot
      state.selected_slot = slot.index

      if old_selected >= 0
        ctx.world.each(InventorySlot) do |e, s|
          next unless s.index == old_selected

          s.selected = false
          ctx.world.insert_component(e, s)
          ctx.world.insert_component(e, Bevy::Sprite.new(
                                          color: Bevy::Color.from_hex('#2C3E50'),
                                          custom_size: Bevy::Vec2.new(SLOT_SIZE, SLOT_SIZE)
                                        ))
        end
      end

      slot.selected = true
      ctx.world.insert_component(entity, slot)
      ctx.world.insert_component(entity, Bevy::Sprite.new(
                                           color: Bevy::Color.from_hex('#F39C12'),
                                           custom_size: Bevy::Vec2.new(SLOT_SIZE, SLOT_SIZE)
                                         ))
      break
    end
  end
end

app.add_update_system do |ctx|
  state = ctx.resource(InventoryState)

  if ctx.key_just_pressed?('E') && state.selected_slot >= 0
    selected_item_id = nil
    selected_item_type = nil

    ctx.world.each(InventorySlot) do |_entity, slot|
      next unless slot.index == state.selected_slot && slot.item_id

      item = ITEM_DB.get(slot.item_id)
      if item && [ItemType::WEAPON, ItemType::ARMOR].include?(item.type)
        selected_item_id = slot.item_id
        selected_item_type = item.type == ItemType::WEAPON ? 'weapon' : 'armor'
      end
    end

    if selected_item_id
      ctx.world.each(EquipmentSlot, Bevy::Transform) do |entity, eq_slot, transform|
        next unless eq_slot.slot_type == selected_item_type

        eq_slot.item_id = selected_item_id
        ctx.world.insert_component(entity, eq_slot)

        item = ITEM_DB.get(selected_item_id)
        ctx.spawn(
          Bevy::Transform.from_xyz(transform.translation.x, transform.translation.y, 1.0),
          Bevy::Sprite.new(
            color: Bevy::Color.from_hex(item.icon_color),
            custom_size: Bevy::Vec2.new(50.0, 50.0)
          )
        )
        break
      end
    end
  end
end

app.add_update_system do |ctx|
  ctx.app.stop if ctx.key_pressed?('ESCAPE')
end

puts 'Inventory System Demo'
puts 'Controls:'
puts '  1 - Add Health Potion'
puts '  2 - Add Mana Potion'
puts '  3 - Add Flame Blade (Rare)'
puts '  4 - Add Dragon Scale (Epic)'
puts '  5 - Add Staff of Ages (Legendary)'
puts '  6 - Add Gold Ore'
puts '  Click - Select slot'
puts '  E - Equip selected item'
puts '  ESC - Exit'
app.run
