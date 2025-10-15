module Types
  class StorageProviderType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :provider_type, String, null: false
    field :active, Boolean, null: false
    field :position, Integer, null: true
    
    # Provider type flags
    field :local, Boolean, null: false
    field :s3, Boolean, null: false
    field :gcs, Boolean, null: false
    field :azure, Boolean, null: false
    
    # Timestamps
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Helper methods for provider type flags
    def local
      object.local?
    end
    
    def s3
      object.s3?
    end
    
    def gcs
      object.gcs?
    end
    
    def azure
      object.azure?
    end
  end
end

