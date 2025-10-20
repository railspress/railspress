require 'rails_helper'

RSpec.describe Theme, type: :model do
  let(:tenant) { create(:tenant) }
  let(:theme) { build(:theme, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_many(:templates).dependent(:destroy) }
    it { should have_many(:theme_versions).dependent(:destroy) }
    it { should have_many(:theme_files).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:version) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'scopes' do
    let!(:active_theme) { create(:theme, active: true, tenant: tenant, name: 'Active Theme', slug: 'active-theme') }
    let!(:inactive_theme) { create(:theme, active: false, tenant: tenant, name: 'Inactive Theme', slug: 'inactive-theme') }

    describe '.active' do
      it 'returns only active themes' do
        expect(Theme.active).to include(active_theme)
        expect(Theme.active).not_to include(inactive_theme)
      end
    end
  end

  describe 'class methods' do
    describe '.current' do
      it 'returns active theme' do
        active_theme = create(:theme, active: true, tenant: tenant, name: 'Current Theme', slug: 'current-theme')
        expect(Theme.current).to eq(active_theme)
      end
      
      it 'returns first theme when no active theme' do
        theme = create(:theme, active: false, tenant: tenant, name: 'First Theme', slug: 'first-theme')
        expect(Theme.current).to eq(theme)
      end
    end
  end

  describe 'instance methods' do
    describe '#activate!' do
      it 'activates the theme and deactivates others' do
        theme1 = create(:theme, active: true, tenant: tenant, name: 'Theme 1', slug: 'theme-1')
        theme2 = create(:theme, active: false, tenant: tenant, name: 'Theme 2', slug: 'theme-2')
        
        theme2.activate!
        
        expect(theme2.reload.active).to be true
        expect(theme1.reload.active).to be false
      end
      
      it 'creates published version when activating' do
        allow_any_instance_of(Theme).to receive(:ensure_published_version_exists!)
        theme = create(:theme, active: false, tenant: tenant, name: 'Test Theme', slug: 'test-theme')
        expect(theme).to receive(:ensure_published_version_exists!)
        theme.activate!
      end
    end

    describe '#get_file' do
      let(:theme_version) { double('theme_version') }
      let(:theme_file) { double('theme_file', content: 'file content') }
      
      it 'returns file content from live version' do
        allow(theme).to receive(:theme_versions).and_return(double('scope', live: double('live', first: theme_version)))
        allow(theme_version).to receive(:file_content).with('test.liquid').and_return('file content')
        
        expect(theme.get_file('test.liquid')).to eq('file content')
      end
      
      it 'returns nil when no live version' do
        allow(theme).to receive(:theme_versions).and_return(double('scope', live: double('live', first: nil)))
        
        expect(theme.get_file('test.liquid')).to be_nil
      end
    end

    describe '#get_parsed_file' do
      it 'parses JSON files' do
        allow(theme).to receive(:get_file).with('test.json').and_return('{"key": "value"}')
        
        result = theme.get_parsed_file('test.json')
        expect(result).to eq({ 'key' => 'value' })
      end
      
      it 'returns raw content for non-JSON files' do
        allow(theme).to receive(:get_file).with('test.liquid').and_return('raw content')
        
        result = theme.get_parsed_file('test.liquid')
        expect(result).to eq('raw content')
      end
      
      it 'returns nil for invalid JSON' do
        allow(theme).to receive(:get_file).with('test.json').and_return('invalid json')
        
        result = theme.get_parsed_file('test.json')
        expect(result).to be_nil
      end
      
      it 'returns nil when file not found' do
        allow(theme).to receive(:get_file).with('test.json').and_return(nil)
        
        result = theme.get_parsed_file('test.json')
        expect(result).to be_nil
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values for new records' do
        theme = Theme.new
        expect(theme.config).to eq({})
      end
    end

    describe 'before_save' do
      it 'deactivates other themes when activating' do
        theme1 = create(:theme, active: true, tenant: tenant, name: 'Theme 1', slug: 'theme-1')
        theme2 = create(:theme, active: false, tenant: tenant, name: 'Theme 2', slug: 'theme-2')
        
        theme2.active = true
        theme2.save!
        
        expect(theme1.reload.active).to be false
        expect(theme2.reload.active).to be true
      end
      
      it 'sets slug from name' do
        theme = build(:theme, name: 'Test Theme', slug: nil, tenant: tenant)
        theme.save!
        expect(theme.slug).to eq('test-theme')
      end
    end
  end

  describe 'serialization' do
    it 'serializes config as JSON' do
      theme = build(:theme, config: { 'key' => 'value' }, tenant: tenant)
      theme.save!
      expect(theme.reload.config).to eq({ 'key' => 'value' })
    end
  end
end
