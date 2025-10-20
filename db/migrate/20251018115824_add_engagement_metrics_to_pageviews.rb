class AddEngagementMetricsToPageviews < ActiveRecord::Migration[7.1]
  def change
    add_column :pageviews, :reading_time, :integer
    add_column :pageviews, :scroll_depth, :integer
    add_column :pageviews, :completion_rate, :decimal
    add_column :pageviews, :time_on_page, :integer
    add_column :pageviews, :exit_intent, :boolean
  end
end
