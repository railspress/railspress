class AddTenantIdToBuilderThemeFiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :builder_theme_files, :tenant, null: false, foreign_key: true
  end
end
