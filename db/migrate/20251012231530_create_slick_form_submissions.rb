class CreateSlickFormSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :slick_form_submissions do |t|
      t.references :slick_form, null: false, foreign_key: true
      t.json :data
      t.string :ip_address
      t.string :user_agent
      t.string :referrer
      t.boolean :spam, default: false
      t.integer :tenant_id
      t.timestamps
      
      t.index :spam
      t.index :created_at
      t.index :tenant_id
    end
  end
end
