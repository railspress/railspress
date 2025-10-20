require 'rails_helper'

RSpec.describe "Api::V1::AiAgents", type: :request do
  let(:user) { create(:user, api_key: 'test-api-key') }
  let(:ai_provider) { create(:ai_provider) }
  let(:ai_agent) { create(:ai_agent, ai_provider: ai_provider) }

  before do
    allow_any_instance_of(Api::V1::AiAgentsController).to receive(:current_user).and_return(user)
  end

  describe "GET /api/v1/ai_agents" do
    it "returns http success" do
      get "/api/v1/ai_agents", headers: { 'Authorization' => 'Bearer test-api-key' }
      expect(response).to have_http_status(:success)
    end

    it "returns JSON response with agents" do
      agent1 = create(:ai_agent, name: "Agent 1", active: true)
      agent2 = create(:ai_agent, name: "Agent 2", active: false)
      
      get "/api/v1/ai_agents", headers: { 'Authorization' => 'Bearer test-api-key' }
      
      response_data = JSON.parse(response.body)
      expect(response_data["success"]).to be true
      expect(response_data["agents"].length).to eq(1) # Only active agents
      expect(response_data["agents"].first["name"]).to eq("Agent 1")
      expect(response_data["total"]).to eq(1)
    end

    it "includes agent details" do
      get "/api/v1/ai_agents", headers: { 'Authorization' => 'Bearer test-api-key' }
      
      response_data = JSON.parse(response.body)
      agent_data = response_data["agents"].first
      
      expect(agent_data).to include("id", "name", "type", "active", "provider")
      expect(agent_data["provider"]).to include("id", "name", "type")
    end

    it "requires authentication" do
      get "/api/v1/ai_agents"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/ai_agents/:id" do
    it "returns http success" do
      get "/api/v1/ai_agents/#{ai_agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      expect(response).to have_http_status(:success)
    end

    it "returns detailed agent information" do
      get "/api/v1/ai_agents/#{ai_agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      
      response_data = JSON.parse(response.body)
      expect(response_data["success"]).to be true
      expect(response_data["agent"]["id"]).to eq(ai_agent.id)
      expect(response_data["agent"]["name"]).to eq(ai_agent.name)
      expect(response_data["agent"]).to include("prompt", "content", "guidelines", "rules", "tasks", "master_prompt")
    end

    it "returns 404 for non-existent agent" do
      get "/api/v1/ai_agents/99999", headers: { 'Authorization' => 'Bearer test-api-key' }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for inactive agent" do
      inactive_agent = create(:ai_agent, active: false)
      get "/api/v1/ai_agents/#{inactive_agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/ai_agents" do
    let(:valid_params) do
      {
        ai_agent: {
          name: "Test Agent",
          agent_type: "content_summarizer",
          prompt: "You are a content summarizer.",
          content: "Focus on key points.",
          guidelines: "Keep it concise.",
          rules: "No personal opinions.",
          tasks: "Extract main ideas.",
          master_prompt: "You are an AI assistant.",
          active: true,
          position: 1
        },
        ai_provider_id: ai_provider.id
      }
    end

    context "with valid parameters" do
      it "creates a new AI agent" do
        expect {
          post "/api/v1/ai_agents", params: valid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        }.to change(AiAgent, :count).by(1)
      end

      it "returns created status" do
        post "/api/v1/ai_agents", params: valid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        expect(response).to have_http_status(:created)
      end

      it "returns the created agent" do
        post "/api/v1/ai_agents", params: valid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be true
        expect(response_data["agent"]["name"]).to eq("Test Agent")
        expect(response_data["message"]).to eq("AI Agent created successfully")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          ai_agent: {
            name: "",
            agent_type: "invalid_type"
          },
          ai_provider_id: ai_provider.id
        }
      end

      it "does not create a new AI agent" do
        expect {
          post "/api/v1/ai_agents", params: invalid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        }.not_to change(AiAgent, :count)
      end

      it "returns unprocessable entity" do
        post "/api/v1/ai_agents", params: invalid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages" do
        post "/api/v1/ai_agents", params: invalid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be false
        expect(response_data["errors"]).to be_present
      end
    end
  end

  describe "PATCH /api/v1/ai_agents/:id" do
    let(:update_params) do
      {
        ai_agent: {
          name: "Updated Agent",
          prompt: "Updated prompt"
        }
      }
    end

    context "with valid parameters" do
      it "updates the AI agent" do
        patch "/api/v1/ai_agents/#{ai_agent.id}", params: update_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        ai_agent.reload
        expect(ai_agent.name).to eq("Updated Agent")
        expect(ai_agent.prompt).to eq("Updated prompt")
      end

      it "returns success response" do
        patch "/api/v1/ai_agents/#{ai_agent.id}", params: update_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        expect(response).to have_http_status(:success)
      end

      it "returns updated agent data" do
        patch "/api/v1/ai_agents/#{ai_agent.id}", params: update_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be true
        expect(response_data["agent"]["name"]).to eq("Updated Agent")
        expect(response_data["message"]).to eq("AI Agent updated successfully")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          ai_agent: {
            name: "",
            agent_type: "invalid_type"
          }
        }
      end

      it "does not update the AI agent" do
        original_name = ai_agent.name
        
        patch "/api/v1/ai_agents/#{ai_agent.id}", params: invalid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        ai_agent.reload
        expect(ai_agent.name).to eq(original_name)
      end

      it "returns unprocessable entity" do
        patch "/api/v1/ai_agents/#{ai_agent.id}", params: invalid_params, headers: { 'Authorization' => 'Bearer test-api-key' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/ai_agents/:id" do
    it "deletes the AI agent" do
      agent = create(:ai_agent)
      
      expect {
        delete "/api/v1/ai_agents/#{agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      }.to change(AiAgent, :count).by(-1)
    end

    it "returns success response" do
      delete "/api/v1/ai_agents/#{ai_agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      expect(response).to have_http_status(:success)
    end

    it "returns success message" do
      delete "/api/v1/ai_agents/#{ai_agent.id}", headers: { 'Authorization' => 'Bearer test-api-key' }
      
      response_data = JSON.parse(response.body)
      expect(response_data["success"]).to be true
      expect(response_data["message"]).to eq("AI Agent deleted successfully")
    end
  end

  describe "POST /api/v1/ai_agents/:id/execute" do
    context "with successful execution" do
      before do
        allow_any_instance_of(AiService).to receive(:generate).and_return("Test response")
      end

      it "executes the agent successfully" do
        post "/api/v1/ai_agents/#{ai_agent.id}/execute", params: {
          user_input: "Test input",
          context: { temperature: 0.7 }
        }, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        expect(response).to have_http_status(:success)
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be true
        expect(response_data["result"]).to eq("Test response")
        expect(response_data["agent"]["id"]).to eq(ai_agent.id)
        expect(response_data["agent"]["name"]).to eq(ai_agent.name)
        expect(response_data["agent"]["type"]).to eq(ai_agent.agent_type)
      end

      it "logs the usage" do
        expect {
          post "/api/v1/ai_agents/#{ai_agent.id}/execute", params: {
            user_input: "Test input"
          }, headers: { 'Authorization' => 'Bearer test-api-key' }
        }.to change(AiUsage, :count).by(1)
      end
    end

    context "with execution error" do
      before do
        allow_any_instance_of(AiService).to receive(:generate).and_raise(StandardError.new("API Error"))
      end

      it "handles the error gracefully" do
        post "/api/v1/ai_agents/#{ai_agent.id}/execute", params: {
          user_input: "Test input"
        }, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be false
        expect(response_data["error"]).to eq("API Error")
      end
    end
  end

  describe "POST /api/v1/ai_agents/execute/:agent_type" do
    let(:content_summarizer) { create(:ai_agent, agent_type: "content_summarizer", active: true) }

    context "with successful execution" do
      before do
        allow_any_instance_of(AiService).to receive(:generate).and_return("Test response")
      end

      it "executes agent by type successfully" do
        post "/api/v1/ai_agents/execute/content_summarizer", params: {
          user_input: "Test input",
          context: { temperature: 0.7 }
        }, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        expect(response).to have_http_status(:success)
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be true
        expect(response_data["result"]).to eq("Test response")
        expect(response_data["agent"]["type"]).to eq("content_summarizer")
      end
    end

    context "when no active agent found" do
      it "returns 404" do
        post "/api/v1/ai_agents/execute/nonexistent_type", params: {
          user_input: "Test input"
        }, headers: { 'Authorization' => 'Bearer test-api-key' }
        
        expect(response).to have_http_status(:not_found)
        
        response_data = JSON.parse(response.body)
        expect(response_data["success"]).to be false
        expect(response_data["error"]).to eq("No active agent found for type: nonexistent_type")
      end
    end
  end

  describe "authentication" do
    it "requires valid API key" do
      get "/api/v1/ai_agents", headers: { 'Authorization' => 'Bearer invalid-key' }
      expect(response).to have_http_status(:unauthorized)
    end

    it "requires authentication header" do
      get "/api/v1/ai_agents"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
