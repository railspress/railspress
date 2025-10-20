class CreateChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :channels do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :domain
      t.string :locale, default: 'en'
      t.json :metadata, default: {}
      t.json :settings, default: {}

      t.timestamps
    end
    add_index :channels, :slug, unique: true
    add_index :channels, :domain
  end
end
