# SlickForm Model
# Represents a form created with SlickForms plugin

class SlickForm < ApplicationRecord
  # Associations
  has_many :slick_form_submissions, dependent: :destroy
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :title, presence: true
  validates :active, inclusion: { in: [true, false] }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :accessible_by, ->(tenant) { tenant ? where(tenant_id: tenant.id) : all }
  scope :recent, -> { order(created_at: :desc) }
  
  # JSON fields are handled natively by Rails 7+
  
  # Callbacks
  before_save :ensure_defaults
  
  # Methods
  
  def field_count
    fields&.size || 0
  end
  
  def has_submissions?
    submissions_count > 0
  end
  
  def conversion_rate
    return 0.0 unless views_count&.> 0
    submissions_count.to_f / views_count
  end
  
  def duplicate!
    new_form = dup
    new_form.name = "#{name} (Copy)"
    new_form.title = "#{title} (Copy)"
    new_form.submissions_count = 0
    new_form.save!
    new_form
  end
  
  def public_url
    "/plugins/slick_forms/form/#{id}"
  end
  
  def embed_url
    "/plugins/slick_forms/form/#{id}/embed"
  end
  
  def submission_url
    "/plugins/slick_forms/submit/#{id}"
  end
  
  private
  
  def ensure_defaults
    self.fields ||= []
    self.settings ||= {}
    self.submissions_count ||= 0
  end
end
