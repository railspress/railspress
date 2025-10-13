class AddDisplayNamesToTaxonomies < ActiveRecord::Migration[7.1]
  def change
    add_column :taxonomies, :singular_name, :string
    add_column :taxonomies, :plural_name, :string
  end
end
