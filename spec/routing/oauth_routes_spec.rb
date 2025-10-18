require 'rails_helper'

RSpec.describe 'OAuth Routes', type: :routing do
  describe 'Admin OAuth routes' do
    it 'routes GET /admin/sign_in to admin/sessions#new' do
      expect(get: '/admin/sign_in').to route_to(
        controller: 'admin/sessions',
        action: 'new'
      )
    end

    it 'routes POST /admin/sign_in to admin/sessions#create' do
      expect(post: '/admin/sign_in').to route_to(
        controller: 'admin/sessions',
        action: 'create'
      )
    end

    it 'routes DELETE /admin/sign_out to admin/sessions#destroy' do
      expect(delete: '/admin/sign_out').to route_to(
        controller: 'admin/sessions',
        action: 'destroy'
      )
    end

    it 'routes GET /admin/password/new to admin/passwords#new' do
      expect(get: '/admin/password/new').to route_to(
        controller: 'admin/passwords',
        action: 'new'
      )
    end

    it 'routes GET /admin/password/edit to admin/passwords#edit' do
      expect(get: '/admin/password/edit').to route_to(
        controller: 'admin/passwords',
        action: 'edit'
      )
    end

    it 'routes PATCH /admin/password to admin/passwords#update' do
      expect(patch: '/admin/password').to route_to(
        controller: 'admin/passwords',
        action: 'update'
      )
    end

    it 'routes PUT /admin/password to admin/passwords#update' do
      expect(put: '/admin/password').to route_to(
        controller: 'admin/passwords',
        action: 'update'
      )
    end

    it 'routes POST /admin/password to admin/passwords#create' do
      expect(post: '/admin/password').to route_to(
        controller: 'admin/passwords',
        action: 'create'
      )
    end

    describe 'OAuth callback routes' do
      it 'routes GET /admin/auth/:provider/callback to omniauth_callbacks#create' do
        expect(get: '/admin/auth/google_oauth2/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'google_oauth2'
        )
      end

      it 'routes POST /admin/auth/:provider/callback to omniauth_callbacks#create' do
        expect(post: '/admin/auth/github/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'github'
        )
      end

      it 'routes GET /admin/auth/:provider/callback for facebook' do
        expect(get: '/admin/auth/facebook/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'facebook'
        )
      end

      it 'routes GET /admin/auth/:provider/callback for twitter' do
        expect(get: '/admin/auth/twitter/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'twitter'
        )
      end
    end
  end

  describe 'Frontend OAuth routes' do
    it 'routes GET /auth/sign_in to users/sessions#new' do
      expect(get: '/auth/sign_in').to route_to(
        controller: 'users/sessions',
        action: 'new'
      )
    end

    it 'routes POST /auth/sign_in to users/sessions#create' do
      expect(post: '/auth/sign_in').to route_to(
        controller: 'users/sessions',
        action: 'create'
      )
    end

    it 'routes DELETE /auth/sign_out to users/sessions#destroy' do
      expect(delete: '/auth/sign_out').to route_to(
        controller: 'users/sessions',
        action: 'destroy'
      )
    end

    it 'routes GET /auth/sign_up to users/registrations#new' do
      expect(get: '/auth/sign_up').to route_to(
        controller: 'users/registrations',
        action: 'new'
      )
    end

    it 'routes POST /auth to users/registrations#create' do
      expect(post: '/auth').to route_to(
        controller: 'users/registrations',
        action: 'create'
      )
    end

    it 'routes GET /auth/password/new to users/passwords#new' do
      expect(get: '/auth/password/new').to route_to(
        controller: 'users/passwords',
        action: 'new'
      )
    end

    it 'routes GET /auth/password/edit to users/passwords#edit' do
      expect(get: '/auth/password/edit').to route_to(
        controller: 'users/passwords',
        action: 'edit'
      )
    end

    it 'routes PATCH /auth/password to users/passwords#update' do
      expect(patch: '/auth/password').to route_to(
        controller: 'users/passwords',
        action: 'update'
      )
    end

    it 'routes PUT /auth/password to users/passwords#update' do
      expect(put: '/auth/password').to route_to(
        controller: 'users/passwords',
        action: 'update'
      )
    end

    it 'routes POST /auth/password to users/passwords#create' do
      expect(post: '/auth/password').to route_to(
        controller: 'users/passwords',
        action: 'create'
      )
    end

    describe 'OAuth callback routes' do
      it 'routes GET /auth/:provider/callback to omniauth_callbacks#create' do
        expect(get: '/auth/google_oauth2/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'google_oauth2'
        )
      end

      it 'routes POST /auth/:provider/callback to omniauth_callbacks#create' do
        expect(post: '/auth/github/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'github'
        )
      end

      it 'routes GET /auth/:provider/callback for facebook' do
        expect(get: '/auth/facebook/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'facebook'
        )
      end

      it 'routes GET /auth/:provider/callback for twitter' do
        expect(get: '/auth/twitter/callback').to route_to(
          controller: 'omniauth_callbacks',
          action: 'create',
          provider: 'twitter'
        )
      end
    end
  end

  describe 'OAuth provider routes' do
    describe 'Google OAuth2' do
      it 'routes GET /auth/google_oauth2 to omniauth provider' do
        expect(get: '/auth/google_oauth2').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'google_oauth2'
        )
      end

      it 'routes POST /auth/google_oauth2 to omniauth provider' do
        expect(post: '/auth/google_oauth2').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'google_oauth2'
        )
      end

      it 'routes GET /admin/auth/google_oauth2 to omniauth provider' do
        expect(get: '/admin/auth/google_oauth2').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'google_oauth2'
        )
      end

      it 'routes POST /admin/auth/google_oauth2 to omniauth provider' do
        expect(post: '/admin/auth/google_oauth2').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'google_oauth2'
        )
      end
    end

    describe 'GitHub OAuth' do
      it 'routes GET /auth/github to omniauth provider' do
        expect(get: '/auth/github').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'github'
        )
      end

      it 'routes POST /auth/github to omniauth provider' do
        expect(post: '/auth/github').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'github'
        )
      end

      it 'routes GET /admin/auth/github to omniauth provider' do
        expect(get: '/admin/auth/github').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'github'
        )
      end

      it 'routes POST /admin/auth/github to omniauth provider' do
        expect(post: '/admin/auth/github').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'github'
        )
      end
    end

    describe 'Facebook OAuth' do
      it 'routes GET /auth/facebook to omniauth provider' do
        expect(get: '/auth/facebook').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'facebook'
        )
      end

      it 'routes POST /auth/facebook to omniauth provider' do
        expect(post: '/auth/facebook').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'facebook'
        )
      end

      it 'routes GET /admin/auth/facebook to omniauth provider' do
        expect(get: '/admin/auth/facebook').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'facebook'
        )
      end

      it 'routes POST /admin/auth/facebook to omniauth provider' do
        expect(post: '/admin/auth/facebook').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'facebook'
        )
      end
    end

    describe 'Twitter OAuth' do
      it 'routes GET /auth/twitter to omniauth provider' do
        expect(get: '/auth/twitter').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'twitter'
        )
      end

      it 'routes POST /auth/twitter to omniauth provider' do
        expect(post: '/auth/twitter').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'twitter'
        )
      end

      it 'routes GET /admin/auth/twitter to omniauth provider' do
        expect(get: '/admin/auth/twitter').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'twitter'
        )
      end

      it 'routes POST /admin/auth/twitter to omniauth provider' do
        expect(post: '/admin/auth/twitter').to route_to(
          controller: 'omniauth_callbacks',
          action: 'passthru',
          provider: 'twitter'
        )
      end
    end
  end

  describe 'Route helpers' do
    it 'generates new_admin_user_session_path' do
      expect(new_admin_user_session_path).to eq('/admin/sign_in')
    end

    it 'generates admin_user_session_path' do
      expect(admin_user_session_path).to eq('/admin/sign_in')
    end

    it 'generates destroy_admin_user_session_path' do
      expect(destroy_admin_user_session_path).to eq('/admin/sign_out')
    end

    it 'generates new_admin_user_password_path' do
      expect(new_admin_user_password_path).to eq('/admin/password/new')
    end

    it 'generates edit_admin_user_password_path' do
      expect(edit_admin_user_password_path).to eq('/admin/password/edit')
    end

    it 'generates admin_user_password_path' do
      expect(admin_user_password_path).to eq('/admin/password')
    end

    it 'generates new_user_session_path' do
      expect(new_user_session_path).to eq('/auth/sign_in')
    end

    it 'generates user_session_path' do
      expect(user_session_path).to eq('/auth/sign_in')
    end

    it 'generates destroy_user_session_path' do
      expect(destroy_user_session_path).to eq('/auth/sign_out')
    end

    it 'generates new_user_registration_path' do
      expect(new_user_registration_path).to eq('/auth/sign_up')
    end

    it 'generates user_registration_path' do
      expect(user_registration_path).to eq('/auth')
    end

    it 'generates new_user_password_path' do
      expect(new_user_password_path).to eq('/auth/password/new')
    end

    it 'generates edit_user_password_path' do
      expect(edit_user_password_path).to eq('/auth/password/edit')
    end

    it 'generates user_password_path' do
      expect(user_password_path).to eq('/auth/password')
    end
  end

  describe 'OAuth route constraints' do
    it 'does not conflict with other routes' do
      # Ensure OAuth routes don't interfere with other application routes
      expect(get: '/admin/dashboard').to route_to(
        controller: 'admin/dashboard',
        action: 'index'
      )
      
      expect(get: '/posts').to route_to(
        controller: 'posts',
        action: 'index'
      )
    end

    it 'handles OAuth provider names correctly' do
      # Test that provider names with underscores work
      expect(get: '/auth/google_oauth2').to route_to(
        controller: 'omniauth_callbacks',
        action: 'passthru',
        provider: 'google_oauth2'
      )
      
      # Test that simple provider names work
      expect(get: '/auth/github').to route_to(
        controller: 'omniauth_callbacks',
        action: 'passthru',
        provider: 'github'
      )
    end
  end
end
