class Subscriber < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Versioning
  has_paper_trail
  
  # Serialization
  serialize :metadata, coder: JSON, type: Hash
  serialize :tags, coder: JSON, type: Array
  serialize :lists, coder: JSON, type: Array
  
  # Enums
  enum status: {
    pending: 0,      # Awaiting confirmation
    confirmed: 1,    # Confirmed and active
    unsubscribed: 2, # Opted out
    bounced: 3,      # Email bounced
    complained: 4    # Marked as spam
  }, _suffix: true
  
  # Validations
  validates :email, presence: true, 
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :status, presence: true
  validate :email_not_in_blocklist
  
  # Scopes
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :pending, -> { where(status: 'pending') }
  scope :unsubscribed, -> { where(status: 'unsubscribed') }
  scope :bounced, -> { where(status: 'bounced') }
  scope :complained, -> { where(status: 'complained') }
  scope :active, -> { where(status: ['confirmed', 'pending']) }
  scope :by_source, ->(source) { where(source: source) }
  scope :by_tag, ->(tag) { where("tags LIKE ?", "%#{tag}%") }
  scope :by_list, ->(list) { where("lists LIKE ?", "%#{list}%") }
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) { where('email LIKE ? OR name LIKE ?', "%#{query}%", "%#{query}%") }
  
  # Callbacks
  before_create :generate_unsubscribe_token
  after_create :send_confirmation_email
  after_update :handle_status_change
  
  # Instance methods
  
  # Confirm subscription
  def confirm!
    update!(
      status: 'confirmed',
      confirmed_at: Time.current
    )
  end
  
  # Unsubscribe
  def unsubscribe!
    update!(
      status: 'unsubscribed',
      unsubscribed_at: Time.current
    )
  end
  
  # Resubscribe
  def resubscribe!
    update!(
      status: 'confirmed',
      unsubscribed_at: nil
    )
  end
  
  # Mark as bounced
  def mark_bounced!
    update!(status: 'bounced')
  end
  
  # Mark as complained (spam)
  def mark_complained!
    update!(status: 'complained')
  end
  
  # Add tag
  def add_tag(tag)
    self.tags ||= []
    self.tags << tag unless self.tags.include?(tag)
    save
  end
  
  # Remove tag
  def remove_tag(tag)
    self.tags ||= []
    self.tags.delete(tag)
    save
  end
  
  # Add to list
  def add_to_list(list)
    self.lists ||= []
    self.lists << list unless self.lists.include?(list)
    save
  end
  
  # Remove from list
  def remove_from_list(list)
    self.lists ||= []
    self.lists.delete(list)
    save
  end
  
  # Get unsubscribe URL
  def unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_url(token: unsubscribe_token)
  rescue
    "#"
  end
  
  # Check if subscriber can receive emails
  def can_receive_emails?
    confirmed_status? && confirmed_at.present?
  end
  
  # Get metadata value
  def get_metadata(key, default = nil)
    (metadata || {})[key.to_s] || default
  end
  
  # Set metadata value
  def set_metadata(key, value)
    self.metadata ||= {}
    self.metadata[key.to_s] = value
    save
  end
  
  private
  
  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end
  
  def send_confirmation_email
    return if confirmed_at.present? # Already confirmed
    return unless Rails.env.production? || ENV['SEND_CONFIRMATION_EMAILS'] == 'true'
    
    # Send confirmation email via background job
    # SubscriberMailer.confirmation_email(self).deliver_later
  end
  
  def handle_status_change
    return unless saved_change_to_status?
    
    case status.to_sym
    when :confirmed
      self.confirmed_at ||= Time.current
      # Could trigger welcome email
    when :unsubscribed
      self.unsubscribed_at ||= Time.current
      # Could trigger goodbye email
    end
  end
  
  def email_not_in_blocklist
    # Check against a blocklist (could be a separate model or Redis set)
    blocklist = ['spam@example.com', 'abuse@example.com']
    if blocklist.include?(email&.downcase)
      errors.add(:email, 'is not allowed')
    end
  end
  
  # Class methods
  
  # Import subscribers from CSV
  def self.import_from_csv(csv_data)
    require 'csv'
    
    imported = 0
    errors = []
    
    CSV.parse(csv_data, headers: true).each_with_index do |row, index|
      subscriber = new(
        email: row['email'] || row['Email'],
        name: row['name'] || row['Name'],
        source: row['source'] || row['Source'] || 'csv_import',
        status: row['status'] || row['Status'] || 'confirmed'
      )
      
      if subscriber.save
        imported += 1
      else
        errors << { row: index + 2, email: row['email'], errors: subscriber.errors.full_messages }
      end
    end
    
    { imported: imported, errors: errors, total: imported + errors.count }
  end
  
  # Export to CSV
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Email', 'Name', 'Status', 'Source', 'Confirmed At', 'Tags', 'Lists', 'Created At']
      
      all.each do |subscriber|
        csv << [
          subscriber.email,
          subscriber.name,
          subscriber.status,
          subscriber.source,
          subscriber.confirmed_at&.strftime('%Y-%m-%d %H:%M'),
          (subscriber.tags || []).join(', '),
          (subscriber.lists || []).join(', '),
          subscriber.created_at.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
  end
  
  # Get statistics
  def self.stats
    {
      total: count,
      confirmed: confirmed.count,
      pending: pending.count,
      unsubscribed: unsubscribed.count,
      bounced: bounced.count,
      growth_this_month: where('created_at >= ?', 1.month.ago).count,
      growth_this_week: where('created_at >= ?', 1.week.ago).count,
      confirmation_rate: count > 0 ? (confirmed.count.to_f / count * 100).round(1) : 0
    }
  end
end
