class ThemePreview < ApplicationRecord
  belongs_to :builder_theme
  belongs_to :tenant
  has_many :theme_preview_sections, dependent: :destroy
  has_many :theme_preview_files, dependent: :destroy

  validates :template_name, presence: true, uniqueness: { scope: :builder_theme_id }

  # Initialize preview with files and sections from builder theme
  def initialize_from_builder_theme!
    # Copy files from builder theme
    ThemePreviewFile.copy_from_builder_theme(builder_theme, template_name)
    
    # Copy sections from builder theme
    ThemePreviewSection.copy_from_builder_theme(self, builder_theme, template_name)
  end

  # Update section settings
  def update_section_settings(section_id, settings)
    section = theme_preview_sections.find_by(section_id: section_id)
    
    if section
      # Update existing section
      section.update_settings(settings)
      Rails.logger.info "Updated existing section #{section_id} with settings: #{settings.inspect}"
    else
      # Create new section if it doesn't exist
      new_section = theme_preview_sections.create!(
        section_id: section_id,
        section_type: section_id, # Default type
        settings: settings,
        position: theme_preview_sections.count
      )
      Rails.logger.info "Created new section #{section_id} with settings: #{settings.inspect}"
      new_section
    end
  end

  # Update section order
  def update_section_order(section_ids)
    ThemePreviewSection.reorder_sections(self, section_ids)
  end

  # Get sections ordered by position
  def ordered_sections
    theme_preview_sections.ordered_by_position(self)
  end

  # Get template content as JSON (for compatibility)
  def template_content
    sections_data = {}
    section_order = []
    
    ordered_sections.each do |section|
      sections_data[section.section_id] = {
        'type' => section.section_type,
        'settings' => section.settings
      }
      section_order << section.section_id
    end
    
    {
      'name' => template_name.humanize,
      'sections' => sections_data,
      'order' => section_order
    }
  end

  # Class methods for managing previews
  def self.find_or_create_for_builder(builder_theme, template_name = 'index')
    preview = find_by(
      builder_theme: builder_theme,
      template_name: template_name
    )
    
    unless preview
      preview = create!(
        builder_theme: builder_theme,
        tenant: builder_theme.tenant,
        template_name: template_name
      )
      
      # Initialize with files and sections from builder theme
      preview.initialize_from_builder_theme!
    else
      # Ensure existing preview has sections (in case it was created before sections were added)
      if preview.theme_preview_sections.empty?
        Rails.logger.info "Initializing empty ThemePreview sections from BuilderTheme"
        preview.initialize_from_builder_theme!
      end
    end
    
    preview
  end

  # Clean up duplicate sections
  def cleanup_duplicates!
    Rails.logger.info "=== CLEANING UP DUPLICATE SECTIONS ==="
    
    # Remove duplicate sections (keep the latest one)
    section_ids = theme_preview_sections.pluck(:section_id)
    duplicate_section_ids = section_ids.select { |id| section_ids.count(id) > 1 }.uniq
    
    Rails.logger.info "Found duplicate section IDs: #{duplicate_section_ids}"
    
    duplicate_section_ids.each do |section_id|
      duplicates = theme_preview_sections.where(section_id: section_id).order(:updated_at)
      Rails.logger.info "Cleaning up #{duplicates.count} duplicates for section #{section_id}"
      # Keep the latest one, remove the rest
      duplicates.offset(1).destroy_all
    end
    
    # Note: ThemePreviewFile belongs to BuilderTheme, not ThemePreview
    # So we don't need to clean up files here
  end

  # Class method to clean up all duplicates across all previews
  def self.cleanup_all_duplicates!
    all.each(&:cleanup_duplicates!)
  end
end