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
    it { should validate_uniqueness_of(:api_key).allow_nil }
    it { should validate_inclusion_of(:editor_preference).in_array(User::EDITOR_OPTIONS).allow_nil }
    it { should validate_inclusion_of(:monaco_theme).in_array(User::MONACO_THEMES).allow_nil }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(subscriber: 0, contributor: 1, author: 2, editor: 3, administrator: 4) }
  end

  describe 'devise configuration' do
    it 'includes devise modules' do
      expect(User.devise_modules).to include(:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable)
    end

    it 'configures omniauth providers' do
      expect(User.omniauth_providers).to include(:google_oauth2, :github, :facebook, :twitter)
    end
  end

  describe 'callbacks' do
    it 'sets default role on initialization' do
      new_user = User.new
      expect(new_user.role).to eq('subscriber')
    end

    it 'generates API token and key on create' do
      user.save!
      expect(user.api_token).to be_present
      expect(user.api_key).to be_present
      expect(user.api_requests_count).to eq(0)
      expect(user.api_requests_reset_at).to be_present
    end
  end

  describe 'role helper methods' do
    describe '#admin?' do
      it 'returns true for administrators' do
        user.role = :administrator
        expect(user.admin?).to be true
      end

      it 'returns false for non-administrators' do
        user.role = :author
        expect(user.admin?).to be false
      end
    end

    describe '#can_publish?' do
      it 'returns true for authors, editors, and administrators' do
        %w[author editor administrator].each do |role|
          user.role = role
          expect(user.can_publish?).to be true
        end
      end

      it 'returns false for subscribers and contributors' do
        %w[subscriber contributor].each do |role|
          user.role = role
          expect(user.can_publish?).to be false
        end
      end
    end

    describe '#can_edit_others_posts?' do
      it 'returns true for editors and administrators' do
        %w[editor administrator].each do |role|
          user.role = role
          expect(user.can_edit_others_posts?).to be true
        end
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author].each do |role|
          user.role = role
          expect(user.can_edit_others_posts?).to be false
        end
      end
    end

    describe '#can_delete_posts?' do
      it 'returns true only for administrators' do
        user.role = :administrator
        expect(user.can_delete_posts?).to be true
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author editor].each do |role|
          user.role = role
          expect(user.can_delete_posts?).to be false
        end
      end
    end
  end

  describe 'editor preferences' do
    describe '#preferred_editor' do
      it 'returns editor_preference if set' do
        user.editor_preference = 'trix'
        expect(user.preferred_editor).to eq('trix')
      end

      it 'returns blocknote as default' do
        user.editor_preference = nil
        expect(user.preferred_editor).to eq('blocknote')
      end
    end

    describe '#preferred_monaco_theme' do
      it 'returns monaco_theme if set' do
        user.monaco_theme = 'dark'
        expect(user.preferred_monaco_theme).to eq('dark')
      end

      it 'returns auto as default' do
        user.monaco_theme = nil
        expect(user.preferred_monaco_theme).to eq('auto')
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user, tenant: tenant) }

    describe '#regenerate_api_token!' do
      it 'updates the API token' do
        old_token = user.api_token
        user.regenerate_api_token!
        expect(user.api_token).not_to eq(old_token)
      end
    end

    describe '#rate_limit_exceeded?' do
      it 'returns false when reset time has passed' do
        user.update!(api_requests_reset_at: 1.hour.ago, api_requests_count: 1000)
        expect(user.rate_limit_exceeded?).to be false
        expect(user.reload.api_requests_count).to eq(0)
      end

      it 'returns true when rate limit is exceeded' do
        user.update!(api_requests_reset_at: 1.hour.from_now, api_requests_count: 1000)
        expect(user.rate_limit_exceeded?).to be true
      end

      it 'returns false when under rate limit' do
        user.update!(api_requests_reset_at: 1.hour.from_now, api_requests_count: 500)
        expect(user.rate_limit_exceeded?).to be false
      end
    end

    describe '#increment_api_request!' do
      it 'increments the request count' do
        initial_count = user.api_requests_count
        user.increment_api_request!
        expect(user.reload.api_requests_count).to eq(initial_count + 1)
      end

      it 'resets count when reset time has passed' do
        user.update!(api_requests_reset_at: 1.hour.ago, api_requests_count: 100)
        user.increment_api_request!
        expect(user.reload.api_requests_count).to eq(1)
      end
    end
  end

  describe 'permission methods' do
    describe '#can_manage_plugins?' do
      it 'returns true for administrators and editors' do
        %w[administrator editor].each do |role|
          user.role = role
          expect(user.can_manage_plugins?).to be true
        end
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author].each do |role|
          user.role = role
          expect(user.can_manage_plugins?).to be false
        end
      end
    end

    describe '#can_manage_themes?' do
      it 'returns true only for administrators' do
        user.role = :administrator
        expect(user.can_manage_themes?).to be true
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author editor].each do |role|
          user.role = role
          expect(user.can_manage_themes?).to be false
        end
      end
    end

    describe '#can_manage_settings?' do
      it 'returns true only for administrators' do
        user.role = :administrator
        expect(user.can_manage_settings?).to be true
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author editor].each do |role|
          user.role = role
          expect(user.can_manage_settings?).to be false
        end
      end
    end

    describe '#can_manage_users?' do
      it 'returns true only for administrators' do
        user.role = :administrator
        expect(user.can_manage_users?).to be true
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author editor].each do |role|
          user.role = role
          expect(user.can_manage_users?).to be false
        end
      end
    end

    describe '#can_create_posts?' do
      it 'returns true for administrators, editors, and authors' do
        %w[administrator editor author].each do |role|
          user.role = role
          expect(user.can_create_posts?).to be true
        end
      end

      it 'returns false for subscribers and contributors' do
        %w[subscriber contributor].each do |role|
          user.role = role
          expect(user.can_create_posts?).to be false
        end
      end
    end

    describe '#can_create_pages?' do
      it 'returns true for administrators and editors' do
        %w[administrator editor].each do |role|
          user.role = role
          expect(user.can_create_pages?).to be true
        end
      end

      it 'returns false for other roles' do
        %w[subscriber contributor author].each do |role|
          user.role = role
          expect(user.can_create_pages?).to be false
        end
      end
    end

    describe '#can_upload_media?' do
      it 'returns true for administrators, editors, and authors' do
        %w[administrator editor author].each do |role|
          user.role = role
          expect(user.can_upload_media?).to be true
        end
      end

      it 'returns false for subscribers and contributors' do
        %w[subscriber contributor].each do |role|
          user.role = role
          expect(user.can_upload_media?).to be false
        end
      end
    end

    describe '#can_upload_files?' do
      it 'returns true for administrators, editors, and authors' do
        %w[administrator editor author].each do |role|
          user.role = role
          expect(user.can_upload_files?).to be true
        end
      end

      it 'returns false for subscribers and contributors' do
        %w[subscriber contributor].each do |role|
          user.role = role
          expect(user.can_upload_files?).to be false
        end
      end
    end
  end

  describe 'API key methods' do
    let(:user) { create(:user, tenant: tenant) }

    describe '#generate_api_key' do
      it 'generates a unique API key' do
        key1 = user.generate_api_key
        key2 = user.generate_api_key
        expect(key1).not_to eq(key2)
        expect(key1).to start_with('sk-')
        expect(key1.length).to be > 10
      end
    end

    describe '#regenerate_api_key!' do
      it 'updates the API key' do
        old_key = user.api_key
        user.regenerate_api_key!
        expect(user.api_key).not_to eq(old_key)
        expect(user.api_key).to start_with('sk-')
      end
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }

    it 'can belong to different tenants' do
      user1 = create(:user, tenant: tenant1)
      user2 = create(:user, tenant: tenant2)

      expect(user1.tenant).to eq(tenant1)
      expect(user2.tenant).to eq(tenant2)
    end

    it 'can exist without a tenant' do
      user = create(:user, tenant: nil)
      expect(user.tenant).to be_nil
    end
  end

  describe 'OAuth integration' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can have OAuth accounts' do
      oauth_account = create(:oauth_account, user: user, tenant: tenant)
      expect(user.oauth_accounts).to include(oauth_account)
    end

    it 'deletes OAuth accounts when user is destroyed' do
      oauth_account = create(:oauth_account, user: user, tenant: tenant)
      user.destroy
      expect(OauthAccount.find_by(id: oauth_account.id)).to be_nil
    end
  end

  describe 'API tokens' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can have multiple API tokens' do
      api_token = create(:api_token, user: user, tenant: tenant)
      expect(user.api_tokens).to include(api_token)
    end

    it 'deletes API tokens when user is destroyed' do
      api_token = create(:api_token, user: user, tenant: tenant)
      user.destroy
      expect(ApiToken.find_by(id: api_token.id)).to be_nil
    end
  end

  describe 'AI usage tracking' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can have AI usage records' do
      ai_usage = create(:ai_usage, user: user, tenant: tenant)
      expect(user.ai_usages).to include(ai_usage)
    end

    it 'deletes AI usage records when user is destroyed' do
      ai_usage = create(:ai_usage, user: user, tenant: tenant)
      user.destroy
      expect(AiUsage.find_by(id: ai_usage.id)).to be_nil
    end
  end

  describe 'content creation' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can create posts' do
      post = create(:post, user: user, tenant: tenant)
      expect(user.posts).to include(post)
    end

    it 'can create pages' do
      page = create(:page, user: user, tenant: tenant)
      expect(user.pages).to include(page)
    end

    it 'can create media' do
      medium = create(:medium, user: user, tenant: tenant)
      expect(user.media).to include(medium)
    end

    it 'can create comments' do
      comment = create(:comment, user: user, tenant: tenant)
      expect(user.comments).to include(comment)
    end
  end

  describe 'meta fields integration' do
    let(:user) { create(:user, tenant: tenant) }

    it 'includes metable functionality' do
      expect(user).to respond_to(:meta_fields)
      expect(user).to respond_to(:get_meta)
      expect(user).to respond_to(:set_meta)
    end

    it 'can have meta fields' do
      meta_field = create(:meta_field, metable: user, tenant: tenant)
      expect(user.meta_fields).to include(meta_field)
    end
  end

  describe 'avatar attachment' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can have an avatar attached' do
      expect(user).to respond_to(:avatar)
    end
  end

  describe 'devise authentication' do
    let(:user) { create(:user, tenant: tenant) }

    it 'can be authenticated with email and password' do
      expect(user.valid_password?('password123')).to be true
    end

    it 'can be registered' do
      expect(user).to be_persisted
    end

    it 'can be remembered' do
      expect(user).to respond_to(:remember_me)
    end

    it 'can recover password' do
      expect(user).to respond_to(:reset_password_token)
    end
  end
end
