class CreateAiUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_usages do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :prompt
      t.text :response
      t.integer :tokens_used
      t.decimal :cost
      t.decimal :response_time
      t.boolean :success
      t.text :error_message
      t.json :metadata

      t.timestamps
    end
  end
end
