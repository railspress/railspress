class AddSlugToThemes < ActiveRecord::Migration[7.1]
  def change
    # Clear related tables first due to foreign key constraints
    ThemeFileVersion.delete_all
    ThemeFile.delete_all
    Template.delete_all
    
    # Clear existing themes since they don't have slugs
    Theme.delete_all
    
    add_column :themes, :slug, :string
    add_index :themes, :slug, unique: true
  end
end
