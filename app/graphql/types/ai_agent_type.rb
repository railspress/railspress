module Types
  class AiAgentType < Types::BaseObject
    description "An AI agent for automated tasks"

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :prompt, String, null: false
    field :guidelines, String, null: true
    field :tasks, String, null: true
    field :agent_type, String, null: false
    field :active, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # AI Provider
    field :ai_provider, Types::BaseObject, null: true do
      description "The AI provider this agent uses"
    end
    
    # Usage statistics
    field :usage_count, Integer, null: false, description: "Number of times this agent has been used"
    field :last_used_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When this agent was last used"
    
    # Meta Fields
    field :meta_fields, [Types::MetaFieldType], null: true, description: "Custom meta fields for this AI agent" do
      argument :key, String, required: false, description: "Filter by specific meta field key"
      argument :immutable, Boolean, required: false, description: "Filter by immutable status"
    end
    
    field :meta_field, Types::MetaFieldType, null: true, description: "Get a specific meta field by key" do
      argument :key, String, required: true, description: "The key of the meta field to retrieve"
    end
    
    field :all_meta, GraphQL::Types::JSON, null: true, description: "All meta fields as a key-value hash"
    
    def ai_provider
      object.ai_provider
    end
    
    def usage_count
      object.ai_usages.count
    end
    
    def last_used_at
      object.ai_usages.order(created_at: :desc).first&.created_at
    end
    
    def meta_fields(key: nil, immutable: nil)
      meta_fields = object.meta_fields
      meta_fields = meta_fields.by_key(key) if key.present?
      meta_fields = meta_fields.immutable if immutable == true
      meta_fields = meta_fields.mutable if immutable == false
      meta_fields
    end
    
    def meta_field(key:)
      object.meta_fields.find_by(key: key)
    end
    
    def all_meta
      object.all_meta
    end
  end
end


