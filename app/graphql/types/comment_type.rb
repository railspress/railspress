module Types
  class CommentType < Types::BaseObject
    description "A comment on a post or page"

    field :id, ID, null: false
    field :content, String, null: false
    field :author_name, String, null: true
    field :author_email, String, null: true
    field :status, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Author (user)
    field :user, Types::UserType, null: true
    
    # Commentable (polymorphic)
    field :commentable_type, String, null: false
    field :commentable_id, ID, null: false
    field :post, Types::PostType, null: true
    field :page, Types::PageType, null: true
    
    # Threading
    field :parent, Types::CommentType, null: true
    field :replies, [Types::CommentType], null: true
    
    def post
      object.commentable if object.commentable_type == 'Post'
    end
    
    def page
      object.commentable if object.commentable_type == 'Page'
    end
  end
end





