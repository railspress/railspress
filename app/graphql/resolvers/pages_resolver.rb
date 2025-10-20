module Resolvers
  class PagesResolver < Resolvers::BaseResolver
    description "Find pages with channel filtering"

    argument :channel, String, required: false, description: "Filter pages by channel slug"
    argument :status, String, required: false, description: "Filter by page status"
    argument :parent_id, Integer, required: false, description: "Filter by parent page ID"
    argument :search, String, required: false, description: "Search in title and content"
    argument :limit, Integer, required: false, description: "Limit number of results"
    argument :offset, Integer, required: false, description: "Offset for pagination"

    type [Types::PageType], null: true

    def resolve(channel: nil, status: nil, parent_id: nil, search: nil, limit: nil, offset: nil)
      pages = Page.all

      # Apply filters
      pages = pages.where(status: status) if status.present?
      pages = pages.where(parent_id: parent_id) if parent_id.present?
      pages = pages.where("title ILIKE ? OR content ILIKE ?", "%#{search}%", "%#{search}%") if search.present?

      # Channel filtering
      if channel.present?
        channel_obj = Channel.find_by(slug: channel)
        if channel_obj
          pages = pages.left_joins(:channels)
                       .where('channels.id = ? OR channels.id IS NULL', channel_obj.id)

          # Apply channel exclusions
          excluded_page_ids = channel_obj.channel_overrides
                                         .exclusions
                                         .enabled
                                         .where(resource_type: 'Page')
                                         .pluck(:resource_id)
          pages = pages.where.not(id: excluded_page_ids) if excluded_page_ids.any?

          # Set channel context for serialization
          context[:current_channel] = channel_obj
        end
      end

      # Only published for non-authenticated users
      unless context[:current_user]&.can_edit_others_posts?
        pages = pages.published
      end

      # Pagination
      pages = pages.limit(limit) if limit.present?
      pages = pages.offset(offset) if offset.present?

      pages.order(:order, :title)
    end
  end
end

