class TrashSetting < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Validations
  validates :cleanup_after_days, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 365 }
  
  # Callbacks
  before_validation :set_defaults
  
  # Class methods
  def self.current
    find_by(tenant: ActsAsTenant.current_tenant) || create_default!
  end
  
  def self.create_default!
    create!(
      auto_cleanup_enabled: true,
      cleanup_after_days: 30,
      tenant: ActsAsTenant.current_tenant
    )
  end
  
  # Instance methods
  def cleanup_after_hours
    cleanup_after_days * 24
  end
  
  def cleanup_after_minutes
    cleanup_after_hours * 60
  end
  
  def cleanup_threshold
    cleanup_after_days.days.ago
  end
  
  def should_cleanup?(deleted_at)
    return false unless auto_cleanup_enabled?
    deleted_at < cleanup_threshold
  end
  
  private
  
  def set_defaults
    self.auto_cleanup_enabled = true if auto_cleanup_enabled.nil?
    self.cleanup_after_days ||= 30
  end
end
