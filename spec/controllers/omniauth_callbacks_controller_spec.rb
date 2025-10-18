require 'rails_helper'

RSpec.describe OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user, email: 'test@example.com') }
  let(:tenant) { create(:tenant) }

  before do
    # Set up OAuth settings
    SiteSetting.set('oauth_auto_register', true, 'boolean')
    SiteSetting.set('oauth_default_role', 'subscriber', 'string')
    SiteSetting.set('oauth_require_email', true, 'boolean')
    SiteSetting.set('oauth_allow_existing_users', true, 'boolean')
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
      request.env['omniauth.auth'] = auth_data
    end

    describe 'POST #google_oauth2' do
      context 'with valid OAuth data' do
        it 'creates a new user if auto-registration is enabled' do
          expect {
            post :google_oauth2
          }.to change(User, :count).by(1)
        end

        it 'creates an OAuth account record' do
          expect {
            post :google_oauth2
          }.to change(OauthAccount, :count).by(1)
        end

        it 'signs in the user' do
          post :google_oauth2
          expect(controller.current_user).to be_present
          expect(controller.current_user.email).to eq('oauth@example.com')
        end

        it 'redirects to root path' do
          post :google_oauth2
          expect(response).to redirect_to(root_path)
        end

        it 'sets success flash message' do
          post :google_oauth2
          expect(flash[:notice]).to include('Google')
        end
      end

      context 'with existing user' do
        let!(:existing_user) { create(:user, email: 'oauth@example.com') }

        it 'links OAuth account to existing user' do
          expect {
            post :google_oauth2
          }.to change(OauthAccount, :count).by(1)
        end

        it 'signs in the existing user' do
          post :google_oauth2
          expect(controller.current_user).to eq(existing_user)
        end

        it 'does not create a new user' do
          expect {
            post :google_oauth2
          }.not_to change(User, :count)
        end
      end

      context 'when auto-registration is disabled' do
        before do
          SiteSetting.set('oauth_auto_register', false, 'boolean')
        end

        it 'does not create a new user' do
          expect {
            post :google_oauth2
          }.not_to change(User, :count)
        end

        it 'redirects to registration page' do
          post :google_oauth2
          expect(response).to redirect_to(new_user_registration_path)
        end
      end

      context 'when email is required but not provided' do
        let(:auth_data) do
          {
            'provider' => 'google_oauth2',
            'uid' => '123456789',
            'info' => {
              'name' => 'OAuth User',
              'first_name' => 'OAuth',
              'last_name' => 'User'
            }
          }
        end

        it 'does not create a user' do
          expect {
            post :google_oauth2
          }.not_to change(User, :count)
        end

        it 'redirects to registration with error' do
          post :google_oauth2
          expect(response).to redirect_to(new_user_registration_path)
          expect(flash[:alert]).to include('Email is required')
        end
      end
    end

    describe 'POST #github' do
      let(:auth_data) do
        {
          'provider' => 'github',
          'uid' => '987654321',
          'info' => {
            'email' => 'github@example.com',
            'name' => 'GitHub User',
            'nickname' => 'githubuser',
            'image' => 'https://github.com/avatar.jpg'
          }
        }
      end

      before do
        request.env['omniauth.auth'] = auth_data
      end

      it 'creates a new user' do
        expect {
          post :github
        }.to change(User, :count).by(1)
      end

      it 'creates an OAuth account with GitHub provider' do
        post :github
        oauth_account = OauthAccount.last
        expect(oauth_account.provider).to eq('github')
        expect(oauth_account.uid).to eq('987654321')
      end
    end

    describe 'POST #facebook' do
      let(:auth_data) do
        {
          'provider' => 'facebook',
          'uid' => '555666777',
          'info' => {
            'email' => 'facebook@example.com',
            'name' => 'Facebook User',
            'first_name' => 'Facebook',
            'last_name' => 'User',
            'image' => 'https://facebook.com/avatar.jpg'
          }
        }
      end

      before do
        request.env['omniauth.auth'] = auth_data
      end

      it 'creates a new user' do
        expect {
          post :facebook
        }.to change(User, :count).by(1)
      end

      it 'creates an OAuth account with Facebook provider' do
        post :facebook
        oauth_account = OauthAccount.last
        expect(oauth_account.provider).to eq('facebook')
        expect(oauth_account.uid).to eq('555666777')
      end
    end

    describe 'POST #twitter' do
      let(:auth_data) do
        {
          'provider' => 'twitter',
          'uid' => '111222333',
          'info' => {
            'name' => 'Twitter User',
            'nickname' => 'twitteruser',
            'image' => 'https://twitter.com/avatar.jpg'
          }
        }
      end

      before do
        request.env['omniauth.auth'] = auth_data
        SiteSetting.set('oauth_require_email', false, 'boolean')
      end

      it 'creates a new user without email' do
        expect {
          post :twitter
        }.to change(User, :count).by(1)
      end

      it 'creates an OAuth account with Twitter provider' do
        post :twitter
        oauth_account = OauthAccount.last
        expect(oauth_account.provider).to eq('twitter')
        expect(oauth_account.uid).to eq('111222333')
      end
    end

    describe 'error handling' do
      context 'when OAuth data is missing' do
        before do
          request.env['omniauth.auth'] = nil
        end

        it 'redirects to sign in page' do
          post :google_oauth2
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'sets error flash message' do
          post :google_oauth2
          expect(flash[:alert]).to include('Authentication failed')
        end
      end

      context 'when user creation fails' do
        let(:auth_data) do
          {
            'provider' => 'google_oauth2',
            'uid' => '123456789',
            'info' => {
              'email' => '', # Invalid email
              'name' => 'OAuth User'
            }
          }
        end

        it 'redirects to registration with errors' do
          post :google_oauth2
          expect(response).to redirect_to(new_user_registration_path)
          expect(flash[:alert]).to be_present
        end
      end
    end

    describe 'admin OAuth callbacks' do
      context 'when request comes from admin path' do
        before do
          allow(request).to receive(:path).and_return('/admin/auth/google_oauth2/callback')
        end

        it 'redirects to admin sign in on error' do
          request.env['omniauth.auth'] = nil
          post :google_oauth2
          expect(response).to redirect_to(new_admin_user_session_path)
        end
      end
    end
  end

  describe 'private methods' do
    let(:auth_data) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => {
          'email' => 'test@example.com',
          'name' => 'Test User',
          'first_name' => 'Test',
          'last_name' => 'User',
          'image' => 'https://example.com/avatar.jpg'
        }
      }
    end

    describe '#extract_email' do
      it 'extracts email from auth data' do
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_email, auth_data)).to eq('test@example.com')
      end
    end

    describe '#extract_name' do
      it 'extracts name from auth data' do
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_name, auth_data)).to eq('Test User')
      end

      it 'falls back to first_name + last_name' do
        auth_data['info']['name'] = nil
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_name, auth_data)).to eq('Test User')
      end

      it 'falls back to nickname' do
        auth_data['info']['name'] = nil
        auth_data['info']['first_name'] = nil
        auth_data['info']['last_name'] = nil
        auth_data['info']['nickname'] = 'testuser'
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_name, auth_data)).to eq('testuser')
      end

      it 'falls back to default name' do
        auth_data['info']['name'] = nil
        auth_data['info']['first_name'] = nil
        auth_data['info']['last_name'] = nil
        auth_data['info']['nickname'] = nil
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_name, auth_data)).to eq('OAuth User')
      end
    end

    describe '#extract_avatar_url' do
      it 'extracts avatar URL from auth data' do
        request.env['omniauth.auth'] = auth_data
        expect(controller.send(:extract_avatar_url, auth_data)).to eq('https://example.com/avatar.jpg')
      end
    end
  end
end
