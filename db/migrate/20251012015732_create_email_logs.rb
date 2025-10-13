class CreateEmailLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :email_logs do |t|
      t.string :from_address
      t.string :to_address
      t.string :subject
      t.text :body
      t.string :status
      t.string :provider
      t.text :error_message
      t.datetime :sent_at
      t.text :metadata

      t.timestamps
    end
  end
end
