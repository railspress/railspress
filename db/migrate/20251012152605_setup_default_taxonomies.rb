class SetupDefaultTaxonomies < ActiveRecord::Migration[7.1]
  def up
    # Create default taxonomies
    
    # 1. Category taxonomy
    category_taxonomy = Taxonomy.find_or_create_by!(slug: 'category') do |t|
      t.name = 'Category'
      t.singular_name = 'Category'
      t.plural_name = 'Categories'
      t.description = 'Organize posts into categories'
      t.hierarchical = true
      t.object_types = ['Post']
      t.settings = {
        'show_in_menu' => true,
        'show_in_api' => true,
        'show_ui' => true
      }
    end
    
    # Create default "Uncategorized" term
    Term.find_or_create_by!(
      taxonomy: category_taxonomy,
      slug: 'uncategorized'
    ) do |term|
      term.name = 'Uncategorized'
      term.description = 'Posts without a specific category'
    end
    
    # 2. Post Tag taxonomy
    tag_taxonomy = Taxonomy.find_or_create_by!(slug: 'tag') do |t|
      t.name = 'Tag'
      t.singular_name = 'Tag'
      t.plural_name = 'Tags'
      t.description = 'Tag your posts with keywords'
      t.hierarchical = false
      t.object_types = ['Post']
      t.settings = {
        'show_in_menu' => true,
        'show_in_api' => true,
        'show_ui' => true
      }
    end
    
    # No default tags - empty until used
    
    # 3. Post Format taxonomy
    format_taxonomy = Taxonomy.find_or_create_by!(slug: 'post_format') do |t|
      t.name = 'Post Format'
      t.singular_name = 'Format'
      t.plural_name = 'Formats'
      t.description = 'Post format types (video, audio, gallery, etc.)'
      t.hierarchical = false
      t.object_types = ['Post']
      t.settings = {
        'show_in_menu' => false,
        'show_in_api' => true,
        'show_ui' => true
      }
    end
    
    # Available but empty until theme uses them
    
    # Migrate existing categories if Category model exists
    if defined?(Category) && ActiveRecord::Base.connection.table_exists?('categories')
      Category.find_each do |category|
        Term.find_or_create_by!(
          taxonomy: category_taxonomy,
          slug: category.slug
        ) do |term|
          term.name = category.name
          term.description = category.respond_to?(:description) ? category.description : nil
          term.parent_id = category.respond_to?(:parent_id) ? category.parent_id : nil
        end
      end
    end
    
    # Migrate existing tags if Tag model exists
    if defined?(Tag) && ActiveRecord::Base.connection.table_exists?('tags')
      Tag.find_each do |tag|
        Term.find_or_create_by!(
          taxonomy: tag_taxonomy,
          slug: tag.slug
        ) do |term|
          term.name = tag.name
          term.description = tag.respond_to?(:description) ? tag.description : nil
        end
      end
    end
    
    say "✅ Created default taxonomies:"
    say "  - Category (hierarchical, default: Uncategorized)"
    say "  - Post Tag (flat, no defaults)"
    say "  - Post Format (flat, empty)"
    
    if defined?(Category)
      say "  - Migrated #{Category.count} categories to terms"
    end
    
    if defined?(Tag)
      say "  - Migrated #{Tag.count} tags to terms"
    end
  end
  
  def down
    # Remove default taxonomies
    Taxonomy.where(slug: ['category', 'post_tag', 'post_format']).destroy_all
  end
end