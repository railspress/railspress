class RailspressSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Maximum query depth
  max_depth 15

  # Maximum query complexity
  max_complexity 300

  # Error handling
  rescue_from(ActiveRecord::RecordNotFound) do |err, obj, args, ctx, field|
    raise GraphQL::ExecutionError, "#{field.type.unwrap.graphql_name} not found"
  end

  rescue_from(ActiveRecord::RecordInvalid) do |err, obj, args, ctx, field|
    raise GraphQL::ExecutionError, err.record.errors.full_messages.join(", ")
  end

  # Relay-style object identification
  def self.object_from_id(node_id, ctx)
    type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(node_id)
    
    case type_name
    when "Post"
      Post.find(item_id)
    when "Page"
      Page.find(item_id)
    when "User"
      User.find(item_id)
    when "Category"
      # Category is now a Term in category taxonomy
      Taxonomy.find_by(slug: 'category')&.terms&.find(item_id)
    when "Tag"
      # Tag is now a Term in tag taxonomy
      Taxonomy.find_by(slug: 'tag')&.terms&.find(item_id)
    when "Taxonomy"
      Taxonomy.find(item_id)
    when "Term"
      Term.find(item_id)
    when "Comment"
      Comment.find(item_id)
    else
      nil
    end
  end

  def self.resolve_type(abstract_type, obj, ctx)
    case obj
    when Post
      Types::PostType
    when Page
      Types::PageType
    when User
      Types::UserType
    when Term
      # Check if it's a category or tag term
      if obj.taxonomy.slug == 'category'
        Types::CategoryType
      elsif obj.taxonomy.slug == 'post_tag'
        Types::TagType
      else
        Types::TermType
      end
    when Taxonomy
      Types::TaxonomyType
    when Comment
      Types::CommentType
    else
      raise("Unexpected object: #{obj}")
    end
  end
end



