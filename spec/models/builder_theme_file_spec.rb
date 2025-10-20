require 'rails_helper'

RSpec.describe BuilderThemeFile, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:builder_theme) { create(:builder_theme, tenant: tenant, user: user) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:builder_theme) }
  end

  describe 'validations' do
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:checksum) }
    it { should validate_presence_of(:builder_theme) }
    
    it 'validates uniqueness of path scoped to builder_theme' do
      existing_file = create(:builder_theme_file, builder_theme: builder_theme, tenant: tenant)
      duplicate_file = build(:builder_theme_file, path: existing_file.path, builder_theme: builder_theme, tenant: tenant)
      expect(duplicate_file).not_to be_valid
      expect(duplicate_file.errors[:path]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:liquid_file) { create(:builder_theme_file, path: 'templates/page.liquid', builder_theme: builder_theme, tenant: tenant) }
    let!(:json_file) { create(:builder_theme_file, path: 'settings.json', builder_theme: builder_theme, tenant: tenant) }
    let!(:css_file) { create(:builder_theme_file, path: 'assets/style.css', builder_theme: builder_theme, tenant: tenant) }
    let!(:js_file) { create(:builder_theme_file, path: 'assets/script.js', builder_theme: builder_theme, tenant: tenant) }
    let!(:section_file) { create(:builder_theme_file, path: 'sections/header.liquid', builder_theme: builder_theme, tenant: tenant) }
    let!(:template_file) { create(:builder_theme_file, path: 'templates/product.json', builder_theme: builder_theme, tenant: tenant) }
    let!(:snippet_file) { create(:builder_theme_file, path: 'snippets/navigation.liquid', builder_theme: builder_theme, tenant: tenant) }
    let!(:layout_file) { create(:builder_theme_file, path: 'layout/theme.liquid', builder_theme: builder_theme, tenant: tenant) }

    describe '.liquid_files' do
      it 'returns only liquid files' do
        liquid_files = BuilderThemeFile.liquid_files
        expect(liquid_files).to include(liquid_file, section_file, snippet_file, layout_file)
        expect(liquid_files).not_to include(json_file, css_file, js_file, template_file)
      end
    end

    describe '.json_files' do
      it 'returns only json files' do
        json_files = BuilderThemeFile.json_files
        expect(json_files).to include(json_file, template_file)
        expect(json_files).not_to include(liquid_file, css_file, js_file, section_file, snippet_file, layout_file)
      end
    end

    describe '.css_files' do
      it 'returns only css files' do
        css_files = BuilderThemeFile.css_files
        expect(css_files).to include(css_file)
        expect(css_files).not_to include(liquid_file, json_file, js_file, section_file, template_file, snippet_file, layout_file)
      end
    end

    describe '.js_files' do
      it 'returns only js files' do
        js_files = BuilderThemeFile.js_files
        expect(js_files).to include(js_file)
        expect(js_files).not_to include(liquid_file, json_file, css_file, section_file, template_file, snippet_file, layout_file)
      end
    end

    describe '.sections' do
      it 'returns only section files' do
        sections = BuilderThemeFile.sections
        expect(sections).to include(section_file)
        expect(sections).not_to include(liquid_file, json_file, css_file, js_file, template_file, snippet_file, layout_file)
      end
    end

    describe '.templates' do
      it 'returns only template files' do
        templates = BuilderThemeFile.templates
        expect(templates).to include(template_file)
        expect(templates).not_to include(liquid_file, json_file, css_file, js_file, section_file, snippet_file, layout_file)
      end
    end

    describe '.snippets' do
      it 'returns only snippet files' do
        snippets = BuilderThemeFile.snippets
        expect(snippets).to include(snippet_file)
        expect(snippets).not_to include(liquid_file, json_file, css_file, js_file, section_file, template_file, layout_file)
      end
    end

    describe '.layouts' do
      it 'returns only layout files' do
        layouts = BuilderThemeFile.layouts
        expect(layouts).to include(layout_file)
        expect(layouts).not_to include(liquid_file, json_file, css_file, js_file, section_file, template_file, snippet_file)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation :generate_checksum' do
      it 'generates checksum on create' do
        file = build(:builder_theme_file, builder_theme: builder_theme, tenant: tenant)
        expect(file.checksum).to be_nil
        file.save!
        expect(file.checksum).to be_present
      end
    end

    describe 'before_validation :calculate_file_size' do
      it 'calculates file size on create' do
        file = build(:builder_theme_file, builder_theme: builder_theme, tenant: tenant)
        expect(file.file_size).to be_nil
        file.save!
        expect(file.file_size).to be_present
      end
    end
  end

  describe 'class methods' do
    describe '.editable_extensions' do
      it 'returns array of editable file extensions' do
        extensions = BuilderThemeFile.editable_extensions
        expect(extensions).to include('.liquid', '.json', '.css', '.js', '.html', '.md', '.yml', '.yaml')
      end
    end
  end

  describe 'instance methods' do
    let(:theme_file) { create(:builder_theme_file, builder_theme: builder_theme, tenant: tenant) }

    describe '#editable?' do
      it 'returns true for editable file extensions' do
        BuilderThemeFile.editable_extensions.each do |ext|
          file = build(:builder_theme_file, path: "test#{ext}", builder_theme: builder_theme, tenant: tenant)
          expect(file.editable?).to be true
        end
      end

      it 'returns false for non-editable file extensions' do
        file = build(:builder_theme_file, path: 'test.txt', builder_theme: builder_theme, tenant: tenant)
        expect(file.editable?).to be false
      end
    end

    describe '#file_type' do
      it 'returns correct file type for liquid files' do
        file = build(:builder_theme_file, path: 'test.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.file_type).to eq('liquid')
      end

      it 'returns correct file type for json files' do
        file = build(:builder_theme_file, path: 'test.json', builder_theme: builder_theme, tenant: tenant)
        expect(file.file_type).to eq('json')
      end

      it 'returns correct file type for css files' do
        file = build(:builder_theme_file, path: 'test.css', builder_theme: builder_theme, tenant: tenant)
        expect(file.file_type).to eq('css')
      end

      it 'returns correct file type for js files' do
        file = build(:builder_theme_file, path: 'test.js', builder_theme: builder_theme, tenant: tenant)
        expect(file.file_type).to eq('javascript')
      end

      it 'returns text for other file types' do
        file = build(:builder_theme_file, path: 'test.txt', builder_theme: builder_theme, tenant: tenant)
        expect(file.file_type).to eq('text')
      end
    end

    describe '#section_name' do
      it 'returns section name for section files' do
        file = build(:builder_theme_file, path: 'sections/header.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.section_name).to eq('header')
      end

      it 'returns nil for non-section files' do
        file = build(:builder_theme_file, path: 'templates/page.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.section_name).to be_nil
      end
    end

    describe '#template_name' do
      it 'returns template name for template files' do
        file = build(:builder_theme_file, path: 'templates/product.json', builder_theme: builder_theme, tenant: tenant)
        expect(file.template_name).to eq('product')
      end

      it 'returns nil for non-template files' do
        file = build(:builder_theme_file, path: 'sections/header.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.template_name).to be_nil
      end
    end

    describe '#snippet_name' do
      it 'returns snippet name for snippet files' do
        file = build(:builder_theme_file, path: 'snippets/navigation.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.snippet_name).to eq('navigation')
      end

      it 'returns nil for non-snippet files' do
        file = build(:builder_theme_file, path: 'sections/header.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.snippet_name).to be_nil
      end
    end

    describe '#layout_name' do
      it 'returns layout name for layout files' do
        file = build(:builder_theme_file, path: 'layout/theme.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.layout_name).to eq('theme')
      end

      it 'returns nil for non-layout files' do
        file = build(:builder_theme_file, path: 'sections/header.liquid', builder_theme: builder_theme, tenant: tenant)
        expect(file.layout_name).to be_nil
      end
    end
  end
end
