module Types
  class ChannelOverrideType < Types::BaseObject
    description "A channel override for customizing content per channel"

    field :id, ID, null: false
    field :kind, String, null: false, description: "Type of override: 'override' or 'exclude'"
    field :path, String, null: false, description: "JSON path to the field being overridden"
    field :data, GraphQL::Types::JSON, null: true, description: "Override data"
    field :enabled, Boolean, null: false
    field :resource_type, String, null: false
    field :resource_id, Integer, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Associations
    field :channel, Types::ChannelType, null: false
    field :resource, Types::NodeType, null: true

    # Computed fields
    field :is_override, Boolean, null: false
    field :is_exclusion, Boolean, null: false
    field :resource_name, String, null: true

    def is_override
      object.kind == 'override'
    end

    def is_exclusion
      object.kind == 'exclude'
    end

    def resource_name
      return nil unless object.resource_id
      
      case object.resource_type
      when 'Post'
        Post.find_by(id: object.resource_id)&.title
      when 'Page'
        Page.find_by(id: object.resource_id)&.title
      when 'Medium'
        Medium.find_by(id: object.resource_id)&.title
      else
        "#{object.resource_type} ##{object.resource_id}"
      end
    end
  end
end

