require 'rails_helper'

RSpec.describe "Api::V1::AiAgents", type: :request do
  describe "GET /execute" do
    it "returns http success" do
      get "/api/v1/ai_agents/execute"
      expect(response).to have_http_status(:success)
    end
  end

end
