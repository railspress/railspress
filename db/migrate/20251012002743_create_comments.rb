class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.text :content
      t.string :author_name
      t.string :author_email
      t.string :author_url
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.integer :parent_id

      t.timestamps
    end
    add_index :comments, :parent_id
  end
end
