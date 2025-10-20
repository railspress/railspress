class AddEnabledToChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :channels, :enabled, :boolean, default: true, null: false
  end
end
