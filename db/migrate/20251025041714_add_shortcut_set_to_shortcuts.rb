class AddShortcutSetToShortcuts < ActiveRecord::Migration[7.1]
  def change
    add_column :shortcuts, :shortcut_set, :string, default: 'global'
    add_index :shortcuts, :shortcut_set
  end
end
