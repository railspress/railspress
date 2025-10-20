require 'rails_helper'

RSpec.describe LiquidTemplateRenderer, type: :service do
  let(:theme_name) { 'test_theme' }
  let(:template_type) { 'index' }
  let(:template_data) { { 'order' => ['header'], 'sections' => { 'header' => { 'type' => 'header' } } } }
  let(:service) { LiquidTemplateRenderer.new(theme_name, template_type, template_data) }
  let(:theme_path) { Rails.root.join('tmp', 'test_themes', theme_name) }

  before do
    # Create test theme directory
    FileUtils.mkdir_p(theme_path)
    service.instance_variable_set(:@theme_path, theme_path)
  end

  after do
    FileUtils.rm_rf(theme_path) if Dir.exist?(theme_path)
  end

  describe '#initialize' do
    it 'sets theme name, template type, and template data' do
      expect(service.instance_variable_get(:@theme_name)).to eq(theme_name)
      expect(service.instance_variable_get(:@template_type)).to eq(template_type)
      expect(service.instance_variable_get(:@template_data)).to eq(template_data)
    end

    it 'sets theme path' do
      expect(service.instance_variable_get(:@theme_path)).to eq(theme_path)
    end
  end

  describe '#render' do
    before do
      # Create layout file
      layout_dir = File.join(theme_path, 'layout')
      FileUtils.mkdir_p(layout_dir)
      File.write(File.join(layout_dir, 'theme.liquid'), '<html><head><title>{{ page.title }}</title></head><body>{{ content_for_layout }}</body></html>')

      # Create template file
      template_dir = File.join(theme_path, 'templates')
      FileUtils.mkdir_p(template_dir)
      File.write(File.join(template_dir, 'index.json'), template_data.to_json)

      # Create section file
      section_dir = File.join(theme_path, 'sections')
      FileUtils.mkdir_p(section_dir)
      File.write(File.join(section_dir, 'header.liquid'), '<header>{{ section.settings.title }}</header>')
    end

    it 'renders complete template' do
      result = service.render

      expect(result).to include('<html>')
      expect(result).to include('<title>Homepage</title>')
      expect(result).to include('<header></header>')
    end

    it 'handles missing template file gracefully' do
      File.delete(File.join(theme_path, 'templates', 'index.json'))
      
      result = service.render
      
      expect(result).to include('<html>')
      expect(result).to include('<title>Homepage</title>')
    end

    it 'handles missing layout file gracefully' do
      File.delete(File.join(theme_path, 'layout', 'theme.liquid'))
      
      result = service.render
      
      expect(result).to include('<!DOCTYPE html>')
      expect(result).to include('{{ page.title }}')
    end
  end

  describe '#render_section' do
    let(:section_id) { 'header' }
    let(:section_data) { { 'type' => 'header', 'settings' => { 'title' => 'Welcome' } } }

    before do
      # Create section file
      section_dir = File.join(theme_path, 'sections')
      FileUtils.mkdir_p(section_dir)
      File.write(File.join(section_dir, 'header.liquid'), '<header>{{ section.settings.title }}</header>')
    end

    it 'renders section with settings' do
      result = service.render_section(section_id, section_data)

      expect(result).to eq('<header>Welcome</header>')
    end

    it 'handles missing section file' do
      File.delete(File.join(theme_path, 'sections', 'header.liquid'))
      
      result = service.render_section(section_id, section_data)
      
      expect(result).to eq('')
    end

    it 'handles rendering errors gracefully' do
      File.write(File.join(theme_path, 'sections', 'header.liquid'), '{{ invalid.liquid.syntax }}')
      
      result = service.render_section(section_id, section_data)
      
      expect(result).to include('Error rendering section: header')
    end
  end

  describe 'private methods' do
    describe '#load_template_structure' do
      before do
        template_dir = File.join(theme_path, 'templates')
        FileUtils.mkdir_p(template_dir)
        File.write(File.join(template_dir, 'index.json'), template_data.to_json)
      end

      it 'loads template structure from file' do
        result = service.send(:load_template_structure)
        
        expect(result).to eq(template_data)
      end

      it 'returns template data when file does not exist' do
        File.delete(File.join(theme_path, 'templates', 'index.json'))
        
        result = service.send(:load_template_structure)
        
        expect(result).to eq(template_data)
      end
    end

    describe '#render_layout' do
      before do
        layout_dir = File.join(theme_path, 'layout')
        FileUtils.mkdir_p(layout_dir)
        File.write(File.join(layout_dir, 'theme.liquid'), '<html><title>{{ page.title }}</title></html>')
      end

      it 'renders layout from file' do
        result = service.send(:render_layout)
        
        expect(result).to include('<html>')
        expect(result).to include('<title>Homepage</title>')
      end

      it 'returns default layout when file does not exist' do
        File.delete(File.join(theme_path, 'layout', 'theme.liquid'))
        
        result = service.send(:render_layout)
        
        expect(result).to include('<!DOCTYPE html>')
        expect(result).to include('{{ page.title }}')
      end

      it 'handles rendering errors gracefully' do
        File.write(File.join(theme_path, 'layout', 'theme.liquid'), '{{ invalid.liquid.syntax }}')
        
        result = service.send(:render_layout)
        
        expect(result).to include('<!DOCTYPE html>')
      end
    end

    describe '#render_sections' do
      let(:template_structure) do
        {
          'order' => ['header', 'content'],
          'sections' => {
            'header' => { 'type' => 'header', 'settings' => { 'title' => 'Header' } },
            'content' => { 'type' => 'text', 'settings' => { 'text' => 'Content' } }
          }
        }
      end

      before do
        section_dir = File.join(theme_path, 'sections')
        FileUtils.mkdir_p(section_dir)
        File.write(File.join(section_dir, 'header.liquid'), '<header>{{ section.settings.title }}</header>')
        File.write(File.join(section_dir, 'text.liquid'), '<div>{{ section.settings.text }}</div>')
      end

      it 'renders sections in order' do
        result = service.send(:render_sections, template_structure)
        
        expect(result).to include('<header>Header</header>')
        expect(result).to include('<div>Content</div>')
      end

      it 'handles missing sections gracefully' do
        template_structure['sections'].delete('content')
        
        result = service.send(:render_sections, template_structure)
        
        expect(result).to include('<header>Header</header>')
        expect(result).not_to include('<div>Content</div>')
      end

      it 'returns empty string for invalid structure' do
        result = service.send(:render_sections, {})
        
        expect(result).to eq('')
      end
    end

    describe '#load_theme_settings' do
      before do
        config_dir = File.join(theme_path, 'config')
        FileUtils.mkdir_p(config_dir)
        
        settings_schema = [
          {
            'name' => 'General',
            'settings' => [
              { 'id' => 'site_title', 'default' => 'My Site' },
              { 'id' => 'site_description', 'default' => 'A great site' }
            ]
          }
        ]
        File.write(File.join(config_dir, 'settings_schema.json'), settings_schema.to_json)
      end

      it 'loads theme settings from schema' do
        result = service.send(:load_theme_settings)
        
        expect(result).to eq({
          'site_title' => 'My Site',
          'site_description' => 'A great site'
        })
      end

      it 'returns empty hash when schema file does not exist' do
        File.delete(File.join(theme_path, 'config', 'settings_schema.json'))
        
        result = service.send(:load_theme_settings)
        
        expect(result).to eq({})
      end
    end

    describe '#load_page_data' do
      it 'returns homepage data for index template' do
        service.instance_variable_set(:@template_type, 'index')
        
        result = service.send(:load_page_data)
        
        expect(result).to eq({
          'title' => 'Homepage',
          'description' => 'Welcome to our site'
        })
      end

      it 'returns blog data for blog template' do
        service.instance_variable_set(:@template_type, 'blog')
        
        result = service.send(:load_page_data)
        
        expect(result).to eq({
          'title' => 'Blog',
          'description' => 'Latest posts'
        })
      end

      it 'returns page data for page template' do
        service.instance_variable_set(:@template_type, 'page')
        
        result = service.send(:load_page_data)
        
        expect(result).to eq({
          'title' => 'Page',
          'description' => 'Page content'
        })
      end

      it 'returns post data for post template' do
        service.instance_variable_set(:@template_type, 'post')
        
        result = service.send(:load_page_data)
        
        expect(result).to eq({
          'title' => 'Blog Post',
          'description' => 'Post content'
        })
      end

      it 'returns humanized data for unknown template' do
        service.instance_variable_set(:@template_type, 'custom_template')
        
        result = service.send(:load_page_data)
        
        expect(result).to eq({
          'title' => 'Custom template',
          'description' => ''
        })
      end
    end

    describe '#default_layout' do
      it 'returns default HTML layout' do
        result = service.send(:default_layout)
        
        expect(result).to include('<!DOCTYPE html>')
        expect(result).to include('<html>')
        expect(result).to include('<title>{{ page.title }}</title>')
        expect(result).to include('<meta name="description" content="{{ page.description }}">')
        expect(result).to include('<link rel="stylesheet" href="/assets/theme.css">')
        expect(result).to include('{{ content_for_layout }}')
        expect(result).to include('<script src="/assets/theme.js"></script>')
      end
    end
  end
end
