namespace :theme_preview do
  desc "Clean up duplicate sections and files in theme previews"
  task cleanup_duplicates: :environment do
    puts "Starting cleanup of theme preview duplicates..."
    
    # Clean up duplicates in all theme previews
    ThemePreview.cleanup_all_duplicates!
    
    puts "Cleanup completed successfully!"
  end

  desc "Show statistics about theme preview duplicates"
  task stats: :environment do
    puts "Theme Preview Statistics:"
    puts "========================"
    
    # Count total previews
    total_previews = ThemePreview.count
    puts "Total Theme Previews: #{total_previews}"
    
    # Count total sections
    total_sections = ThemePreviewSection.count
    puts "Total Theme Preview Sections: #{total_sections}"
    
    # Count total files
    total_files = ThemePreviewFile.count
    puts "Total Theme Preview Files: #{total_files}"
    
    # Check for duplicate sections
    duplicate_sections = ThemePreviewSection.group(:theme_preview_id, :section_id).having('COUNT(*) > 1').count
    if duplicate_sections.any?
      puts "\nDuplicate Sections Found:"
      duplicate_sections.each do |key, count|
        theme_preview_id, section_id = key
        puts "  Theme Preview #{theme_preview_id}, Section #{section_id}: #{count} duplicates"
      end
    else
      puts "\nNo duplicate sections found."
    end
    
    # Check for duplicate files
    duplicate_files = ThemePreviewFile.group(:builder_theme_id, :file_path).having('COUNT(*) > 1').count
    if duplicate_files.any?
      puts "\nDuplicate Files Found:"
      duplicate_files.each do |key, count|
        builder_theme_id, file_path = key
        puts "  Builder Theme #{builder_theme_id}, File #{file_path}: #{count} duplicates"
      end
    else
      puts "\nNo duplicate files found."
    end
  end
end
