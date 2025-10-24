class CreateAgentEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_events do |t|
      t.references :agent_session, null: false, foreign_key: true
      t.references :target_event, null: true, foreign_key: { to_table: :agent_events }
      t.string :event_type, null: false # intent, action, observation, response, feedback
      t.string :subtype # user_text, api_call, api_result, text, unlike, etc.
      t.text :summary
      t.json :payload, default: {}
      t.integer :sequence # for strict ordering if needed
      t.timestamps
    end
    
    add_index :agent_events, :event_type
    add_index :agent_events, [:agent_session_id, :event_type]
    add_index :agent_events, [:agent_session_id, :created_at]
    # target_event_id index is automatically created by foreign_key
  end
end
