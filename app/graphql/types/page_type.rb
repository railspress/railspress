module Types
  class PageType < Types::BaseObject
    description "A page with channel support"

    field :id, ID, null: false
    field :title, String, null: false
    field :slug, String, null: false
    field :content, String, null: true
    field :status, String, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true
    field :parent_id, Integer, null: true
    field :order, Integer, null: true
    field :template, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Channel support
    field :channels, [Types::ChannelType], null: true
    field :channel_context, String, null: true, description: "Current channel context"
    field :provenance, GraphQL::Types::JSON, null: true, description: "Data provenance information"

    # Associations
    field :user, Types::UserType, null: true
    field :parent, Types::PageType, null: true
    field :children, [Types::PageType], null: true

    # Computed fields
    field :url, String, null: true
    field :author_name, String, null: true
    field :content_type, String, null: false

    def url
      Rails.application.routes.url_helpers.page_url(object, host: context[:request]&.host)
    rescue
      nil
    end

    def author_name
      object.user&.display_name || object.user&.email
    end

    def content_type
      'page'
    end
  end
end