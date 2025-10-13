module Api
  module V1
    class TagsController < Api::V1::BaseController
      before_action :set_taxonomy
      before_action :set_tag, only: [:show, :update, :destroy]

      # GET /api/v1/tags
      def index
        tags = @taxonomy.terms.includes(:term_relationships).order(:name)
        
        render json: tags.map { |tag| tag_json(tag) }
      end

      # GET /api/v1/tags/:id
      def show
        render json: tag_json(@tag)
      end

      # POST /api/v1/tags
      def create
        @tag = @taxonomy.terms.new(tag_params)

        if @tag.save
          render json: tag_json(@tag), status: :created
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/tags/:id
      def update
        if @tag.update(tag_params)
          render json: tag_json(@tag)
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tags/:id
      def destroy
        @tag.destroy
        head :no_content
      end

      private

      def set_taxonomy
        @taxonomy = Taxonomy.find_by!(slug: 'tag')
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tag taxonomy not found' }, status: :not_found
      end

      def set_tag
        @tag = @taxonomy.terms.friendly.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tag not found' }, status: :not_found
      end

      def tag_params
        params.require(:tag).permit(:name, :slug, :description, :meta)
      end

      def tag_json(tag)
        {
          id: tag.id,
          name: tag.name,
          slug: tag.slug,
          description: tag.description,
          count: tag.term_relationships.where(object_type: 'Post').count,
          meta: tag.meta,
          created_at: tag.created_at,
          updated_at: tag.updated_at,
          url: "/blog/tag/#{tag.slug}"
        }
      end
    end
  end
end
