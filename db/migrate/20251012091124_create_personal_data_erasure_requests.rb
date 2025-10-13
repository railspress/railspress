class CreatePersonalDataErasureRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :personal_data_erasure_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email
      t.integer :requested_by
      t.integer :confirmed_by
      t.string :status
      t.string :token
      t.text :reason
      t.datetime :confirmed_at
      t.datetime :completed_at
      t.json :metadata
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
