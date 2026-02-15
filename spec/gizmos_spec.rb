# frozen_string_literal: true

RSpec.describe Bevy::Gizmos do
  describe '.new' do
    it 'creates enabled gizmos with default line width' do
      gizmos = described_class.new
      expect(gizmos.enabled).to be true
      expect(gizmos.line_width).to eq(1.0)
      expect(gizmos.commands).to be_empty
    end
  end

  describe '#line' do
    it 'adds line command' do
      gizmos = described_class.new
      gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.new(1.0, 0.0, 0.0))
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:line)
    end

    it 'accepts custom color' do
      gizmos = described_class.new
      color = Bevy::Color.red
      gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.one, color: color)
      expect(gizmos.commands.first[:color]).to eq(color)
    end

    it 'returns self for chaining' do
      gizmos = described_class.new
      result = gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.one)
      expect(result).to eq(gizmos)
    end
  end

  describe '#ray' do
    it 'adds line command for ray' do
      gizmos = described_class.new
      gizmos.ray(Bevy::Vec3.zero, Bevy::Vec3.new(1.0, 0.0, 0.0), length: 5.0)
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:line)
    end
  end

  describe '#circle' do
    it 'adds circle command' do
      gizmos = described_class.new
      gizmos.circle(Bevy::Vec3.zero, 5.0)
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:circle)
      expect(gizmos.commands.first[:radius]).to eq(5.0)
    end

    it 'accepts custom segments' do
      gizmos = described_class.new
      gizmos.circle(Bevy::Vec3.zero, 5.0, segments: 64)
      expect(gizmos.commands.first[:segments]).to eq(64)
    end
  end

  describe '#sphere' do
    it 'adds sphere command' do
      gizmos = described_class.new
      gizmos.sphere(Bevy::Vec3.zero, 1.0)
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:sphere)
    end
  end

  describe '#rect' do
    it 'adds rect command' do
      gizmos = described_class.new
      gizmos.rect(Bevy::Vec3.zero, Bevy::Vec2.new(10.0, 5.0))
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:rect)
    end
  end

  describe '#box3d' do
    it 'adds box command' do
      gizmos = described_class.new
      gizmos.box3d(Bevy::Vec3.zero, Bevy::Vec3.one)
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:box)
    end
  end

  describe '#arrow' do
    it 'adds arrow command' do
      gizmos = described_class.new
      gizmos.arrow(Bevy::Vec3.zero, Bevy::Vec3.new(0.0, 5.0, 0.0))
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:arrow)
    end
  end

  describe '#arc' do
    it 'adds arc command' do
      gizmos = described_class.new
      gizmos.arc(Bevy::Vec3.zero, 5.0, 0.0, Math::PI)
      expect(gizmos.command_count).to eq(1)
      expect(gizmos.commands.first[:type]).to eq(:arc)
    end
  end

  describe '#grid' do
    it 'adds grid command' do
      gizmos = described_class.new
      gizmos.grid(Bevy::Vec3.zero, 1.0, 10)
      expect(gizmos.command_count).to eq(1)
      cmd = gizmos.commands.first
      expect(cmd[:type]).to eq(:grid)
      expect(cmd[:color]).to be_a(Bevy::Color)
    end
  end

  describe '#cross' do
    it 'adds two line commands' do
      gizmos = described_class.new
      gizmos.cross(Bevy::Vec3.zero, 2.0)
      expect(gizmos.command_count).to eq(2)
    end
  end

  describe '#clear' do
    it 'removes all commands' do
      gizmos = described_class.new
      gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.one)
      gizmos.circle(Bevy::Vec3.zero, 1.0)
      gizmos.clear
      expect(gizmos.commands).to be_empty
    end
  end

  describe '#command_count' do
    it 'returns number of commands' do
      gizmos = described_class.new
      gizmos.line(Bevy::Vec3.zero, Bevy::Vec3.one)
      gizmos.circle(Bevy::Vec3.zero, 1.0)
      expect(gizmos.command_count).to eq(2)
    end
  end

  describe '#type_name' do
    it 'returns Gizmos' do
      expect(described_class.new.type_name).to eq('Gizmos')
    end
  end
end

RSpec.describe Bevy::GizmoConfig do
  describe '.new' do
    it 'creates with default values' do
      config = described_class.new
      expect(config.enabled).to be true
      expect(config.line_width).to eq(1.0)
      expect(config.depth_test).to be true
      expect(config.render_layer).to eq(0)
    end

    it 'accepts custom values' do
      config = described_class.new(enabled: false, line_width: 2.0, depth_test: false, render_layer: 1)
      expect(config.enabled).to be false
      expect(config.line_width).to eq(2.0)
      expect(config.depth_test).to be false
      expect(config.render_layer).to eq(1)
    end
  end

  describe '#type_name' do
    it 'returns GizmoConfig' do
      expect(described_class.new.type_name).to eq('GizmoConfig')
    end
  end
end

RSpec.describe Bevy::AabbGizmo do
  describe '.new' do
    it 'creates with default color' do
      gizmo = described_class.new
      expect(gizmo.color).to be_a(Bevy::Color)
    end

    it 'accepts custom color' do
      color = Bevy::Color.red
      gizmo = described_class.new(color: color)
      expect(gizmo.color).to eq(color)
    end
  end

  describe '#type_name' do
    it 'returns AabbGizmo' do
      expect(described_class.new.type_name).to eq('AabbGizmo')
    end
  end
end

RSpec.describe Bevy::LightGizmo do
  describe '.new' do
    it 'creates with default values' do
      gizmo = described_class.new
      expect(gizmo.draw_range).to be true
      expect(gizmo.draw_direction).to be true
    end

    it 'accepts custom values' do
      gizmo = described_class.new(draw_range: false, draw_direction: false)
      expect(gizmo.draw_range).to be false
      expect(gizmo.draw_direction).to be false
    end
  end

  describe '#type_name' do
    it 'returns LightGizmo' do
      expect(described_class.new.type_name).to eq('LightGizmo')
    end
  end
end

RSpec.describe Bevy::TransformGizmo do
  describe '.new' do
    it 'creates with default translate mode' do
      gizmo = described_class.new
      expect(gizmo.enabled).to be true
      expect(gizmo.mode).to eq(Bevy::TransformGizmo::TRANSLATE)
    end

    it 'accepts custom mode' do
      gizmo = described_class.new(mode: Bevy::TransformGizmo::ROTATE)
      expect(gizmo.mode).to eq(Bevy::TransformGizmo::ROTATE)
    end
  end

  describe '#translate_mode' do
    it 'sets mode to translate' do
      gizmo = described_class.new(mode: Bevy::TransformGizmo::SCALE)
      gizmo.translate_mode
      expect(gizmo.mode).to eq(Bevy::TransformGizmo::TRANSLATE)
    end
  end

  describe '#rotate_mode' do
    it 'sets mode to rotate' do
      gizmo = described_class.new
      gizmo.rotate_mode
      expect(gizmo.mode).to eq(Bevy::TransformGizmo::ROTATE)
    end
  end

  describe '#scale_mode' do
    it 'sets mode to scale' do
      gizmo = described_class.new
      gizmo.scale_mode
      expect(gizmo.mode).to eq(Bevy::TransformGizmo::SCALE)
    end
  end

  describe '#type_name' do
    it 'returns TransformGizmo' do
      expect(described_class.new.type_name).to eq('TransformGizmo')
    end
  end
end
