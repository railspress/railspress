class RemoveKeybindingFromShortcuts < ActiveRecord::Migration[7.1]
  def change
    remove_column :shortcuts, :keybinding, :string
  end
end