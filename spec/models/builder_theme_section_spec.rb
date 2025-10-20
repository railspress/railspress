require 'rails_helper'

RSpec.describe BuilderThemeSection, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:builder_theme) { create(:builder_theme, tenant: tenant, user: user) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:builder_theme) }
  end

  describe 'validations' do
    it { should validate_presence_of(:section_id) }
    it { should validate_presence_of(:section_type) }
    it { should validate_presence_of(:settings) }
    it { should validate_presence_of(:tenant) }
    it { should validate_presence_of(:builder_theme) }
    it { should validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
    
    it 'validates uniqueness of section_id scoped to builder_theme' do
      existing_section = create(:builder_theme_section, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Test" })
      duplicate_section = build(:builder_theme_section, section_id: existing_section.section_id, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Test" })
      expect(duplicate_section).not_to be_valid
      expect(duplicate_section.errors[:section_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:section1) { create(:builder_theme_section, position: 2, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Section 1" }) }
    let!(:section2) { create(:builder_theme_section, position: 1, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Section 2" }) }
    let!(:section3) { create(:builder_theme_section, position: 3, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Section 3" }) }

    describe '.ordered' do
      it 'orders sections by position' do
        ordered_sections = BuilderThemeSection.ordered
        expect(ordered_sections.first).to eq(section2)
        expect(ordered_sections.last).to eq(section3)
      end
    end

    describe '.by_type' do
      it 'returns sections of specific type' do
        header_section = create(:builder_theme_section, section_type: 'header', builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Header" })
        footer_section = create(:builder_theme_section, section_type: 'footer', builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Footer" })
        
        header_sections = BuilderThemeSection.by_type('header')
        expect(header_sections).to include(header_section)
        expect(header_sections).not_to include(footer_section)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation :set_defaults' do
      it 'sets default values on create' do
        section = build(:builder_theme_section, builder_theme: builder_theme, tenant: tenant, settings: nil, position: nil)
        expect(section.settings).to be_nil
        expect(section.position).to be_nil
        section.save!
        expect(section.settings).to eq({})
        expect(section.position).to eq(0)
      end
    end
  end

  describe 'class methods' do
    describe '.create_section' do
      it 'creates a new section with default values' do
        section = BuilderThemeSection.create_section(builder_theme, 'header', { 'title' => 'My Header' })
        
        expect(section).to be_persisted
        expect(section.section_type).to eq('header')
        expect(section.section_id).to start_with('header_')
        expect(section.position).to eq(0)
        expect(section.settings).to include('title' => 'My Header')
      end

      it 'sets position based on existing sections count' do
        create(:builder_theme_section, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Existing" })
        section = BuilderThemeSection.create_section(builder_theme, 'footer', { 'title' => 'Footer' })
        
        expect(section.position).to eq(1)
      end
    end
  end

  describe 'instance methods' do
    let(:section) { create(:builder_theme_section, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Test Section" }) }

    describe '#settings=' do
      it 'sets settings data' do
        settings = { "colors" => { "primary" => "#007cba" } }
        section.settings = settings
        expect(section.settings).to eq(settings)
      end
    end

    describe '#settings' do
      it 'returns settings data' do
        settings = { "colors" => { "primary" => "#007cba" } }
        section.settings = settings
        expect(section.settings).to eq(settings)
      end
    end
  end

  describe 'serialization' do
    it 'serializes settings as JSON' do
      section = create(:builder_theme_section, builder_theme: builder_theme, tenant: tenant, settings: { "title" => "Test" })
      settings = { "colors" => { "primary" => "#007cba" }, "layout" => { "width" => "1200px" } }
      section.settings = settings
      section.save!
      
      reloaded_section = BuilderThemeSection.find(section.id)
      expect(reloaded_section.settings).to eq(settings)
    end
  end
end
