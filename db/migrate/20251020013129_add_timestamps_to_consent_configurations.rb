class AddTimestampsToConsentConfigurations < ActiveRecord::Migration[7.1]
  def change
    add_column :consent_configurations, :created_at, :datetime
    add_column :consent_configurations, :updated_at, :datetime
  end
end
