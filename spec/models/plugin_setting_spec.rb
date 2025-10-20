require 'rails_helper'

RSpec.describe PluginSetting, type: :model do
  describe 'validations' do
    it 'validates presence of plugin_name' do
      setting = PluginSetting.new(key: 'test_key', value: 'test_value')
      expect(setting).not_to be_valid
      expect(setting.errors[:plugin_name]).to include("can't be blank")
    end

    it 'validates presence of key' do
      setting = PluginSetting.new(plugin_name: 'test_plugin', value: 'test_value')
      expect(setting).not_to be_valid
      expect(setting.errors[:key]).to include("can't be blank")
    end

    it 'validates uniqueness of key scoped to plugin_name' do
      PluginSetting.create!(plugin_name: 'test_plugin', key: 'test_key', value: 'test_value')
      setting = PluginSetting.new(plugin_name: 'test_plugin', key: 'test_key', value: 'another_value')
      expect(setting).not_to be_valid
      expect(setting.errors[:key]).to include('has already been taken')
    end

    it 'validates setting_type inclusion' do
      setting = PluginSetting.new(plugin_name: 'test_plugin', key: 'test_key', value: 'test_value', setting_type: 'invalid_type')
      expect(setting).not_to be_valid
      expect(setting.errors[:setting_type]).to include('is not included in the list')
    end

    it 'allows valid setting_types' do
      valid_types = %w[string boolean integer float array json text]
      valid_types.each do |type|
        setting = PluginSetting.new(plugin_name: 'test_plugin', key: "key_#{type}", value: 'test_value', setting_type: type)
        expect(setting).to be_valid, "Setting type '#{type}' should be valid"
      end
    end
  end

  describe 'scopes' do
    let!(:plugin1_setting1) { PluginSetting.create!(plugin_name: 'plugin1', key: 'key1', value: 'value1') }
    let!(:plugin1_setting2) { PluginSetting.create!(plugin_name: 'plugin1', key: 'key2', value: 'value2') }
    let!(:plugin2_setting1) { PluginSetting.create!(plugin_name: 'plugin2', key: 'key1', value: 'value3') }

    describe '.for_plugin' do
      it 'returns settings for a specific plugin' do
        settings = PluginSetting.for_plugin('plugin1')
        expect(settings).to contain_exactly(plugin1_setting1, plugin1_setting2)
      end
    end

    describe '.by_key' do
      it 'returns settings with a specific key' do
        settings = PluginSetting.by_key('key1')
        expect(settings).to contain_exactly(plugin1_setting1, plugin2_setting1)
      end
    end
  end

  describe 'typed_value' do
    it 'returns boolean true for boolean type with value "true"' do
      setting = PluginSetting.new(setting_type: 'boolean', value: 'true')
      expect(setting.typed_value).to be true
    end

    it 'returns boolean true for boolean type with value "1"' do
      setting = PluginSetting.new(setting_type: 'boolean', value: '1')
      expect(setting.typed_value).to be true
    end

    it 'returns boolean false for boolean type with value "false"' do
      setting = PluginSetting.new(setting_type: 'boolean', value: 'false')
      expect(setting.typed_value).to be false
    end

    it 'returns integer for integer type' do
      setting = PluginSetting.new(setting_type: 'integer', value: '42')
      expect(setting.typed_value).to eq(42)
    end

    it 'returns float for float type' do
      setting = PluginSetting.new(setting_type: 'float', value: '3.14')
      expect(setting.typed_value).to eq(3.14)
    end

    it 'returns parsed array for array type' do
      setting = PluginSetting.new(setting_type: 'array', value: '["a", "b", "c"]')
      expect(setting.typed_value).to eq(['a', 'b', 'c'])
    end

    it 'returns parsed JSON for json type' do
      setting = PluginSetting.new(setting_type: 'json', value: '{"key": "value"}')
      expect(setting.typed_value).to eq({'key' => 'value'})
    end

    it 'returns string for string type' do
      setting = PluginSetting.new(setting_type: 'string', value: 'hello world')
      expect(setting.typed_value).to eq('hello world')
    end

    it 'returns string for text type' do
      setting = PluginSetting.new(setting_type: 'text', value: 'long text content')
      expect(setting.typed_value).to eq('long text content')
    end
  end

  describe 'typed_value=' do
    it 'converts boolean to string' do
      setting = PluginSetting.new(setting_type: 'boolean')
      setting.typed_value = true
      expect(setting.value).to eq('true')
    end

    it 'converts integer to string' do
      setting = PluginSetting.new(setting_type: 'integer')
      setting.typed_value = 42
      expect(setting.value).to eq('42')
    end

    it 'converts float to string' do
      setting = PluginSetting.new(setting_type: 'float')
      setting.typed_value = 3.14
      expect(setting.value).to eq('3.14')
    end

    it 'converts array to JSON string' do
      setting = PluginSetting.new(setting_type: 'array')
      setting.typed_value = ['a', 'b', 'c']
      expect(setting.value).to eq('["a","b","c"]')
    end

    it 'converts hash to JSON string' do
      setting = PluginSetting.new(setting_type: 'json')
      setting.typed_value = {'key' => 'value'}
      expect(setting.value).to eq('{"key":"value"}')
    end

    it 'converts string to string' do
      setting = PluginSetting.new(setting_type: 'string')
      setting.typed_value = 'hello world'
      expect(setting.value).to eq('hello world')
    end
  end

  describe 'class methods' do
    describe '.get' do
      it 'returns the typed value for an existing setting' do
        PluginSetting.create!(plugin_name: 'test_plugin', key: 'test_key', value: '42', setting_type: 'integer')
        expect(PluginSetting.get('test_plugin', 'test_key')).to eq(42)
      end

      it 'returns default value for non-existing setting' do
        expect(PluginSetting.get('test_plugin', 'non_existing_key', 'default_value')).to eq('default_value')
      end
    end

    describe '.set' do
      it 'creates a new setting' do
        setting = PluginSetting.set('test_plugin', 'new_key', 'new_value', 'string')
        expect(setting.plugin_name).to eq('test_plugin')
        expect(setting.key).to eq('new_key')
        expect(setting.value).to eq('new_value')
        expect(setting.setting_type).to eq('string')
      end

      it 'updates an existing setting' do
        PluginSetting.create!(plugin_name: 'test_plugin', key: 'existing_key', value: 'old_value', setting_type: 'string')
        setting = PluginSetting.set('test_plugin', 'existing_key', 'new_value', 'string')
        expect(setting.value).to eq('new_value')
      end

      it 'sets default type to string when not specified' do
        setting = PluginSetting.set('test_plugin', 'key', 'value')
        expect(setting.setting_type).to eq('string')
      end
    end
  end

  describe 'callbacks' do
    it 'sets default type to string before save' do
      setting = PluginSetting.new(plugin_name: 'test_plugin', key: 'test_key', value: 'test_value')
      setting.save!
      expect(setting.setting_type).to eq('string')
    end
  end
end