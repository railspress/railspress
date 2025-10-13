module Types
  class QueryType < Types::BaseObject
    description "The query root of the RailsPress GraphQL API"
    
    # Node interface
    field :node, Types::NodeType, null: true do
      description "Fetches an object given its ID"
      argument :id, ID, required: true
    end
    
    def node(id:)
      context.schema.object_from_id(id, context)
    end
    
    # ========== CONTENT TYPES ==========
    
    field :content_types, [Types::ContentTypeType], null: false do
      description "List all content types"
      argument :active_only, Boolean, required: false, default_value: true
    end
    
    field :content_type, Types::ContentTypeType, null: true do
      description "Find a content type by ID or identifier"
      argument :id, ID, required: false
      argument :ident, String, required: false
    end
    
    # ========== POSTS ==========
    
    field :posts, [Types::PostType], null: false do
      description "List all posts"
      argument :status, String, required: false
      argument :category_slug, String, required: false
      argument :tag_slug, String, required: false
      argument :content_type, String, required: false
      argument :limit, Integer, required: false
      argument :offset, Integer, required: false
    end
    
    field :post, Types::PostType, null: true do
      description "Find a post by ID or slug"
      argument :id, ID, required: false
      argument :slug, String, required: false
    end
    
    field :published_posts, [Types::PostType], null: false do
      description "List published posts"
      argument :limit, Integer, required: false
    end
    
    # ========== PAGES ==========
    
    field :pages, [Types::PageType], null: false do
      description "List all pages"
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :page, Types::PageType, null: true do
      description "Find a page by ID or slug"
      argument :id, ID, required: false
      argument :slug, String, required: false
    end
    
    field :root_pages, [Types::PageType], null: false do
      description "List root level pages (no parent)"
    end
    
    # ========== USERS ==========
    
    field :users, [Types::UserType], null: false do
      description "List all users"
      argument :role, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :user, Types::UserType, null: true do
      description "Find a user by ID"
      argument :id, ID, required: true
    end
    
    field :current_user, Types::UserType, null: true do
      description "Get the currently authenticated user"
    end
    
    # ========== TAXONOMIES ==========
    
    field :taxonomies, [Types::TaxonomyType], null: false do
      description "List all taxonomies"
    end
    
    field :taxonomy, Types::TaxonomyType, null: true do
      description "Find a taxonomy by ID or slug"
      argument :id, ID, required: false
      argument :slug, String, required: false
    end
    
    # ========== TERMS ==========
    
    field :terms, [Types::TermType], null: false do
      description "List all terms"
      argument :taxonomy_slug, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :term, Types::TermType, null: true do
      description "Find a term by ID"
      argument :id, ID, required: true
    end
    
    # ========== CATEGORIES ==========
    
    field :categories, [Types::CategoryType], null: false do
      description "List all categories"
      argument :parent_id, ID, required: false
      argument :limit, Integer, required: false
    end
    
    field :category, Types::CategoryType, null: true do
      description "Find a category by ID or slug"
      argument :id, ID, required: false
      argument :slug, String, required: false
    end
    
    field :root_categories, [Types::CategoryType], null: false do
      description "List root level categories (no parent)"
    end
    
    # ========== TAGS ==========
    
    field :tags, [Types::TagType], null: false do
      description "List all tags"
      argument :limit, Integer, required: false
    end
    
    field :tag, Types::TagType, null: true do
      description "Find a tag by ID or slug"
      argument :id, ID, required: false
      argument :slug, String, required: false
    end
    
    # ========== COMMENTS ==========
    
    field :comments, [Types::CommentType], null: false do
      description "List all comments"
      argument :post_id, ID, required: false
      argument :page_id, ID, required: false
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :comment, Types::CommentType, null: true do
      description "Find a comment by ID"
      argument :id, ID, required: true
    end
    
    # ========== SUBSCRIBERS ==========
    
    field :subscribers, [Types::SubscriberType], null: false do
      description "List all subscribers"
      argument :status, String, required: false
      argument :limit, Integer, required: false
    end
    
    field :subscriber, Types::SubscriberType, null: true do
      description "Find a subscriber by ID"
      argument :id, ID, required: true
    end
    
    field :subscriber_stats, GraphQL::Types::JSON, null: false do
      description "Get subscriber statistics"
    end
    
    # ========== SEARCH ==========
    
    field :search, Types::SearchResultsType, null: false do
      description "Search across posts and pages"
      argument :query, String, required: true
      argument :limit, Integer, required: false
    end
    
    # ========================================================
    # RESOLVERS
    # ========================================================
    
    # Posts
    def content_types(active_only: true)
      types = ContentType.all
      types = types.active if active_only
      types.ordered
    end
    
    def content_type(id: nil, ident: nil)
      return ContentType.find(id) if id
      return ContentType.find_by_ident(ident) if ident
      nil
    end
    
    def posts(status: nil, category_slug: nil, tag_slug: nil, content_type: nil, limit: nil, offset: nil)
      posts = Post.all
      posts = posts.where(status: status) if status
      
      # Filter by content type
      if content_type
        ct = ContentType.find_by_ident(content_type)
        posts = posts.where(content_type: ct) if ct
      end
      
      # Filter by category
      if category_slug
        category_taxonomy = Taxonomy.find_by(slug: 'category')
        if category_taxonomy
          posts = posts.joins(:terms).where(terms: { slug: category_slug, taxonomy: category_taxonomy })
        end
      end
      
      # Filter by tag
      if tag_slug
        tag_taxonomy = Taxonomy.find_by(slug: 'post_tag')
        if tag_taxonomy
          posts = posts.joins(:terms).where(terms: { slug: tag_slug, taxonomy: tag_taxonomy })
        end
      end
      
      posts = posts.offset(offset) if offset
      posts = posts.limit(limit) if limit
      posts.order(created_at: :desc)
    end
    
    def post(id: nil, slug: nil)
      return Post.find(id) if id
      return Post.friendly.find(slug) if slug
      nil
    end
    
    def published_posts(limit: 10)
      Post.published.order(published_at: :desc).limit(limit)
    end
    
    # Pages
    def pages(status: nil, limit: nil)
      pages = Page.all
      pages = pages.where(status: status) if status
      pages = pages.limit(limit) if limit
      pages.order(created_at: :desc)
    end
    
    def page(id: nil, slug: nil)
      return Page.find(id) if id
      return Page.friendly.find(slug) if slug
      nil
    end
    
    def root_pages
      Page.where(parent_id: nil).order(:title)
    end
    
    # Users
    def users(role: nil, limit: nil)
      users = User.all
      users = users.where(role: role) if role
      users = users.limit(limit) if limit
      users.order(created_at: :desc)
    end
    
    def user(id:)
      User.find(id)
    end
    
    def current_user
      context[:current_user]
    end
    
    # Taxonomies
    def taxonomies
      Taxonomy.all.order(:name)
    end
    
    def taxonomy(id: nil, slug: nil)
      return Taxonomy.find(id) if id
      return Taxonomy.friendly.find(slug) if slug
      nil
    end
    
    # Terms
    def terms(taxonomy_slug: nil, limit: nil)
      terms = Term.all
      if taxonomy_slug
        terms = terms.joins(:taxonomy).where(taxonomies: { slug: taxonomy_slug })
      end
      terms = terms.limit(limit) if limit
      terms.order(:name)
    end
    
    def term(id:)
      Term.find(id)
    end
    
    # Categories (via Taxonomy)
    def categories(parent_id: nil, limit: nil)
      taxonomy = Taxonomy.find_by(slug: 'category')
      return [] unless taxonomy
      
      terms = taxonomy.terms
      terms = terms.where(parent_id: parent_id) if parent_id
      terms = terms.limit(limit) if limit
      terms.order(:name)
    end
    
    def category(id: nil, slug: nil)
      taxonomy = Taxonomy.find_by(slug: 'category')
      return nil unless taxonomy
      
      return taxonomy.terms.find(id) if id
      return taxonomy.terms.friendly.find(slug) if slug
      nil
    end
    
    def root_categories
      taxonomy = Taxonomy.find_by(slug: 'category')
      return [] unless taxonomy
      taxonomy.terms.where(parent_id: nil).order(:name)
    end
    
    # Tags (via Taxonomy)
    def tags(limit: nil)
      taxonomy = Taxonomy.find_by(slug: 'tag')
      return [] unless taxonomy
      
      terms = taxonomy.terms
      terms = terms.limit(limit) if limit
      terms.order(:name)
    end
    
    def tag(id: nil, slug: nil)
      taxonomy = Taxonomy.find_by(slug: 'tag')
      return nil unless taxonomy
      
      return taxonomy.terms.find(id) if id
      return taxonomy.terms.friendly.find(slug) if slug
      nil
    end
    
    # Comments
    def comments(post_id: nil, page_id: nil, status: nil, limit: nil)
      comments = Comment.all
      comments = comments.where(commentable_type: 'Post', commentable_id: post_id) if post_id
      comments = comments.where(commentable_type: 'Page', commentable_id: page_id) if page_id
      comments = comments.where(status: status) if status
      comments = comments.limit(limit) if limit
      comments.order(created_at: :desc)
    end
    
    def comment(id:)
      Comment.find(id)
    end
    
    # Subscribers
    def subscribers(status: nil, limit: nil)
      subscribers = Subscriber.all
      subscribers = subscribers.where(status: status) if status
      subscribers = subscribers.limit(limit) if limit
      subscribers.order(created_at: :desc)
    end
    
    def subscriber(id:)
      Subscriber.find(id)
    end
    
    def subscriber_stats
      Subscriber.stats
    end
    
    # Search
    def search(query:, limit: 20)
      posts = Post.search_full_text(query).published.limit(limit)
      pages = Page.search_full_text(query).published.limit(limit)
      
      {
        posts: posts,
        pages: pages,
        total: posts.count + pages.count
      }
    end
  end
end

