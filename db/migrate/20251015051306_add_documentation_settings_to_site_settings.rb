class AddDocumentationSettingsToSiteSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :site_settings, :theme_development_docs, :text
    add_column :site_settings, :plugin_development_docs, :text
    add_column :site_settings, :docs_sync_enabled, :boolean, default: false
    add_column :site_settings, :docs_sync_source_url, :string
    add_column :site_settings, :docs_last_synced_at, :datetime
  end
end
