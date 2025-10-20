module Resolvers
  class ChannelsResolver < Resolvers::BaseResolver
    description "Find channels"

    argument :slug, String, required: false, description: "Find channel by slug"
    argument :domain, String, required: false, description: "Find channel by domain"
    argument :enabled, Boolean, required: false, description: "Filter by enabled status"
    argument :device_type, String, required: false, description: "Filter by device type"

    type [Types::ChannelType], null: true

    def resolve(slug: nil, domain: nil, enabled: nil, device_type: nil)
      channels = Channel.all

      channels = channels.where(slug: slug) if slug.present?
      channels = channels.where(domain: domain) if domain.present?
      channels = channels.where(enabled: enabled) if enabled != nil
      
      if device_type.present?
        channels = channels.where("metadata->>'device_type' = ?", device_type)
      end

      channels.order(:name)
    end
  end
end

