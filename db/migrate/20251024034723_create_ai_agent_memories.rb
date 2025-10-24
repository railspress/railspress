class CreateAiAgentMemories < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_agent_memories do |t|
      t.references :ai_agent, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :key, null: false
      t.json :value, default: {}
      t.text :value_text # for full-text search
      t.text :embedding # store as text for now (pgvector not available in SQLite)
      t.string :source # e.g., "agent_session:uuid"
      t.string :memory_type # preference, fact, context, etc.
      t.json :metadata, default: {}
      t.datetime :expires_at
      t.timestamps
    end
    
    add_index :ai_agent_memories, :key
    add_index :ai_agent_memories, [:ai_agent_id, :key]
    add_index :ai_agent_memories, [:user_id, :key]
    add_index :ai_agent_memories, :memory_type
    add_index :ai_agent_memories, :expires_at
    # add_index :ai_agent_memories, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
