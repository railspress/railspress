class AddVariantsToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :variants, :text
  end
end
