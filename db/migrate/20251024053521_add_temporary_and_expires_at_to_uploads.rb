class AddTemporaryAndExpiresAtToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :temporary, :boolean, default: false
    add_column :uploads, :expires_at, :datetime
    add_index :uploads, :temporary
    add_index :uploads, :expires_at
  end
end
