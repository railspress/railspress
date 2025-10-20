class CreateChannelsPostsJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :channels, :posts do |t|
      # t.index [:channel_id, :post_id]
      # t.index [:post_id, :channel_id]
    end
  end
end
