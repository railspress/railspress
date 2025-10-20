module Types
  class ImageOptimizationLogType < Types::BaseObject
    description "Image optimization log entry"
    
    field :id, ID, null: false
    field :filename, String, null: true
    field :content_type, String, null: true
    field :original_size, Integer, null: true
    field :optimized_size, Integer, null: true
    field :bytes_saved, Integer, null: true
    field :size_reduction_percentage, Float, null: true
    field :size_reduction_mb, Float, null: true
    field :compression_level, String, null: true
    field :compression_level_name, String, null: true
    field :quality, Integer, null: true
    field :processing_time, Float, null: true
    field :processing_time_formatted, String, null: true
    field :status, String, null: true
    field :optimization_type, String, null: true
    field :variants_generated, [String], null: true
    field :responsive_variants_generated, [String], null: true
    field :error_message, String, null: true
    field :warnings, [String], null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    
    field :user, Types::UserType, null: true
    field :medium, Types::MediumType, null: true
    field :upload, Types::UploadType, null: true
    
    def compression_level_name
      ImageOptimizationService.available_compression_levels[object.compression_level]&.dig(:name) || object.compression_level&.capitalize
    end
    
    def size_reduction_mb
      object.size_reduction_mb
    end
    
    def processing_time_formatted
      object.processing_time_formatted
    end
  end
  
  class ImageOptimizationStatsType < Types::BaseObject
    description "Image optimization statistics"
    
    field :total_optimizations, Integer, null: false
    field :successful_optimizations, Integer, null: false
    field :failed_optimizations, Integer, null: false
    field :skipped_optimizations, Integer, null: false
    field :total_bytes_saved, Integer, null: false
    field :total_size_saved_mb, Float, null: false
    field :average_size_reduction, Float, null: true
    field :average_processing_time, Float, null: true
    field :today_optimizations, Integer, null: false
    field :this_week_optimizations, Integer, null: false
    field :this_month_optimizations, Integer, null: false
  end
  
  class CompressionLevelType < Types::BaseObject
    description "Compression level configuration"
    
    field :name, String, null: false
    field :description, String, null: false
    field :quality, Integer, null: false
    field :compression_level, Integer, null: false
    field :lossy, Boolean, null: false
    field :expected_savings, String, null: false
    field :recommended_for, String, null: false
  end
  
  class ImageOptimizationReportType < Types::BaseObject
    description "Image optimization report"
    
    field :total_optimizations, Integer, null: false
    field :successful_optimizations, Integer, null: false
    field :failed_optimizations, Integer, null: false
    field :skipped_optimizations, Integer, null: false
    field :total_bytes_saved, Integer, null: false
    field :total_size_saved_mb, Float, null: false
    field :average_size_reduction, Float, null: true
    field :average_processing_time, Float, null: true
    field :compression_level_breakdown, GraphQL::Types::JSON, null: true
    field :optimization_type_breakdown, GraphQL::Types::JSON, null: true
    field :daily_optimizations, GraphQL::Types::JSON, null: true
    field :top_users, GraphQL::Types::JSON, null: true
    field :top_tenants, GraphQL::Types::JSON, null: true
  end
end
