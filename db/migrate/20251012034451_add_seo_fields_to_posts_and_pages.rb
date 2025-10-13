class AddSeoFieldsToPostsAndPages < ActiveRecord::Migration[7.1]
  def change
    # Add SEO fields to posts (skip existing meta_description and meta_keywords)
    add_column :posts, :meta_title, :string unless column_exists?(:posts, :meta_title)
    add_column :posts, :canonical_url, :string unless column_exists?(:posts, :canonical_url)
    add_column :posts, :og_title, :string unless column_exists?(:posts, :og_title)
    add_column :posts, :og_description, :text unless column_exists?(:posts, :og_description)
    add_column :posts, :og_image_url, :string unless column_exists?(:posts, :og_image_url)
    add_column :posts, :twitter_card, :string, default: 'summary_large_image' unless column_exists?(:posts, :twitter_card)
    add_column :posts, :twitter_title, :string unless column_exists?(:posts, :twitter_title)
    add_column :posts, :twitter_description, :text unless column_exists?(:posts, :twitter_description)
    add_column :posts, :twitter_image_url, :string unless column_exists?(:posts, :twitter_image_url)
    add_column :posts, :robots_meta, :string, default: 'index, follow' unless column_exists?(:posts, :robots_meta)
    add_column :posts, :focus_keyphrase, :string unless column_exists?(:posts, :focus_keyphrase)
    add_column :posts, :schema_type, :string, default: 'Article' unless column_exists?(:posts, :schema_type)
    
    # Add SEO fields to pages
    add_column :pages, :meta_title, :string unless column_exists?(:pages, :meta_title)
    add_column :pages, :meta_description, :text unless column_exists?(:pages, :meta_description)
    add_column :pages, :meta_keywords, :string unless column_exists?(:pages, :meta_keywords)
    add_column :pages, :canonical_url, :string unless column_exists?(:pages, :canonical_url)
    add_column :pages, :og_title, :string unless column_exists?(:pages, :og_title)
    add_column :pages, :og_description, :text unless column_exists?(:pages, :og_description)
    add_column :pages, :og_image_url, :string unless column_exists?(:pages, :og_image_url)
    add_column :pages, :twitter_card, :string, default: 'summary_large_image' unless column_exists?(:pages, :twitter_card)
    add_column :pages, :twitter_title, :string unless column_exists?(:pages, :twitter_title)
    add_column :pages, :twitter_description, :text unless column_exists?(:pages, :twitter_description)
    add_column :pages, :twitter_image_url, :string unless column_exists?(:pages, :twitter_image_url)
    add_column :pages, :robots_meta, :string, default: 'index, follow' unless column_exists?(:pages, :robots_meta)
    add_column :pages, :focus_keyphrase, :string unless column_exists?(:pages, :focus_keyphrase)
    add_column :pages, :schema_type, :string, default: 'WebPage' unless column_exists?(:pages, :schema_type)
    
    # Add indexes for SEO queries
    add_index :posts, :focus_keyphrase unless index_exists?(:posts, :focus_keyphrase)
    add_index :pages, :focus_keyphrase unless index_exists?(:pages, :focus_keyphrase)
  end
end
