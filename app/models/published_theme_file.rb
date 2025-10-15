class PublishedThemeFile < ApplicationRecord
  belongs_to :published_theme_version
  
  # Scopes
  scope :templates, -> { where(file_type: 'template') }
  scope :sections, -> { where(file_type: 'section') }
  scope :layouts, -> { where(file_type: 'layout') }
  scope :assets, -> { where(file_type: 'asset') }
  scope :configs, -> { where(file_type: 'config') }
end
