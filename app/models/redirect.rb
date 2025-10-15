class Redirect < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant)
  
  # Versioning
  has_paper_trail
  
  # Enums
  enum redirect_type: {
    permanent: 0,    # 301 - Permanent redirect
    temporary: 1,    # 302 - Temporary redirect
    see_other: 2,    # 303 - See Other
    temporary_new: 3 # 307 - Temporary Redirect (preserves method)
  }
  
  # Validations
  validates :from_path, presence: true, uniqueness: { scope: :tenant_id }
  validates :to_path, presence: true
  validates :status_code, inclusion: { in: [301, 302, 303, 307, 308] }
  validate :paths_are_different
  validate :no_circular_redirects
  validate :from_path_format
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(redirect_type: type) }
  scope :most_used, -> { order(hits_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_validation :normalize_paths
  after_initialize :set_default_status_code
  
  # Instance methods
  
  # Increment hit counter
  def record_hit!
    increment!(:hits_count)
  end
  
  # Get the appropriate HTTP status code
  def http_status_code
    case redirect_type.to_sym
    when :permanent
      301
    when :temporary
      302
    when :see_other
      303
    when :temporary_new
      307
    else
      status_code || 301
    end
  end
  
  # Check if redirect matches a given path
  def matches?(path)
    return false unless active?
    
    # Exact match
    return true if from_path == path
    
    # Wildcard match (if from_path ends with *)
    if from_path.ends_with?('*')
      pattern = from_path.chomp('*')
      return path.starts_with?(pattern)
    end
    
    false
  end
  
  # Get the destination path for a given request path
  def destination_for(request_path)
    # Handle wildcard redirects
    if from_path.ends_with?('*') && request_path.starts_with?(from_path.chomp('*'))
      pattern = from_path.chomp('*')
      remainder = request_path[pattern.length..]
      return "#{to_path}#{remainder}"
    end
    
    to_path
  end
  
  private
  
  def normalize_paths
    # Ensure paths start with /
    self.from_path = "/#{from_path}" unless from_path&.start_with?('/')
    self.to_path = "/#{to_path}" unless to_path&.start_with?('/') || to_path&.start_with?('http')
    
    # Remove trailing slashes (except for root)
    self.from_path = from_path.chomp('/') if from_path && from_path.length > 1
    self.to_path = to_path.chomp('/') if to_path && to_path.length > 1 && !to_path.start_with?('http')
  end
  
  def paths_are_different
    if from_path.present? && to_path.present? && from_path == to_path
      errors.add(:to_path, "must be different from source path")
    end
  end
  
  def no_circular_redirects
    return unless from_path.present? && to_path.present?
    
    # Check if destination redirects back to source
    destination_redirect = Redirect.active
                                   .where(from_path: to_path)
                                   .where.not(id: id)
                                   .first
    
    if destination_redirect && destination_redirect.to_path == from_path
      errors.add(:to_path, "creates a circular redirect")
    end
  end
  
  def from_path_format
    return unless from_path.present?
    
    # Allow wildcard at end
    if from_path.include?('*') && !from_path.ends_with?('*')
      errors.add(:from_path, "wildcard (*) can only be used at the end")
    end
  end
  
  def set_default_status_code
    return if status_code.present?
    
    self.status_code = case redirect_type&.to_sym
                       when :permanent
                         301
                       when :temporary
                         302
                       when :see_other
                         303
                       when :temporary_new
                         307
                       else
                         301
                       end
  end
  
  # Class methods
  
  # Find redirect for a given path
  def self.find_for_path(path)
    active.find do |redirect|
      redirect.matches?(path)
    end
  end
  
  # Import redirects from CSV or array
  def self.import_redirects(data)
    imported = 0
    errors = []
    
    data.each do |row|
      redirect = new(
        from_path: row[:from_path] || row['from_path'],
        to_path: row[:to_path] || row['to_path'],
        redirect_type: row[:redirect_type] || row['redirect_type'] || 'permanent',
        notes: row[:notes] || row['notes']
      )
      
      if redirect.save
        imported += 1
      else
        errors << { row: row, errors: redirect.errors.full_messages }
      end
    end
    
    { imported: imported, errors: errors }
  end
  
  # Export to CSV format
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['From Path', 'To Path', 'Type', 'Status Code', 'Active', 'Hits', 'Notes']
      
      all.each do |redirect|
        csv << [
          redirect.from_path,
          redirect.to_path,
          redirect.redirect_type,
          redirect.status_code,
          redirect.active,
          redirect.hits_count,
          redirect.notes
        ]
      end
    end
  end
end
