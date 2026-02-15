# frozen_string_literal: true

module Bevy
  module Plugins
    class DefaultPlugins < Plugin
      def build(app)
        add_core_plugins(app)
        add_input_plugins(app) unless app.respond_to?(:headless?) && app.headless?
        add_render_plugins(app) if app.render_enabled?
      end

      private

      def add_core_plugins(app)
        app.insert_resource(Time.new) unless app.resources.has?(Time)
        app.insert_resource(FixedTime.new) unless app.resources.has?(FixedTime)
      end

      def add_input_plugins(app)
        app.add_plugins(InputPlugin.new) unless app.resources.has?(KeyboardInput)
      end

      def add_render_plugins(app)
      end
    end

    class MinimalPlugins < Plugin
      def build(app)
        app.insert_resource(Time.new) unless app.resources.has?(Time)
        app.insert_resource(FixedTime.new) unless app.resources.has?(FixedTime)
      end
    end
  end
end
