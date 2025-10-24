class AddSystemDefaultToAiProvidersAndUuidToAiAgents < ActiveRecord::Migration[7.1]
  def change
    # Add system_default to ai_providers
    add_column :ai_providers, :system_default, :boolean, default: false
    
    # Add uuid to ai_agents
    add_column :ai_agents, :uuid, :string
    add_index :ai_agents, :uuid, unique: true
    
    # Set the first active provider as system_default if none exists
    reversible do |dir|
      dir.up do
        if AiProvider.where(system_default: true).none?
          provider = AiProvider.where(active: true).first
          provider&.update_column(:system_default, true)
        end
        
        # Generate UUIDs for existing agents
        AiAgent.where(uuid: nil).find_each do |agent|
          agent.update_column(:uuid, SecureRandom.uuid)
        end
      end
    end
  end
end
