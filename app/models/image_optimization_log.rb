class ImageOptimizationLog < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Associations
  belongs_to :medium
  belongs_to :upload
  belongs_to :user
  
  # Serialization
  serialize :variants_generated, coder: JSON, type: Array
  serialize :responsive_variants_generated, coder: JSON, type: Array
  serialize :warnings, coder: JSON, type: Array
  
  # Validations
  validates :compression_level, presence: true
  validates :status, presence: true, inclusion: { in: %w[success failed skipped partial] }
  validates :optimization_type, presence: true, inclusion: { in: %w[upload bulk manual regenerate] }
  validates :original_size, presence: true, numericality: { greater_than: 0 }
  validates :optimized_size, presence: true, numericality: { greater_than: 0 }
  validates :quality, presence: true, numericality: { in: 1..100 }
  validates :processing_time, presence: true, numericality: { greater_than: 0 }
  
  # Scopes
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
  scope :skipped, -> { where(status: 'skipped') }
  scope :partial, -> { where(status: 'partial') }
  
  scope :by_compression_level, ->(level) { where(compression_level: level) }
  scope :by_optimization_type, ->(type) { where(optimization_type: type) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_tenant, ->(tenant) { where(tenant: tenant) }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_week, -> { where(created_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  
  # Callbacks
  before_validation :calculate_metrics
  
  # Class methods for analytics
  def self.total_images_optimized
    successful.count
  end
  
  def self.total_bytes_saved
    successful.sum(:bytes_saved)
  end
  
  def self.total_processing_time
    successful.sum(:processing_time)
  end
  
  def self.average_size_reduction
    successful.average(:size_reduction_percentage)
  end
  
  def self.average_processing_time
    successful.average(:processing_time)
  end
  
  def self.compression_level_stats
    successful.group(:compression_level).count
  end
  
  def self.optimization_type_stats
    successful.group(:optimization_type).count
  end
  
  def self.daily_stats(days = 30)
    successful.where(created_at: days.days.ago..Time.current)
              .group("DATE(created_at)")
              .count
  end
  
  def self.user_stats
    successful.group(:user_id).count
  end
  
  def self.tenant_stats
    successful.group(:tenant_id).count
  end
  
  def self.top_savings(limit = 10)
    successful.order(bytes_saved: :desc).limit(limit)
  end
  
  def self.failed_optimizations
    failed.includes(:medium, :upload, :user)
  end
  
  # Instance methods
  def success?
    status == 'success'
  end
  
  def failed?
    status == 'failed'
  end
  
  def skipped?
    status == 'skipped'
  end
  
  def partial?
    status == 'partial'
  end
  
  def size_reduction_mb
    (bytes_saved / 1024.0 / 1024.0).round(2)
  end
  
  def original_size_mb
    (original_size / 1024.0 / 1024.0).round(2)
  end
  
  def optimized_size_mb
    (optimized_size / 1024.0 / 1024.0).round(2)
  end
  
  def processing_time_formatted
    if processing_time < 1
      "#{(processing_time * 1000).round(0)}ms"
    else
      "#{processing_time.round(2)}s"
    end
  end
  
  def compression_level_name
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:name) || compression_level.capitalize
  end
  
  def compression_level_description
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:description) || 'Custom settings'
  end
  
  def expected_savings
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:expected_savings) || 'Variable'
  end
  
  def recommended_for
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:recommended_for) || 'Advanced users'
  end
  
  # Status check methods
  def success?
    status == 'success'
  end
  
  def failed?
    status == 'failed'
  end
  
  def skipped?
    status == 'skipped'
  end
  
  def partial?
    status == 'partial'
  end
  
  # Size and time formatting methods
  def size_reduction_mb
    (bytes_saved / 1024.0 / 1024.0).round(2)
  end
  
  def processing_time_formatted
    if processing_time < 1
      "#{(processing_time * 1000).round(0)}ms"
    else
      "#{processing_time.round(2)}s"
    end
  end
  
  # Compression level info methods
  def compression_level_name
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:name) || compression_level.capitalize
  end
  
  def compression_level_description
    ImageOptimizationService.available_compression_levels[compression_level]&.dig(:description) || 'Custom settings'
  end
  
  # API response method
  def api_response
    {
      id: id,
      filename: filename,
      content_type: content_type,
      original_size: original_size,
      optimized_size: optimized_size,
      bytes_saved: bytes_saved,
      size_reduction_percentage: size_reduction_percentage,
      size_reduction_mb: size_reduction_mb,
      compression_level: compression_level,
      compression_level_name: compression_level_name,
      quality: quality,
      processing_time: processing_time,
      processing_time_formatted: processing_time_formatted,
      status: status,
      optimization_type: optimization_type,
      variants_generated: variants_generated,
      responsive_variants_generated: responsive_variants_generated,
      error_message: error_message,
      warnings: warnings,
      user: {
        id: user_id,
        email: user&.email
      },
      medium: {
        id: medium_id,
        title: medium&.title
      },
      upload: {
        id: upload_id,
        title: upload&.title
      },
      created_at: created_at,
      updated_at: updated_at
    }
  end
  
  # Analytics methods
  def self.generate_report(start_date = 30.days.ago, end_date = Time.current)
    logs = where(created_at: start_date..end_date)
    
    {
      total_optimizations: logs.count,
      successful_optimizations: logs.successful.count,
      failed_optimizations: logs.failed.count,
      skipped_optimizations: logs.skipped.count,
      total_bytes_saved: logs.successful.sum(:bytes_saved),
      total_size_saved_mb: (logs.successful.sum(:bytes_saved) / 1024.0 / 1024.0).round(2),
      average_size_reduction: logs.successful.average(:size_reduction_percentage)&.round(2),
      average_processing_time: logs.successful.average(:processing_time)&.round(3),
      compression_level_breakdown: logs.successful.group(:compression_level).count,
      optimization_type_breakdown: logs.successful.group(:optimization_type).count,
      daily_optimizations: logs.successful.group("DATE(created_at)").count,
      top_users: logs.successful.group(:user_id).count.sort_by { |_, count| -count }.first(10),
      top_tenants: logs.successful.group(:tenant_id).count.sort_by { |_, count| -count }.first(10)
    }
  end
  
  def self.export_to_csv(start_date = 30.days.ago, end_date = Time.current)
    require 'csv'
    
    logs = where(created_at: start_date..end_date).includes(:medium, :upload, :user, :tenant)
    
    CSV.generate do |csv|
      csv << [
        'Date', 'User', 'Tenant', 'Filename', 'Content Type', 'Original Size (MB)', 
        'Optimized Size (MB)', 'Bytes Saved', 'Size Reduction %', 'Compression Level',
        'Quality', 'Processing Time', 'Status', 'Optimization Type', 'Variants Generated',
        'Responsive Variants', 'Storage Provider', 'CDN Enabled', 'Error Message'
      ]
      
      logs.each do |log|
        csv << [
          log.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          log.user&.email || 'Unknown',
          log.tenant&.name || 'Unknown',
          log.filename,
          log.content_type,
          log.original_size_mb,
          log.optimized_size_mb,
          log.bytes_saved,
          log.size_reduction_percentage,
          log.compression_level,
          log.quality,
          log.processing_time_formatted,
          log.status,
          log.optimization_type,
          log.variants_generated&.join(', ') || '',
          log.responsive_variants_generated&.join(', ') || '',
          log.storage_provider,
          log.cdn_enabled ? 'Yes' : 'No',
          log.error_message || ''
        ]
      end
    end
  end
  
  private
  
  def calculate_metrics
    return unless original_size && optimized_size
    
    self.bytes_saved = original_size - optimized_size
    self.size_reduction_percentage = ((bytes_saved.to_f / original_size) * 100).round(2)
  end
end
