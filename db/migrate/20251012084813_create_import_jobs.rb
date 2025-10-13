class CreateImportJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :import_jobs do |t|
      t.string :import_type
      t.string :file_path
      t.string :file_name
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.integer :progress
      t.integer :total_items
      t.integer :imported_items
      t.integer :failed_items
      t.text :error_log
      t.json :metadata
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
