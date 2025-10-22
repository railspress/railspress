class RemovePreferredEditorFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :preferred_editor, :string
  end
end
