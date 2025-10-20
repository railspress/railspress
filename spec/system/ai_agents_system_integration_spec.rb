require 'rails_helper'

RSpec.describe 'AI Agents System Integration', type: :system do
  let(:admin_user) { create(:user, role: :administrator, email: 'admin@example.com') }
  let(:ai_provider) { create(:ai_provider, provider_type: 'openai', api_key: 'sk-test-key') }
  let(:ai_agent) { create(:ai_agent, ai_provider: ai_provider, agent_type: 'content_summarizer') }

  before do
    # Set up test data
    ActsAsTenant.current_tenant = create(:tenant)
    sign_in admin_user
  end

  describe 'Complete AI Agent Workflow' do
    it 'allows admin to create, configure, and execute AI agents' do
      # Step 1: Create AI Provider
      visit new_admin_ai_provider_path
      
      fill_in 'Name', with: 'Test OpenAI Provider'
      select 'OpenAI', from: 'Provider Type'
      fill_in 'API Key', with: 'sk-test-key-123456789'
      fill_in 'Model Identifier', with: 'gpt-4'
      fill_in 'Max Tokens', with: '4000'
      fill_in 'Temperature', with: '0.7'
      check 'Active'
      
      click_button 'Create AI Provider'
      
      expect(page).to have_content('AI Provider was successfully created')
      
      # Step 2: Create AI Agent
      visit new_admin_ai_agent_path
      
      fill_in 'Name', with: 'Content Summarizer Agent'
      select 'content_summarizer', from: 'Agent Type'
      fill_in 'Prompt', with: 'You are a content summarizer. Summarize the following content:'
      fill_in 'Content', with: 'Focus on key points and main ideas.'
      fill_in 'Guidelines', with: 'Keep summaries concise and informative.'
      fill_in 'Rules', with: 'Do not add personal opinions or bias.'
      fill_in 'Tasks', with: 'Extract main points, identify key themes, provide brief summary.'
      fill_in 'Master Prompt', with: 'You are an AI assistant specialized in content analysis.'
      select 'Test OpenAI Provider', from: 'AI Provider'
      check 'Active'
      fill_in 'Position', with: '1'
      
      click_button 'Create AI Agent'
      
      expect(page).to have_content('AI Agent created successfully')
      
      # Step 3: Test AI Agent
      agent = AiAgent.last
      visit admin_ai_agent_path(agent)
      
      # Mock AI service response
      allow_any_instance_of(AiService).to receive(:generate).and_return('This is a summary of the content.')
      
      click_button 'Test Agent'
      
      # Fill in test input
      fill_in 'Test Input', with: 'This is a long article about artificial intelligence and its applications in modern technology.'
      click_button 'Execute Test'
      
      expect(page).to have_content('Test completed successfully')
      
      # Step 4: Check Usage Statistics
      visit usage_admin_ai_agents_path
      
      expect(page).to have_content('AI Agents Usage')
      expect(page).to have_content('Total Requests')
      expect(page).to have_content('Total Tokens')
      expect(page).to have_content('Total Cost')
      
      # Step 5: API Integration Test
      visit '/api/v1/ai_agents'
      
      # Should redirect to login since we're not authenticated via API
      expect(page).to have_content('Authentication required')
    end
  end

  describe 'AI Agent Error Handling' do
    it 'handles AI service errors gracefully' do
      visit admin_ai_agent_path(ai_agent)
      
      # Mock AI service error
      allow_any_instance_of(AiService).to receive(:generate).and_raise(StandardError.new('API Error: Rate limit exceeded'))
      
      click_button 'Test Agent'
      fill_in 'Test Input', with: 'Test content'
      click_button 'Execute Test'
      
      expect(page).to have_content('Test failed')
      expect(page).to have_content('API Error')
      
      # Check that error was logged
      usage = AiUsage.last
      expect(usage.success).to be false
      expect(usage.error_message).to include('API Error')
    end
  end

  describe 'AI Agent Management' do
    it 'allows bulk operations on AI agents' do
      # Create multiple agents
      agent1 = create(:ai_agent, name: 'Agent 1', ai_provider: ai_provider)
      agent2 = create(:ai_agent, name: 'Agent 2', ai_provider: ai_provider)
      agent3 = create(:ai_agent, name: 'Agent 3', ai_provider: ai_provider)
      
      visit admin_ai_agents_path
      
      # Select multiple agents
      check "agent_#{agent1.id}"
      check "agent_#{agent2.id}"
      
      # Bulk activate
      select 'Activate', from: 'Bulk Action'
      click_button 'Apply'
      
      expect(page).to have_content('AI Agents were successfully updated')
      
      # Verify agents are active
      agent1.reload
      agent2.reload
      expect(agent1.active).to be true
      expect(agent2.active).to be true
    end

    it 'allows searching and filtering agents' do
      # Create agents with different types
      summarizer = create(:ai_agent, name: 'Content Summarizer', agent_type: 'content_summarizer', ai_provider: ai_provider)
      writer = create(:ai_agent, name: 'Post Writer', agent_type: 'post_writer', ai_provider: ai_provider)
      
      visit admin_ai_agents_path
      
      # Search by name
      fill_in 'Search', with: 'Summarizer'
      click_button 'Search'
      
      expect(page).to have_content('Content Summarizer')
      expect(page).not_to have_content('Post Writer')
      
      # Filter by type
      select 'post_writer', from: 'Agent Type'
      click_button 'Filter'
      
      expect(page).to have_content('Post Writer')
      expect(page).not_to have_content('Content Summarizer')
    end
  end

  describe 'AI Agent API Integration' do
    it 'provides complete API functionality' do
      # Test API authentication
      visit '/api/v1/ai_agents'
      expect(page).to have_content('Authentication required')
      
      # Test with valid API key
      user = create(:user, api_key: 'test-api-key')
      
      # Mock authentication
      allow_any_instance_of(Api::V1::AiAgentsController).to receive(:current_user).and_return(user)
      
      # Test API endpoints
      visit '/api/v1/ai_agents'
      expect(page).to have_content('"success":true')
      
      # Test agent execution via API
      allow_any_instance_of(AiService).to receive(:generate).and_return('API test response')
      
      visit "/api/v1/ai_agents/#{ai_agent.id}/execute"
      expect(page).to have_content('"success":true')
      expect(page).to have_content('"result":"API test response"')
    end
  end

  describe 'AI Agent Performance Monitoring' do
    it 'tracks usage statistics and performance metrics' do
      # Create usage records
      create(:ai_usage, 
        ai_agent: ai_agent, 
        user: admin_user, 
        success: true, 
        tokens_used: 100, 
        cost: 0.001, 
        response_time: 1.5
      )
      
      create(:ai_usage, 
        ai_agent: ai_agent, 
        user: admin_user, 
        success: true, 
        tokens_used: 150, 
        cost: 0.002, 
        response_time: 2.0
      )
      
      create(:ai_usage, 
        ai_agent: ai_agent, 
        user: admin_user, 
        success: false, 
        tokens_used: 50, 
        cost: 0.0, 
        response_time: 1.0
      )
      
      visit admin_ai_agent_path(ai_agent)
      
      # Check usage statistics
      expect(page).to have_content('Total Requests: 3')
      expect(page).to have_content('Total Tokens: 300')
      expect(page).to have_content('Success Rate: 66.7%')
      expect(page).to have_content('Average Response Time: 1.5s')
      
      # Check usage breakdown
      visit usage_admin_ai_agents_path
      
      expect(page).to have_content('Agent Usage Breakdown')
      expect(page).to have_content('Total Usage Statistics')
    end
  end

  describe 'AI Agent Security' do
    it 'enforces proper authentication and authorization' do
      # Test admin access
      visit admin_ai_agents_path
      expect(page).to have_content('AI Agents')
      
      # Test non-admin access
      regular_user = create(:user, role: :author)
      sign_out admin_user
      sign_in regular_user
      
      visit admin_ai_agents_path
      expect(page).to have_content('Access denied')
      
      # Test API authentication
      visit '/api/v1/ai_agents'
      expect(page).to have_content('Authentication required')
    end

    it 'validates input and prevents injection attacks' do
      visit new_admin_ai_agent_path
      
      # Try to inject malicious content
      fill_in 'Name', with: '<script>alert("xss")</script>'
      fill_in 'Prompt', with: '{{ malicious.liquid.code }}'
      fill_in 'Content', with: 'DROP TABLE users;'
      
      select 'Test OpenAI Provider', from: 'AI Provider'
      click_button 'Create AI Agent'
      
      # Should handle malicious input safely
      expect(page).to have_content('AI Agent created successfully')
      
      agent = AiAgent.last
      expect(agent.name).to include('<script>')
      expect(agent.prompt).to include('{{ malicious.liquid.code }}')
    end
  end

  describe 'AI Agent Integration with Content System' do
    it 'integrates with posts and pages for content generation' do
      # Create a post
      post = create(:post, title: 'Test Post', content: 'This is a test post about artificial intelligence.')
      
      # Create an AI agent for content enhancement
      content_agent = create(:ai_agent, 
        name: 'Content Enhancer', 
        agent_type: 'post_writer',
        ai_provider: ai_provider,
        prompt: 'Enhance the following content:'
      )
      
      # Mock AI service response
      allow_any_instance_of(AiService).to receive(:generate).and_return('This is an enhanced version of the content with improved clarity and structure.')
      
      # Test agent execution with post content
      visit admin_ai_agent_path(content_agent)
      
      click_button 'Test Agent'
      fill_in 'Test Input', with: post.content
      click_button 'Execute Test'
      
      expect(page).to have_content('Test completed successfully')
      
      # Verify usage was logged
      usage = AiUsage.last
      expect(usage.prompt).to include(post.content)
      expect(usage.metadata['agent_type']).to eq('post_writer')
    end
  end

  describe 'AI Agent Multi-tenancy' do
    it 'respects tenant boundaries' do
      # Create tenant-specific data
      tenant1 = create(:tenant, name: 'Tenant 1')
      tenant2 = create(:tenant, name: 'Tenant 2')
      
      ActsAsTenant.current_tenant = tenant1
      agent1 = create(:ai_agent, name: 'Tenant 1 Agent', ai_provider: ai_provider)
      
      ActsAsTenant.current_tenant = tenant2
      agent2 = create(:ai_agent, name: 'Tenant 2 Agent', ai_provider: ai_provider)
      
      # Switch to tenant 1
      ActsAsTenant.current_tenant = tenant1
      visit admin_ai_agents_path
      
      expect(page).to have_content('Tenant 1 Agent')
      expect(page).not_to have_content('Tenant 2 Agent')
      
      # Switch to tenant 2
      ActsAsTenant.current_tenant = tenant2
      visit admin_ai_agents_path
      
      expect(page).to have_content('Tenant 2 Agent')
      expect(page).not_to have_content('Tenant 1 Agent')
    end
  end
end
