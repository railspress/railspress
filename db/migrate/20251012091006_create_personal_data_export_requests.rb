class CreatePersonalDataExportRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :personal_data_export_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email
      t.integer :requested_by
      t.string :status
      t.string :token
      t.string :file_path
      t.json :metadata
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
