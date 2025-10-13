class CreatePages < ActiveRecord::Migration[7.1]
  def change
    create_table :pages do |t|
      t.string :title
      t.string :slug
      t.text :content
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.datetime :published_at
      t.integer :parent_id
      t.integer :order
      t.string :template
      t.string :meta_description
      t.string :meta_keywords

      t.timestamps
    end
    add_index :pages, :parent_id
  end
end
