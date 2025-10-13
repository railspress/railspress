module Api
  module V1
    class PostsController < BaseController
      before_action :set_post, only: [:show, :update, :destroy]
      
      # GET /api/v1/posts
      def index
        posts = Post.includes(:user, :categories, :tags, :comments)
        
        # Filter by status
        posts = posts.where(status: params[:status]) if params[:status].present?
        
        # Filter by category
        posts = posts.by_category(params[:category]) if params[:category].present?
        
        # Filter by tag
        posts = posts.by_tag(params[:tag]) if params[:tag].present?
        
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
        data = {
          id: post.id,
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          status: post.status,
          published_at: post.published_at,
          created_at: post.created_at,
          updated_at: post.updated_at,
          content_type: post.content_type ? {
            id: post.content_type.id,
            ident: post.content_type.ident,
            label: post.content_type.label,
            singular: post.content_type.singular,
            plural: post.content_type.plural
          } : nil,
          post_type_ident: post.post_type_ident,
          author: {
            id: post.user.id,
            name: post.author_name,
            email: post.user.email
          },
          categories: post.terms_for_taxonomy('category').map { |c| { id: c.id, name: c.name, slug: c.slug } },
          tags: post.terms_for_taxonomy('post_tag').map { |t| { id: t.id, name: t.name, slug: t.slug } },
          comments_count: post.comments.where(status: 'approved').count,
          meta: {
            description: post.meta_description,
            keywords: post.meta_keywords
          },
          url: blog_post_url(post.slug)
        }
        
        if detailed
          data.merge!(
            content: post.content.to_s,
            featured_image: post.featured_image_file.attached? ? url_for(post.featured_image_file) : nil
          )
        end
        
        data
      end
      
      def filter_meta
        {
          status: params[:status],
          category: params[:category],
          tag: params[:tag],
          search: params[:q]
        }
      end
    end
  end
end



