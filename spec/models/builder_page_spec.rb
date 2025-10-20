require 'rails_helper'

RSpec.describe BuilderPage, type: :model do
  let(:tenant) { create(:tenant) }
  let(:builder_theme) { create(:builder_theme, tenant: tenant) }
  let(:builder_page) { build(:builder_page, builder_theme: builder_theme, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:builder_theme) }
    it { should have_many(:builder_page_sections).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:template_name) }
    it { should validate_presence_of(:page_title) }
    it { should validate_presence_of(:tenant) }
    it { should validate_presence_of(:builder_theme) }
    
    it 'validates uniqueness of template_name scoped to builder_theme' do
      create(:builder_page, template_name: 'home', builder_theme: builder_theme, tenant: tenant)
      duplicate_page = build(:builder_page, template_name: 'home', builder_theme: builder_theme, tenant: tenant)
      expect(duplicate_page).not_to be_valid
      expect(duplicate_page.errors[:template_name]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    # describe '.ordered' do
    #   it 'orders pages by position' do
    #     fresh_theme = create(:builder_theme, tenant: tenant)
    #     page1 = create(:builder_page, builder_theme: fresh_theme, tenant: tenant, position: 2, template_name: 'page1')
    #     page2 = create(:builder_page, builder_theme: fresh_theme, tenant: tenant, position: 1, template_name: 'page2')
    #     
    #     ordered_pages = BuilderPage.where(builder_theme: fresh_theme).ordered
    #     expect(ordered_pages.first).to eq(page2)
    #     expect(ordered_pages.last).to eq(page1)
    #   end
    # end

    describe '.published' do
      it 'returns only published pages' do
        fresh_theme = create(:builder_theme, tenant: tenant)
        published_page = create(:builder_page, builder_theme: fresh_theme, tenant: tenant, published: true, template_name: 'published')
        unpublished_page = create(:builder_page, builder_theme: fresh_theme, tenant: tenant, published: false, template_name: 'unpublished')
        
        published_pages = BuilderPage.where(builder_theme: fresh_theme).published
        expect(published_pages).to include(published_page)
        expect(published_pages).not_to include(unpublished_page)
      end
    end

    # describe '.by_template' do
    #   it 'returns pages with specific template' do
    #     fresh_theme = create(:builder_theme, tenant: tenant)
    #     home_page = create(:builder_page, template_name: 'home', builder_theme: fresh_theme, tenant: tenant)
    #     blog_page = create(:builder_page, template_name: 'blog', builder_theme: fresh_theme, tenant: tenant)
    #     
    #     home_pages = BuilderPage.where(builder_theme: fresh_theme).by_template('home')
    #     expect(home_pages).to include(home_page)
    #     expect(home_pages).not_to include(blog_page)
    #   end
    # end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets default values' do
        page = BuilderPage.new(builder_theme: builder_theme, tenant: tenant, template_name: 'test', page_title: 'Test')
        page.valid?
        
        expect(page.settings).to eq({})
        expect(page.sections).to eq({})
        expect(page.position).to eq(0)
        expect(page.published).to be false
      end
    end
  end

  # describe 'class methods' do
  #   describe '.create_page' do
  #     it 'creates a page with correct attributes' do
  #       fresh_theme = create(:builder_theme, tenant: tenant)
  #       page = BuilderPage.create_page(fresh_theme, 'home', 'Home Page', { 'color' => 'blue' }, { 'header' => {} })
  #       
  #       expect(page.builder_theme).to eq(fresh_theme)
  #       expect(page.tenant).to eq(tenant)
  #       expect(page.template_name).to eq('home')
  #       expect(page.page_title).to eq('Home Page')
  #       expect(page.settings).to eq({ 'color' => 'blue' })
  #       expect(page.sections).to eq({ 'header' => {} })
  #       expect(page.position).to eq(0)
  #     end
  #   end

  #   describe '.initialize_default_pages' do
  #     it 'creates default pages for a theme' do
  #       fresh_theme = create(:builder_theme, tenant: tenant)
  #       BuilderPage.initialize_default_pages(fresh_theme)
  #       
  #       expect(fresh_theme.builder_pages.count).to eq(5)
  #       expect(fresh_theme.builder_pages.pluck(:template_name)).to include('index', 'blog', 'post', 'page', 'search')
  #     end

  #     it 'does not create duplicate pages' do
  #       fresh_theme = create(:builder_theme, tenant: tenant)
  #       create(:builder_page, template_name: 'index', builder_theme: fresh_theme, tenant: tenant)
  #       BuilderPage.initialize_default_pages(fresh_theme)
  #       
  #       expect(fresh_theme.builder_pages.where(template_name: 'index').count).to eq(1)
  #     end
  #   end
  # end

  describe 'instance methods' do
    let(:page) { create(:builder_page, builder_theme: builder_theme, tenant: tenant, page_title: 'Test Page', template_name: 'home', sections: { 'header' => {}, 'footer' => {} }) }

    describe '#display_name' do
      it 'returns page title' do
        expect(page.display_name).to eq('Test Page')
      end
    end

    describe '#description' do
      it 'returns description with template and section count' do
        expect(page.description).to eq('Home page with 2 sections')
      end
    end

    describe '#section_order' do
      it 'returns section keys' do
        expect(page.section_order).to eq(['header', 'footer'])
      end
    end

    describe '#get_setting' do
      it 'returns setting value' do
        page.update!(settings: { 'color' => 'blue' })
        expect(page.get_setting('color')).to eq('blue')
        expect(page.get_setting('size', 'large')).to eq('large')
      end
    end

    describe '#set_setting' do
      it 'sets setting value' do
        page.set_setting('color', 'red')
        expect(page.settings['color']).to eq('red')
      end
    end

    describe '#get_section_settings' do
      it 'returns section settings' do
        page.update!(sections: { 'header' => { 'height' => '100px' } })
        expect(page.get_section_settings('header')).to eq({ 'height' => '100px' })
        expect(page.get_section_settings('footer')).to eq({})
      end
    end

    describe '#set_section_settings' do
      it 'sets section settings' do
        page.set_section_settings('header', { 'height' => '120px' })
        expect(page.sections['header']).to eq({ 'height' => '120px' })
      end
    end

    describe '#add_section' do
      it 'adds a new section' do
        page.add_section('sidebar', { 'width' => '300px' })
        expect(page.sections['sidebar']).to eq({ 'width' => '300px' })
      end
    end

    describe '#remove_section' do
      it 'removes a section' do
        page.remove_section('header')
        expect(page.sections).not_to have_key('header')
      end
    end

    describe '#reorder_sections' do
      it 'reorders sections' do
        page.update!(sections: { 'header' => {}, 'content' => {}, 'footer' => {} })
        page.reorder_sections(['footer', 'header', 'content'])
        
        expect(page.section_order).to eq(['footer', 'header', 'content'])
      end
    end

    describe '#sections_data' do
      it 'returns formatted sections data' do
        page.update!(sections: { 'header' => { 'height' => '100px' } })
        data = page.sections_data
        
        expect(data).to include({
          'id' => 'header',
          'type' => 'header',
          'settings' => { 'height' => '100px' }
        })
      end
    end

    describe '#template_file_path' do
      it 'returns template file path' do
        expect(page.template_file_path).to eq('templates/home.json')
      end
    end

    describe '#template_content' do
      it 'returns default template structure when file does not exist' do
        content = page.template_content
        
        expect(content).to include('sections', 'order', 'settings')
        expect(content['sections']).to eq(page.sections)
        expect(content['order']).to eq(page.section_order)
        expect(content['settings']).to eq(page.settings)
      end
    end

    describe '#publish!' do
      it 'publishes the page' do
        page.publish!
        expect(page.published).to be true
      end
    end

    describe '#unpublish!' do
      it 'unpublishes the page' do
        page.update!(published: true)
        page.unpublish!
        expect(page.published).to be false
      end
    end
  end
end
