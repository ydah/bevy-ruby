# frozen_string_literal: true

# Breakout Game Example
# A classic arcade-style brick-breaking game with real window rendering.
# Control the paddle with A/D or Left/Right arrows. Press P or ESC to pause.

require 'bevy'

module GameConfig
  ARENA_WIDTH = 800.0
  ARENA_HEIGHT = 600.0
  WALL_THICKNESS = 10.0

  PADDLE_WIDTH = 100.0
  PADDLE_HEIGHT = 20.0
  PADDLE_SPEED = 500.0
  PADDLE_Y = -250.0

  BALL_SIZE = 15.0
  BALL_SPEED = 300.0

  BRICK_WIDTH = 70.0
  BRICK_HEIGHT = 25.0
  BRICK_ROWS = 5
  BRICK_COLS = 10
  BRICK_PADDING = 5.0
  BRICK_TOP_Y = 200.0

  PADDLE_COLOR = Bevy::Color.from_hex('#4ECDC4')
  BALL_COLOR = Bevy::Color.white
  WALL_COLOR = Bevy::Color.from_hex('#2C3E50')

  BRICK_COLORS = [
    Bevy::Color.from_hex('#E74C3C'),
    Bevy::Color.from_hex('#E67E22'),
    Bevy::Color.from_hex('#F1C40F'),
    Bevy::Color.from_hex('#2ECC71'),
    Bevy::Color.from_hex('#3498DB')
  ].freeze
end

class Paddle < Bevy::ComponentDSL
  attribute :speed, Float, default: GameConfig::PADDLE_SPEED
end

class Ball < Bevy::ComponentDSL
  attribute :velocity_x, Float, default: 0.0
  attribute :velocity_y, Float, default: 0.0
end

class Brick < Bevy::ComponentDSL
  attribute :points, Integer, default: 10
end

class Wall < Bevy::ComponentDSL
  attribute :side, String, default: 'top'
end

class Collider < Bevy::ComponentDSL
  attribute :width, Float, default: 0.0
  attribute :height, Float, default: 0.0
end

class GameState < Bevy::ResourceDSL
  attribute :score, Integer, default: 0
  attribute :lives, Integer, default: 3
  attribute :bricks_remaining, Integer, default: 0
  attribute :game_over, :boolean, default: false
  attribute :game_won, :boolean, default: false
  attribute :paused, :boolean, default: false
end

class AABB
  attr_reader :min_x, :min_y, :max_x, :max_y

  def initialize(x, y, width, height)
    @min_x = x - width / 2
    @max_x = x + width / 2
    @min_y = y - height / 2
    @max_y = y + height / 2
  end

  def intersects?(other)
    @min_x < other.max_x && @max_x > other.min_x &&
      @min_y < other.max_y && @max_y > other.min_y
  end
end

class PaddlePlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      next if ctx.resource(GameState).paused

      delta = ctx.delta

      ctx.world.each(Paddle, Bevy::Transform) do |entity, paddle, transform|
        direction = 0.0
        direction -= 1.0 if ctx.key_pressed?('A') || ctx.key_pressed?('LEFT')
        direction += 1.0 if ctx.key_pressed?('D') || ctx.key_pressed?('RIGHT')

        next if direction.zero?

        new_x = transform.translation.x + direction * paddle.speed * delta

        half_paddle = GameConfig::PADDLE_WIDTH / 2
        half_arena = GameConfig::ARENA_WIDTH / 2 - GameConfig::WALL_THICKNESS
        new_x = new_x.clamp(-half_arena + half_paddle, half_arena - half_paddle)

        new_pos = Bevy::Vec3.new(new_x, transform.translation.y, transform.translation.z)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
      end
    end
  end
end

class BallPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      next if state.paused || state.game_over

      delta = ctx.delta

      ctx.world.each(Ball, Bevy::Transform) do |entity, ball, transform|
        new_x = transform.translation.x + ball.velocity_x * delta
        new_y = transform.translation.y + ball.velocity_y * delta

        new_pos = Bevy::Vec3.new(new_x, new_y, transform.translation.z)
        ctx.world.insert_component(entity, transform.with_translation(new_pos))
      end
    end

    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      next if state.game_over

      ctx.world.each(Ball, Bevy::Transform) do |entity, ball, transform|
        next unless transform.translation.y < -GameConfig::ARENA_HEIGHT / 2

        state.lives -= 1

        if state.lives <= 0
          state.game_over = true
        else
          ball.velocity_x = GameConfig::BALL_SPEED * (rand < 0.5 ? -1 : 1) * 0.7
          ball.velocity_y = GameConfig::BALL_SPEED
          new_pos = Bevy::Vec3.new(0.0, 0.0, 0.0)
          ctx.world.insert_component(entity, transform.with_translation(new_pos))
          ctx.world.insert_component(entity, ball)
        end
      end
    end
  end
end

class CollisionPlugin < Bevy::Plugin
  def build(app)
    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      next if state.paused || state.game_over

      ctx.world.each(Ball, Bevy::Transform, Collider) do |ball_entity, ball, ball_transform, ball_collider|
        ball_aabb = AABB.new(
          ball_transform.translation.x,
          ball_transform.translation.y,
          ball_collider.width,
          ball_collider.height
        )

        ctx.world.each(Wall, Bevy::Transform, Collider) do |_wall_entity, wall, wall_transform, wall_collider|
          wall_aabb = AABB.new(
            wall_transform.translation.x,
            wall_transform.translation.y,
            wall_collider.width,
            wall_collider.height
          )

          next unless ball_aabb.intersects?(wall_aabb)

          case wall.side
          when 'left', 'right'
            ball.velocity_x = -ball.velocity_x
          when 'top'
            ball.velocity_y = -ball.velocity_y
          end

          ctx.world.insert_component(ball_entity, ball)
        end
      end
    end

    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      next if state.paused || state.game_over

      ctx.world.each(Ball, Bevy::Transform, Collider) do |ball_entity, ball, ball_transform, ball_collider|
        ball_aabb = AABB.new(
          ball_transform.translation.x,
          ball_transform.translation.y,
          ball_collider.width,
          ball_collider.height
        )

        ctx.world.each(Paddle, Bevy::Transform,
                       Collider) do |_paddle_entity, _paddle, paddle_transform, paddle_collider|
          paddle_aabb = AABB.new(
            paddle_transform.translation.x,
            paddle_transform.translation.y,
            paddle_collider.width,
            paddle_collider.height
          )

          next unless ball_aabb.intersects?(paddle_aabb)
          next unless ball.velocity_y < 0

          hit_pos = (ball_transform.translation.x - paddle_transform.translation.x) / (GameConfig::PADDLE_WIDTH / 2)
          hit_pos = hit_pos.clamp(-1.0, 1.0)

          speed = Math.sqrt(ball.velocity_x**2 + ball.velocity_y**2)
          angle = hit_pos * Math::PI / 3

          ball.velocity_x = speed * Math.sin(angle)
          ball.velocity_y = speed * Math.cos(angle).abs

          ctx.world.insert_component(ball_entity, ball)
        end
      end
    end

    app.add_update_system do |ctx|
      state = ctx.resource(GameState)
      next if state.paused || state.game_over

      bricks_to_destroy = []

      ctx.world.each(Ball, Bevy::Transform, Collider) do |ball_entity, ball, ball_transform, ball_collider|
        ball_aabb = AABB.new(
          ball_transform.translation.x,
          ball_transform.translation.y,
          ball_collider.width,
          ball_collider.height
        )

        ctx.world.each(Brick, Bevy::Transform, Collider) do |brick_entity, brick, brick_transform, brick_collider|
          brick_aabb = AABB.new(
            brick_transform.translation.x,
            brick_transform.translation.y,
            brick_collider.width,
            brick_collider.height
          )

          next unless ball_aabb.intersects?(brick_aabb)

          dx = ball_transform.translation.x - brick_transform.translation.x
          dy = ball_transform.translation.y - brick_transform.translation.y

          if dx.abs > dy.abs
            ball.velocity_x = -ball.velocity_x
          else
            ball.velocity_y = -ball.velocity_y
          end

          ctx.world.insert_component(ball_entity, ball)

          bricks_to_destroy << { entity: brick_entity, points: brick.points }

          break
        end
      end

      bricks_to_destroy.each do |brick_data|
        ctx.world.despawn(brick_data[:entity])
        state.score += brick_data[:points]
        state.bricks_remaining -= 1

        next unless state.bricks_remaining <= 0

        state.game_won = true
        state.game_over = true
      end
    end
  end
end

class GameStatePlugin < Bevy::Plugin
  def build(app)
    app.insert_resource(GameState.new)

    app.add_update_system do |ctx|
      state = ctx.resource(GameState)

      state.paused = !state.paused if ctx.key_just_pressed?('P') || ctx.key_just_pressed?('ESCAPE')
    end
  end
end

def spawn_walls(ctx)
  half_width = GameConfig::ARENA_WIDTH / 2
  half_height = GameConfig::ARENA_HEIGHT / 2
  thickness = GameConfig::WALL_THICKNESS

  ctx.spawn(
    Wall.new(side: 'top'),
    Collider.new(width: GameConfig::ARENA_WIDTH, height: thickness),
    Bevy::Transform.from_xyz(0.0, half_height - thickness / 2, 0.0),
    Bevy::Sprite.new(
      color: GameConfig::WALL_COLOR,
      custom_size: Bevy::Vec2.new(GameConfig::ARENA_WIDTH, thickness)
    )
  )

  ctx.spawn(
    Wall.new(side: 'left'),
    Collider.new(width: thickness, height: GameConfig::ARENA_HEIGHT),
    Bevy::Transform.from_xyz(-half_width + thickness / 2, 0.0, 0.0),
    Bevy::Sprite.new(
      color: GameConfig::WALL_COLOR,
      custom_size: Bevy::Vec2.new(thickness, GameConfig::ARENA_HEIGHT)
    )
  )

  ctx.spawn(
    Wall.new(side: 'right'),
    Collider.new(width: thickness, height: GameConfig::ARENA_HEIGHT),
    Bevy::Transform.from_xyz(half_width - thickness / 2, 0.0, 0.0),
    Bevy::Sprite.new(
      color: GameConfig::WALL_COLOR,
      custom_size: Bevy::Vec2.new(thickness, GameConfig::ARENA_HEIGHT)
    )
  )
end

def spawn_paddle(ctx)
  ctx.spawn(
    Paddle.new,
    Collider.new(width: GameConfig::PADDLE_WIDTH, height: GameConfig::PADDLE_HEIGHT),
    Bevy::Transform.from_xyz(0.0, GameConfig::PADDLE_Y, 0.0),
    Bevy::Sprite.new(
      color: GameConfig::PADDLE_COLOR,
      custom_size: Bevy::Vec2.new(GameConfig::PADDLE_WIDTH, GameConfig::PADDLE_HEIGHT)
    )
  )
end

def spawn_ball(ctx)
  angle = (rand * 0.5 + 0.25) * Math::PI
  velocity_x = GameConfig::BALL_SPEED * Math.cos(angle) * (rand < 0.5 ? -1 : 1)
  velocity_y = GameConfig::BALL_SPEED * Math.sin(angle)

  ctx.spawn(
    Ball.new(velocity_x: velocity_x, velocity_y: velocity_y),
    Collider.new(width: GameConfig::BALL_SIZE, height: GameConfig::BALL_SIZE),
    Bevy::Transform.from_xyz(0.0, 0.0, 0.0),
    Bevy::Sprite.new(
      color: GameConfig::BALL_COLOR,
      custom_size: Bevy::Vec2.new(GameConfig::BALL_SIZE, GameConfig::BALL_SIZE)
    )
  )
end

def spawn_bricks(ctx)
  state = ctx.resource(GameState)
  total_width = GameConfig::BRICK_COLS * (GameConfig::BRICK_WIDTH + GameConfig::BRICK_PADDING) - GameConfig::BRICK_PADDING
  start_x = -total_width / 2 + GameConfig::BRICK_WIDTH / 2

  GameConfig::BRICK_ROWS.times do |row|
    GameConfig::BRICK_COLS.times do |col|
      x = start_x + col * (GameConfig::BRICK_WIDTH + GameConfig::BRICK_PADDING)
      y = GameConfig::BRICK_TOP_Y - row * (GameConfig::BRICK_HEIGHT + GameConfig::BRICK_PADDING)

      points = (GameConfig::BRICK_ROWS - row) * 10
      color = GameConfig::BRICK_COLORS[row % GameConfig::BRICK_COLORS.length]

      ctx.spawn(
        Brick.new(points: points),
        Collider.new(width: GameConfig::BRICK_WIDTH, height: GameConfig::BRICK_HEIGHT),
        Bevy::Transform.from_xyz(x, y, 0.0),
        Bevy::Sprite.new(
          color: color,
          custom_size: Bevy::Vec2.new(GameConfig::BRICK_WIDTH, GameConfig::BRICK_HEIGHT)
        )
      )

      state.bricks_remaining += 1
    end
  end
end

app = Bevy::App.new(
  render: true,
  window: {
    title: 'Breakout - A/D or Arrows to move, P to pause',
    width: GameConfig::ARENA_WIDTH,
    height: GameConfig::ARENA_HEIGHT
  }
)

app.add_plugins(PaddlePlugin.new)
app.add_plugins(BallPlugin.new)
app.add_plugins(CollisionPlugin.new)
app.add_plugins(GameStatePlugin.new)

app.add_startup_system do |ctx|
  spawn_walls(ctx)
  spawn_paddle(ctx)
  spawn_ball(ctx)
  spawn_bricks(ctx)
end

puts 'Breakout Game'
puts 'Controls:'
puts '  A/D or Left/Right - Move paddle'
puts '  P or ESC - Pause'
puts 'Destroy all bricks to win!'
app.run

state = app.resources.get(GameState)
puts "\nFinal Score: #{state.score}"
puts "Lives Remaining: #{state.lives}"
puts "Result: #{if state.game_won
                  'VICTORY!'
                else
                  (state.lives <= 0 ? 'GAME OVER' : 'QUIT')
                end}"
