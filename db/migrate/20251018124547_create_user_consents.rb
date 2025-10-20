class CreateUserConsents < ActiveRecord::Migration[7.1]
  def change
    create_table :user_consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :consent_type
      t.text :consent_text
      t.boolean :granted
      t.datetime :granted_at
      t.datetime :withdrawn_at
      t.string :ip_address
      t.text :user_agent
      t.references :tenant, null: false, foreign_key: true
    end
  end
end
