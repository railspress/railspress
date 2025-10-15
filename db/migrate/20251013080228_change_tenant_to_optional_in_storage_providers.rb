class ChangeTenantToOptionalInStorageProviders < ActiveRecord::Migration[7.1]
  def change
    change_column_null :storage_providers, :tenant_id, true
  end
end
