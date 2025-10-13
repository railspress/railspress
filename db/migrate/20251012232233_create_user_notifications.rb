class CreateUserNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :user_notifications do |t|
      t.string :plugin
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.string :notification_type
      t.json :metadata
      t.boolean :read

      t.timestamps
    end
  end
end
