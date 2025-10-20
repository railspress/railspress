require 'rails_helper'

RSpec.describe Api::V1::McpController, type: :controller do
  let(:user) { create(:user, :administrator) }
  let(:api_key) { user.api_key }
  
  before do
    request.headers['Authorization'] = "Bearer #{api_key}"
  end

  describe 'POST #handshake' do
    context 'with valid handshake request' do
      let(:valid_request) do
        {
          jsonrpc: '2.0',
          method: 'session/handshake',
          params: {
            protocolVersion: '2025-03-26',
            clientInfo: {
              name: 'test-client',
              version: '1.0.0'
            }
          },
          id: 1
        }
      end

      it 'returns successful handshake response' do
        post :handshake, params: valid_request, as: :json
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['result']['protocolVersion']).to eq('2025-03-26')
        expect(response_data['result']['capabilities']).to include('tools', 'resources', 'prompts')
        expect(response_data['result']['serverInfo']['name']).to eq('railspress-mcp-server')
        expect(response_data['id']).to eq(1)
      end
    end

    context 'with invalid protocol version' do
      let(:invalid_request) do
        {
          jsonrpc: '2.0',
          method: 'session/handshake',
          params: {
            protocolVersion: '2024-01-01',
            clientInfo: {
              name: 'test-client',
              version: '1.0.0'
            }
          },
          id: 1
        }
      end

      it 'returns error for invalid protocol version' do
        post :handshake, params: invalid_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32602)
        expect(response_data['error']['message']).to eq('Invalid protocol version')
      end
    end

    context 'with invalid JSON-RPC format' do
      let(:invalid_request) do
        {
          jsonrpc: '1.0',
          method: 'session/handshake',
          params: {
            protocolVersion: '2025-03-26',
            clientInfo: {
              name: 'test-client',
              version: '1.0.0'
            }
          },
          id: 1
        }
      end

      it 'returns error for invalid request' do
        post :handshake, params: invalid_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32600)
        expect(response_data['error']['message']).to eq('Invalid Request')
      end
    end

    context 'with empty request body' do
      it 'returns parse error' do
        post :handshake, params: {}, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32700)
        expect(response_data['error']['message']).to eq('Parse error')
      end
    end
  end

  describe 'GET #tools_list' do
    it 'returns list of available tools' do
      get :tools_list
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      response_data = JSON.parse(response.body)
      expect(response_data['jsonrpc']).to eq('2.0')
      expect(response_data['result']['tools']).to be_an(Array)
      expect(response_data['result']['tools'].length).to be > 0
      
      # Check for core tools
      tool_names = response_data['result']['tools'].map { |tool| tool['name'] }
      expect(tool_names).to include('get_posts', 'create_post', 'get_pages', 'create_page')
      
      # Check tool structure
      first_tool = response_data['result']['tools'].first
      expect(first_tool).to have_key('name')
      expect(first_tool).to have_key('description')
      expect(first_tool).to have_key('inputSchema')
      expect(first_tool).to have_key('outputSchema')
    end
  end

  describe 'POST #tools_call' do
    context 'with valid API key' do
      let(:valid_request) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: {
              limit: 5
            }
          },
          id: 2
        }
      end

      it 'calls the tool successfully' do
        post :tools_call, params: valid_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['result']).to have_key('content')
        expect(response_data['id']).to eq(2)
      end
    end

    context 'without API key' do
      before do
        request.headers['Authorization'] = nil
      end

      let(:request_without_auth) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: {
              limit: 5
            }
          },
          id: 2
        }
      end

      it 'returns unauthorized error' do
        post :tools_call, params: request_without_auth, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be false
        expect(response_data['error']).to eq('API key required')
        expect(response_data['code']).to eq('MISSING_API_KEY')
      end
    end

    context 'with invalid API key' do
      before do
        request.headers['Authorization'] = 'Bearer invalid-key'
      end

      let(:request_with_invalid_auth) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: {
              limit: 5
            }
          },
          id: 2
        }
      end

      it 'returns unauthorized error' do
        post :tools_call, params: request_with_invalid_auth, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be false
        expect(response_data['error']).to eq('Invalid API key')
        expect(response_data['code']).to eq('INVALID_API_KEY')
      end
    end

    context 'with non-existent tool' do
      let(:invalid_tool_request) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'non_existent_tool',
            arguments: {}
          },
          id: 2
        }
      end

      it 'returns error for unknown tool' do
        post :tools_call, params: invalid_tool_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32601)
        expect(response_data['error']['message']).to eq('Unknown tool: non_existent_tool')
      end
    end
  end

  describe 'GET #resources_list' do
    it 'returns list of available resources' do
      get :resources_list
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      response_data = JSON.parse(response.body)
      expect(response_data['jsonrpc']).to eq('2.0')
      expect(response_data['result']['resources']).to be_an(Array)
      expect(response_data['result']['resources'].length).to be > 0
      
      # Check for core resources
      resource_uris = response_data['result']['resources'].map { |resource| resource['uri'] }
      expect(resource_uris).to include('railspress://posts', 'railspress://pages', 'railspress://taxonomies')
      
      # Check resource structure
      first_resource = response_data['result']['resources'].first
      expect(first_resource).to have_key('uri')
      expect(first_resource).to have_key('name')
      expect(first_resource).to have_key('description')
      expect(first_resource).to have_key('mimeType')
    end
  end

  describe 'GET #prompts_list' do
    it 'returns list of available prompts' do
      get :prompts_list
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
      
      response_data = JSON.parse(response.body)
      expect(response_data['jsonrpc']).to eq('2.0')
      expect(response_data['result']['prompts']).to be_an(Array)
      expect(response_data['result']['prompts'].length).to be > 0
      
      # Check for core prompts
      prompt_names = response_data['result']['prompts'].map { |prompt| prompt['name'] }
      expect(prompt_names).to include('seo_optimize', 'content_summarize', 'content_generate')
      
      # Check prompt structure
      first_prompt = response_data['result']['prompts'].first
      expect(first_prompt).to have_key('name')
      expect(first_prompt).to have_key('description')
      expect(first_prompt).to have_key('arguments')
    end
  end

  describe 'GET #tools_stream' do
    it 'returns streaming response' do
      get :tools_stream
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/event-stream')
    end
  end

  describe 'authentication' do
    context 'when user is inactive' do
      before do
        user.update!(status: 'inactive')
      end

      let(:request_with_inactive_user) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: { limit: 5 }
          },
          id: 2
        }
      end

      it 'returns unauthorized error' do
        post :tools_call, params: request_with_inactive_user, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be false
        expect(response_data['error']).to eq('User account is inactive')
        expect(response_data['code']).to eq('INACTIVE_USER')
      end
    end
  end

  describe 'tool permissions' do
    let(:regular_user) { create(:user, :editor) }
    let(:regular_api_key) { regular_user.api_key }

    before do
      request.headers['Authorization'] = "Bearer #{regular_api_key}"
    end

    context 'when user lacks permission for create_post' do
      let(:create_post_request) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'create_post',
            arguments: {
              title: 'Test Post',
              content: 'Test content'
            }
          },
          id: 2
        }
      end

      it 'returns permission error' do
        post :tools_call, params: create_post_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32000)
        expect(response_data['error']['message']).to include('Permission denied')
      end
    end

    context 'when user has permission for get_posts' do
      let(:get_posts_request) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: {
              limit: 5
            }
          },
          id: 2
        }
      end

      it 'allows the operation' do
        post :tools_call, params: get_posts_request, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['result']).to have_key('content')
      end
    end
  end

  describe 'error handling' do
    context 'when tool execution raises an exception' do
      before do
        allow_any_instance_of(Api::V1::McpController).to receive(:execute_tool).and_raise(StandardError.new('Test error'))
      end

      let(:request_that_raises_error) do
        {
          jsonrpc: '2.0',
          method: 'tools/call',
          params: {
            name: 'get_posts',
            arguments: { limit: 5 }
          },
          id: 2
        }
      end

      it 'returns internal error' do
        post :tools_call, params: request_that_raises_error, as: :json
        
        expect(response).to have_http_status(:ok)
        
        response_data = JSON.parse(response.body)
        expect(response_data['jsonrpc']).to eq('2.0')
        expect(response_data['error']['code']).to eq(-32603)
        expect(response_data['error']['message']).to eq('Internal error')
      end
    end
  end
end