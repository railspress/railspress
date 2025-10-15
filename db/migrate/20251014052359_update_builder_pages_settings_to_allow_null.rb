class UpdateBuilderPagesSettingsToAllowNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :builder_pages, :settings, true
    change_column_null :builder_pages, :sections, true
  end
end