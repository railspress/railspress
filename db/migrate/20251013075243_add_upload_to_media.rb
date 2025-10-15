class AddUploadToMedia < ActiveRecord::Migration[7.1]
  def change
    add_reference :media, :upload, null: false, foreign_key: true
  end
end
