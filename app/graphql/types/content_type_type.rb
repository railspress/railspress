module Types
  class ContentTypeType < Types::BaseObject
    description "A content type (custom post type)"
    
    field :id, ID, null: false
    field :ident, String, null: false, description: "Unique identifier for the content type"
    field :label, String, null: false, description: "Display label"
    field :singular, String, null: false, description: "Singular name"
    field :plural, String, null: false, description: "Plural name"
    field :description, String, null: true, description: "Description of the content type"
    field :icon, String, null: true, description: "Icon name"
    field :public, Boolean, null: false, description: "Is visible on frontend"
    field :hierarchical, Boolean, null: false, description: "Supports parent/child relationships"
    field :has_archive, Boolean, null: false, description: "Has archive page"
    field :menu_position, Integer, null: true, description: "Position in admin menu"
    field :supports, [String], null: false, description: "Features this type supports"
    field :capabilities, GraphQL::Types::JSON, null: true, description: "Custom capabilities"
    field :rest_base, String, null: false, description: "REST API endpoint base"
    field :active, Boolean, null: false, description: "Is currently active"
    field :posts_count, Integer, null: false, description: "Number of posts of this type"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :posts, [Types::PostType], null: false, description: "Posts of this content type"
    
    def posts_count
      object.posts.count
    end
    
    def rest_base
      object.rest_endpoint
    end
  end
end



