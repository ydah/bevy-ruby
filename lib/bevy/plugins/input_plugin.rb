# frozen_string_literal: true

module Bevy
  module Plugins
    class InputPlugin < Plugin
      def build(app)
        setup_keyboard(app)
        setup_mouse(app)
        setup_gamepads(app)
        setup_touch(app) if respond_to?(:touch_enabled?) && touch_enabled?
      end

      private

      def setup_keyboard(app)
        app.insert_resource(KeyboardInput.new) unless app.resources.has?(KeyboardInput)
      end

      def setup_mouse(app)
        app.insert_resource(MouseInput.new) unless app.resources.has?(MouseInput)
      end

      def setup_gamepads(app)
        app.insert_resource(Gamepads.new) unless app.resources.has?(Gamepads)
      end

      def setup_touch(app)
      end
    end

    class KeyboardPlugin < Plugin
      def build(app)
        app.insert_resource(KeyboardInput.new) unless app.resources.has?(KeyboardInput)
      end
    end

    class MousePlugin < Plugin
      def build(app)
        app.insert_resource(MouseInput.new) unless app.resources.has?(MouseInput)
      end
    end

    class GamepadPlugin < Plugin
      def build(app)
        app.insert_resource(Gamepads.new) unless app.resources.has?(Gamepads)
      end
    end
  end
end
