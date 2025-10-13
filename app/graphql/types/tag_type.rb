module Types
  class TagType < Types::BaseObject
    description "A tag (non-hierarchical term)"

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :description, String, null: true
    field :count, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Associated content
    field :posts, [Types::PostType], null: true do
      argument :limit, Integer, required: false
    end
    
    def posts(limit: nil)
      posts = Post.joins(:term_relationships).where(term_relationships: { term_id: object.id })
      posts = posts.published
      posts = posts.limit(limit) if limit
      posts
    end
  end
end


