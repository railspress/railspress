module Types
  class TaxonomyType < Types::BaseObject
    description "A custom taxonomy"

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false
    field :description, String, null: true
    field :hierarchical, Boolean, null: false
    field :object_types, [String], null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    # Terms
    field :terms, [Types::TermType], null: true do
      argument :parent_id, ID, required: false
      argument :limit, Integer, required: false
    end
    
    # Counts
    field :term_count, Integer, null: false
    
    def terms(parent_id: nil, limit: nil)
      terms = object.terms
      if parent_id
        terms = terms.where(parent_id: parent_id)
      elsif object.hierarchical
        terms = terms.where(parent_id: nil)  # Only root terms for hierarchical
      end
      terms = terms.limit(limit) if limit
      terms
    end
    
    def term_count
      object.terms.count
    end
  end
end






