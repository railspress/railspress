class ThemePreviewSection < ApplicationRecord
  belongs_to :theme_preview

  validates :section_id, presence: true, uniqueness: { scope: :theme_preview_id }
  validates :section_type, presence: true
  validates :position, presence: true

  serialize :settings, coder: JSON, type: Hash

  # Class method to copy sections from BuilderTheme to ThemePreview
  def self.copy_from_builder_theme(theme_preview, builder_theme, template_name)
    # Get the template file from published theme files (since BuilderTheme files might be empty)
    published_version = builder_theme.published_version
    template_file = published_version.published_theme_files.find_by(file_path: "templates/#{template_name}.json")
    
    if template_file
      template_content = JSON.parse(template_file.content)
      sections = template_content['sections'] || {}
      section_order = (template_content['order'] || sections.keys).uniq  # Remove duplicates
      
      # Get existing sections in preview
      existing_sections = where(theme_preview: theme_preview).index_by(&:section_id)
      
      # Track which sections we've processed
      processed_section_ids = []
      
      # Create or update sections in the preview
      section_order.each_with_index do |section_id, index|
        section_data = sections[section_id]
        next unless section_data
        
        processed_section_ids << section_id
        
        if existing_sections[section_id]
          # Update existing section
          existing_sections[section_id].update!(
            section_type: section_data['type'] || section_id,
            settings: section_data['settings'] || {},
            position: index
          )
        else
          # Create new section
          create!(
            theme_preview: theme_preview,
            section_id: section_id,
            section_type: section_data['type'] || section_id,
            settings: section_data['settings'] || {},
            position: index
          )
        end
      end
      
      # Remove sections that no longer exist in the builder theme
      sections_to_remove = existing_sections.keys - processed_section_ids
      sections_to_remove.each do |section_id|
        existing_sections[section_id]&.destroy!
      end
    else
      # If no template file exists, clear all existing sections
      where(theme_preview: theme_preview).destroy_all
    end
  end

  # Update section settings
  def update_settings(new_settings)
    self.settings = new_settings
    save!
  end

  # Reorder sections
  def self.reorder_sections(theme_preview, section_ids)
    section_ids.each_with_index do |section_id, index|
      section = find_by(theme_preview: theme_preview, section_id: section_id)
      section&.update!(position: index)
    end
  end

  # Get sections ordered by position
  def self.ordered_by_position(theme_preview)
    where(theme_preview: theme_preview).order(:position)
  end
end
