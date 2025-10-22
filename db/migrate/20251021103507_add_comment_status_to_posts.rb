class AddCommentStatusToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :comment_status, :string, default: 'open'
  end
end
