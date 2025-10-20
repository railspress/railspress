require 'rails_helper'

RSpec.describe User, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { build(:user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant).optional }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:pages).dependent(:destroy) }
    it { should have_many(:media).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:api_tokens).dependent(:destroy) }
    it { should have_many(:ai_usages).dependent(:destroy) }
    it { should have_many(:oauth_accounts).dependent(:destroy) }
    it { should have_many(:meta_fields).dependent(:destroy) }
    it { should have_one_attached(:avatar) }
  end

  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:editor_preference).in_array(User::EDITOR_OPTIONS).allow_nil }
    it { should validate_inclusion_of(:monaco_theme).in_array(User::MONACO_THEMES).allow_nil }
    it { should validate_uniqueness_of(:api_key).allow_nil }
  end

  describe 'enums' do
    it 'defines role enum' do
      expect(User.roles).to eq({
        'subscriber' => 0,
        'contributor' => 1,
        'author' => 2,
        'editor' => 3,
        'administrator' => 4
      })
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default role for new records' do
        user = User.new
        expect(user.role).to eq('subscriber')
      end
    end

    describe 'before_create' do
      it 'generates api token and key' do
        user = build(:user, tenant: tenant)
        user.save!
        
        expect(user.api_token).to be_present
        expect(user.api_key).to be_present
        expect(user.api_key).to start_with('sk-')
        expect(user.api_requests_count).to eq(0)
        expect(user.api_requests_reset_at).to be_present
      end
    end
  end

  describe 'role helper methods' do
    let(:admin_user) { create(:user, role: :administrator, tenant: tenant) }
    let(:editor_user) { create(:user, role: :editor, tenant: tenant) }
    let(:author_user) { create(:user, role: :author, tenant: tenant) }
    let(:contributor_user) { create(:user, role: :contributor, tenant: tenant) }
    let(:subscriber_user) { create(:user, role: :subscriber, tenant: tenant) }

    describe '#admin?' do
      it 'returns true for administrator' do
        expect(admin_user.admin?).to be true
        expect(editor_user.admin?).to be false
      end
    end

    describe '#can_publish?' do
      it 'returns true for author, editor, and administrator' do
        expect(author_user.can_publish?).to be true
        expect(editor_user.can_publish?).to be true
        expect(admin_user.can_publish?).to be true
        expect(contributor_user.can_publish?).to be false
        expect(subscriber_user.can_publish?).to be false
      end
    end

    describe '#can_edit_others_posts?' do
      it 'returns true for editor and administrator' do
        expect(editor_user.can_edit_others_posts?).to be true
        expect(admin_user.can_edit_others_posts?).to be true
        expect(author_user.can_edit_others_posts?).to be false
      end
    end

    describe '#can_delete_posts?' do
      it 'returns true only for administrator' do
        expect(admin_user.can_delete_posts?).to be true
        expect(editor_user.can_delete_posts?).to be false
      end
    end

    describe '#can_manage_plugins?' do
      it 'returns true for administrator and editor' do
        expect(admin_user.can_manage_plugins?).to be true
        expect(editor_user.can_manage_plugins?).to be true
        expect(author_user.can_manage_plugins?).to be false
      end
    end

    describe '#can_manage_themes?' do
      it 'returns true only for administrator' do
        expect(admin_user.can_manage_themes?).to be true
        expect(editor_user.can_manage_themes?).to be false
      end
    end

    describe '#can_manage_settings?' do
      it 'returns true only for administrator' do
        expect(admin_user.can_manage_settings?).to be true
        expect(editor_user.can_manage_settings?).to be false
      end
    end

    describe '#can_manage_users?' do
      it 'returns true only for administrator' do
        expect(admin_user.can_manage_users?).to be true
        expect(editor_user.can_manage_users?).to be false
      end
    end

    describe '#can_create_posts?' do
      it 'returns true for administrator, editor, and author' do
        expect(admin_user.can_create_posts?).to be true
        expect(editor_user.can_create_posts?).to be true
        expect(author_user.can_create_posts?).to be true
        expect(contributor_user.can_create_posts?).to be false
      end
    end

    describe '#can_create_pages?' do
      it 'returns true for administrator and editor' do
        expect(admin_user.can_create_pages?).to be true
        expect(editor_user.can_create_pages?).to be true
        expect(author_user.can_create_pages?).to be false
      end
    end

    describe '#can_upload_media?' do
      it 'returns true for administrator, editor, and author' do
        expect(admin_user.can_upload_media?).to be true
        expect(editor_user.can_upload_media?).to be true
        expect(author_user.can_upload_media?).to be true
        expect(contributor_user.can_upload_media?).to be false
      end
    end

    describe '#can_upload_files?' do
      it 'returns true for administrator, editor, and author' do
        expect(admin_user.can_upload_files?).to be true
        expect(editor_user.can_upload_files?).to be true
        expect(author_user.can_upload_files?).to be true
        expect(contributor_user.can_upload_files?).to be false
      end
    end
  end

  describe 'preference methods' do
    let(:user) { create(:user, tenant: tenant) }

    describe '#preferred_editor' do
      it 'returns editor preference or default' do
        expect(user.preferred_editor).to eq('blocknote')
        
        user.update!(editor_preference: 'trix')
        expect(user.preferred_editor).to eq('trix')
      end
    end

    describe '#preferred_monaco_theme' do
      it 'returns monaco theme or default' do
        expect(user.preferred_monaco_theme).to eq('auto')
        
        user.update!(monaco_theme: 'dark')
        expect(user.preferred_monaco_theme).to eq('dark')
      end
    end

    describe '#sidebar_order' do
      it 'returns default sidebar order' do
        expect(user.sidebar_order).to eq(['publish', 'featured-image', 'categories-tags', 'excerpt', 'seo'])
      end

      it 'returns custom sidebar order' do
        user.update!(sidebar_order: ['seo', 'publish'])
        expect(user.sidebar_order).to eq(['seo', 'publish'])
      end

      it 'handles invalid JSON gracefully' do
        user.update_column(:sidebar_order, 'invalid json')
        expect(user.sidebar_order).to eq(['publish', 'featured-image', 'categories-tags', 'excerpt', 'seo'])
      end
    end

    describe '#sidebar_order=' do
      it 'accepts array and converts to JSON' do
        user.sidebar_order = ['seo', 'publish']
        expect(user.read_attribute(:sidebar_order)).to eq('["seo","publish"]')
      end

      it 'accepts JSON string' do
        user.sidebar_order = '["seo","publish"]'
        expect(user.read_attribute(:sidebar_order)).to eq('["seo","publish"]')
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user, tenant: tenant) }

    describe '#regenerate_api_token!' do
      it 'updates api token' do
        old_token = user.api_token
        user.regenerate_api_token!
        expect(user.api_token).not_to eq(old_token)
      end
    end

    describe '#rate_limit_exceeded?' do
      it 'returns false when no reset time set' do
        user.update!(api_requests_reset_at: nil)
        expect(user.rate_limit_exceeded?).to be false
      end

      it 'returns false when reset time has passed' do
        user.update!(api_requests_reset_at: 1.hour.ago)
        expect(user.rate_limit_exceeded?).to be false
      end

      it 'returns false when under limit' do
        user.update!(api_requests_count: 500, api_requests_reset_at: 1.hour.from_now)
        expect(user.rate_limit_exceeded?).to be false
      end

      it 'returns true when over limit' do
        user.update!(api_requests_count: 1000, api_requests_reset_at: 1.hour.from_now)
        expect(user.rate_limit_exceeded?).to be true
      end
    end

    describe '#increment_api_request!' do
      it 'increments request count' do
        expect { user.increment_api_request! }.to change { user.api_requests_count }.by(1)
      end

      it 'sets reset time if not set' do
        user.update!(api_requests_reset_at: nil)
        user.increment_api_request!
        expect(user.api_requests_reset_at).to be_present
      end
    end

    describe '#regenerate_api_key!' do
      it 'generates new api key' do
        old_key = user.api_key
        user.regenerate_api_key!
        expect(user.api_key).not_to eq(old_key)
        expect(user.api_key).to start_with('sk-')
      end
    end
  end

  describe 'constants' do
    it 'defines EDITOR_OPTIONS' do
      expect(User::EDITOR_OPTIONS).to eq(%w[blocknote trix ckeditor editorjs])
    end

    it 'defines MONACO_THEMES' do
      expect(User::MONACO_THEMES).to eq(%w[auto dark light blue])
    end
  end
end
