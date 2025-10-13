module Types
  class PostType < Types::BaseObject
    description "A blog post"

    field :id, ID, null: false
    field :title, String, null: false
    field :slug, String, null: false
    field :excerpt, String, null: true
    field :status, String, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Content
    field :content_html, String, null: true do
      description "HTML content of the post"
    end
    
    # Author
    field :author, Types::UserType, null: true
    field :author_name, String, null: true
    
    # Content Type
    field :content_type, Types::ContentTypeType, null: true, description: "The content type of this post"
    field :post_type_ident, String, null: false, description: "Content type identifier"
    
    # Taxonomies
    field :categories, [Types::CategoryType], null: true
    field :tags, [Types::TagType], null: true
    field :terms, [Types::TermType], null: true do
      description "All taxonomy terms for this post"
      argument :taxonomy_slug, String, required: false
    end
    
    # Comments
    field :comments, [Types::CommentType], null: true do
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    # Counts
    field :comment_count, Integer, null: false
    field :category_count, Integer, null: false
    field :tag_count, Integer, null: false
    
    # URLs
    field :url, String, null: false
    field :permalink, String, null: false
    
    # Meta
    field :reading_time, Integer, null: true do
      description "Estimated reading time in minutes"
    end
    
    def content_html
      object.content.to_s if object.content.present?
    end
    
    def author
      object.user
    end
    
    def terms(taxonomy_slug: nil)
      terms = object.terms
      if taxonomy_slug
        terms = terms.joins(:taxonomy).where(taxonomies: { slug: taxonomy_slug })
      end
      terms
    end
    
    def comments(status: nil, limit: nil)
      comments = object.comments
      comments = comments.where(status: status) if status
      comments = comments.limit(limit) if limit
      comments
    end
    
    def comment_count
      object.comments.count
    end
    
    def category_count
      category_taxonomy = Taxonomy.find_by(slug: 'category')
      return 0 unless category_taxonomy
      object.terms.where(taxonomy: category_taxonomy).count
    end
    
    def tag_count
      tag_taxonomy = Taxonomy.find_by(slug: 'tag')
      return 0 unless tag_taxonomy
      object.terms.where(taxonomy: tag_taxonomy).count
    end
    
    def url
      Rails.application.routes.url_helpers.blog_post_url(object.slug)
    rescue
      "#"
    end
    
    def permalink
      url
    end
    
    def reading_time
      return nil unless object.content.present?
      
      words = object.content.to_plain_text.split.size
      (words / 200.0).ceil
    end
  end
end



