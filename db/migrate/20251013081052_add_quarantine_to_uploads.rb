class AddQuarantineToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :quarantined, :boolean
    add_column :uploads, :quarantine_reason, :text
  end
end
