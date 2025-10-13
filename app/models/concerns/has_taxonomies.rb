module HasTaxonomies
  extend ActiveSupport::Concern

  included do
    has_many :term_relationships, as: :object, dependent: :destroy
    has_many :terms, through: :term_relationships
  end

  class_methods do
    # Register a taxonomy for this model
    def has_taxonomy(taxonomy_slug, options = {})
      taxonomy_name = options[:taxonomy_name] || taxonomy_slug.to_s.pluralize
      
      # Define association
      has_many :"#{taxonomy_slug}_relationships",
        -> { joins(:term).where(terms: { taxonomy_id: Taxonomy.find_by(slug: taxonomy_slug)&.id }) },
        class_name: 'TermRelationship',
        as: :object,
        dependent: :destroy
      
      has_many taxonomy_slug.to_sym,
        through: :"#{taxonomy_slug}_relationships",
        source: :term
      
      # Define helper methods
      define_method "#{taxonomy_slug}_list" do
        send(taxonomy_slug).pluck(:name).join(', ')
      end
      
      define_method "#{taxonomy_slug}_list=" do |names|
        taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
        return unless taxonomy
        
        term_names = names.split(',').map(&:strip).reject(&:blank?)
        new_terms = term_names.map do |name|
          taxonomy.terms.find_or_create_by!(name: name)
        end
        
        send("#{taxonomy_slug}=", new_terms)
      end
    end
  end

  # Instance methods
  
  # Get all terms for a specific taxonomy
  def terms_for_taxonomy(taxonomy_slug)
    taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
    return Term.none unless taxonomy
    
    terms.where(taxonomy_id: taxonomy.id)
  end
  
  # Set terms for a taxonomy
  def set_terms_for_taxonomy(taxonomy_slug, term_ids)
    taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
    return unless taxonomy
    
    # Remove existing terms for this taxonomy
    term_relationships.joins(:term)
      .where(terms: { taxonomy_id: taxonomy.id })
      .destroy_all
    
    # Add new terms
    Array(term_ids).each do |term_id|
      term = taxonomy.terms.find_by(id: term_id)
      terms << term if term && !terms.include?(term)
    end
  end
  
  # Add a single term
  def add_term(term_or_name, taxonomy_slug)
    taxonomy = Taxonomy.find_by(slug: taxonomy_slug)
    return unless taxonomy
    
    term = if term_or_name.is_a?(Term)
      term_or_name
    else
      taxonomy.terms.find_or_create_by!(name: term_or_name)
    end
    
    terms << term unless terms.include?(term)
  end
  
  # Remove a term
  def remove_term(term)
    terms.delete(term)
  end
  
  # Check if has term
  def has_term?(term_or_slug)
    if term_or_slug.is_a?(Term)
      terms.include?(term_or_slug)
    else
      terms.exists?(slug: term_or_slug)
    end
  end
  
  # Get term names for taxonomy
  def term_names_for(taxonomy_slug)
    terms_for_taxonomy(taxonomy_slug).pluck(:name)
  end
end






