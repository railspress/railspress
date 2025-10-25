class AddKeybindingToShortcuts < ActiveRecord::Migration[7.1]
  def change
    add_column :shortcuts, :keybinding, :string
    add_index :shortcuts, :keybinding
  end
end
