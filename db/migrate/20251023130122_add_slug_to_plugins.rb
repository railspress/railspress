class AddSlugToPlugins < ActiveRecord::Migration[7.1]
  def change
    add_column :plugins, :slug, :string
    add_index :plugins, :slug, unique: true
    
    # Populate slugs for existing plugins
    reversible do |dir|
      dir.up do
        Plugin.find_each do |plugin|
          plugin.update_column(:slug, plugin.name.underscore.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, ''))
        end
      end
    end
  end
end
