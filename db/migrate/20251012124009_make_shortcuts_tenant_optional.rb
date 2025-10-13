class MakeShortcutsTenantOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :shortcuts, :tenant_id, true
  end
end
