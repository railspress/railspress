module Types
  class UploadType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :description, String, null: true
    field :alt_text, String, null: true
    
    # File information
    field :filename, String, null: true
    field :content_type, String, null: true
    field :file_size, Integer, null: true
    field :url, String, null: true
    
    # File type flags
    field :image, Boolean, null: false
    field :video, Boolean, null: false
    field :document, Boolean, null: false
    
    # Security status
    field :quarantined, Boolean, null: false
    field :quarantine_reason, String, null: true
    field :approved, Boolean, null: false
    
    # Timestamps
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Relationships
    field :user, Types::UserType, null: false
    field :storage_provider, Types::StorageProviderType, null: true
    field :media, [Types::MediaType], null: false
    
    # Helper methods for file type flags
    def image
      object.image?
    end
    
    def video
      object.video?
    end
    
    def document
      object.document?
    end
    
    def quarantined
      object.quarantined?
    end
    
    def approved
      object.approved?
    end
    
    def file_size
      object.file_size
    end
  end
end

