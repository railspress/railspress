class CreateAiAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_agents do |t|
      t.string :name
      t.text :description
      t.string :agent_type
      t.text :prompt
      t.text :content
      t.text :guidelines
      t.text :rules
      t.text :tasks
      t.text :master_prompt
      t.references :ai_provider, null: false, foreign_key: true
      t.boolean :active
      t.integer :position

      t.timestamps
    end
  end
end
