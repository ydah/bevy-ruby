# frozen_string_literal: true

# Game Menu Example
# Demonstrates a simple game menu system with state management.
# Navigate with UP/DOWN arrows, select with ENTER/SPACE.

require 'bevy'

module GameState
  MENU = :menu
  PLAYING = :playing
  PAUSED = :paused
  GAME_OVER = :game_over
end

class MenuState < Bevy::ResourceDSL
  attribute :current_state, Symbol, default: GameState::MENU
  attribute :selected_index, Integer, default: 0
  attribute :menu_items, Array, default: []
end

class MenuItem < Bevy::ComponentDSL
  attribute :index, Integer, default: 0
  attribute :label, String, default: ''
  attribute :action, Symbol, default: :none
end

class GameData < Bevy::ComponentDSL
  attribute :score, Integer, default: 0
  attribute :player_y, Float, default: 0.0
  attribute :target_y, Float, default: 100.0
end

class Player < Bevy::ComponentDSL
end

class Target < Bevy::ComponentDSL
end

class ScoreDisplay < Bevy::ComponentDSL
end

MENU_ITEMS = [
  { label: 'Start Game', action: :start },
  { label: 'Options', action: :options },
  { label: 'Credits', action: :credits },
  { label: 'Quit', action: :quit }
].freeze

MENU_Y_START = 100.0
MENU_Y_SPACING = 60.0

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Game Menu - UP/DOWN to navigate, ENTER to select',
    width: 800.0,
    height: 600.0
  }
)

app.insert_resource(MenuState.new(
                      current_state: GameState::MENU,
                      selected_index: 0,
                      menu_items: MENU_ITEMS.map { |m| m[:label] }
                    ))

def spawn_menu(ctx)
  ctx.spawn(
    Bevy::Transform.from_xyz(0.0, 220.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#3498DB'),
      custom_size: Bevy::Vec2.new(300.0, 60.0)
    )
  )

  MENU_ITEMS.each_with_index do |item, index|
    y = MENU_Y_START - index * MENU_Y_SPACING
    color = index.zero? ? '#F39C12' : '#ECF0F1'

    ctx.spawn(
      MenuItem.new(index: index, label: item[:label], action: item[:action]),
      Bevy::Transform.from_xyz(0.0, y, 0.0),
      Bevy::Sprite.new(
        color: Bevy::Color.from_hex(color),
        custom_size: Bevy::Vec2.new(200.0, 40.0)
      )
    )
  end
end

def spawn_game_elements(ctx)
  ctx.spawn(
    Player.new,
    Bevy::Transform.from_xyz(0.0, -200.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#2ECC71'),
      custom_size: Bevy::Vec2.new(50.0, 50.0)
    )
  )

  target_x = rand(-300.0..300.0)
  target_y = rand(-100.0..200.0)

  ctx.spawn(
    Target.new,
    Bevy::Transform.from_xyz(target_x, target_y, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#E74C3C'),
      custom_size: Bevy::Vec2.new(30.0, 30.0)
    )
  )

  ctx.spawn(
    ScoreDisplay.new,
    GameData.new(score: 0),
    Bevy::Transform.from_xyz(0.0, 250.0, 0.0),
    Bevy::Sprite.new(
      color: Bevy::Color.from_hex('#9B59B6'),
      custom_size: Bevy::Vec2.new(100.0, 30.0)
    )
  )
end

def clear_all_entities(ctx)
  entities_to_remove = []

  ctx.world.each(MenuItem) do |entity, _|
    entities_to_remove << entity
  end

  ctx.world.each(Player) do |entity, _|
    entities_to_remove << entity
  end

  ctx.world.each(Target) do |entity, _|
    entities_to_remove << entity
  end

  ctx.world.each(ScoreDisplay) do |entity, _|
    entities_to_remove << entity
  end

  entities_to_remove.each { |e| ctx.world.despawn(e) }
end

app.add_startup_system do |ctx|
  spawn_menu(ctx)
end

app.add_update_system do |ctx|
  state = ctx.resource(MenuState)
  next unless state.current_state == GameState::MENU

  state.selected_index = (state.selected_index - 1) % MENU_ITEMS.length if ctx.key_just_pressed?('UP')

  state.selected_index = (state.selected_index + 1) % MENU_ITEMS.length if ctx.key_just_pressed?('DOWN')

  if ctx.key_just_pressed?('ENTER') || ctx.key_just_pressed?('SPACE')
    action = MENU_ITEMS[state.selected_index][:action]

    case action
    when :start
      clear_all_entities(ctx)
      spawn_game_elements(ctx)
      state.current_state = GameState::PLAYING
    when :quit
      ctx.app.stop
    when :options, :credits
      # Flash the selected item to indicate "not implemented"
    end
  end

  ctx.world.each(MenuItem, Bevy::Sprite) do |entity, menu_item, sprite|
    color = if menu_item.index == state.selected_index
              pulse = 0.8 + Math.sin(ctx.elapsed * 5.0) * 0.2
              Bevy::Color.rgba(0.95 * pulse, 0.61 * pulse, 0.07, 1.0)
            else
              Bevy::Color.from_hex('#7F8C8D')
            end

    ctx.world.insert_component(entity, sprite.with_color(color))
  end
end

app.add_update_system do |ctx|
  state = ctx.resource(MenuState)
  next unless state.current_state == GameState::PLAYING

  state.current_state = GameState::PAUSED if ctx.key_just_pressed?('ESCAPE') || ctx.key_just_pressed?('P')

  speed = 300.0
  delta = ctx.delta

  ctx.world.each(Player, Bevy::Transform) do |entity, _, transform|
    dx = 0.0
    dy = 0.0

    dx -= speed * delta if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')
    dx += speed * delta if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')
    dy += speed * delta if ctx.key_pressed?('W') || ctx.key_pressed?('UP')
    dy -= speed * delta if ctx.key_pressed?('S') || ctx.key_pressed?('DOWN')

    new_x = (transform.translation.x + dx).clamp(-350.0, 350.0)
    new_y = (transform.translation.y + dy).clamp(-250.0, 250.0)

    new_pos = Bevy::Vec3.new(new_x, new_y, 0.0)
    ctx.world.insert_component(entity, transform.with_translation(new_pos))
  end

  player_pos = nil
  target_pos = nil
  target_entity = nil

  ctx.world.each(Player, Bevy::Transform) do |_, _, transform|
    player_pos = transform.translation
  end

  ctx.world.each(Target, Bevy::Transform) do |entity, _, transform|
    target_pos = transform.translation
    target_entity = entity
  end

  if player_pos && target_pos
    dx = player_pos.x - target_pos.x
    dy = player_pos.y - target_pos.y
    distance = Math.sqrt(dx * dx + dy * dy)

    if distance < 40.0
      ctx.world.each(GameData) do |entity, game_data|
        game_data.score += 10
        ctx.world.insert_component(entity, game_data)

        if game_data.score >= 100
          clear_all_entities(ctx)
          state.current_state = GameState::GAME_OVER
        end
      end

      if target_entity && state.current_state == GameState::PLAYING
        new_x = rand(-300.0..300.0)
        new_y = rand(-150.0..200.0)
        ctx.world.each(Target, Bevy::Transform) do |e, _, t|
          new_pos = Bevy::Vec3.new(new_x, new_y, 0.0)
          ctx.world.insert_component(e, t.with_translation(new_pos))
        end
      end
    end
  end

  ctx.world.each(Target, Bevy::Transform) do |entity, _, transform|
    pulse = 1.0 + Math.sin(ctx.elapsed * 4.0) * 0.2
    new_scale = Bevy::Vec3.new(pulse, pulse, 1.0)
    ctx.world.insert_component(entity, transform.with_scale(new_scale))
  end

  ctx.world.each(ScoreDisplay, GameData, Bevy::Sprite) do |entity, _, game_data, sprite|
    width = 50.0 + game_data.score * 2.0
    new_sprite = sprite.with_custom_size(Bevy::Vec2.new(width, 30.0))
    ctx.world.insert_component(entity, new_sprite)
  end
end

app.add_update_system do |ctx|
  state = ctx.resource(MenuState)
  next unless state.current_state == GameState::PAUSED

  state.current_state = GameState::PLAYING if ctx.key_just_pressed?('ESCAPE') || ctx.key_just_pressed?('P')

  if ctx.key_just_pressed?('Q')
    clear_all_entities(ctx)
    spawn_menu(ctx)
    state.current_state = GameState::MENU
    state.selected_index = 0
  end

  ctx.world.each(Bevy::Sprite) do |entity, sprite|
    dimmed_color = Bevy::Color.rgba(
      sprite.color.r * 0.5,
      sprite.color.g * 0.5,
      sprite.color.b * 0.5,
      sprite.color.a
    )
    ctx.world.insert_component(entity, sprite.with_color(dimmed_color))
  end
end

app.add_update_system do |ctx|
  state = ctx.resource(MenuState)
  next unless state.current_state == GameState::GAME_OVER

  if ctx.key_just_pressed?('ENTER') || ctx.key_just_pressed?('SPACE')
    spawn_menu(ctx)
    state.current_state = GameState::MENU
    state.selected_index = 0
  end
end

puts 'Game Menu Example'
puts ''
puts 'MENU:'
puts '  UP/DOWN - Navigate'
puts '  ENTER/SPACE - Select'
puts ''
puts 'GAME:'
puts '  WASD/Arrows - Move player (green)'
puts '  Collect targets (red) to score'
puts '  P/ESC - Pause'
puts ''
puts 'PAUSED:'
puts '  P/ESC - Resume'
puts '  Q - Quit to menu'
app.run
