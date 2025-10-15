class AddTenantToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_reference :webhooks, :tenant, null: true, foreign_key: true
  end
end
