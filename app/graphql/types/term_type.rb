module Types
  class TermType < Types::BaseObject
    description "A taxonomy term"

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :description, String, null: true
    field :count, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Taxonomy
    field :taxonomy, Types::TaxonomyType, null: false
    
    # Hierarchy
    field :parent, Types::TermType, null: true
    field :children, [Types::TermType], null: true
    
    # Associated content
    field :posts, [Types::PostType], null: true do
      argument :limit, Integer, required: false
    end
    
    field :pages, [Types::PageType], null: true do
      argument :limit, Integer, required: false
    end
    
    def posts(limit: nil)
      posts = Post.joins(:term_relationships).where(term_relationships: { term_id: object.id })
      posts = posts.published
      posts = posts.limit(limit) if limit
      posts
    end
    
    def pages(limit: nil)
      pages = Page.joins(:term_relationships).where(term_relationships: { term_id: object.id })
      pages = pages.published
      pages = pages.limit(limit) if limit
      pages
    end
  end
end





