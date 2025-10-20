require 'rails_helper'

RSpec.describe FrontendRendererService, type: :service do
  let(:theme) { create(:theme) }
  let(:published_version) { create(:published_theme_version, theme: theme) }
  let(:service) { FrontendRendererService.new(published_version) }

  describe '#initialize' do
    it 'sets the published version' do
      expect(service.published_version).to eq(published_version)
    end

    it 'creates a builder renderer' do
      expect(service.builder_renderer).to be_present
    end

    it 'creates a mock builder theme' do
      expect(service.instance_variable_get(:@builder_theme)).to be_present
    end
  end

  describe '#render_template' do
    let(:template_name) { 'index' }
    let(:context) { { page: { title: 'Test Page' } } }

    before do
      # Create template file
      create(:published_theme_file, 
        published_theme_version: published_version,
        file_path: 'templates/index.json',
        content: '{"order": ["header", "content"], "sections": {"header": {"type": "header", "settings": {}}, "content": {"type": "text", "settings": {"text": "Hello World"}}}}'
      )

      # Create layout file
      create(:published_theme_file,
        published_theme_version: published_version,
        file_path: 'layout/theme.liquid',
        content: '<html><head><title>{{ page.title }}</title></head><body>{{ content_for_layout }}</body></html>'
      )

      # Create section files
      create(:published_theme_file,
        published_theme_version: published_version,
        file_path: 'sections/header.liquid',
        content: '<header>Header Section</header>'
      )

      create(:published_theme_file,
        published_theme_version: published_version,
        file_path: 'sections/text.liquid',
        content: '<div class="text-section">{{ section.settings.text }}</div>'
      )
    end

    it 'renders template successfully' do
      result = service.render_template(template_name, context)
      
      expect(result).to include('<html>')
      expect(result).to include('<title>Test Page</title>')
      expect(result).to include('<header>Header Section</header>')
      expect(result).to include('<div class="text-section">Hello World</div>')
    end

    it 'handles missing template gracefully' do
      result = service.render_template('nonexistent', context)
      
      expect(result).to include('FrontendRendererService Error')
    end

    it 'handles rendering errors gracefully' do
      allow_any_instance_of(BuilderLiquidRenderer).to receive(:render_template).and_raise(StandardError.new('Render error'))
      
      result = service.render_template(template_name, context)
      
      expect(result).to include('FrontendRendererService Error: Render error')
    end
  end

  describe '#assets' do
    it 'returns assets from builder renderer' do
      assets = service.assets
      
      expect(assets).to be_a(Hash)
      expect(assets).to have_key(:css)
      expect(assets).to have_key(:js)
    end
  end

  describe 'private methods' do
    describe '#replace_asset_urls_with_content' do
      let(:html_with_css) { '<link href="/theme.css" rel="stylesheet">' }
      let(:html_with_js) { '<script src="/theme.js"></script>' }

      before do
        allow(service.builder_renderer).to receive(:assets).and_return({
          css: 'body { color: red; }',
          js: 'console.log("test");'
        })
      end

      it 'replaces CSS link tags with embedded styles' do
        result = service.send(:replace_asset_urls_with_content, html_with_css)
        
        expect(result).to include('<style>body { color: red; }</style>')
        expect(result).not_to include('<link href="/theme.css"')
      end

      it 'replaces JS script tags with embedded scripts' do
        result = service.send(:replace_asset_urls_with_content, html_with_js)
        
        expect(result).to include('<script>console.log("test");</script>')
        expect(result).not_to include('<script src="/theme.js"')
      end

      it 'handles missing assets gracefully' do
        allow(service.builder_renderer).to receive(:assets).and_return({ css: nil, js: nil })
        
        result = service.send(:replace_asset_urls_with_content, html_with_css)
        
        expect(result).to eq(html_with_css)
      end

      it 'handles errors gracefully' do
        allow(service.builder_renderer).to receive(:assets).and_raise(StandardError.new('Asset error'))
        
        result = service.send(:replace_asset_urls_with_content, html_with_css)
        
        expect(result).to eq(html_with_css)
      end
    end

    describe '#create_mock_builder_theme' do
      it 'creates a mock theme object' do
        mock_theme = service.send(:create_mock_builder_theme)
        
        expect(mock_theme).to be_present
        expect(mock_theme).to respond_to(:get_rendered_file)
        expect(mock_theme).to respond_to(:theme_name)
        expect(mock_theme).to respond_to(:id)
      end

      it 'returns template data for existing templates' do
        create(:published_theme_file,
          published_theme_version: published_version,
          file_path: 'templates/index.json',
          content: '{"order": ["header"], "sections": {"header": {"type": "header"}}}'
        )

        mock_theme = service.send(:create_mock_builder_theme)
        result = mock_theme.get_rendered_file('index')
        
        expect(result).to be_a(Hash)
        expect(result[:template_name]).to eq('index')
        expect(result[:template_content]).to be_present
        expect(result[:page_sections]).to be_an(Array)
      end

      it 'returns nil for non-existent templates' do
        mock_theme = service.send(:create_mock_builder_theme)
        result = mock_theme.get_rendered_file('nonexistent')
        
        expect(result).to be_nil
      end
    end

    describe '#default_layout' do
      it 'returns default HTML layout' do
        layout = FrontendRendererService.default_layout
        
        expect(layout).to include('<!DOCTYPE html>')
        expect(layout).to include('<html lang="en">')
        expect(layout).to include('{{ page.title | default: site.title }}')
        expect(layout).to include('{{ content_for_layout }}')
      end
    end
  end
end
