class Api::V1::MetaFieldsController < Api::V1::BaseController
  before_action :authenticate_api_key
  before_action :set_metable
  before_action :set_meta_field, only: [:show, :update, :destroy]

  # GET /api/v1/:metable_type/:metable_id/meta_fields
  def index
    meta_fields = @metable.meta_fields
    meta_fields = meta_fields.by_key(params[:key]) if params[:key].present?
    meta_fields = meta_fields.immutable if params[:immutable] == 'true'
    meta_fields = meta_fields.mutable if params[:immutable] == 'false'

    render json: {
      meta_fields: meta_fields.map do |mf|
        {
          id: mf.id,
          key: mf.key,
          value: mf.value,
          immutable: mf.immutable,
          created_at: mf.created_at,
          updated_at: mf.updated_at
        }
      end
    }
  end

  # GET /api/v1/:metable_type/:metable_id/meta_fields/:key
  def show
    render json: {
      meta_field: {
        id: @meta_field.id,
        key: @meta_field.key,
        value: @meta_field.value,
        immutable: @meta_field.immutable,
        created_at: @meta_field.created_at,
        updated_at: @meta_field.updated_at
      }
    }
  end

  # POST /api/v1/:metable_type/:metable_id/meta_fields
  def create
    meta_field = @metable.meta_fields.build(meta_field_params)

    if meta_field.save
      render json: {
        meta_field: {
          id: meta_field.id,
          key: meta_field.key,
          value: meta_field.value,
          immutable: meta_field.immutable,
          created_at: meta_field.created_at,
          updated_at: meta_field.updated_at
        }
      }, status: :created
    else
      render json: {
        errors: meta_field.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/:metable_type/:metable_id/meta_fields/:key
  def update
    if @meta_field.update(meta_field_params)
      render json: {
        meta_field: {
          id: @meta_field.id,
          key: @meta_field.key,
          value: @meta_field.value,
          immutable: @meta_field.immutable,
          created_at: @meta_field.created_at,
          updated_at: @meta_field.updated_at
        }
      }
    else
      render json: {
        errors: @meta_field.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/:metable_type/:metable_id/meta_fields/:key
  def destroy
    if @meta_field.destroy
      head :no_content
    else
      render json: {
        errors: @meta_field.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/:metable_type/:metable_id/meta_fields/bulk
  def bulk_create
    meta_fields_data = params[:meta_fields] || []
    created_meta_fields = []
    errors = []

    @metable.transaction do
      meta_fields_data.each do |meta_field_data|
        meta_field = @metable.meta_fields.build(meta_field_data.permit(:key, :value, :immutable))
        
        if meta_field.save
          created_meta_fields << {
            id: meta_field.id,
            key: meta_field.key,
            value: meta_field.value,
            immutable: meta_field.immutable,
            created_at: meta_field.created_at,
            updated_at: meta_field.updated_at
          }
        else
          errors << {
            key: meta_field_data[:key],
            errors: meta_field.errors.full_messages
          }
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { errors: errors }, status: :unprocessable_entity
    else
      render json: { meta_fields: created_meta_fields }, status: :created
    end
  end

  # PATCH /api/v1/:metable_type/:metable_id/meta_fields/bulk
  def bulk_update
    meta_fields_data = params[:meta_fields] || {}
    updated_meta_fields = []
    errors = []

    @metable.transaction do
      meta_fields_data.each do |key, data|
        meta_field = @metable.meta_fields.find_by(key: key)
        
        if meta_field
          if meta_field.update(data.permit(:value, :immutable))
            updated_meta_fields << {
              id: meta_field.id,
              key: meta_field.key,
              value: meta_field.value,
              immutable: meta_field.immutable,
              created_at: meta_field.created_at,
              updated_at: meta_field.updated_at
            }
          else
            errors << {
              key: key,
              errors: meta_field.errors.full_messages
            }
          end
        else
          errors << {
            key: key,
            errors: ["Meta field not found"]
          }
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { errors: errors }, status: :unprocessable_entity
    else
      render json: { meta_fields: updated_meta_fields }
    end
  end

  private

  def authenticate_api_key
    api_key = request.headers['Authorization']&.split(' ')&.last
    @api_user = User.find_by(api_key: api_key)

    unless @api_user
      render json: { 
        error: { 
          message: "Invalid API key", 
          type: "authentication_error", 
          code: "invalid_api_key" 
        } 
      }, status: :unauthorized
      return false
    end
  end

  def set_metable
    metable_type = params[:metable_type].classify
    metable_id = params[:metable_id]

    # Validate metable_type
    unless %w[Post Page User AiAgent].include?(metable_type)
      render json: { 
        error: { 
          message: "Invalid metable type. Must be one of: Post, Page, User, AiAgent", 
          type: "invalid_request_error", 
          code: "invalid_metable_type" 
        } 
      }, status: :bad_request
      return
    end

    @metable = metable_type.constantize.find(metable_id)
  rescue ActiveRecord::RecordNotFound
    render json: { 
      error: { 
        message: "#{metable_type} not found", 
        type: "not_found_error", 
        code: "metable_not_found" 
      } 
    }, status: :not_found
  end

  def set_meta_field
    @meta_field = @metable.meta_fields.find_by!(key: params[:key])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      error: { 
        message: "Meta field not found", 
        type: "not_found_error", 
        code: "meta_field_not_found" 
      } 
    }, status: :not_found
  end

  def meta_field_params
    params.require(:meta_field).permit(:key, :value, :immutable)
  end
end
