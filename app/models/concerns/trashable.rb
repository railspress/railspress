module Trashable
  extend ActiveSupport::Concern
  
  included do
    # Scopes
    scope :kept, -> { where(deleted_at: nil) }
    scope :trashed, -> { where.not(deleted_at: nil) }
    scope :trashed_before, ->(date) { where('deleted_at < ?', date) }
    
    # Associations
    belongs_to :trashed_by, class_name: 'User', optional: true
  end
  
  # Instance methods
  def trashed?
    deleted_at.present?
  end
  
  def kept?
    deleted_at.nil?
  end
  
  def trash!(user = nil)
    update!(
      deleted_at: Time.current,
      trashed_by: user
    )
    
    # Trigger plugin hook
    Railspress::PluginSystem.do_action("#{self.class.name.downcase}_trashed", self)
  end
  
  def untrash!
    update!(
      deleted_at: nil,
      trashed_by: nil
    )
    
    # Trigger plugin hook
    Railspress::PluginSystem.do_action("#{self.class.name.downcase}_untrashed", self)
  end
  
  def destroy_permanently!
    # Trigger plugin hook before permanent deletion
    Railspress::PluginSystem.do_action("#{self.class.name.downcase}_permanently_deleted", self)
    
    super
  end
  
  # Class methods
  class_methods do
    def cleanup_trash!
      settings = TrashSetting.current
      return unless settings.auto_cleanup_enabled?
      
      threshold = settings.cleanup_threshold
      trashed_before(threshold).find_each(&:destroy_permanently!)
    end
    
    def trash_count
      trashed.count
    end
    
    def kept_count
      kept.count
    end
  end
end

