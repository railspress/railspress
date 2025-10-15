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
    
    # Meta Fields
    field :meta_fields, [Types::MetaFieldType], null: true, description: "Custom meta fields for this user" do
      argument :key, String, required: false, description: "Filter by specific meta field key"
      argument :immutable, Boolean, required: false, description: "Filter by immutable status"
    end
    
    field :meta_field, Types::MetaFieldType, null: true, description: "Get a specific meta field by key" do
      argument :key, String, required: true, description: "The key of the meta field to retrieve"
    end
    
    field :all_meta, GraphQL::Types::JSON, null: true, description: "All meta fields as a key-value hash"
    
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
    
    def meta_fields(key: nil, immutable: nil)
      meta_fields = object.meta_fields
      meta_fields = meta_fields.by_key(key) if key.present?
      meta_fields = meta_fields.immutable if immutable == true
      meta_fields = meta_fields.mutable if immutable == false
      meta_fields
    end
    
    def meta_field(key:)
      object.meta_fields.find_by(key: key)
    end
    
    def all_meta
      object.all_meta
    end
  end
end








