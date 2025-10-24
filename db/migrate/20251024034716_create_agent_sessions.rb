class CreateAgentSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_sessions do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.references :ai_provider, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :uuid, null: false
      t.string :status, default: "open", null: false # open, closed, error
      t.string :channel # web, api, mobile, etc.
      t.json :metadata, default: {}
      t.json :context, default: {} # session context
      t.integer :event_count, default: 0
      t.datetime :last_event_at
      t.timestamps
    end
    
    add_index :agent_sessions, :uuid, unique: true
    add_index :agent_sessions, :status
    add_index :agent_sessions, :channel
    add_index :agent_sessions, [:ai_agent_id, :status]
    add_index :agent_sessions, [:user_id, :status]
  end
end
