require 'rails_helper'

RSpec.describe Plugin, type: :model do
  let(:plugin) { build(:plugin) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:version) }
    
    it 'validates uniqueness of name' do
      create(:plugin, name: 'test-plugin')
      duplicate_plugin = build(:plugin, name: 'test-plugin')
      expect(duplicate_plugin).not_to be_valid
      expect(duplicate_plugin.errors[:name]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:active_plugin) { create(:plugin, active: true, name: 'active-plugin') }
    let!(:inactive_plugin) { create(:plugin, active: false, name: 'inactive-plugin') }

    describe '.active' do
      it 'returns only active plugins' do
        expect(Plugin.active).to include(active_plugin)
        expect(Plugin.active).not_to include(inactive_plugin)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values for new records' do
        plugin = Plugin.new
        expect(plugin.active).to be false
        expect(plugin.settings).to eq({})
      end
    end
  end

  describe 'instance methods' do
    let(:plugin) { create(:plugin, active: false) }

    describe '#activate!' do
      it 'activates the plugin' do
        plugin.activate!
        expect(plugin.active).to be true
      end
    end

    describe '#deactivate!' do
      it 'deactivates the plugin' do
        plugin.update!(active: true)
        plugin.deactivate!
        expect(plugin.active).to be false
      end
    end
  end
end
