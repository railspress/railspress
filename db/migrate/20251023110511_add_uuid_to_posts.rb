class AddUuidToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :uuid, :string
    add_index :posts, :uuid, unique: true
    
    # Backfill existing posts with UUIDs
    reversible do |dir|
      dir.up do
        Post.find_each do |post|
          post.update_column(:uuid, SecureRandom.uuid)
        end
      end
    end
  end
end
