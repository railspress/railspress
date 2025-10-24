class AddPublicToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :public, :boolean, default: false
    add_index :uploads, :public
  end
end
