class EmailNotifications < Railspress::PluginBase
  plugin_name 'Email Notifications'
  plugin_version '2.0.0'
  plugin_description 'Send email notifications for various events using schema-based settings'
  plugin_author 'RailsPress Team'
  
  # Define settings schema - this will auto-generate the admin UI!
  settings_schema do
    section 'General Settings', description: 'Configure basic email notification settings' do
      checkbox 'enabled', 'Enable Email Notifications',
        description: 'Turn on/off all email notifications',
        default: true
      
      email 'admin_email', 'Admin Email Address',
        description: 'Email address to receive admin notifications',
        required: true,
        placeholder: 'admin@example.com'
      
      text 'from_name', 'From Name',
        description: 'The name that appears in the From field',
        default: 'RailsPress',
        placeholder: 'Your Site Name'
    end
    
    section 'Post Notifications', description: 'Configure notifications for posts' do
      checkbox 'notify_on_new_post', 'New Post Created',
        description: 'Send notification when a new post is created',
        default: true
      
      checkbox 'notify_on_post_published', 'Post Published',
        description: 'Send notification when a post is published',
        default: true
      
      select 'post_notification_recipients', 'Recipients',
        [
          ['Administrators Only', 'administrators'],
          ['All Editors', 'editors'],
          ['All Users', 'all']
        ],
        description: 'Who should receive post notifications',
        default: 'administrators'
    end
    
    section 'Comment Notifications', description: 'Configure notifications for comments' do
      checkbox 'notify_on_new_comment', 'New Comment',
        description: 'Send notification when a new comment is submitted',
        default: true
      
      checkbox 'notify_on_comment_approved', 'Comment Approved',
        description: 'Send notification when a comment is approved',
        default: false
      
      checkbox 'notify_post_author', 'Notify Post Author',
        description: 'Send notification to post author when someone comments',
        default: true
    end
    
    section 'Advanced Settings', description: 'Advanced configuration options' do
      number 'batch_size', 'Batch Size',
        description: 'Number of emails to send per batch',
        default: 10,
        min: 1,
        max: 100
      
      number 'delay_between_batches', 'Delay Between Batches (seconds)',
        description: 'Wait time between email batches to avoid rate limiting',
        default: 5,
        min: 0,
        max: 60
      
      textarea 'email_template', 'Custom Email Template',
        description: 'Custom HTML email template (leave blank for default)',
        rows: 8,
        placeholder: '<html><body>{{content}}</body></html>'
    end
  end
  
  # Initialization
  def initialize
    super
    register_hooks if get_setting('enabled', true)
  end
  
  def activate
    super
    Rails.logger.info "Email Notifications plugin activated with schema-based settings"
  end
  
  private
  
  def register_hooks
    # Post notifications
    if get_setting('notify_on_new_post', true)
      add_action('post_created', 10) do |post|
        send_post_created_notification(post)
      end
    end
    
    if get_setting('notify_on_post_published', true)
      add_action('post_published', 10) do |post|
        send_post_published_notification(post)
      end
    end
    
    # Comment notifications
    if get_setting('notify_on_new_comment', true)
      add_action('comment_created', 10) do |comment|
        send_comment_notification(comment)
      end
    end
    
    if get_setting('notify_post_author', true)
      add_action('comment_created', 15) do |comment|
        send_author_notification(comment)
      end
    end
  end
  
  def send_post_created_notification(post)
    recipients = get_recipients
    return if recipients.empty?
    
    recipients.each do |user|
      # TODO: Send email via ActionMailer
      Rails.logger.info "Would send 'post created' email to #{user.email}"
    end
  end
  
  def send_post_published_notification(post)
    recipients = get_recipients
    return if recipients.empty?
    
    recipients.each do |user|
      Rails.logger.info "Would send 'post published' email to #{user.email}"
    end
  end
  
  def send_comment_notification(comment)
    admin_email = get_setting('admin_email')
    return unless admin_email
    
    Rails.logger.info "Would send comment notification to #{admin_email}"
  end
  
  def send_author_notification(comment)
    return unless comment.commentable.respond_to?(:user)
    
    author = comment.commentable.user
    return unless author
    
    Rails.logger.info "Would send comment notification to post author: #{author.email}"
  end
  
  def get_recipients
    recipient_type = get_setting('post_notification_recipients', 'administrators')
    
    case recipient_type
    when 'administrators'
      User.administrator
    when 'editors'
      User.where(role: ['administrator', 'editor'])
    when 'all'
      User.all
    else
      User.administrator
    end
  end
end

# Auto-initialize if active
if Plugin.exists?(name: 'Email Notifications', active: true)
  EmailNotifications.new
end
