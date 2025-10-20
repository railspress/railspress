module Resolvers
  class ChannelResolver < Resolvers::BaseResolver
    description "Find a single channel"

    argument :id, ID, required: false, description: "Find channel by ID"
    argument :slug, String, required: false, description: "Find channel by slug"

    type Types::ChannelType, null: true

    def resolve(id: nil, slug: nil)
      if id.present?
        Channel.find(id)
      elsif slug.present?
        Channel.find_by(slug: slug)
      else
        raise GraphQL::ExecutionError, "Either id or slug must be provided"
      end
    end
  end
end

