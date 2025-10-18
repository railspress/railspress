class CreateOauthAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :tenant, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email, null: false
      t.string :name, null: false
      t.string :avatar_url

      t.timestamps
    end

    add_index :oauth_accounts, [:provider, :uid, :tenant_id], unique: true
    add_index :oauth_accounts, [:provider, :email, :tenant_id]
  end
end
