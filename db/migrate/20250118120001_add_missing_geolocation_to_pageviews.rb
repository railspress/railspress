class AddMissingGeolocationToPageviews < ActiveRecord::Migration[7.1]
  def change
    # Only add columns that don't already exist
    add_column :pageviews, :country_name, :string unless column_exists?(:pageviews, :country_name)
    add_column :pageviews, :latitude, :decimal, precision: 10, scale: 6 unless column_exists?(:pageviews, :latitude)
    add_column :pageviews, :longitude, :decimal, precision: 10, scale: 6 unless column_exists?(:pageviews, :longitude)
    add_column :pageviews, :timezone, :string unless column_exists?(:pageviews, :timezone)
    
    # Add indexes for the new columns
    add_index :pageviews, :country_name unless index_exists?(:pageviews, :country_name)
    add_index :pageviews, [:latitude, :longitude] unless index_exists?(:pageviews, [:latitude, :longitude])
    add_index :pageviews, :timezone unless index_exists?(:pageviews, :timezone)
  end
end
