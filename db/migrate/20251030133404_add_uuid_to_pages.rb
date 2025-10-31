class AddUuidToPages < ActiveRecord::Migration[7.1]
  def up
    add_column :pages, :uuid, :string
    add_index :pages, :uuid, unique: true
    # Backfill existing rows
    say_with_time 'Backfilling page UUIDs' do
      Page.reset_column_information
      Page.where(uuid: [nil, '']).find_each(batch_size: 1000) do |p|
        p.update_columns(uuid: SecureRandom.uuid)
      end
    end
  end

  def down
    remove_index :pages, :uuid if index_exists?(:pages, :uuid)
    remove_column :pages, :uuid if column_exists?(:pages, :uuid)
  end
end
