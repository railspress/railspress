class Comment < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  belongs_to :user, optional: true
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'Comment', optional: true
  
  # Hierarchical comments (threaded)
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  
  # Status enum
  enum status: {
    pending: 0,
    approved: 1,
    spam: 2,
    trash: 3
  }
  
  # Validations
  validates :content, presence: true
  validates :author_name, presence: true, unless: :user_id?
  validates :author_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :user_id?
  validates :status, presence: true
  
  # Scopes
  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :root_comments, -> { where(parent_id: nil) }
  
  # Callbacks
  after_initialize :set_default_status, if: :new_record?
  after_create :trigger_comment_created_hook
  after_update :trigger_comment_status_changed_hook, if: :saved_change_to_status?
  
  # Methods
  def author
    user&.email&.split('@')&.first || author_name
  end
  
  private
  
  def set_default_status
    self.status ||= :pending
  end
  
  def trigger_comment_created_hook
    Railspress::PluginSystem.do_action('comment_created', self)
  end
  
  def trigger_comment_status_changed_hook
    if approved?
      Railspress::PluginSystem.do_action('comment_approved', self)
    elsif spam?
      Railspress::PluginSystem.do_action('comment_marked_spam', self)
    end
  end
end
