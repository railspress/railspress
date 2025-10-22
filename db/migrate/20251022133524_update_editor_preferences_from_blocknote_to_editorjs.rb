class UpdateEditorPreferencesFromBlocknoteToEditorjs < ActiveRecord::Migration[7.1]
  def up
    # Update all users who have 'blocknote' as their editor preference to 'editorjs'
    User.where(editor_preference: 'blocknote').update_all(editor_preference: 'editorjs')
    
    # Update users with nil editor preference to 'editorjs' (new default)
    User.where(editor_preference: nil).update_all(editor_preference: 'editorjs')
  end

  def down
    # Revert back to 'blocknote' if needed
    User.where(editor_preference: 'editorjs').update_all(editor_preference: 'blocknote')
  end
end