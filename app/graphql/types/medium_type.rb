module Types
  class MediumType < Types::BaseObject
    description "A media file with channel support"

    field :id, ID, null: false
    field :title, String, null: false
    field :file_name, String, null: false
    field :file_type, String, null: false
    field :description, String, null: true
    field :alt_text, String, null: true
    field :file_size, Integer, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Channel support
    field :channels, [Types::ChannelType], null: true
    field :channel_context, String, null: true, description: "Current channel context"
    field :provenance, GraphQL::Types::JSON, null: true, description: "Data provenance information"

    # Computed fields
    field :url, String, null: true
    field :content_type, String, null: false
    field :file_extension, String, null: true
    field :is_image, Boolean, null: false
    field :is_video, Boolean, null: false
    field :is_document, Boolean, null: false

    def url
      object.file_url if object.respond_to?(:file_url)
    end

    def content_type
      'media'
    end

    def file_extension
      File.extname(object.file_name).downcase[1..-1]
    end

    def is_image
      %w[jpg jpeg png gif webp svg].include?(file_extension)
    end

    def is_video
      %w[mp4 avi mov wmv flv webm].include?(file_extension)
    end

    def is_document
      %w[pdf doc docx txt rtf].include?(file_extension)
    end
  end
end

