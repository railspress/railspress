class CreateUploadSecurities < ActiveRecord::Migration[7.1]
  def change
    create_table :upload_securities do |t|
      t.integer :max_file_size
      t.text :allowed_extensions
      t.text :blocked_extensions
      t.text :allowed_mime_types
      t.text :blocked_mime_types
      t.boolean :scan_for_viruses
      t.boolean :quarantine_suspicious
      t.boolean :auto_approve_trusted
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
