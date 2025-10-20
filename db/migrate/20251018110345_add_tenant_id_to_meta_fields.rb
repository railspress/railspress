class AddTenantIdToMetaFields < ActiveRecord::Migration[7.1]
  def change
    add_reference :meta_fields, :tenant, null: false, foreign_key: true
  end
end
