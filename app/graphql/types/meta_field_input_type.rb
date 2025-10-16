module Types
  class MetaFieldInputType < Types::BaseInputObject
    description "Input for creating or updating a meta field"

    argument :key, String, required: true, description: "The key/name of the meta field"
    argument :value, String, required: false, description: "The value of the meta field"
    argument :immutable, Boolean, required: false, default_value: false, description: "Whether this meta field can be modified"
  end

  class MetaFieldBulkInputType < Types::BaseInputObject
    description "Input for bulk creating or updating meta fields"

    argument :meta_fields, [MetaFieldInputType], required: true, description: "Array of meta fields to create or update"
  end

  class MetaFieldUpdateInputType < Types::BaseInputObject
    description "Input for updating an existing meta field"

    argument :value, String, required: false, description: "The new value of the meta field"
    argument :immutable, Boolean, required: false, description: "Whether this meta field can be modified"
  end
end




