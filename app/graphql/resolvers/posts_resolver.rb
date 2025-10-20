module Resolvers
  class PostsResolver < Resolvers::BaseResolver
    description "Find posts with channel filtering"

    argument :channel, String, required: false, description: "Filter posts by channel slug"
    argument :status, String, required: false, description: "Filter by post status"
    argument :category, String, required: false, description: "Filter by category slug"
    argument :tag, String, required: false, description: "Filter by tag slug"
    argument :search, String, required: false, description: "Search in title and content"
    argument :limit, Integer, required: false, description: "Limit number of results"
    argument :offset, Integer, required: false, description: "Offset for pagination"

    type [Types::PostType], null: true

    def resolve(channel: nil, status: nil, category: nil, tag: nil, search: nil, limit: nil, offset: nil)
      posts = Post.all

      # Apply filters
      posts = posts.where(status: status) if status.present?
      posts = posts.by_category(category) if category.present?
      posts = posts.by_tag(tag) if tag.present?
      posts = posts.search(search) if search.present?

      # Channel filtering
      if channel.present?
        channel_obj = Channel.find_by(slug: channel)
        if channel_obj
          posts = posts.left_joins(:channels)
                       .where('channels.id = ? OR channels.id IS NULL', channel_obj.id)

          # Apply channel exclusions
          excluded_post_ids = channel_obj.channel_overrides
                                         .exclusions
                                         .enabled
                                         .where(resource_type: 'Post')
                                         .pluck(:resource_id)
          posts = posts.where.not(id: excluded_post_ids) if excluded_post_ids.any?

          # Set channel context for serialization
          context[:current_channel] = channel_obj
        end
      end

      # Only published for non-authenticated users
      unless context[:current_user]&.can_edit_others_posts?
        posts = posts.published
      end

      # Pagination
      posts = posts.limit(limit) if limit.present?
      posts = posts.offset(offset) if offset.present?

      posts.order(created_at: :desc)
    end
  end
end

