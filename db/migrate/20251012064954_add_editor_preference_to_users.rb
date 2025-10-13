class AddEditorPreferenceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :editor_preference, :string, default: 'blocknote'
  end
end
