class AddTenantIdToBuilderThemes < ActiveRecord::Migration[7.1]
  def change
    add_reference :builder_themes, :tenant, null: false, foreign_key: true
  end
end
