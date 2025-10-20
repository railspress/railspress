class AddVariantsToUploads < ActiveRecord::Migration[7.1]
  def change
    if table_exists?(:uploads) && !column_exists?(:uploads, :variants)
      add_column :uploads, :variants, :text
    end
  end
end
