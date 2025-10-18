require 'rails_helper'

RSpec.describe OauthAccount, type: :model do
  let(:user) { create(:user) }
  let(:tenant) { create(:tenant) }
  let(:oauth_account) { build(:oauth_account, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:tenant) }
  end

  describe 'validations' do
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }

    it 'validates uniqueness of uid scoped to provider' do
      create(:oauth_account, provider: 'google_oauth2', uid: '123456789')
      duplicate = build(:oauth_account, provider: 'google_oauth2', uid: '123456789')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uid]).to include('has already been taken')
    end

    it 'allows same uid for different providers' do
      create(:oauth_account, provider: 'google_oauth2', uid: '123456789')
      different_provider = build(:oauth_account, provider: 'github', uid: '123456789')
      expect(different_provider).to be_valid
    end

    it 'validates email format' do
      oauth_account.email = 'invalid-email'
      expect(oauth_account).not_to be_valid
      expect(oauth_account.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email format' do
      oauth_account.email = 'user@example.com'
      expect(oauth_account).to be_valid
    end
  end

  describe 'scopes' do
    let!(:google_account) { create(:oauth_account, provider: 'google_oauth2') }
    let!(:github_account) { create(:oauth_account, provider: 'github') }
    let!(:facebook_account) { create(:oauth_account, provider: 'facebook') }
    let!(:twitter_account) { create(:oauth_account, provider: 'twitter') }

    describe '.by_provider' do
      it 'returns accounts for specific provider' do
        expect(OauthAccount.by_provider('google_oauth2')).to include(google_account)
        expect(OauthAccount.by_provider('google_oauth2')).not_to include(github_account)
      end
    end

    describe '.google' do
      it 'returns Google OAuth accounts' do
        expect(OauthAccount.google).to include(google_account)
        expect(OauthAccount.google).not_to include(github_account)
      end
    end

    describe '.github' do
      it 'returns GitHub OAuth accounts' do
        expect(OauthAccount.github).to include(github_account)
        expect(OauthAccount.github).not_to include(google_account)
      end
    end

    describe '.facebook' do
      it 'returns Facebook OAuth accounts' do
        expect(OauthAccount.facebook).to include(facebook_account)
        expect(OauthAccount.facebook).not_to include(google_account)
      end
    end

    describe '.twitter' do
      it 'returns Twitter OAuth accounts' do
        expect(OauthAccount.twitter).to include(twitter_account)
        expect(OauthAccount.twitter).not_to include(google_account)
      end
    end
  end

  describe 'instance methods' do
    describe '#provider_display_name' do
      it 'returns "Google" for google_oauth2' do
        oauth_account.provider = 'google_oauth2'
        expect(oauth_account.provider_display_name).to eq('Google')
      end

      it 'returns "GitHub" for github' do
        oauth_account.provider = 'github'
        expect(oauth_account.provider_display_name).to eq('GitHub')
      end

      it 'returns "Facebook" for facebook' do
        oauth_account.provider = 'facebook'
        expect(oauth_account.provider_display_name).to eq('Facebook')
      end

      it 'returns "Twitter" for twitter' do
        oauth_account.provider = 'twitter'
        expect(oauth_account.provider_display_name).to eq('Twitter')
      end

      it 'returns capitalized provider name for unknown providers' do
        oauth_account.provider = 'unknown_provider'
        expect(oauth_account.provider_display_name).to eq('Unknown_provider')
      end
    end

    describe '#provider_icon' do
      it 'returns Google icon URL for google_oauth2' do
        oauth_account.provider = 'google_oauth2'
        expect(oauth_account.provider_icon).to eq('https://developers.google.com/identity/images/g-logo.png')
      end

      it 'returns GitHub icon URL for github' do
        oauth_account.provider = 'github'
        expect(oauth_account.provider_icon).to eq('https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png')
      end

      it 'returns Facebook icon URL for facebook' do
        oauth_account.provider = 'facebook'
        expect(oauth_account.provider_icon).to eq('https://facebookbrand.com/wp-content/uploads/2019/04/f_logo_RGB-Hex-Blue_512.png')
      end

      it 'returns Twitter icon URL for twitter' do
        oauth_account.provider = 'twitter'
        expect(oauth_account.provider_icon).to eq('https://abs.twimg.com/icons/apple-touch-icon-192x192.png')
      end

      it 'returns nil for unknown providers' do
        oauth_account.provider = 'unknown_provider'
        expect(oauth_account.provider_icon).to be_nil
      end
    end

    describe '#provider_color' do
      it 'returns Google color for google_oauth2' do
        oauth_account.provider = 'google_oauth2'
        expect(oauth_account.provider_color).to eq('#4285F4')
      end

      it 'returns GitHub color for github' do
        oauth_account.provider = 'github'
        expect(oauth_account.provider_color).to eq('#333333')
      end

      it 'returns Facebook color for facebook' do
        oauth_account.provider = 'facebook'
        expect(oauth_account.provider_color).to eq('#1877F2')
      end

      it 'returns Twitter color for twitter' do
        oauth_account.provider = 'twitter'
        expect(oauth_account.provider_color).to eq('#1DA1F2')
      end

      it 'returns default color for unknown providers' do
        oauth_account.provider = 'unknown_provider'
        expect(oauth_account.provider_color).to eq('#6B7280')
      end
    end
  end

  describe 'class methods' do
    describe '.find_by_provider_and_uid' do
      let!(:oauth_account) { create(:oauth_account, provider: 'google_oauth2', uid: '123456789') }

      it 'finds account by provider and uid' do
        found = OauthAccount.find_by_provider_and_uid('google_oauth2', '123456789')
        expect(found).to eq(oauth_account)
      end

      it 'returns nil when not found' do
        found = OauthAccount.find_by_provider_and_uid('google_oauth2', '999999999')
        expect(found).to be_nil
      end
    end

    describe '.create_from_omniauth' do
      let(:auth_data) do
        {
          'provider' => 'google_oauth2',
          'uid' => '123456789',
          'info' => {
            'email' => 'oauth@example.com',
            'name' => 'OAuth User',
            'image' => 'https://example.com/avatar.jpg'
          }
        }
      end

      it 'creates OAuth account from OmniAuth data' do
        expect {
          OauthAccount.create_from_omniauth(auth_data, user, tenant)
        }.to change(OauthAccount, :count).by(1)
      end

      it 'sets correct attributes' do
        account = OauthAccount.create_from_omniauth(auth_data, user, tenant)
        expect(account.provider).to eq('google_oauth2')
        expect(account.uid).to eq('123456789')
        expect(account.email).to eq('oauth@example.com')
        expect(account.name).to eq('OAuth User')
        expect(account.avatar_url).to eq('https://example.com/avatar.jpg')
        expect(account.user).to eq(user)
        expect(account.tenant).to eq(tenant)
      end

      it 'handles missing avatar URL' do
        auth_data['info']['image'] = nil
        account = OauthAccount.create_from_omniauth(auth_data, user, tenant)
        expect(account.avatar_url).to be_nil
      end

      it 'handles missing name' do
        auth_data['info']['name'] = nil
        account = OauthAccount.create_from_omniauth(auth_data, user, tenant)
        expect(account.name).to eq('OAuth User')
      end
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant, subdomain: 'tenant1') }
    let(:tenant2) { create(:tenant, subdomain: 'tenant2') }
    let(:user1) { create(:user, tenant: tenant1) }
    let(:user2) { create(:user, tenant: tenant2) }

    it 'scopes OAuth accounts by tenant' do
      account1 = create(:oauth_account, user: user1, tenant: tenant1)
      account2 = create(:oauth_account, user: user2, tenant: tenant2)

      ActsAsTenant.with_tenant(tenant1) do
        expect(OauthAccount.all).to include(account1)
        expect(OauthAccount.all).not_to include(account2)
      end

      ActsAsTenant.with_tenant(tenant2) do
        expect(OauthAccount.all).to include(account2)
        expect(OauthAccount.all).not_to include(account1)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'updates user avatar if OAuth account has avatar URL' do
        oauth_account.avatar_url = 'https://example.com/avatar.jpg'
        oauth_account.save!
        expect(user.reload.avatar_url).to eq('https://example.com/avatar.jpg')
      end

      it 'does not update user avatar if OAuth account has no avatar URL' do
        oauth_account.avatar_url = nil
        oauth_account.save!
        expect(user.reload.avatar_url).to be_nil
      end
    end

    describe 'after_update' do
      let!(:oauth_account) { create(:oauth_account, user: user, avatar_url: 'https://example.com/old-avatar.jpg') }

      it 'updates user avatar when OAuth account avatar changes' do
        oauth_account.update!(avatar_url: 'https://example.com/new-avatar.jpg')
        expect(user.reload.avatar_url).to eq('https://example.com/new-avatar.jpg')
      end
    end
  end
end
