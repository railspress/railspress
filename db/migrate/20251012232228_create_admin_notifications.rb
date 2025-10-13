class CreateAdminNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_notifications do |t|
      t.string :plugin
      t.text :message
      t.string :notification_type
      t.json :metadata
      t.boolean :read

      t.timestamps
    end
  end
end
