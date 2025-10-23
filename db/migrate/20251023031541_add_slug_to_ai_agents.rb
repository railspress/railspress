class AddSlugToAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agents, :slug, :string
    add_index :ai_agents, :slug, unique: true
  end
end
