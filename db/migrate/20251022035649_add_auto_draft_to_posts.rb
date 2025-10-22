class AddAutoDraftToPosts < ActiveRecord::Migration[7.1]
  def up
    # Update existing trash status (5) to new value (6)
    execute "UPDATE posts SET status = 6 WHERE status = 5"
  end

  def down
    # Revert trash status back to 5
    execute "UPDATE posts SET status = 5 WHERE status = 6"
  end
end
