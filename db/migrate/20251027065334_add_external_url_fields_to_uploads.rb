class AddExternalUrlFieldsToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :external_url, :string
    add_column :uploads, :external_thumbnail_url, :string
    add_column :uploads, :external_preview_url, :string
    add_column :uploads, :is_external, :boolean, default: false
    add_column :uploads, :external_width, :integer
    add_column :uploads, :external_height, :integer
    add_column :uploads, :external_content_type, :string
  end
end
