class AddThemeIdToPublishedThemeVersions < ActiveRecord::Migration[7.1]
  def up
    # Add theme_id column (nullable first)
    add_reference :published_theme_versions, :theme, null: true, foreign_key: true
    
    # Populate theme_id from theme_name
    PublishedThemeVersion.find_each do |ptv|
      theme = Theme.where("LOWER(name) = ?", ptv.theme_name.downcase).first
      if theme
        ptv.update_column(:theme_id, theme.id)
      else
        puts "Warning: Could not find theme for #{ptv.theme_name}"
      end
    end
    
    # Make theme_id not null and remove theme_name
    change_column_null :published_theme_versions, :theme_id, false
    remove_column :published_theme_versions, :theme_name
  end
  
  def down
    # Add theme_name back
    add_column :published_theme_versions, :theme_name, :string
    
    # Populate theme_name from theme_id
    PublishedThemeVersion.find_each do |ptv|
      ptv.update_column(:theme_name, ptv.theme.name.underscore)
    end
    
    # Remove theme_id
    remove_reference :published_theme_versions, :theme, foreign_key: true
  end
end
