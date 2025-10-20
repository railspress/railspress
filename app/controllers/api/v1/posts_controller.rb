module Api
  module V1
    class PostsController < BaseController
      before_action :set_post, only: [:show, :update, :destroy]
      
      # GET /api/v1/posts
      def index
        posts = Post.all
        
        # Filter by status
        posts = posts.where(status: params[:status]) if params[:status].present?
        
        # Filter by category
        posts = posts.by_category(params[:category]) if params[:category].present?
        
        # Filter by tag
        posts = posts.by_tag(params[:tag]) if params[:tag].present?
        
        # Filter by channel
        if params[:channel].present?
          channel = Channel.find_by(slug: params[:channel])
          if channel
            # Get posts assigned to this channel or global posts (no channel assignment)
            posts = posts.left_joins(:channels)
                         .where('channels.id = ? OR channels.id IS NULL', channel.id)
            
            # Apply channel exclusions
            excluded_post_ids = channel.channel_overrides
                                       .exclusions
                                       .enabled
                                       .where(resource_type: 'Post')
                                       .pluck(:resource_id)
            posts = posts.where.not(id: excluded_post_ids) if excluded_post_ids.any?
            
            @current_channel = channel
          end
        elsif params[:auto_channel].present?
          # Use auto-detected channel from middleware
          channel = Channel.find_by(slug: params[:auto_channel])
          if channel
            posts = posts.left_joins(:channels)
                         .where('channels.id = ? OR channels.id IS NULL', channel.id)
            
            excluded_post_ids = channel.channel_overrides
                                       .exclusions
                                       .enabled
                                       .where(resource_type: 'Post')
                                       .pluck(:resource_id)
            posts = posts.where.not(id: excluded_post_ids) if excluded_post_ids.any?
            
            @current_channel = channel
          end
        end
        
        # Search
        posts = posts.search(params[:q]) if params[:q].present?
        
        # Only published for non-authenticated or non-admin users
        unless current_api_user&.can_edit_others_posts?
          posts = posts.published
        end
        
        # Paginate
        @posts = paginate(posts.order(created_at: :desc))
        
        render_success(
          @posts.map { |post| post_serializer(post) },
          { filters: filter_meta }
        )
      end
      
      # GET /api/v1/posts/:id
      def show
        # Set current channel if channel parameter is provided
        if params[:channel].present?
          @current_channel = Channel.find_by(slug: params[:channel])
        elsif params[:auto_channel].present?
          # Use auto-detected channel from middleware
          @current_channel = Channel.find_by(slug: params[:auto_channel])
        end
        
        render_success(post_serializer(@post, detailed: true))
      end
      
      # POST /api/v1/posts
      def create
        unless current_api_user.can_publish?
          return render_error('You do not have permission to create posts', :forbidden)
        end
        
        @post = current_api_user.posts.build(post_params)
        
        if @post.save
          render_success(post_serializer(@post), {}, :created)
        else
          render_error(@post.errors.full_messages.join(', '))
        end
      end
      
      # PATCH/PUT /api/v1/posts/:id
      def update
        unless can_edit_post?
          return render_error('You do not have permission to edit this post', :forbidden)
        end
        
        if @post.update(post_params)
          render_success(post_serializer(@post))
        else
          render_error(@post.errors.full_messages.join(', '))
        end
      end
      
      # DELETE /api/v1/posts/:id
      def destroy
        unless current_api_user.can_delete_posts?
          return render_error('You do not have permission to delete posts', :forbidden)
        end
        
        @post.destroy
        render_success({ message: 'Post deleted successfully' })
      end
      
      private
      
      def set_post
        @post = Post.friendly.find(params[:id])
      end
      
      def can_edit_post?
        return true if current_api_user.can_edit_others_posts?
        @post.user_id == current_api_user.id
      end
      
      def post_params
        params.require(:post).permit(
          :title, :slug, :content, :excerpt, :status, :published_at,
          :featured_image, :meta_description, :meta_keywords,
          category_ids: [], tag_ids: []
        )
      end
      
      def post_serializer(post, detailed: false)
        # Get channel slugs for this post
        channel_slugs = post.channels.pluck(:slug)
        
        # Start with basic post data
        post_data = {
          id: post.id,
          title: post.title,
          slug: post.slug,
          status: post.status,
          channels: channel_slugs,
          channel_context: @current_channel&.slug
        }
        
        # Add detailed fields if requested
        if detailed
          post_data.merge!({
            content: post.content,
            excerpt: post.excerpt,
            published_at: post.published_at,
            created_at: post.created_at,
            updated_at: post.updated_at,
            url: Rails.application.routes.url_helpers.blog_post_url(post, host: request.host)
          })
        end
        
        # Apply channel overrides if current channel is set
        if @current_channel
          original_data = post_data.dup
          overridden_data, provenance = @current_channel.apply_overrides_to_data(
            original_data, 
            'Post', 
            post.id, 
            true
          )
          
          # Merge overridden data
          post_data.merge!(overridden_data)
          
          # Add provenance information
          post_data[:provenance] = provenance if provenance.present?
        end
        
        post_data
      end
      
      def filter_meta
        {
          status: params[:status],
          category: params[:category],
          tag: params[:tag],
          search: params[:q],
          channel: params[:channel] || params[:auto_channel]
        }
      end
    end
  end
end



