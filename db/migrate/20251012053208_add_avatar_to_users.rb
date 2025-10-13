class AddAvatarToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :avatar_url, :string
    add_column :users, :bio, :text
    add_column :users, :phone, :string
    add_column :users, :location, :string
    add_column :users, :website, :string
    add_column :users, :two_factor_enabled, :boolean
    add_column :users, :notification_email_enabled, :boolean
    add_column :users, :notification_comment_enabled, :boolean
    add_column :users, :notification_mention_enabled, :boolean
  end
end
