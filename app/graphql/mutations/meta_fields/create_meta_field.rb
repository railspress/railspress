module Mutations
  module MetaFields
    class CreateMetaField < BaseMutation
      description "Create a new meta field for a model"

      argument :metable_type, String, required: true, description: "Type of the parent object (Post, Page, User, AiAgent)"
      argument :metable_id, ID, required: true, description: "ID of the parent object"
      argument :key, String, required: true, description: "The key/name of the meta field"
      argument :value, String, required: false, description: "The value of the meta field"
      argument :immutable, Boolean, required: false, default_value: false, description: "Whether this meta field can be modified"

      field :meta_field, Types::MetaFieldType, null: true, description: "The created meta field"
      field :errors, [String], null: false, description: "Any errors that occurred"

      def resolve(metable_type:, metable_id:, key:, value: nil, immutable: false)
        # Validate metable_type
        unless %w[Post Page User AiAgent].include?(metable_type.classify)
          return {
            meta_field: nil,
            errors: ["Invalid metable type. Must be one of: Post, Page, User, AiAgent"]
          }
        end

        begin
          # Find the parent object
          metable = metable_type.classify.constantize.find(metable_id)
          
          # Create the meta field
          meta_field = metable.meta_fields.build(
            key: key,
            value: value,
            immutable: immutable
          )
          
          if meta_field.save
            {
              meta_field: meta_field,
              errors: []
            }
          else
            {
              meta_field: nil,
              errors: meta_field.errors.full_messages
            }
          end
        rescue ActiveRecord::RecordNotFound
          {
            meta_field: nil,
            errors: ["#{metable_type} not found"]
          }
        rescue => e
          {
            meta_field: nil,
            errors: [e.message]
          }
        end
      end
    end
  end
end


