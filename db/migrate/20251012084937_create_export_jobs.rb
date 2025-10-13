class CreateExportJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :export_jobs do |t|
      t.string :export_type
      t.string :file_path
      t.string :file_name
      t.string :content_type
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.integer :progress
      t.integer :total_items
      t.integer :exported_items
      t.json :options
      t.json :metadata
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
