# frozen_string_literal: true

RSpec.describe Bevy::WindowMode do
  it 'defines window modes' do
    expect(described_class::WINDOWED).to eq(:windowed)
    expect(described_class::BORDERLESS_FULLSCREEN).to eq(:borderless_fullscreen)
    expect(described_class::FULLSCREEN).to eq(:fullscreen)
  end
end

RSpec.describe Bevy::CursorGrabMode do
  it 'defines cursor grab modes' do
    expect(described_class::NONE).to eq(:none)
    expect(described_class::CONFINED).to eq(:confined)
    expect(described_class::LOCKED).to eq(:locked)
  end
end

RSpec.describe Bevy::Window do
  describe '.new' do
    it 'creates with default values' do
      window = described_class.new
      expect(window.title).to eq('Bevy App')
      expect(window.width).to eq(1280.0)
      expect(window.height).to eq(720.0)
      expect(window.mode).to eq(Bevy::WindowMode::WINDOWED)
      expect(window.resizable).to be true
    end

    it 'creates with custom values' do
      window = described_class.new(
        title: 'My Game',
        width: 1920,
        height: 1080,
        mode: Bevy::WindowMode::FULLSCREEN
      )
      expect(window.title).to eq('My Game')
      expect(window.width).to eq(1920.0)
      expect(window.height).to eq(1080.0)
      expect(window.mode).to eq(Bevy::WindowMode::FULLSCREEN)
    end
  end

  describe '#set_title' do
    it 'changes title and returns self' do
      window = described_class.new
      result = window.set_title('New Title')
      expect(window.title).to eq('New Title')
      expect(result).to eq(window)
    end
  end

  describe '#resize' do
    it 'changes dimensions' do
      window = described_class.new
      window.resize(800, 600)
      expect(window.width).to eq(800.0)
      expect(window.height).to eq(600.0)
    end
  end

  describe '#set_position' do
    it 'sets window position' do
      window = described_class.new
      window.set_position(100, 200)
      expect(window.position_x).to eq(100.0)
      expect(window.position_y).to eq(200.0)
    end
  end

  describe '#center' do
    it 'clears position for centering' do
      window = described_class.new
      window.set_position(100, 200)
      window.center
      expect(window.position_x).to be_nil
      expect(window.position_y).to be_nil
    end
  end

  describe '#fullscreen' do
    it 'sets fullscreen mode' do
      window = described_class.new
      window.fullscreen
      expect(window.mode).to eq(Bevy::WindowMode::FULLSCREEN)
    end
  end

  describe '#borderless_fullscreen' do
    it 'sets borderless fullscreen mode' do
      window = described_class.new
      window.borderless_fullscreen
      expect(window.mode).to eq(Bevy::WindowMode::BORDERLESS_FULLSCREEN)
    end
  end

  describe '#windowed' do
    it 'sets windowed mode' do
      window = described_class.new(mode: Bevy::WindowMode::FULLSCREEN)
      window.windowed
      expect(window.mode).to eq(Bevy::WindowMode::WINDOWED)
    end
  end

  describe '#toggle_fullscreen' do
    it 'toggles between windowed and borderless fullscreen' do
      window = described_class.new
      expect(window.mode).to eq(Bevy::WindowMode::WINDOWED)

      window.toggle_fullscreen
      expect(window.mode).to eq(Bevy::WindowMode::BORDERLESS_FULLSCREEN)

      window.toggle_fullscreen
      expect(window.mode).to eq(Bevy::WindowMode::WINDOWED)
    end
  end

  describe '#hide_cursor and #show_cursor' do
    it 'toggles cursor visibility' do
      window = described_class.new
      expect(window.cursor_visible).to be true

      window.hide_cursor
      expect(window.cursor_visible).to be false

      window.show_cursor
      expect(window.cursor_visible).to be true
    end
  end

  describe '#lock_cursor' do
    it 'locks cursor' do
      window = described_class.new
      window.lock_cursor
      expect(window.cursor_grab_mode).to eq(Bevy::CursorGrabMode::LOCKED)
    end
  end

  describe '#confine_cursor' do
    it 'confines cursor' do
      window = described_class.new
      window.confine_cursor
      expect(window.cursor_grab_mode).to eq(Bevy::CursorGrabMode::CONFINED)
    end
  end

  describe '#release_cursor' do
    it 'releases cursor' do
      window = described_class.new
      window.lock_cursor
      window.release_cursor
      expect(window.cursor_grab_mode).to eq(Bevy::CursorGrabMode::NONE)
    end
  end

  describe '#aspect_ratio' do
    it 'returns width/height ratio' do
      window = described_class.new(width: 1920, height: 1080)
      expect(window.aspect_ratio).to be_within(0.01).of(16.0 / 9.0)
    end

    it 'returns 0 for zero height' do
      window = described_class.new(width: 100, height: 0)
      expect(window.aspect_ratio).to eq(0.0)
    end
  end

  describe '#resolution' do
    it 'returns Vec2 of dimensions' do
      window = described_class.new(width: 800, height: 600)
      res = window.resolution
      expect(res.x).to eq(800.0)
      expect(res.y).to eq(600.0)
    end
  end

  describe '#fullscreen?' do
    it 'returns true when not windowed' do
      window = described_class.new(mode: Bevy::WindowMode::FULLSCREEN)
      expect(window.fullscreen?).to be true

      window.windowed
      expect(window.fullscreen?).to be false
    end
  end

  describe '#type_name' do
    it 'returns Window' do
      expect(described_class.new.type_name).to eq('Window')
    end
  end
end

RSpec.describe Bevy::PrimaryWindow do
  describe '.new' do
    it 'creates with default window' do
      primary = described_class.new
      expect(primary.window).to be_a(Bevy::Window)
    end

    it 'creates with custom window' do
      window = Bevy::Window.new(title: 'Custom')
      primary = described_class.new(window)
      expect(primary.window.title).to eq('Custom')
    end
  end

  describe '#type_name' do
    it 'returns PrimaryWindow' do
      expect(described_class.new.type_name).to eq('PrimaryWindow')
    end
  end
end

RSpec.describe Bevy::WindowResized do
  describe '.new' do
    it 'creates resize event' do
      event = described_class.new(window_id: 1, width: 1024, height: 768)
      expect(event.window_id).to eq(1)
      expect(event.width).to eq(1024.0)
      expect(event.height).to eq(768.0)
    end
  end

  describe '#type_name' do
    it 'returns WindowResized' do
      event = described_class.new(window_id: 1, width: 800, height: 600)
      expect(event.type_name).to eq('WindowResized')
    end
  end
end

RSpec.describe Bevy::WindowFocused do
  describe '.new' do
    it 'creates focus event' do
      event = described_class.new(window_id: 1, focused: true)
      expect(event.window_id).to eq(1)
      expect(event.focused?).to be true
    end
  end
end

RSpec.describe Bevy::Monitor do
  describe '.new' do
    it 'creates monitor info' do
      monitor = described_class.new(
        name: 'Primary',
        physical_width: 2560,
        physical_height: 1440,
        refresh_rate: 144.0
      )
      expect(monitor.name).to eq('Primary')
      expect(monitor.physical_width).to eq(2560)
      expect(monitor.refresh_rate).to eq(144.0)
    end
  end

  describe '#resolution' do
    it 'returns Vec2 of physical size' do
      monitor = described_class.new(name: 'Test', physical_width: 1920, physical_height: 1080)
      res = monitor.resolution
      expect(res.x).to eq(1920.0)
      expect(res.y).to eq(1080.0)
    end
  end
end

RSpec.describe Bevy::WindowPlugin do
  describe '.new' do
    it 'creates with defaults' do
      plugin = described_class.new
      expect(plugin.primary_window).to be_nil
      expect(plugin.close_when_requested).to be true
    end

    it 'creates with custom window' do
      window = Bevy::Window.new(title: 'Custom')
      plugin = described_class.new(primary_window: window)
      expect(plugin.primary_window.title).to eq('Custom')
    end
  end

  describe '#build' do
    it 'adds primary window resource to app' do
      window = Bevy::Window.new(title: 'Game')
      plugin = described_class.new(primary_window: window)
      app = Bevy::App.new
      plugin.build(app)
      expect(app.resources.get(Bevy::PrimaryWindow)).to be_a(Bevy::PrimaryWindow)
    end
  end
end
