class Comment < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant(:tenant, optional: true)
  
  # Trash functionality
  include Trashable
  
  belongs_to :user, optional: true
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'Comment', optional: true
  belongs_to :comment_parent, class_name: 'Comment', optional: true
  
  # Hierarchical comments (threaded)
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  has_many :comment_replies, class_name: 'Comment', foreign_key: 'comment_parent_id', dependent: :destroy
  
  # Status enum
  enum status: {
    pending: 0,
    approved: 1,
    spam: 2,
    trash: 3
  }
  
  # Comment type enum
  enum comment_type: {
    comment: 'comment',
    pingback: 'pingback',
    trackback: 'trackback'
  }
  
  # Validations
  validates :content, presence: true
  validates :author_name, presence: true, unless: :user_id?
  validates :author_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :user_id?
  validates :status, presence: true
  validates :comment_type, presence: true
  validates :comment_approved, presence: true, inclusion: { in: %w[0 1] }
  validates :author_ip, presence: true
  validates :author_agent, presence: true
  
  # Scopes
  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :root_comments, -> { where(parent_id: nil) }
  scope :comments_only, -> { where(comment_type: :comment) }
  scope :pingbacks, -> { where(comment_type: :pingback) }
  scope :trackbacks, -> { where(comment_type: :trackback) }
  
  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  after_create :trigger_comment_created_hook
  after_update :trigger_comment_status_changed_hook, if: :saved_change_to_status?
  
  # Methods
  def author
    user&.email&.split('@')&.first || author_name
  end
  
  def approved?
    comment_approved == '1'
  end
  
  def pending?
    comment_approved == '0'
  end
  
  def approve!
    update!(comment_approved: '1', status: :approved)
  end
  
  def unapprove!
    update!(comment_approved: '0', status: :pending)
  end
  
  def browser_info
    return 'Unknown' unless author_agent.present?
    
    # Simple browser detection
    case author_agent.downcase
    when /chrome/
      'Chrome'
    when /firefox/
      'Firefox'
    when /safari/
      'Safari'
    when /edge/
      'Edge'
    when /opera/
      'Opera'
    else
      'Other'
    end
  end
  
  def is_reply?
    comment_parent_id.present?
  end
  
  def is_threaded_reply?
    parent_id.present?
  end
  
  # Convert Comment to Liquid-compatible hash
  def to_liquid
    {
      'id' => id,
      'content' => content,
      'author' => author,
      'author_name' => author_name,
      'author_email' => author_email,
      'author_url' => author_url,
      'created_at' => created_at,
      'updated_at' => updated_at,
      'status' => status,
      'comment_type' => comment_type,
      'approved' => approved?,
      'pending' => pending?,
      'is_reply' => is_reply?,
      'is_threaded_reply' => is_threaded_reply?,
      'parent_id' => parent_id,
      'comment_parent_id' => comment_parent_id,
      'browser_info' => browser_info,
      'user' => user,
      'replies' => replies.to_a, # Convert AssociationRelation to array
      'comment_replies' => comment_replies.to_a # Convert AssociationRelation to array
    }
  end
  
  # Make methods public for Liquid access
  public :to_liquid
  
  private
  
  def set_defaults
    self.status ||= :pending
    self.comment_type ||= :comment
    self.comment_approved ||= '0'
    self.author_ip ||= '127.0.0.1'
    self.author_agent ||= 'Unknown'
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
