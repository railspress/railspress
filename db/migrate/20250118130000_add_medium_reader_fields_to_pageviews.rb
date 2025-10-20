class AddMediumReaderFieldsToPageviews < ActiveRecord::Migration[7.1]
  def change
    add_column :pageviews, :is_reader, :boolean, default: false unless column_exists?(:pageviews, :is_reader)
    add_column :pageviews, :engagement_score, :integer, default: 0 unless column_exists?(:pageviews, :engagement_score)
    
    add_index :pageviews, :is_reader unless index_exists?(:pageviews, :is_reader)
    add_index :pageviews, :engagement_score unless index_exists?(:pageviews, :engagement_score)
  end
end