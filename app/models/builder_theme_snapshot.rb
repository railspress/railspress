class BuilderThemeSnapshot < ApplicationRecord
  # Associations
  belongs_to :tenant
  belongs_to :builder_theme
  belongs_to :user
  
  # Validations
  validates :theme_name, presence: true
  validates :settings_data, presence: true
  validates :sections_data, presence: true
  validates :checksum, presence: true, uniqueness: true
  validates :builder_theme, presence: true
  validates :user, presence: true
  
  # Scopes
  scope :for_theme, ->(theme_name) { where(theme_name: theme_name) }
  scope :latest, -> { order(created_at: :desc) }
  
  # Callbacks
  before_validation :generate_checksum, on: :create
  
  # Class methods
  def self.current_for_theme(theme_name)
    for_theme(theme_name).latest.first
  end
  
  def self.create_from_version(builder_theme)
    create!(
      theme_name: builder_theme.theme_name,
      builder_theme: builder_theme,
      settings_data: builder_theme.settings_data.to_json,
      sections_data: builder_theme.sections_data.to_json,
      user: builder_theme.user
    )
  end
  
  # Instance methods
  def settings
    @settings ||= JSON.parse(settings_data)
  rescue JSON::ParserError
    {}
  end
  
  def sections
    @sections ||= JSON.parse(sections_data)
  rescue JSON::ParserError
    {}
  end
  
  def settings=(data)
    @settings = data
    self.settings_data = data.to_json
  end
  
  def sections=(data)
    @sections = data
    self.sections_data = data.to_json
  end
  
  def get_setting(key, default = nil)
    settings[key.to_s] || default
  end
  
  def get_section(section_id)
    sections[section_id.to_s]
  end
  
  def section_order
    sections.keys
  end
  
  def apply_to_frontend!
    # This method would be called to apply the snapshot to the frontend
    # For now, we'll just log it - the actual implementation would depend
    # on how the frontend picks up theme changes
    
    Rails.logger.info "Applying theme snapshot #{id} for theme #{theme_name}"
    
    # In a real implementation, this might:
    # 1. Update a cache key
    # 2. Trigger a webhook
    # 3. Update a database flag that the frontend checks
    # 4. Send a message to a queue for processing
    
    # For now, we'll create a simple cache entry
    Rails.cache.write("theme_snapshot_#{theme_name}", id, expires_in: 1.hour)
  end
  
  def rollback_to!(target_snapshot)
    return false unless target_snapshot.theme_name == theme_name
    
    # Create a new version based on the target snapshot
    new_version = BuilderTheme.create_version(
      theme_name,
      user,
      builder_theme,
      "Rollback to #{target_snapshot.created_at.strftime('%Y-%m-%d %H:%M')}"
    )
    
    # Apply the snapshot data to the new version
    new_version.settings_data = target_snapshot.settings
    new_version.sections_data = target_snapshot.sections
    new_version.save!
    
    new_version
  end
  
  def diff_with(other_snapshot)
    return {} unless other_snapshot.is_a?(BuilderThemeSnapshot)
    
    {
      settings: diff_hash(settings, other_snapshot.settings),
      sections: diff_hash(sections, other_snapshot.sections)
    }
  end
  
  def created_by
    user.email
  end
  
  def version_info
    {
      id: id,
      theme_name: theme_name,
      created_at: created_at,
      created_by: created_by,
      checksum: checksum
    }
  end
  
  private
  
  def generate_checksum
    return if checksum.present?
    
    content = "#{settings_data}#{sections_data}#{created_at || Time.current}"
    self.checksum = Digest::SHA256.hexdigest(content)
  end
  
  def diff_hash(hash1, hash2)
    diff = {}
    
    # Find keys that are different or new
    (hash1.keys + hash2.keys).uniq.each do |key|
      val1 = hash1[key]
      val2 = hash2[key]
      
      if val1 != val2
        diff[key] = {
          from: val1,
          to: val2,
          type: val1.nil? ? 'added' : (val2.nil? ? 'removed' : 'changed')
        }
      end
    end
    
    diff
  end
end
