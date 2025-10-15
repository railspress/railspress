class AddStorageProviderToUploads < ActiveRecord::Migration[7.1]
  def change
    add_reference :uploads, :storage_provider, null: false, foreign_key: true
  end
end
