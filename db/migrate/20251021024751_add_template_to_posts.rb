class AddTemplateToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :template, :string
  end
end
