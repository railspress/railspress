module Resolvers
  class ImageOptimizationResolver < Resolvers::BaseResolver
    description "Image optimization queries and mutations"
    
    # Query: Get optimization analytics
    field :image_optimization_analytics, Types::ImageOptimizationStatsType, null: false do
      description "Get image optimization analytics"
    end
    
    # Query: Get optimization logs
    field :image_optimization_logs, [Types::ImageOptimizationLogType], null: true do
      description "Get image optimization logs"
      argument :limit, Integer, required: false, default_value: 50
      argument :status, String, required: false
      argument :compression_level, String, required: false
      argument :optimization_type, String, required: false
    end
    
    # Query: Get failed optimizations
    field :failed_image_optimizations, [Types::ImageOptimizationLogType], null: true do
      description "Get failed image optimizations"
      argument :limit, Integer, required: false, default_value: 20
    end
    
    # Query: Get top savings
    field :top_image_savings, [Types::ImageOptimizationLogType], null: true do
      description "Get top image optimization savings"
      argument :limit, Integer, required: false, default_value: 10
    end
    
    # Query: Get compression levels
    field :compression_levels, [Types::CompressionLevelType], null: true do
      description "Get available compression levels"
    end
    
    # Query: Get optimization report
    field :image_optimization_report, Types::ImageOptimizationReportType, null: true do
      description "Get image optimization report"
      argument :start_date, GraphQL::Types::ISO8601Date, required: false
      argument :end_date, GraphQL::Types::ISO8601Date, required: false
    end
    
    # Mutation: Bulk optimize images
    field :bulk_optimize_images, GraphQL::Types::Boolean, null: false do
      description "Start bulk optimization of images"
    end
    
    # Mutation: Regenerate variants
    field :regenerate_image_variants, GraphQL::Types::Boolean, null: false do
      description "Regenerate image variants"
      argument :medium_id, ID, required: true
    end
    
    # Mutation: Clear optimization logs
    field :clear_optimization_logs, GraphQL::Types::Boolean, null: false do
      description "Clear all optimization logs"
      argument :confirm, Boolean, required: true
    end
    
    def image_optimization_analytics
      {
        total_optimizations: ImageOptimizationLog.count,
        successful_optimizations: ImageOptimizationLog.successful.count,
        failed_optimizations: ImageOptimizationLog.failed.count,
        skipped_optimizations: ImageOptimizationLog.skipped.count,
        total_bytes_saved: ImageOptimizationLog.total_bytes_saved || 0,
        total_size_saved_mb: ((ImageOptimizationLog.total_bytes_saved || 0) / 1024.0 / 1024.0).round(2),
        average_size_reduction: ImageOptimizationLog.average_size_reduction&.round(2),
        average_processing_time: ImageOptimizationLog.average_processing_time&.round(3),
        today_optimizations: ImageOptimizationLog.today.count,
        this_week_optimizations: ImageOptimizationLog.this_week.count,
        this_month_optimizations: ImageOptimizationLog.this_month.count
      }
    end
    
    def image_optimization_logs(limit:, status:, compression_level:, optimization_type:)
      logs = ImageOptimizationLog.includes(:medium, :upload, :user)
      
      logs = logs.where(status: status) if status.present?
      logs = logs.where(compression_level: compression_level) if compression_level.present?
      logs = logs.where(optimization_type: optimization_type) if optimization_type.present?
      
      logs.recent.limit(limit)
    end
    
    def failed_image_optimizations(limit:)
      ImageOptimizationLog.failed_optimizations
                         .includes(:medium, :upload, :user)
                         .limit(limit)
    end
    
    def top_image_savings(limit:)
      ImageOptimizationLog.top_savings(limit).includes(:medium, :upload, :user)
    end
    
    def compression_levels
      ImageOptimizationService.available_compression_levels.map do |key, config|
        {
          name: config[:name],
          description: config[:description],
          quality: config[:quality],
          compression_level: config[:compression_level],
          lossy: config[:lossy],
          expected_savings: config[:expected_savings],
          recommended_for: config[:recommended_for]
        }
      end
    end
    
    def image_optimization_report(start_date:, end_date:)
      start_date ||= 30.days.ago.to_date
      end_date ||= Date.current
      
      report = ImageOptimizationLog.generate_report(start_date, end_date)
      
      {
        total_optimizations: report[:total_optimizations],
        successful_optimizations: report[:successful_optimizations],
        failed_optimizations: report[:failed_optimizations],
        skipped_optimizations: report[:skipped_optimizations],
        total_bytes_saved: report[:total_bytes_saved],
        total_size_saved_mb: report[:total_size_saved_mb],
        average_size_reduction: report[:average_size_reduction],
        average_processing_time: report[:average_processing_time],
        compression_level_breakdown: report[:compression_level_breakdown],
        optimization_type_breakdown: report[:optimization_type_breakdown],
        daily_optimizations: report[:daily_optimizations],
        top_users: report[:top_users],
        top_tenants: report[:top_tenants]
      }
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
  end
end
