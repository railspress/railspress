require 'rails_helper'

RSpec.describe BuilderTheme, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:theme) { create(:theme, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:user) }
    it { should belong_to(:parent_version).class_name('BuilderTheme').optional }
    it { should have_many(:child_versions).class_name('BuilderTheme').with_foreign_key('parent_version_id').dependent(:nullify) }
    it { should have_many(:builder_theme_files).dependent(:destroy) }
    it { should have_many(:builder_theme_sections).dependent(:destroy) }
    it { should have_many(:builder_pages).dependent(:destroy) }
    it { should have_many(:builder_theme_snapshots).dependent(:destroy) }
    it { should have_many(:theme_previews).dependent(:destroy) }
    it { should have_many(:theme_preview_files).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:theme_name) }
    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:user) }
    
    it 'validates uniqueness of checksum' do
      existing_theme = create(:builder_theme, tenant: tenant, user: user)
      duplicate_theme = build(:builder_theme, checksum: existing_theme.checksum, tenant: tenant, user: user)
      expect(duplicate_theme).not_to be_valid
      expect(duplicate_theme.errors[:checksum]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:published_theme) { create(:builder_theme, published: true, theme_name: 'theme-1', label: 'Version 1', tenant: tenant, user: user) }
    let!(:draft_theme) { create(:builder_theme, published: false, theme_name: 'theme-2', label: 'Version 2', tenant: tenant, user: user) }

    describe '.published' do
      it 'returns only published themes' do
        expect(BuilderTheme.published).to include(published_theme)
        expect(BuilderTheme.published).not_to include(draft_theme)
      end
    end

    describe '.drafts' do
      it 'returns only draft themes' do
        expect(BuilderTheme.drafts).to include(draft_theme)
        expect(BuilderTheme.drafts).not_to include(published_theme)
      end
    end

    describe '.for_theme' do
      it 'returns themes for specific theme name' do
        themes = BuilderTheme.for_theme(published_theme.theme_name)
        expect(themes).to include(published_theme)
        expect(themes).not_to include(draft_theme) if draft_theme.theme_name != published_theme.theme_name
      end
    end

    describe '.latest' do
      it 'orders themes by creation date descending' do
        themes = BuilderTheme.latest
        expect(themes.first).to eq(themes.max_by(&:created_at))
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation :generate_checksum' do
      it 'generates checksum on create' do
        theme = build(:builder_theme, tenant: tenant, user: user)
        expect(theme.checksum).to be_nil
        theme.save!
        expect(theme.checksum).to be_present
      end
    end

    describe 'after_create :initialize_default_pages' do
      it 'initializes default pages after creation' do
        expect_any_instance_of(BuilderTheme).to receive(:initialize_default_pages)
        create(:builder_theme, tenant: tenant, user: user)
      end
    end
  end

  describe 'instance methods' do
    let(:builder_theme) { create(:builder_theme, tenant: tenant, user: user, theme_name: theme.name) }

    describe '#theme' do
      it 'returns the associated theme' do
        expect(builder_theme.theme).to eq(theme)
      end

      it 'returns nil if no theme found' do
        builder_theme.update!(theme_name: 'nonexistent')
        expect(builder_theme.theme).to be_nil
      end
    end

    describe '#has_published_version?' do
      it 'returns true if theme has published version' do
        allow(builder_theme).to receive(:theme).and_return(theme)
        allow(PublishedThemeVersion).to receive(:for_theme).with(theme).and_return(double(exists?: true))
        expect(builder_theme.has_published_version?).to be true
      end

      it 'returns false if theme has no published version' do
        allow(builder_theme).to receive(:theme).and_return(theme)
        allow(PublishedThemeVersion).to receive(:for_theme).with(theme).and_return(double(exists?: false))
        expect(builder_theme.has_published_version?).to be false
      end
    end

    describe '#published_version' do
      it 'returns the latest published version' do
        published_version = double('PublishedThemeVersion')
        allow(builder_theme).to receive(:theme).and_return(theme)
        allow(PublishedThemeVersion).to receive(:for_theme).with(theme).and_return(double(latest: double(first: published_version)))
        expect(builder_theme.published_version).to eq(published_version)
      end
    end

    describe '#is_theme_active?' do
      it 'returns true if theme is active' do
        allow(builder_theme).to receive(:theme).and_return(theme)
        allow(theme).to receive(:active?).and_return(true)
        expect(builder_theme.is_theme_active?).to be true
      end

      it 'returns false if theme is not active' do
        allow(builder_theme).to receive(:theme).and_return(theme)
        allow(theme).to receive(:active?).and_return(false)
        expect(builder_theme.is_theme_active?).to be false
      end

      it 'returns nil if no theme' do
        allow(builder_theme).to receive(:theme).and_return(nil)
        expect(builder_theme.is_theme_active?).to be_nil
      end
    end

  end
end
