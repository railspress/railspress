class AddTenantIdToModels < ActiveRecord::Migration[7.1]
  def change
    # Add tenant_id to content models
    add_reference :posts, :tenant, foreign_key: true, index: true
    add_reference :pages, :tenant, foreign_key: true, index: true
    add_reference :media, :tenant, foreign_key: true, index: true
    add_reference :comments, :tenant, foreign_key: true, index: true
    
    # Add tenant_id to taxonomy models
    add_reference :categories, :tenant, foreign_key: true, index: true if table_exists?(:categories)
    add_reference :tags, :tenant, foreign_key: true, index: true if table_exists?(:tags)
    add_reference :taxonomies, :tenant, foreign_key: true, index: true
    add_reference :terms, :tenant, foreign_key: true, index: true
    
    # Add tenant_id to structure models
    add_reference :menus, :tenant, foreign_key: true, index: true
    add_reference :menu_items, :tenant, foreign_key: true, index: true
    add_reference :widgets, :tenant, foreign_key: true, index: true
    
    # Add tenant_id to system models
    add_reference :themes, :tenant, foreign_key: true, index: true
    add_reference :templates, :tenant, foreign_key: true, index: true
    add_reference :site_settings, :tenant, foreign_key: true, index: true
    
    # Users can belong to multiple tenants, so we'll handle that separately
    # For now, add optional tenant_id to users
    add_reference :users, :tenant, foreign_key: true, index: true, null: true
    
    # Add tenant_id to email logs
    add_reference :email_logs, :tenant, foreign_key: true, index: true
  end
end
