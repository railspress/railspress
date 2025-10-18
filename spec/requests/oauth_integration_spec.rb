require 'rails_helper'

RSpec.describe 'OAuth Integration', type: :request do
  let(:user) { create(:user, email: 'test@example.com') }
  let(:tenant) { create(:tenant) }

  before do
    # Set up OAuth settings
    SiteSetting.set('oauth_auto_register', true, 'boolean')
    SiteSetting.set('oauth_default_role', 'subscriber', 'string')
    SiteSetting.set('oauth_require_email', true, 'boolean')
    SiteSetting.set('oauth_allow_existing_users', true, 'boolean')
  end

  describe 'OAuth sign-in flow' do
    describe 'GET /auth/sign_in' do
      context 'when OAuth providers are configured' do
        before do
          SiteSetting.set('google_oauth_enabled', true, 'boolean')
          SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
          SiteSetting.set('github_oauth_enabled', true, 'boolean')
          SiteSetting.set('github_oauth_client_id', 'test-github-client-id', 'string')
        end

        it 'renders sign-in page with OAuth buttons' do
          get '/auth/sign_in'
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Google')
          expect(response.body).to include('GitHub')
          expect(response.body).to include('Or continue with')
        end

        it 'includes OAuth button forms' do
          get '/auth/sign_in'
          expect(response.body).to include('auth/google_oauth2')
          expect(response.body).to include('auth/github')
        end

        it 'uses light theme styling' do
          get '/auth/sign_in'
          expect(response.body).to include('border-gray-300')
          expect(response.body).to include('bg-white')
        end
      end

      context 'when no OAuth providers are configured' do
        it 'renders sign-in page without OAuth buttons' do
          get '/auth/sign_in'
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include('Or continue with')
        end
      end
    end

    describe 'GET /admin/sign_in' do
      context 'when OAuth providers are configured' do
        before do
          SiteSetting.set('google_oauth_enabled', true, 'boolean')
          SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
          SiteSetting.set('github_oauth_enabled', true, 'boolean')
          SiteSetting.set('github_oauth_client_id', 'test-github-client-id', 'string')
        end

        it 'renders admin sign-in page with OAuth buttons' do
          get '/admin/sign_in'
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Google')
          expect(response.body).to include('GitHub')
          expect(response.body).to include('Or continue with')
        end

        it 'includes admin OAuth button forms' do
          get '/admin/sign_in'
          expect(response.body).to include('/admin/auth/google_oauth2')
          expect(response.body).to include('/admin/auth/github')
        end

        it 'uses dark theme styling' do
          get '/admin/sign_in'
          expect(response.body).to include('border-[#2a2a2a]')
          expect(response.body).to include('bg-[#0a0a0a]')
        end

        it 'uses admin layout' do
          get '/admin/sign_in'
          expect(response.body).to include('Admin Panel')
        end
      end

      context 'when no OAuth providers are configured' do
        it 'renders admin sign-in page without OAuth buttons' do
          get '/admin/sign_in'
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include('Or continue with')
        end
      end
    end
  end

  describe 'OAuth callback handling' do
    let(:auth_data) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => {
          'email' => 'oauth@example.com',
          'name' => 'OAuth User',
          'first_name' => 'OAuth',
          'last_name' => 'User',
          'image' => 'https://example.com/avatar.jpg'
        }
      }
    end

    before do
      # Mock OmniAuth
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_data
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    describe 'POST /auth/google_oauth2' do
      it 'redirects to Google OAuth' do
        post '/auth/google_oauth2'
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('accounts.google.com')
      end
    end

    describe 'GET /auth/google_oauth2/callback' do
      it 'creates a new user' do
        expect {
          get '/auth/google_oauth2/callback'
        }.to change(User, :count).by(1)
      end

      it 'creates an OAuth account' do
        expect {
          get '/auth/google_oauth2/callback'
        }.to change(OauthAccount, :count).by(1)
      end

      it 'signs in the user' do
        get '/auth/google_oauth2/callback'
        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq('oauth@example.com')
      end

      it 'redirects to root path' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'POST /admin/auth/google_oauth2' do
      it 'redirects to Google OAuth' do
        post '/admin/auth/google_oauth2'
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('accounts.google.com')
      end
    end

    describe 'GET /admin/auth/google_oauth2/callback' do
      it 'creates a new user' do
        expect {
          get '/admin/auth/google_oauth2/callback'
        }.to change(User, :count).by(1)
      end

      it 'signs in the user' do
        get '/admin/auth/google_oauth2/callback'
        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq('oauth@example.com')
      end

      it 'redirects to admin root' do
        get '/admin/auth/google_oauth2/callback'
        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  describe 'OAuth error handling' do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    describe 'GET /auth/google_oauth2/callback with invalid credentials' do
      it 'redirects to sign-in page' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'sets error flash message' do
        get '/auth/google_oauth2/callback'
        follow_redirect!
        expect(flash[:alert]).to include('Authentication failed')
      end
    end

    describe 'GET /admin/auth/google_oauth2/callback with invalid credentials' do
      it 'redirects to admin sign-in page' do
        get '/admin/auth/google_oauth2/callback'
        expect(response).to redirect_to(new_admin_user_session_path)
      end

      it 'sets error flash message' do
        get '/admin/auth/google_oauth2/callback'
        follow_redirect!
        expect(flash[:alert]).to include('Authentication failed')
      end
    end
  end

  describe 'OAuth settings integration' do
    describe 'when auto-registration is disabled' do
      before do
        SiteSetting.set('oauth_auto_register', false, 'boolean')
        SiteSetting.set('google_oauth_enabled', true, 'boolean')
        SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
        
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:google_oauth2] = {
          'provider' => 'google_oauth2',
          'uid' => '123456789',
          'info' => {
            'email' => 'oauth@example.com',
            'name' => 'OAuth User'
          }
        }
      end

      after do
        OmniAuth.config.test_mode = false
        OmniAuth.config.mock_auth[:google_oauth2] = nil
      end

      it 'does not create a new user' do
        expect {
          get '/auth/google_oauth2/callback'
        }.not_to change(User, :count)
      end

      it 'redirects to registration page' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    describe 'when existing users are not allowed' do
      let!(:existing_user) { create(:user, email: 'oauth@example.com') }

      before do
        SiteSetting.set('oauth_allow_existing_users', false, 'boolean')
        SiteSetting.set('google_oauth_enabled', true, 'boolean')
        SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
        
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:google_oauth2] = {
          'provider' => 'google_oauth2',
          'uid' => '123456789',
          'info' => {
            'email' => 'oauth@example.com',
            'name' => 'OAuth User'
          }
        }
      end

      after do
        OmniAuth.config.test_mode = false
        OmniAuth.config.mock_auth[:google_oauth2] = nil
      end

      it 'does not sign in existing user' do
        get '/auth/google_oauth2/callback'
        expect(controller.current_user).to be_nil
      end

      it 'redirects to registration with error' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(new_user_registration_path)
        follow_redirect!
        expect(flash[:alert]).to include('not allowed for existing users')
      end
    end
  end

  describe 'OAuth provider service integration' do
    describe 'GET /auth/sign_in' do
      context 'with multiple providers configured' do
        before do
          SiteSetting.set('google_oauth_enabled', true, 'boolean')
          SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
          SiteSetting.set('github_oauth_enabled', true, 'boolean')
          SiteSetting.set('github_oauth_client_id', 'test-github-client-id', 'string')
          SiteSetting.set('facebook_oauth_enabled', true, 'boolean')
          SiteSetting.set('facebook_oauth_app_id', 'test-facebook-app-id', 'string')
          SiteSetting.set('twitter_oauth_enabled', true, 'boolean')
          SiteSetting.set('twitter_oauth_api_key', 'test-twitter-api-key', 'string')
        end

        it 'shows all configured providers' do
          get '/auth/sign_in'
          expect(response.body).to include('Google')
          expect(response.body).to include('GitHub')
          expect(response.body).to include('Facebook')
          expect(response.body).to include('Twitter')
        end

        it 'uses 2-column grid layout' do
          get '/auth/sign_in'
          expect(response.body).to include('grid-cols-2')
        end
      end

      context 'with single provider configured' do
        before do
          SiteSetting.set('google_oauth_enabled', true, 'boolean')
          SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
        end

        it 'uses single column layout' do
          get '/auth/sign_in'
          expect(response.body).to include('grid-cols-1')
        end
      end
    end
  end
end
