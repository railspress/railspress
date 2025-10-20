module Types
  class MutationType < Types::BaseObject
    description "The mutation root of the RailsPress GraphQL API"
    
    # Example mutations - can be expanded
    # TODO: Add full CRUD mutations for posts, pages, comments, etc.
    
    field :test_field, String, null: false do
      description "An example field added by the generator"
    end

    def test_field
      "Hello World from RailsPress GraphQL!"
    end
    
    # ========== IMAGE OPTIMIZATION MUTATIONS ==========
    
    field :bulk_optimize_images, GraphQL::Types::Boolean, null: false do
      description "Start bulk optimization of images"
    end
    
    field :regenerate_image_variants, GraphQL::Types::Boolean, null: false do
      description "Regenerate image variants"
      argument :medium_id, ID, required: true
    end
    
    field :clear_optimization_logs, GraphQL::Types::Boolean, null: false do
      description "Clear all optimization logs"
      argument :confirm, Boolean, required: true
    end
    
    def bulk_optimize_images
      # Get all unoptimized images
      unoptimized_uploads = Upload.joins(:media)
                                 .where(media: { id: Medium.where.not(id: ImageOptimizationLog.select(:medium_id)) })
                                 .where.not(file: nil)
      
      return true if unoptimized_uploads.empty?
      
      # Queue optimization jobs
      unoptimized_uploads.limit(100).each do |upload|
        medium = upload.media.first
        if medium
          OptimizeImageJob.perform_later(
            medium_id: medium.id,
            optimization_type: 'bulk',
            request_context: {
              user_agent: context[:request]&.user_agent,
              ip_address: context[:request]&.remote_ip
            }
          )
        end
      end
      
      true
    end
    
    def regenerate_image_variants(medium_id:)
      medium = Medium.find(medium_id)
      OptimizeImageJob.perform_later(
        medium_id: medium.id,
        optimization_type: 'regenerate',
        request_context: {
          user_agent: context[:request]&.user_agent,
          ip_address: context[:request]&.remote_ip
        }
      )
      true
    end
    
    def clear_optimization_logs(confirm:)
      return false unless confirm
      
      ImageOptimizationLog.delete_all
      true
    end
    
    # ========== GDPR COMPLIANCE MUTATIONS ==========
    
    field :request_data_export, mutation: Mutations::GdprMutations::RequestDataExport
    field :request_data_erasure, mutation: Mutations::GdprMutations::RequestDataErasure
    field :confirm_data_erasure, mutation: Mutations::GdprMutations::ConfirmDataErasure
    field :record_consent, mutation: Mutations::GdprMutations::RecordConsent
    field :withdraw_consent, mutation: Mutations::GdprMutations::WithdrawConsent
  end
end








