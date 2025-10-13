module Railspress
  module AiAgentPluginHelper
    # Easy access to AI Agents from plugins
    
    # Create a new AI Agent for your plugin
    # 
    # Example:
    #   Railspress::AiAgentPluginHelper.create_agent(
    #     name: 'My Plugin Agent',
    #     agent_type: 'custom_analyzer',
    #     prompt: 'You are a custom analyzer...',
    #     provider_type: 'openai'
    #   )
    def self.create_agent(name:, agent_type:, prompt:, provider_type: 'openai', **options)
      # Find or create provider
      provider = AiProvider.find_by(provider_type: provider_type, active: true)
      
      unless provider
        raise "No active AI provider found for type: #{provider_type}. Please configure one in Admin > AI Agents > Providers"
      end
      
      # Create agent
      AiAgent.create!(
        name: name,
        agent_type: agent_type,
        prompt: prompt,
        ai_provider: provider,
        content: options[:content],
        guidelines: options[:guidelines],
        rules: options[:rules],
        tasks: options[:tasks],
        master_prompt: options[:master_prompt],
        active: options.fetch(:active, true),
        position: options.fetch(:position, 0)
      )
    end
    
    # Execute an AI Agent by type
    #
    # Example:
    #   result = Railspress::AiAgentPluginHelper.execute('content_summarizer', 'Text to summarize')
    def self.execute(agent_type, input)
      agent = AiAgent.active.find_by(agent_type: agent_type)
      
      unless agent
        raise "No active agent found for type: #{agent_type}"
      end
      
      agent.execute(input)
    end
    
    # Execute an AI Agent by name
    #
    # Example:
    #   result = Railspress::AiAgentPluginHelper.execute_by_name('My Custom Agent', 'Input text')
    def self.execute_by_name(name, input)
      agent = AiAgent.active.find_by(name: name)
      
      unless agent
        raise "No active agent found with name: #{name}"
      end
      
      agent.execute(input)
    end
    
    # List all available AI Agents
    def self.available_agents
      AiAgent.active.ordered
    end
    
    # List all available providers
    def self.available_providers
      AiProvider.active.ordered
    end
    
    # Check if an agent type exists
    def self.agent_exists?(agent_type)
      AiAgent.active.exists?(agent_type: agent_type)
    end
    
    # Get agent by type
    def self.get_agent(agent_type)
      AiAgent.active.find_by(agent_type: agent_type)
    end
    
    # Update agent settings
    #
    # Example:
    #   Railspress::AiAgentPluginHelper.update_agent('content_summarizer', 
    #     prompt: 'New prompt...')
    def self.update_agent(agent_type, **attributes)
      agent = AiAgent.find_by(agent_type: agent_type)
      
      unless agent
        raise "Agent not found: #{agent_type}"
      end
      
      agent.update!(attributes)
      agent
    end
    
    # Delete an agent
    def self.delete_agent(agent_type)
      agent = AiAgent.find_by(agent_type: agent_type)
      agent&.destroy
    end
    
    # Batch execute multiple agents
    #
    # Example:
    #   results = Railspress::AiAgentPluginHelper.batch_execute([
    #     { type: 'content_summarizer', input: 'Text 1' },
    #     { type: 'seo_analyzer', input: 'Text 2' }
    #   ])
    def self.batch_execute(agent_requests)
      agent_requests.map do |request|
        {
          agent_type: request[:type],
          result: execute(request[:type], request[:input]),
          status: 'success'
        }
      rescue => e
        {
          agent_type: request[:type],
          error: e.message,
          status: 'error'
        }
      end
    end
    
    # Register a custom agent type (add to AiAgent::AGENT_TYPES)
    def self.register_agent_type(type, description = nil)
      unless AiAgent::AGENT_TYPES.include?(type)
        AiAgent::AGENT_TYPES << type
      end
    end
  end
end



