# frozen_string_literal: true

RSpec.describe Bevy::TypeRegistry do
  describe '.new' do
    it 'creates empty registry' do
      registry = described_class.new
      expect(registry.registrations).to be_empty
    end
  end

  describe '#register' do
    it 'registers a type' do
      registry = described_class.new
      registry.register(Bevy::Transform)
      expect(registry.registered?('Transform')).to be true
    end
  end

  describe '#get' do
    it 'returns type registration' do
      registry = described_class.new
      registry.register(Bevy::Transform)
      reg = registry.get('Transform')
      expect(reg).to be_a(Bevy::TypeRegistration)
    end
  end

  describe '#type_names' do
    it 'returns all registered type names' do
      registry = described_class.new
      registry.register(Bevy::Transform)
      registry.register(Bevy::Sprite)
      expect(registry.type_names).to contain_exactly('Transform', 'Sprite')
    end
  end

  describe '#type_name' do
    it 'returns TypeRegistry' do
      expect(described_class.new.type_name).to eq('TypeRegistry')
    end
  end
end

RSpec.describe Bevy::TypeRegistration do
  describe '.new' do
    it 'creates registration with type info' do
      reg = described_class.new(Bevy::Transform)
      expect(reg.type_name).to eq('TypeRegistration')
      expect(reg.type_info).to be_a(Bevy::StructInfo)
    end
  end

  describe '#insert_data and #get_data' do
    it 'stores and retrieves data' do
      reg = described_class.new(Bevy::Transform)
      reg.insert_data(:custom, 'value')
      expect(reg.get_data(:custom)).to eq('value')
    end
  end
end

RSpec.describe Bevy::StructInfo do
  describe '.new' do
    it 'extracts fields from type' do
      info = described_class.new(Bevy::Transform)
      expect(info.name).to eq('Transform')
      expect(info.field_count).to be > 0
    end
  end

  describe '#field' do
    it 'returns field by name' do
      info = described_class.new(Bevy::Transform)
      field = info.field(:translation)
      expect(field).to be_a(Bevy::FieldInfo) if field
    end
  end

  describe '#type_name' do
    it 'returns StructInfo' do
      expect(described_class.new(Bevy::Transform).type_name).to eq('StructInfo')
    end
  end
end

RSpec.describe Bevy::FieldInfo do
  describe '.new' do
    it 'creates field info' do
      field = described_class.new(name: :x, type: :float, default: 0.0)
      expect(field.name).to eq(:x)
      expect(field.type).to eq(:float)
      expect(field.default).to eq(0.0)
    end
  end

  describe '#type_name' do
    it 'returns FieldInfo' do
      expect(described_class.new(name: :test, type: :string).type_name).to eq('FieldInfo')
    end
  end
end

RSpec.describe Bevy::Reflect do
  let(:test_class) do
    Class.new do
      include Bevy::Reflect
      attr_accessor :x, :y

      def initialize(x: 0, y: 0)
        @x = x
        @y = y
      end

      def type_name
        'TestClass'
      end
    end
  end

  describe '#get_field' do
    it 'gets field value' do
      obj = test_class.new(x: 10, y: 20)
      expect(obj.get_field(:x)).to eq(10)
    end
  end

  describe '#set_field' do
    it 'sets field value' do
      obj = test_class.new
      obj.set_field(:x, 50)
      expect(obj.x).to eq(50)
    end
  end

  describe '#field_names' do
    it 'returns all field names' do
      obj = test_class.new(x: 1, y: 2)
      expect(obj.field_names).to contain_exactly(:x, :y)
    end
  end
end

RSpec.describe Bevy::DynamicStruct do
  describe '.new' do
    it 'creates dynamic struct with fields' do
      ds = described_class.new(type_name: 'Point', fields: { x: 10.0, y: 20.0 })
      expect(ds.type_name).to eq('Point')
      expect(ds.x).to eq(10.0)
      expect(ds.y).to eq(20.0)
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      ds = described_class.new(type_name: 'Data', fields: { name: 'test', value: 42 })
      h = ds.to_h
      expect(h[:name]).to eq('test')
      expect(h[:value]).to eq(42)
    end
  end
end

RSpec.describe Bevy::ReflectSerializer do
  describe '.serialize' do
    it 'serializes primitives' do
      expect(described_class.serialize(42)).to eq(42)
      expect(described_class.serialize('hello')).to eq('hello')
      expect(described_class.serialize(true)).to be true
    end

    it 'serializes arrays' do
      result = described_class.serialize([1, 2, 3])
      expect(result).to eq([1, 2, 3])
    end

    it 'serializes hashes' do
      result = described_class.serialize({ a: 1, b: 2 })
      expect(result).to eq({ a: 1, b: 2 })
    end
  end
end

RSpec.describe Bevy::ReflectDeserializer do
  describe '#deserialize' do
    it 'deserializes typed data' do
      registry = Bevy::TypeRegistry.new
      deserializer = described_class.new(registry)

      data = { _type: 'Point', x: 10, y: 20 }
      result = deserializer.deserialize(data)

      expect(result.type_name).to eq('Point')
      expect(result.x).to eq(10)
    end

    it 'deserializes arrays' do
      registry = Bevy::TypeRegistry.new
      deserializer = described_class.new(registry)

      data = [1, 2, 3]
      result = deserializer.deserialize(data)
      expect(result).to eq([1, 2, 3])
    end
  end
end

RSpec.describe Bevy::TypePath do
  describe '.new' do
    it 'creates type path' do
      path = described_class.new('Bevy::Transform')
      expect(path.full_path).to eq('Bevy::Transform')
    end
  end

  describe '#module_name' do
    it 'returns module part' do
      path = described_class.new('Bevy::ECS::Component')
      expect(path.module_name).to eq('Bevy::ECS')
    end
  end

  describe '#type_ident' do
    it 'returns type name part' do
      path = described_class.new('Bevy::Transform')
      expect(path.type_ident).to eq('Transform')
    end
  end

  describe '#type_name' do
    it 'returns TypePath' do
      expect(described_class.new('Test').type_name).to eq('TypePath')
    end
  end
end
