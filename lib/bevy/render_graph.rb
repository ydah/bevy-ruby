# frozen_string_literal: true

module Bevy
  class RenderGraph
    attr_reader :nodes, :edges

    def initialize
      @nodes = {}
      @edges = []
      @input_node = nil
      @output_node = nil
    end

    def add_node(name, node)
      @nodes[name] = node
      self
    end

    def remove_node(name)
      @nodes.delete(name)
      @edges.reject! { |e| e[:from] == name || e[:to] == name }
    end

    def get_node(name)
      @nodes[name]
    end

    def add_edge(from, to)
      @edges << { from: from, to: to }
      self
    end

    def set_input(name)
      @input_node = name
    end

    def set_output(name)
      @output_node = name
    end

    def node_count
      @nodes.size
    end

    def edge_count
      @edges.size
    end

    def topological_order
      visited = {}
      order = []

      @nodes.keys.each do |name|
        visit(name, visited, order) unless visited[name]
      end

      order.reverse
    end

    def type_name
      'RenderGraph'
    end

    private

    def visit(name, visited, order)
      visited[name] = true
      @edges.each do |edge|
        next unless edge[:from] == name
        next if visited[edge[:to]]

        visit(edge[:to], visited, order)
      end
      order << name
    end
  end

  class RenderGraphNode
    attr_reader :name, :inputs, :outputs

    def initialize(name)
      @name = name
      @inputs = []
      @outputs = []
    end

    def add_input(name, type = :texture)
      @inputs << { name: name, type: type }
      self
    end

    def add_output(name, type = :texture)
      @outputs << { name: name, type: type }
      self
    end

    def run(_world, _resources)
      raise NotImplementedError
    end

    def type_name
      'RenderGraphNode'
    end
  end

  class ViewNode < RenderGraphNode
    attr_accessor :view_query

    def initialize(name)
      super(name)
      @view_query = nil
    end

    def type_name
      'ViewNode'
    end
  end

  class RenderPass
    attr_accessor :label, :color_attachments, :depth_stencil_attachment

    def initialize(label: nil)
      @label = label
      @color_attachments = []
      @depth_stencil_attachment = nil
    end

    def add_color_attachment(attachment)
      @color_attachments << attachment
      self
    end

    def type_name
      'RenderPass'
    end
  end

  class ColorAttachment
    attr_accessor :view, :resolve_target, :load_op, :store_op, :clear_color

    LOAD_CLEAR = :clear
    LOAD_LOAD = :load
    STORE_STORE = :store
    STORE_DISCARD = :discard

    def initialize(
      view: nil,
      load_op: LOAD_CLEAR,
      store_op: STORE_STORE,
      clear_color: nil
    )
      @view = view
      @resolve_target = nil
      @load_op = load_op
      @store_op = store_op
      @clear_color = clear_color || Color.black
    end

    def type_name
      'ColorAttachment'
    end
  end

  class DepthStencilAttachment
    attr_accessor :view, :depth_load_op, :depth_store_op, :clear_depth

    def initialize(
      view: nil,
      depth_load_op: :clear,
      depth_store_op: :store,
      clear_depth: 1.0
    )
      @view = view
      @depth_load_op = depth_load_op
      @depth_store_op = depth_store_op
      @clear_depth = clear_depth.to_f
    end

    def type_name
      'DepthStencilAttachment'
    end
  end

  class RenderTarget
    attr_accessor :size, :format, :samples

    def initialize(size:, format: :bgra8_unorm, samples: 1)
      @size = size
      @format = format
      @samples = samples
    end

    def type_name
      'RenderTarget'
    end
  end

  class CameraRenderGraph
    attr_accessor :camera, :graph_name

    def initialize(camera:, graph_name: 'main')
      @camera = camera
      @graph_name = graph_name
    end

    def type_name
      'CameraRenderGraph'
    end
  end
end
