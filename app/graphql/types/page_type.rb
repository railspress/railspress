module Types
  class PageType < Types::BaseObject
    description "A static page"

    field :id, ID, null: false
    field :title, String, null: false
    field :slug, String, null: false
    field :status, String, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Content
    field :content_html, String, null: true do
      description "HTML content of the page"
    end
    
    # Author
    field :author, Types::UserType, null: true
    
    # Hierarchy
    field :parent, Types::PageType, null: true
    field :children, [Types::PageType], null: true
    field :ancestors, [Types::PageType], null: true
    
    # Taxonomies
    field :terms, [Types::TermType], null: true do
      description "All taxonomy terms for this page"
      argument :taxonomy_slug, String, required: false
    end
    
    # URLs
    field :url, String, null: false
    field :permalink, String, null: false
    
    def content_html
      object.content.to_s if object.content.present?
    end
    
    def author
      object.user
    end
    
    def ancestors
      ancestors = []
      current = object.parent
      while current
        ancestors << current
        current = current.parent
      end
      ancestors
    end
    
    def terms(taxonomy_slug: nil)
      terms = object.terms
      if taxonomy_slug
        terms = terms.joins(:taxonomy).where(taxonomies: { slug: taxonomy_slug })
      end
      terms
    end
    
    def url
      Rails.application.routes.url_helpers.page_url(object.slug)
    rescue
      "#"
    end
    
    def permalink
      url
    end
  end
end




