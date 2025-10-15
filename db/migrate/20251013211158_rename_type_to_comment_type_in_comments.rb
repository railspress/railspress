class RenameTypeToCommentTypeInComments < ActiveRecord::Migration[7.1]
  def change
    rename_column :comments, :type, :comment_type
    add_index :comments, :comment_type unless index_exists?(:comments, :comment_type)
  end
end
