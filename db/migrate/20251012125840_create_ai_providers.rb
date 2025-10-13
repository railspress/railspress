class CreateAiProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_providers do |t|
      t.string :name
      t.string :provider_type
      t.string :api_key
      t.string :api_url
      t.string :model_identifier
      t.integer :max_tokens
      t.decimal :temperature
      t.boolean :active
      t.integer :position

      t.timestamps
    end
  end
end
