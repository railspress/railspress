module Types
  class MetaFieldType < Types::BaseObject
    description "A meta field for storing custom data on models"

    field :id, ID, null: false, description: "Unique identifier for the meta field"
    field :key, String, null: false, description: "The key/name of the meta field"
    field :value, String, null: true, description: "The value of the meta field"
    field :immutable, Boolean, null: false, description: "Whether this meta field can be modified"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the meta field was created"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the meta field was last updated"
    field :metable_type, String, null: false, description: "The type of object this meta field belongs to"
    field :metable_id, ID, null: false, description: "The ID of the object this meta field belongs to"

    # Helper method to get the parent object
    field :metable, GraphQL::Types::JSON, null: true, description: "The parent object this meta field belongs to" do
      def resolve(object, args, context)
        # Return basic info about the metable without exposing the full object
        {
          type: object.metable_type,
          id: object.metable_id
        }
      end
    end

    # JSON value helper
    field :json_value, GraphQL::Types::JSON, null: true, description: "The value parsed as JSON if valid" do
      def resolve(object, args, context)
        object.json_value
      end
    end

    # Type-casted value helpers
    field :int_value, Integer, null: true, description: "The value as an integer" do
      def resolve(object, args, context)
        object.to_i
      end
    end

    field :float_value, Float, null: true, description: "The value as a float" do
      def resolve(object, args, context)
        object.to_f
      end
    end

    field :bool_value, Boolean, null: true, description: "The value as a boolean" do
      def resolve(object, args, context)
        object.to_bool
      end
    end
  end
end


