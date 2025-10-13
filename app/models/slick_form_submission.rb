# SlickFormSubmission Model
# Represents a form submission from SlickForms plugin

class SlickFormSubmission < ApplicationRecord
  # Associations
  belongs_to :slick_form
  
  # Validations
  validates :data, presence: true
  
  # JSON fields are handled natively by Rails 7+
  
  # Scopes
  scope :spam, -> { where(spam: true) }
  scope :ham, -> { where(spam: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :accessible_by, ->(tenant) { tenant ? where(tenant_id: tenant.id) : all }
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  
  # Methods
  
  def spam?
    spam == true
  end
  
  def ham?
    spam == false
  end
  
  def mark_as_spam!
    update!(spam: true)
  end
  
  def mark_as_ham!
    update!(spam: false)
  end
  
  def data_field(field_name)
    return nil unless data.is_a?(Hash)
    data[field_name.to_s] || data[field_name.to_sym]
  end
  
  def email
    data_field('email')
  end
  
  def name
    data_field('name') || data_field('first_name')
  end
  
  def form_title
    slick_form&.title || 'Unknown Form'
  end
  
  def ip_location
    # This would integrate with a geolocation service
    'Unknown'
  end
  
  def user_agent_parsed
    # This would parse user agent for browser/OS info
    user_agent
  end
  
  def to_csv_row
    [
      id,
      slick_form_id,
      form_title,
      name,
      email,
      data.to_json,
      ip_address,
      user_agent,
      spam? ? 'Yes' : 'No',
      created_at.strftime('%Y-%m-%d %H:%M:%S')
    ]
  end
  
  class << self
    def csv_headers
      [
        'ID',
        'Form ID', 
        'Form Name',
        'Name',
        'Email',
        'Data',
        'IP Address',
        'User Agent',
        'Spam',
        'Created At'
      ]
    end
    
    def export_csv(submissions = all)
      require 'csv'
      
      CSV.generate do |csv|
        csv << csv_headers
        submissions.each { |submission| csv << submission.to_csv_row }
      end
    end
    
    def spam_count
      spam.count
    end
    
    def ham_count
      ham.count
    end
    
    def total_count
      count
    end
  end
end
