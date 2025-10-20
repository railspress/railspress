require 'rails_helper'

RSpec.describe Template, type: :model do
  let(:tenant) { create(:tenant) }
  let(:theme) { create(:theme, tenant: tenant) }
  let(:template) { build(:template, theme: theme, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:theme) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:template_type) }
    it { should validate_inclusion_of(:template_type).in_array(Template::TEMPLATE_TYPES) }
    it { should validate_uniqueness_of(:template_type).scoped_to(:theme_id) }
  end

  describe 'constants' do
    it 'defines TEMPLATE_TYPES' do
      expect(Template::TEMPLATE_TYPES).to include('homepage', 'blog_index', 'blog_single', 'page_default', 'page_full_width', 'archive', 'category', 'tag', 'search', '404', 'header', 'footer', 'sidebar')
    end
  end

  describe 'scopes' do
    let!(:active_template) { create(:template, active: true, theme: theme, tenant: tenant) }
    let!(:inactive_template) { create(:template, active: false, theme: theme, tenant: tenant) }

    describe '.active' do
      it 'returns only active templates' do
        expect(Template.active).to include(active_template)
        expect(Template.active).not_to include(inactive_template)
      end
    end

    describe '.by_type' do
      it 'returns templates of specific type' do
        homepage_template = create(:template, template_type: 'homepage', theme: theme, tenant: tenant)
        blog_template = create(:template, template_type: 'blog_index', theme: theme, tenant: tenant)
        
        expect(Template.by_type('homepage')).to include(homepage_template)
        expect(Template.by_type('homepage')).not_to include(blog_template)
      end
    end
  end

  describe 'instance methods' do
    describe '#render_content' do
      it 'returns html_content when present' do
        template = build(:template, html_content: 'custom content', theme: theme, tenant: tenant)
        expect(template.render_content).to eq('custom content')
      end
      
      it 'returns default template when html_content is nil' do
        template = build(:template, html_content: nil, name: 'Test Template', theme: theme, tenant: tenant)
        expect(template.render_content).to include('Welcome to Test Template')
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values for new records' do
        template = Template.new
        expect(template.active).to be true
        expect(template.html_content).to include('Welcome to')
        expect(template.css_content).to include('body {')
        expect(template.js_content).to eq('')
      end
    end
  end

  describe 'private methods' do
    describe '#default_template' do
      it 'returns default HTML template' do
        template = Template.new(name: 'Test Template')
        result = template.send(:default_template)
        expect(result).to include('Welcome to Test Template')
        expect(result).to include('Start customizing this template')
      end
    end

    describe '#default_css' do
      it 'returns default CSS' do
        template = Template.new
        result = template.send(:default_css)
        expect(result).to include('body {')
        expect(result).to include('font-family: system-ui')
        expect(result).to include('.container {')
      end
    end
  end
end
