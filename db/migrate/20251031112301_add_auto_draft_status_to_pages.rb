class AddAutoDraftStatusToPages < ActiveRecord::Migration[7.1]
  def up
    # Update existing trash pages from status 5 to status 6
    # Since we're inserting auto_draft at 5, trash moves to 6
    execute "UPDATE pages SET status = 6 WHERE status = 5"
  end

  def down
    # Revert trash pages from status 6 back to status 5
    execute "UPDATE pages SET status = 5 WHERE status = 6"
  end
end
