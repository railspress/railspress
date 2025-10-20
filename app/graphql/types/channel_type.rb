module Types
  class ChannelType < Types::BaseObject
    description "A content channel for distributing content across different platforms"

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :domain, String, null: true
    field :locale, String, null: false
    field :enabled, Boolean, null: false
    field :metadata, GraphQL::Types::JSON, null: true
    field :settings, GraphQL::Types::JSON, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Associations
    field :posts, [Types::PostType], null: true
    field :pages, [Types::PageType], null: true
    field :media, [Types::MediumType], null: true
    field :overrides, [Types::ChannelOverrideType], null: true

    # Computed fields
    field :content_count, Integer, null: false
    field :override_count, Integer, null: false
    field :device_type, String, null: true
    field :target_audience, String, null: true

    def content_count
      object.posts.count + object.pages.count + object.media.count
    end

    def override_count
      object.channel_overrides.count
    end

    def device_type
      object.metadata&.dig('device_type')
    end

    def target_audience
      object.metadata&.dig('target_audience')
    end
  end
end

