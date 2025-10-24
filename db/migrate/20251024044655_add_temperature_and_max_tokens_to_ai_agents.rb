class AddTemperatureAndMaxTokensToAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agents, :temperature, :decimal, precision: 3, scale: 2
    add_column :ai_agents, :max_tokens, :integer
    
    # Set defaults for existing records
    reversible do |dir|
      dir.up do
        AiAgent.find_each do |agent|
          # Use provider defaults if available
          agent.update_columns(
            temperature: agent.ai_provider&.temperature || 0.7,
            max_tokens: agent.ai_provider&.max_tokens || 4000
          )
        end
      end
    end
  end
end
