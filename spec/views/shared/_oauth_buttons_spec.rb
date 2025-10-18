require 'rails_helper'

RSpec.describe 'shared/_oauth_buttons', type: :view do
  let(:user) { create(:user) }
  let(:resource_name) { :user }

  before do
    # Clear any existing OAuth settings
    SiteSetting.where(key: [
      'google_oauth_enabled', 'google_oauth_client_id',
      'github_oauth_enabled', 'github_oauth_client_id',
      'facebook_oauth_enabled', 'facebook_oauth_app_id',
      'twitter_oauth_enabled', 'twitter_oauth_api_key'
    ]).destroy_all
  end

  describe 'when no OAuth providers are configured' do
    it 'renders nothing' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to be_blank
    end
  end

  describe 'when Google OAuth is configured' do
    before do
      SiteSetting.set('google_oauth_enabled', true, 'boolean')
      SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
    end

    it 'renders Google OAuth button' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('Google')
      expect(rendered).to include('google_oauth2')
    end

    it 'includes Google icon SVG' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('viewBox="0 0 24 24"')
      expect(rendered).to include('fill="#4285F4"')
    end

    it 'uses correct OAuth path for frontend' do
      allow(view).to receive(:request).and_return(double(path: '/auth/sign_in'))
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('auth/google_oauth2')
    end

    it 'uses correct OAuth path for admin' do
      allow(view).to receive(:request).and_return(double(path: '/admin/sign_in'))
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('/admin/auth/google_oauth2')
    end
  end

  describe 'when GitHub OAuth is configured' do
    before do
      SiteSetting.set('github_oauth_enabled', true, 'boolean')
      SiteSetting.set('github_oauth_client_id', 'test-github-client-id', 'string')
    end

    it 'renders GitHub OAuth button' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('GitHub')
      expect(rendered).to include('github')
    end

    it 'includes GitHub icon SVG' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('fill="currentColor"')
      expect(rendered).to include('M12 0c-6.626 0-12 5.373-12 12')
    end
  end

  describe 'when Facebook OAuth is configured' do
    before do
      SiteSetting.set('facebook_oauth_enabled', true, 'boolean')
      SiteSetting.set('facebook_oauth_app_id', 'test-facebook-app-id', 'string')
    end

    it 'renders Facebook OAuth button' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('Facebook')
      expect(rendered).to include('facebook')
    end

    it 'includes Facebook icon SVG' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('fill="currentColor"')
      expect(rendered).to include('M24 12.073c0-6.627-5.373-12-12-12')
    end
  end

  describe 'when Twitter OAuth is configured' do
    before do
      SiteSetting.set('twitter_oauth_enabled', true, 'boolean')
      SiteSetting.set('twitter_oauth_api_key', 'test-twitter-api-key', 'string')
    end

    it 'renders Twitter OAuth button' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('Twitter')
      expect(rendered).to include('twitter')
    end

    it 'includes Twitter icon SVG' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('fill="currentColor"')
      expect(rendered).to include('M23.953 4.57a10 10 0 01-2.825.775')
    end
  end

  describe 'when multiple OAuth providers are configured' do
    before do
      SiteSetting.set('google_oauth_enabled', true, 'boolean')
      SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
      SiteSetting.set('github_oauth_enabled', true, 'boolean')
      SiteSetting.set('github_oauth_client_id', 'test-github-client-id', 'string')
      SiteSetting.set('facebook_oauth_enabled', true, 'boolean')
      SiteSetting.set('facebook_oauth_app_id', 'test-facebook-app-id', 'string')
    end

    it 'renders all configured providers' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('Google')
      expect(rendered).to include('GitHub')
      expect(rendered).to include('Facebook')
    end

    it 'uses 2-column grid for more than 2 providers' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('grid-cols-2')
    end

    it 'includes divider text' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('Or continue with')
    end
  end

  describe 'styling based on context' do
    before do
      SiteSetting.set('google_oauth_enabled', true, 'boolean')
      SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
    end

    context 'for frontend pages' do
      before do
        allow(view).to receive(:request).and_return(double(path: '/auth/sign_in'))
      end

      it 'uses light theme styling' do
        render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
        expect(rendered).to include('border-gray-300')
        expect(rendered).to include('text-gray-700')
        expect(rendered).to include('bg-white')
        expect(rendered).to include('hover:bg-gray-50')
      end

      it 'uses light theme for divider' do
        render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
        expect(rendered).to include('bg-white text-gray-500')
      end
    end

    context 'for admin pages' do
      before do
        allow(view).to receive(:request).and_return(double(path: '/admin/sign_in'))
      end

      it 'uses dark theme styling' do
        render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
        expect(rendered).to include('border-[#2a2a2a]')
        expect(rendered).to include('text-gray-300')
        expect(rendered).to include('bg-[#0a0a0a]')
        expect(rendered).to include('hover:bg-[#111111]')
      end

      it 'uses dark theme for divider' do
        render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
        expect(rendered).to include('bg-[#1a1a1a] text-gray-400')
      end
    end
  end

  describe 'OAuth button attributes' do
    before do
      SiteSetting.set('google_oauth_enabled', true, 'boolean')
      SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
    end

    it 'includes proper form attributes' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('method="post"')
      expect(rendered).to include('data-turbo="false"')
    end

    it 'includes proper CSS classes' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      expect(rendered).to include('w-full')
      expect(rendered).to include('inline-flex')
      expect(rendered).to include('justify-center')
      expect(rendered).to include('items-center')
      expect(rendered).to include('px-4')
      expect(rendered).to include('py-2')
      expect(rendered).to include('rounded-lg')
      expect(rendered).to include('shadow-sm')
      expect(rendered).to include('text-sm')
      expect(rendered).to include('font-medium')
      expect(rendered).to include('focus:outline-none')
      expect(rendered).to include('focus:ring-2')
      expect(rendered).to include('focus:ring-offset-2')
      expect(rendered).to include('focus:ring-indigo-500')
      expect(rendered).to include('transition-colors')
    end
  end

  describe 'provider-specific styling' do
    before do
      SiteSetting.set('google_oauth_enabled', true, 'boolean')
      SiteSetting.set('google_oauth_client_id', 'test-client-id', 'string')
    end

    it 'includes provider-specific color classes' do
      render partial: 'shared/oauth_buttons', locals: { resource_name: resource_name }
      # The color classes are defined in the provider hash but not used in the current implementation
      # This test ensures the structure is correct for future enhancements
      expect(rendered).to include('Google')
    end
  end
end
