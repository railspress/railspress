class AddGreetingToAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agents, :greeting, :text
  end
end
