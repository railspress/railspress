module Api
  module V1
    class SystemController < BaseController
      skip_before_action :authenticate_api_user!, only: [:info]
      
      # GET /api/v1/system/info
      def info
        render_success({
          name: 'RailsPress API',
          version: 'v1',
          rails_version: Rails.version,
          ruby_version: RUBY_VERSION,
          environment: Rails.env,
          endpoints: {
            posts: api_v1_posts_url,
            pages: api_v1_pages_url,
            categories: api_v1_categories_url,
            tags: api_v1_tags_url,
            comments: api_v1_comments_url,
            media: api_v1_media_index_url,
            users: api_v1_users_url,
            menus: api_v1_menus_url,
            settings: api_v1_settings_url
          },
          documentation: 'https://github.com/railspress/api-docs'
        })
      end
      
      # GET /api/v1/system/stats
      def stats
        unless current_api_user.administrator?
          return render_error('Only administrators can view system stats', :forbidden)
        end
        
        render_success({
          content: {
            total_posts: Post.count,
            published_posts: Post.published.count,
            draft_posts: Post.draft_status.count,
            total_pages: Page.count,
            published_pages: Page.published.count,
            total_comments: Comment.count,
            approved_comments: Comment.approved.count,
            pending_comments: Comment.pending.count,
            spam_comments: Comment.spam.count
          },
          taxonomy: {
            categories: Term.for_taxonomy('category').count,
            tags: Term.for_taxonomy('post_tag').count
          },
          media: {
            total_files: Medium.count,
            images: Medium.images.count,
            videos: Medium.videos.count,
            documents: Medium.documents.count,
            total_size_mb: (Medium.sum(:file_size).to_f / 1024 / 1024).round(2)
          },
          users: {
            total: User.count,
            administrators: User.administrator.count,
            editors: User.editor.count,
            authors: User.author.count,
            contributors: User.contributor.count,
            subscribers: User.subscriber.count
          },
          system: {
            themes: Theme.count,
            active_theme: Theme.active.first&.name,
            plugins: Plugin.count,
            active_plugins: Plugin.active.count,
            menus: Menu.count,
            widgets: Widget.count,
            active_widgets: Widget.active.count
          }
        })
      end
    end
  end
end



