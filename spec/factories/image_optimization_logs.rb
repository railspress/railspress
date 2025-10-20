FactoryBot.define do
  factory :image_optimization_log do
    association :medium
    association :upload
    association :user
    association :tenant
    
    filename { 'test_image.jpg' }
    content_type { 'image/jpeg' }
    original_size { 1000000 }
    optimized_size { 750000 }
    width { 1920 }
    height { 1080 }
    
    compression_level { 'lossy' }
    quality { 85 }
    strip_metadata { true }
    enable_webp { true }
    enable_avif { true }
    
    processing_time { 1.5 }
    size_reduction_percentage { 25.0 }
    bytes_saved { 250000 }
    
    variants_generated { ['webp', 'avif'] }
    responsive_variants_generated { ['webp_640w', 'avif_1024w'] }
    
    optimization_type { 'upload' }
    status { 'success' }
    error_message { nil }
    warnings { [] }
    
    storage_provider { 'local' }
    cdn_enabled { false }
    user_agent { 'Mozilla/5.0 (Test Browser)' }
    ip_address { '127.0.0.1' }
    
    trait :failed do
      status { 'failed' }
      error_message { 'Processing failed' }
      optimized_size { original_size }
      bytes_saved { 0 }
      size_reduction_percentage { 0 }
    end
    
    trait :skipped do
      status { 'skipped' }
      error_message { 'No size reduction achieved' }
      optimized_size { original_size }
      bytes_saved { 0 }
      size_reduction_percentage { 0 }
    end
    
    trait :partial do
      status { 'partial' }
      error_message { 'Some variants failed to generate' }
      variants_generated { ['webp'] }
      responsive_variants_generated { ['webp_640w'] }
    end
    
    trait :lossless do
      compression_level { 'lossless' }
      quality { 95 }
      bytes_saved { 100000 }
      size_reduction_percentage { 10.0 }
    end
    
    trait :ultra do
      compression_level { 'ultra' }
      quality { 75 }
      bytes_saved { 500000 }
      size_reduction_percentage { 50.0 }
    end
    
    trait :bulk_optimization do
      optimization_type { 'bulk' }
    end
    
    trait :manual_optimization do
      optimization_type { 'manual' }
    end
    
    trait :regenerate_variants do
      optimization_type { 'regenerate' }
    end
    
    trait :with_warnings do
      warnings { ['Large file size', 'Low quality detected'] }
    end
    
    trait :cdn_enabled do
      cdn_enabled { true }
      storage_provider { 's3' }
    end
    
    trait :s3_storage do
      storage_provider { 's3' }
    end
    
    trait :high_resolution do
      width { 3840 }
      height { 2160 }
      original_size { 5000000 }
      optimized_size { 3500000 }
      bytes_saved { 1500000 }
      size_reduction_percentage { 30.0 }
    end
    
    trait :low_resolution do
      width { 640 }
      height { 480 }
      original_size { 100000 }
      optimized_size { 80000 }
      bytes_saved { 20000 }
      size_reduction_percentage { 20.0 }
    end
    
    trait :slow_processing do
      processing_time { 5.0 }
    end
    
    trait :fast_processing do
      processing_time { 0.5 }
    end
    
    trait :many_variants do
      variants_generated { ['webp', 'avif', 'heic', 'jxl'] }
      responsive_variants_generated { ['webp_320w', 'webp_640w', 'webp_1024w', 'avif_320w', 'avif_640w', 'avif_1024w'] }
    end
    
    trait :no_variants do
      variants_generated { [] }
      responsive_variants_generated { [] }
    end
  end
end
