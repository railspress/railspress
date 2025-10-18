class ThemePreviewBlock < ApplicationRecord
  belongs_to :theme_preview_section

  validates :block_id, presence: true, uniqueness: { scope: :theme_preview_section_id }
  validates :block_type, presence: true
  validates :position, presence: true

  serialize :settings, coder: JSON, type: Hash
  
  # Ensure settings is never nil to satisfy the NOT NULL constraint
  before_validation :ensure_settings_not_nil
  
  private
  
  def ensure_settings_not_nil
    # Ensure settings is never nil or empty to satisfy the NOT NULL constraint
    # The JSON serializer converts empty hashes to nil, so we need a non-empty hash
    if settings.nil? || settings.empty?
      self.settings = { 'initialized' => true }
    end
  end
end
