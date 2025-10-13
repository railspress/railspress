require 'rails_helper'

RSpec.describe "Admin::AiProviders", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/ai_providers/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/ai_providers/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/admin/ai_providers/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/admin/ai_providers/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/admin/ai_providers/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/admin/ai_providers/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/admin/ai_providers/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /toggle" do
    it "returns http success" do
      get "/admin/ai_providers/toggle"
      expect(response).to have_http_status(:success)
    end
  end

end
