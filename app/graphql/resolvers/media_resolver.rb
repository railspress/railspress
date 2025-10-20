module Resolvers
  class MediaResolver < Resolvers::BaseResolver
    description "Find media files with channel filtering"

    argument :channel, String, required: false, description: "Filter media by channel slug"
    argument :file_type, String, required: false, description: "Filter by file type"
    argument :search, String, required: false, description: "Search in title and description"
    argument :limit, Integer, required: false, description: "Limit number of results"
    argument :offset, Integer, required: false, description: "Offset for pagination"

    type [Types::MediumType], null: true

    def resolve(channel: nil, file_type: nil, search: nil, limit: nil, offset: nil)
      media = Medium.all

      # Apply filters
      media = media.where(file_type: file_type) if file_type.present?
      media = media.where("title ILIKE ? OR description ILIKE ?", "%#{search}%", "%#{search}%") if search.present?

      # Channel filtering
      if channel.present?
        channel_obj = Channel.find_by(slug: channel)
        if channel_obj
          media = media.left_joins(:channels)
                      .where('channels.id = ? OR channels.id IS NULL', channel_obj.id)

          # Apply channel exclusions
          excluded_media_ids = channel_obj.channel_overrides
                                          .exclusions
                                          .enabled
                                          .where(resource_type: 'Medium')
                                          .pluck(:resource_id)
          media = media.where.not(id: excluded_media_ids) if excluded_media_ids.any?

          # Set channel context for serialization
          context[:current_channel] = channel_obj
        end
      end

      # Pagination
      media = media.limit(limit) if limit.present?
      media = media.offset(offset) if offset.present?

      media.order(created_at: :desc)
    end
  end
end

