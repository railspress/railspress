class CreateChannelsMediaJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :channels, :media do |t|
      # t.index [:channel_id, :medium_id]
      # t.index [:medium_id, :channel_id]
    end
  end
end
