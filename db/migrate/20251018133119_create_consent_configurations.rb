class CreateConsentConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :consent_configurations do |t|
      t.string :name
      t.string :banner_type
      t.string :consent_mode
      t.text :consent_categories
      t.text :pixel_consent_mapping
      t.text :banner_settings
      t.text :geolocation_settings
      t.boolean :active
      t.references :tenant, null: false, foreign_key: true
    end
  end
end
