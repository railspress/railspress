class ThemePreviewFile < ApplicationRecord
  belongs_to :builder_theme
  belongs_to :tenant

  validates :file_path, presence: true, uniqueness: { scope: :builder_theme_id }
  validates :file_type, presence: true
  validates :content, presence: true

  # Class method to copy files from BuilderTheme to ThemePreview
  def self.copy_from_builder_theme(builder_theme, template_name)
    # Get all files from the published theme (since BuilderTheme files might be empty)
    published_version = builder_theme.published_version
    published_files = published_version.published_theme_files
    published_file_paths = published_files.pluck(:file_path)
    
    # Get existing preview files
    existing_preview_files = where(builder_theme: builder_theme).index_by(&:file_path)
    
    # Track which files we've processed
    processed_file_paths = []
    
    published_files.each do |published_file|
      processed_file_paths << published_file.file_path
      
      if existing_preview_files[published_file.file_path]
        # Update existing preview file if content has changed
        existing_file = existing_preview_files[published_file.file_path]
        if existing_file.content != published_file.content
          existing_file.update!(
            content: published_file.content,
            file_type: published_file.file_type
          )
        end
      else
        # Create new preview file
        create!(
          builder_theme: builder_theme,
          tenant: builder_theme.tenant,
          file_path: published_file.file_path,
          file_type: published_file.file_type,
          content: published_file.content
        )
      end
    end
    
    # Remove preview files that no longer exist in the published theme
    files_to_remove = existing_preview_files.keys - processed_file_paths
    files_to_remove.each do |file_path|
      existing_preview_files[file_path]&.destroy!
    end
  end

  # Get template file content for a specific template
  def self.get_template_content(builder_theme, template_name)
    template_file = find_by(
      builder_theme: builder_theme,
      file_path: "templates/#{template_name}.json"
    )
    
    if template_file
      JSON.parse(template_file.content)
    else
      # Return empty structure if no template exists
      {
        'name' => template_name.humanize,
        'sections' => {},
        'order' => []
      }
    end
  end

  # Update template file content
  def self.update_template_content(builder_theme, template_name, content)
    template_file = find_or_create_by(
      builder_theme: builder_theme,
      file_path: "templates/#{template_name}.json",
      file_type: 'template'
    ) do |file|
      file.tenant = builder_theme.tenant
      file.content = content.to_json
    end
    
    template_file.update!(content: content.to_json)
    template_file
  end
end
