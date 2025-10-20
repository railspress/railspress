class CreateChannelsPagesJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :channels, :pages do |t|
      # t.index [:channel_id, :page_id]
      # t.index [:page_id, :channel_id]
    end
  end
end
