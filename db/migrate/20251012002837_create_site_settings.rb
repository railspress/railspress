class CreateSiteSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :site_settings do |t|
      t.string :key
      t.text :value
      t.string :setting_type

      t.timestamps
    end
  end
end
