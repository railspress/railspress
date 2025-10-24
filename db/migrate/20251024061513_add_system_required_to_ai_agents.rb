class AddSystemRequiredToAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agents, :system_required, :boolean, default: false, null: false
    add_index :ai_agents, :system_required
  end
end
