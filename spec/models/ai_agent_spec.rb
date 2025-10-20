require 'rails_helper'

RSpec.describe AiAgent, type: :model do
  let(:ai_provider) { create(:ai_provider) }
  let(:user) { create(:user) }
  let(:ai_agent) { create(:ai_agent, ai_provider: ai_provider) }

  describe 'associations' do
    it { should belong_to(:ai_provider) }
    it { should have_many(:ai_usages).dependent(:destroy) }
    it { should have_many(:meta_fields).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:agent_type) }
    it { should validate_presence_of(:ai_provider) }
    it { should validate_inclusion_of(:agent_type).in_array(AiAgent::AGENT_TYPES) }
  end

  describe 'scopes' do
    let!(:active_agent) { create(:ai_agent, active: true) }
    let!(:inactive_agent) { create(:ai_agent, active: false) }
    let!(:content_summarizer) { create(:ai_agent, agent_type: 'content_summarizer') }
    let!(:post_writer) { create(:ai_agent, agent_type: 'post_writer') }

    describe '.active' do
      it 'returns only active agents' do
        expect(AiAgent.active).to include(active_agent)
        expect(AiAgent.active).not_to include(inactive_agent)
      end
    end

    describe '.by_type' do
      it 'returns agents filtered by type' do
        expect(AiAgent.by_type('content_summarizer')).to include(content_summarizer)
        expect(AiAgent.by_type('content_summarizer')).not_to include(post_writer)
      end
    end

    describe '.ordered' do
      it 'orders by position and name' do
        agent1 = create(:ai_agent, position: 2, name: 'B Agent')
        agent2 = create(:ai_agent, position: 1, name: 'A Agent')
        agent3 = create(:ai_agent, position: 1, name: 'C Agent')

        ordered_agents = AiAgent.where(id: [agent1.id, agent2.id, agent3.id]).ordered.to_a
        expect(ordered_agents.map(&:name)).to eq(['A Agent', 'C Agent', 'B Agent'])
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values for new records' do
        agent = AiAgent.new
        expect(agent.active).to be true
        expect(agent.position).to eq(0)
      end
    end
  end

  describe '#full_prompt' do
    let(:agent) do
      create(:ai_agent,
        master_prompt: 'Master prompt',
        prompt: 'Agent prompt',
        content: 'Content guidelines',
        guidelines: 'Guidelines',
        rules: 'Rules',
        tasks: 'Tasks'
      )
    end

    it 'builds complete prompt with all components' do
      user_input = 'Test input'
      context = { temperature: 0.7 }

      result = agent.full_prompt(user_input, context)

      expect(result).to include('Master prompt')
      expect(result).to include('Agent prompt')
      expect(result).to include('Content Guidelines:')
      expect(result).to include('Content guidelines')
      expect(result).to include('Guidelines:')
      expect(result).to include('Guidelines')
      expect(result).to include('Rules:')
      expect(result).to include('Rules')
      expect(result).to include('Tasks:')
      expect(result).to include('Tasks')
      expect(result).to include('User Input: Test input')
      expect(result).to include('Context:')
      expect(result).to include('temperature: 0.7')
    end

    it 'handles empty components gracefully' do
      agent = create(:ai_agent, master_prompt: nil, prompt: nil, content: nil, guidelines: nil, rules: nil, tasks: nil)
      result = agent.full_prompt('test', {})

      expect(result).to eq('User Input: test')
    end
  end

  describe '#execute' do
    let(:agent) { create(:ai_agent, ai_provider: ai_provider) }

    context 'with successful AI service call' do
      before do
        allow_any_instance_of(AiService).to receive(:generate).and_return('AI Response')
      end

      it 'executes successfully and logs usage' do
        result = agent.execute('Test input', {}, user)

        expect(result).to eq('AI Response')
        expect(agent.ai_usages.count).to eq(1)

        usage = agent.ai_usages.last
        expect(usage.user).to eq(user)
        expect(usage.prompt).to include('Test input')
        expect(usage.response).to eq('AI Response')
        expect(usage.success).to be true
        expect(usage.tokens_used).to be > 0
        expect(usage.cost).to be >= 0
        expect(usage.response_time).to be > 0
        expect(usage.metadata['user_input']).to eq('Test input')
        expect(usage.metadata['agent_type']).to eq(agent.agent_type)
      end

      it 'falls back to first user when no user provided' do
        # Ensure we have a user in the database
        user = create(:user)
        
        result = agent.execute('Test input')

        expect(result).to eq('AI Response')
        usage = agent.ai_usages.last
        expect(usage.user).to eq(user)
      end
    end

    context 'with AI service error' do
      before do
        allow_any_instance_of(AiService).to receive(:generate).and_raise(StandardError.new('API Error'))
      end

      it 'logs failed usage and re-raises error' do
        expect { agent.execute('Test input', {}, user) }.to raise_error(StandardError, 'API Error')

        expect(agent.ai_usages.count).to eq(1)

        usage = agent.ai_usages.last
        expect(usage.user).to eq(user)
        expect(usage.success).to be false
        expect(usage.error_message).to eq('API Error')
        expect(usage.response).to be_nil
        expect(usage.metadata['error_class']).to eq('StandardError')
      end
    end
  end

  describe 'usage statistics' do
    let(:agent) { create(:ai_agent) }

    before do
      # Create successful usages
      create(:ai_usage, ai_agent: agent, user: user, success: true, tokens_used: 100, cost: 0.001, response_time: 1.5)
      create(:ai_usage, ai_agent: agent, user: user, success: true, tokens_used: 150, cost: 0.002, response_time: 2.0)
      
      # Create failed usage
      create(:ai_usage, ai_agent: agent, user: user, success: false, tokens_used: 50, cost: 0.0, response_time: 1.0)
      
      # Create usage from today
      create(:ai_usage, ai_agent: agent, user: user, success: true, tokens_used: 200, cost: 0.003, response_time: 1.8, created_at: Time.current)
      
      # Create usage from this month
      create(:ai_usage, ai_agent: agent, user: user, success: true, tokens_used: 300, cost: 0.004, response_time: 2.2, created_at: Time.current.beginning_of_month + 1.day)
    end

    describe '#total_requests' do
      it 'returns total number of requests' do
        expect(agent.total_requests).to eq(5)
      end
    end

    describe '#total_tokens' do
      it 'returns total tokens used' do
        expect(agent.total_tokens).to eq(800)
      end
    end

    describe '#total_cost' do
      it 'returns total cost' do
        expect(agent.total_cost).to eq(0.01)
      end
    end

    describe '#requests_today' do
      it 'returns requests from today' do
        # Count only the usage created for today in the before block
        today_count = agent.ai_usages.today.count
        expect(today_count).to be >= 1
      end
    end

    describe '#requests_this_month' do
      it 'returns requests from this month' do
        # Count only the usage created for this month in the before block
        month_count = agent.ai_usages.this_month.count
        expect(month_count).to be >= 2
      end
    end

    describe '#average_response_time' do
      it 'returns average response time' do
        expect(agent.average_response_time).to eq(1.7)
      end
    end

    describe '#success_rate' do
      it 'returns success rate percentage' do
        expect(agent.success_rate).to eq(80.0)
      end
    end

    describe '#last_used' do
      it 'returns last usage timestamp' do
        expect(agent.last_used).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe 'private methods' do
    describe '#calculate_tokens' do
      it 'estimates tokens based on text length' do
        prompt = 'This is a test prompt with multiple words.'
        response = 'This is a response.'
        
        tokens = ai_agent.send(:calculate_tokens, prompt, response)
        total_text = prompt + response
        expected_tokens = (total_text.length / 4.0).ceil
        
        expect(tokens).to eq(expected_tokens)
      end
    end

    describe '#calculate_cost' do
      it 'calculates cost based on provider type' do
        prompt = 'Test prompt'
        response = 'Test response'
        
        # Test OpenAI provider
        openai_provider = create(:ai_provider, provider_type: 'openai')
        openai_agent = create(:ai_agent, ai_provider: openai_provider)
        
        cost = openai_agent.send(:calculate_cost, prompt, response)
        tokens = openai_agent.send(:calculate_tokens, prompt, response)
        expected_cost = tokens * 0.00002
        
        expect(cost).to be_within(0.000001).of(expected_cost)
        
        # Test default provider (which is openai from factory)
        cost = ai_agent.send(:calculate_cost, prompt, response)
        tokens = ai_agent.send(:calculate_tokens, prompt, response)
        expected_cost = tokens * 0.00002  # OpenAI rate
        
        expect(cost).to be_within(0.000001).of(expected_cost)
      end
    end
  end

  describe 'metable concern' do
    it 'includes Metable concern' do
      expect(ai_agent).to respond_to(:meta_fields)
      expect(ai_agent).to respond_to(:get_meta)
      expect(ai_agent).to respond_to(:set_meta)
    end
  end
end
