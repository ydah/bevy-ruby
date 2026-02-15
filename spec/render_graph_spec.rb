# frozen_string_literal: true

RSpec.describe Bevy::RenderGraph do
  describe '.new' do
    it 'creates empty graph' do
      graph = described_class.new
      expect(graph.nodes).to be_empty
      expect(graph.edges).to be_empty
      expect(graph.node_count).to eq(0)
    end
  end

  describe '#add_node' do
    it 'adds node to graph' do
      graph = described_class.new
      node = Bevy::RenderGraphNode.new('test')
      graph.add_node('test', node)
      expect(graph.node_count).to eq(1)
    end

    it 'returns self for chaining' do
      graph = described_class.new
      result = graph.add_node('test', Bevy::RenderGraphNode.new('test'))
      expect(result).to eq(graph)
    end
  end

  describe '#remove_node' do
    it 'removes node and associated edges' do
      graph = described_class.new
      graph.add_node('a', Bevy::RenderGraphNode.new('a'))
      graph.add_node('b', Bevy::RenderGraphNode.new('b'))
      graph.add_edge('a', 'b')
      graph.remove_node('a')
      expect(graph.node_count).to eq(1)
      expect(graph.edge_count).to eq(0)
    end
  end

  describe '#get_node' do
    it 'returns node by name' do
      graph = described_class.new
      node = Bevy::RenderGraphNode.new('test')
      graph.add_node('test', node)
      expect(graph.get_node('test')).to eq(node)
    end

    it 'returns nil for unknown name' do
      graph = described_class.new
      expect(graph.get_node('unknown')).to be_nil
    end
  end

  describe '#add_edge' do
    it 'adds edge between nodes' do
      graph = described_class.new
      graph.add_node('a', Bevy::RenderGraphNode.new('a'))
      graph.add_node('b', Bevy::RenderGraphNode.new('b'))
      graph.add_edge('a', 'b')
      expect(graph.edge_count).to eq(1)
    end

    it 'returns self for chaining' do
      graph = described_class.new
      graph.add_node('a', Bevy::RenderGraphNode.new('a'))
      graph.add_node('b', Bevy::RenderGraphNode.new('b'))
      result = graph.add_edge('a', 'b')
      expect(result).to eq(graph)
    end
  end

  describe '#set_input and #set_output' do
    it 'sets input and output nodes' do
      graph = described_class.new
      graph.add_node('input', Bevy::RenderGraphNode.new('input'))
      graph.add_node('output', Bevy::RenderGraphNode.new('output'))
      graph.set_input('input')
      graph.set_output('output')
      expect(graph.instance_variable_get(:@input_node)).to eq('input')
      expect(graph.instance_variable_get(:@output_node)).to eq('output')
    end
  end

  describe '#topological_order' do
    it 'returns nodes in topological order' do
      graph = described_class.new
      graph.add_node('a', Bevy::RenderGraphNode.new('a'))
      graph.add_node('b', Bevy::RenderGraphNode.new('b'))
      graph.add_node('c', Bevy::RenderGraphNode.new('c'))
      graph.add_edge('a', 'b')
      graph.add_edge('b', 'c')
      order = graph.topological_order
      expect(order.index('a')).to be < order.index('b')
      expect(order.index('b')).to be < order.index('c')
    end
  end

  describe '#type_name' do
    it 'returns RenderGraph' do
      expect(described_class.new.type_name).to eq('RenderGraph')
    end
  end
end

RSpec.describe Bevy::RenderGraphNode do
  describe '.new' do
    it 'creates node with name' do
      node = described_class.new('test')
      expect(node.name).to eq('test')
      expect(node.inputs).to be_empty
      expect(node.outputs).to be_empty
    end
  end

  describe '#add_input' do
    it 'adds input slot' do
      node = described_class.new('test')
      node.add_input('color', :texture)
      expect(node.inputs.size).to eq(1)
      expect(node.inputs.first[:name]).to eq('color')
    end

    it 'returns self for chaining' do
      node = described_class.new('test')
      result = node.add_input('color')
      expect(result).to eq(node)
    end
  end

  describe '#add_output' do
    it 'adds output slot' do
      node = described_class.new('test')
      node.add_output('result', :texture)
      expect(node.outputs.size).to eq(1)
      expect(node.outputs.first[:name]).to eq('result')
    end
  end

  describe '#run' do
    it 'raises NotImplementedError' do
      node = described_class.new('test')
      expect { node.run(nil, nil) }.to raise_error(NotImplementedError)
    end
  end

  describe '#type_name' do
    it 'returns RenderGraphNode' do
      expect(described_class.new('test').type_name).to eq('RenderGraphNode')
    end
  end
end

RSpec.describe Bevy::ViewNode do
  describe '.new' do
    it 'creates view node' do
      node = described_class.new('view')
      expect(node.name).to eq('view')
      expect(node.view_query).to be_nil
    end
  end

  describe '#type_name' do
    it 'returns ViewNode' do
      expect(described_class.new('test').type_name).to eq('ViewNode')
    end
  end
end

RSpec.describe Bevy::RenderPass do
  describe '.new' do
    it 'creates render pass' do
      pass = described_class.new(label: 'main')
      expect(pass.label).to eq('main')
      expect(pass.color_attachments).to be_empty
      expect(pass.depth_stencil_attachment).to be_nil
    end
  end

  describe '#add_color_attachment' do
    it 'adds color attachment' do
      pass = described_class.new
      attachment = Bevy::ColorAttachment.new
      pass.add_color_attachment(attachment)
      expect(pass.color_attachments.size).to eq(1)
    end

    it 'returns self for chaining' do
      pass = described_class.new
      result = pass.add_color_attachment(Bevy::ColorAttachment.new)
      expect(result).to eq(pass)
    end
  end

  describe '#type_name' do
    it 'returns RenderPass' do
      expect(described_class.new.type_name).to eq('RenderPass')
    end
  end
end

RSpec.describe Bevy::ColorAttachment do
  describe '.new' do
    it 'creates with default values' do
      attachment = described_class.new
      expect(attachment.load_op).to eq(Bevy::ColorAttachment::LOAD_CLEAR)
      expect(attachment.store_op).to eq(Bevy::ColorAttachment::STORE_STORE)
      expect(attachment.clear_color).to be_a(Bevy::Color)
    end

    it 'accepts custom values' do
      attachment = described_class.new(
        load_op: Bevy::ColorAttachment::LOAD_LOAD,
        store_op: Bevy::ColorAttachment::STORE_DISCARD
      )
      expect(attachment.load_op).to eq(:load)
      expect(attachment.store_op).to eq(:discard)
    end
  end

  describe 'constants' do
    it 'defines load operations' do
      expect(Bevy::ColorAttachment::LOAD_CLEAR).to eq(:clear)
      expect(Bevy::ColorAttachment::LOAD_LOAD).to eq(:load)
    end

    it 'defines store operations' do
      expect(Bevy::ColorAttachment::STORE_STORE).to eq(:store)
      expect(Bevy::ColorAttachment::STORE_DISCARD).to eq(:discard)
    end
  end

  describe '#type_name' do
    it 'returns ColorAttachment' do
      expect(described_class.new.type_name).to eq('ColorAttachment')
    end
  end
end

RSpec.describe Bevy::DepthStencilAttachment do
  describe '.new' do
    it 'creates with default values' do
      attachment = described_class.new
      expect(attachment.depth_load_op).to eq(:clear)
      expect(attachment.depth_store_op).to eq(:store)
      expect(attachment.clear_depth).to eq(1.0)
    end

    it 'accepts custom values' do
      attachment = described_class.new(clear_depth: 0.5)
      expect(attachment.clear_depth).to eq(0.5)
    end
  end

  describe '#type_name' do
    it 'returns DepthStencilAttachment' do
      expect(described_class.new.type_name).to eq('DepthStencilAttachment')
    end
  end
end

RSpec.describe Bevy::RenderTarget do
  describe '.new' do
    it 'creates render target' do
      size = Bevy::Vec2.new(1920, 1080)
      target = described_class.new(size: size)
      expect(target.size).to eq(size)
      expect(target.format).to eq(:bgra8_unorm)
      expect(target.samples).to eq(1)
    end

    it 'accepts custom format and samples' do
      target = described_class.new(size: Bevy::Vec2.new(800, 600), format: :rgba8_unorm, samples: 4)
      expect(target.format).to eq(:rgba8_unorm)
      expect(target.samples).to eq(4)
    end
  end

  describe '#type_name' do
    it 'returns RenderTarget' do
      expect(described_class.new(size: Bevy::Vec2.new(100, 100)).type_name).to eq('RenderTarget')
    end
  end
end

RSpec.describe Bevy::CameraRenderGraph do
  describe '.new' do
    it 'creates camera render graph' do
      camera = :camera_handle
      crg = described_class.new(camera: camera)
      expect(crg.camera).to eq(camera)
      expect(crg.graph_name).to eq('main')
    end

    it 'accepts custom graph name' do
      crg = described_class.new(camera: :camera, graph_name: 'custom')
      expect(crg.graph_name).to eq('custom')
    end
  end

  describe '#type_name' do
    it 'returns CameraRenderGraph' do
      expect(described_class.new(camera: :camera).type_name).to eq('CameraRenderGraph')
    end
  end
end
