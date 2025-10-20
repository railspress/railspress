module Api
  module V1
    class TestController < BaseController
      def index
        begin
          posts = Post.includes(:user, :categories, :tags, :comments, :channels)
          posts = posts.where(status: 'published')
          posts = posts.left_joins(:channels)
          posts = posts.order(created_at: :desc)
          
          @posts = posts.limit(10)
          
          render_success(
            @posts.map { |post| simple_serializer(post) },
            { message: 'Test successful' }
          )
        rescue => e
          render_error("Error: #{e.message}")
        end
      end
      
      private
      
      def simple_serializer(post)
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          status: post.status,
          channels: post.channels.map { |c| c.slug }
        }
      end
    end
  end
end

