class AddSourceAndTagsToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :source, :string
    add_column :uploads, :tags, :string
    add_index :uploads, :source
  end
end
