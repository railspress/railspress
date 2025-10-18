require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do
  let(:user) { create(:user, role: 'administrator') }
  let(:regular_user) { create(:user, role: 'subscriber') }

  describe 'GET #new' do
    context 'when user is not signed in' do
      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:success)
      end

      it 'uses admin layout' do
        get :new
        expect(response).to render_template(layout: 'admin')
      end
    end

    context 'when user is already signed in' do
      before { sign_in user }

      it 'redirects to admin root' do
        get :new
        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        user: {
          email: user.email,
          password: 'password'
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: user.email,
          password: 'wrong_password'
        }
      }
    end

    context 'with valid credentials' do
      it 'signs in the user' do
        post :create, params: valid_params
        expect(controller.current_user).to eq(user)
      end

      it 'redirects to admin root' do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_root_path)
      end

      it 'sets success flash message' do
        post :create, params: valid_params
        expect(flash[:notice]).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'does not sign in the user' do
        post :create, params: invalid_params
        expect(controller.current_user).to be_nil
      end

      it 'renders new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it 'sets error flash message' do
        post :create, params: invalid_params
        expect(flash[:alert]).to be_present
      end
    end

    context 'with non-admin user' do
      let(:non_admin_params) do
        {
          user: {
            email: regular_user.email,
            password: 'password'
          }
        }
      end

      it 'signs in the user but redirects to root' do
        post :create, params: non_admin_params
        expect(controller.current_user).to eq(regular_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in user }

    it 'signs out the user' do
      delete :destroy
      expect(controller.current_user).to be_nil
    end

    it 'redirects to admin sign in page' do
      delete :destroy
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it 'sets success flash message' do
      delete :destroy
      expect(flash[:notice]).to be_present
    end
  end

  describe 'protected methods' do
    describe '#after_sign_in_path_for' do
      it 'returns admin root path' do
        expect(controller.send(:after_sign_in_path_for, user)).to eq(admin_root_path)
      end
    end

    describe '#after_sign_out_path_for' do
      it 'returns admin sign in path' do
        expect(controller.send(:after_sign_out_path_for, user)).to eq(new_admin_user_session_path)
      end
    end
  end
end
