class Api::V1::ContentTypesController < Api::V1::BaseController
  before_action :set_content_type, only: [:show]
  
  # GET /api/v1/content_types
  def index
    @content_types = ContentType.active.ordered
    
    render json: {
      data: @content_types.map { |ct| content_type_json(ct) },
      meta: {
        total: @content_types.count
      }
    }
  end
  
  # GET /api/v1/content_types/:ident
  def show
    render json: {
      data: content_type_json(@content_type)
    }
  end
  
  private
  
  def set_content_type
    @content_type = ContentType.find_by_ident(params[:id]) || ContentType.find(params[:id])
    
    unless @content_type
      render json: { error: 'Content type not found' }, status: :not_found
    end
  end
  
  def content_type_json(content_type)
    {
      id: content_type.id,
      ident: content_type.ident,
      label: content_type.label,
      singular: content_type.singular,
      plural: content_type.plural,
      description: content_type.description,
      icon: content_type.icon,
      public: content_type.public,
      hierarchical: content_type.hierarchical,
      has_archive: content_type.has_archive,
      menu_position: content_type.menu_position,
      supports: content_type.supports,
      capabilities: content_type.capabilities,
      rest_base: content_type.rest_endpoint,
      active: content_type.active,
      posts_count: content_type.posts.count,
      created_at: content_type.created_at.iso8601,
      updated_at: content_type.updated_at.iso8601,
      _links: {
        self: api_v1_content_type_url(content_type.ident),
        posts: api_v1_posts_url(content_type: content_type.ident)
      }
    }
  end
end

