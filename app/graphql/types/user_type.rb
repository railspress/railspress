module Types
  class UserType < Types::BaseObject
    description "A user in the system"

    field :id, ID, null: false
    field :email, String, null: false
    field :role, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Associations
    field :posts, [Types::PostType], null: true do
      description "Posts created by this user"
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :pages, [Types::PageType], null: true do
      description "Pages created by this user"
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :comments, [Types::CommentType], null: true do
      description "Comments by this user"
      argument :limit, Integer, required: false
    end
    
    # Computed fields
    field :post_count, Integer, null: false
    field :page_count, Integer, null: false
    field :is_admin, Boolean, null: false
    
    def posts(status: nil, limit: nil)
      posts = object.posts
      posts = posts.where(status: status) if status
      posts = posts.limit(limit) if limit
      posts
    end
    
    def pages(status: nil, limit: nil)
      pages = object.pages
      pages = pages.where(status: status) if status
      pages = pages.limit(limit) if limit
      pages
    end
    
    def comments(limit: nil)
      comments = object.comments
      comments = comments.limit(limit) if limit
      comments
    end
    
    def post_count
      object.posts.count
    end
    
    def page_count
      object.pages.count
    end
    
    def is_admin
      object.administrator?
    end
  end
end






