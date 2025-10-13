class TermRelationship < ApplicationRecord
  belongs_to :term, counter_cache: :count
  belongs_to :object, polymorphic: true
  
  validates :term, presence: true
  validates :object, presence: true
  validates :term_id, uniqueness: { scope: [:object_type, :object_id] }
  
  # Callbacks
  after_create :update_term_count
  after_destroy :update_term_count
  
  private
  
  def update_term_count
    term.update_count
  end
end
