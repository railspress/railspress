class AddFieldsToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :author_ip, :string
    add_column :comments, :comment_approved, :string, limit: 20
    add_column :comments, :author_agent, :text
    add_column :comments, :type, :string
    add_column :comments, :comment_parent_id, :integer
    
    # Make user_id optional
    change_column_null :comments, :user_id, true
    
    # Add foreign key for comment_parent_id
    add_foreign_key :comments, :comments, column: :comment_parent_id
    
    # Add indexes
    add_index :comments, :comment_parent_id
    add_index :comments, :type
    add_index :comments, :comment_approved
    add_index :comments, :author_ip
  end
end
