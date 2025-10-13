require 'net/imap'
require 'mail'

class PostByEmailService
  class << self
    def check_mail
      return { new_posts: 0, checked: 0 } unless enabled?
      
      new_posts = 0
      checked = 0
      
      imap = connect_to_imap
      
      begin
        imap.select(folder)
        
        # Search for unread emails
        message_ids = imap.search(['NOT', 'SEEN'])
        checked = message_ids.length
        
        Rails.logger.info "Found #{checked} unread email(s) in #{folder}"
        
        message_ids.each do |message_id|
          begin
            # Fetch the email
            msg_data = imap.fetch(message_id, 'RFC822')[0]
            email = Mail.read_from_string(msg_data.attr['RFC822'])
            
            # Create post from email
            if create_post_from_email(email)
              new_posts += 1
              
              # Mark as read if configured
              if mark_as_read?
                imap.store(message_id, "+FLAGS", [:Seen])
              end
              
              # Delete if configured
              if delete_after_import?
                imap.store(message_id, "+FLAGS", [:Deleted])
              end
            end
          rescue => e
            Rails.logger.error "Error processing email #{message_id}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
        
        # Expunge deleted messages
        imap.expunge if delete_after_import?
        
      ensure
        imap.disconnect if imap
      end
      
      { new_posts: new_posts, checked: checked }
    end
    
    private
    
    def enabled?
      SiteSetting.get('post_by_email_enabled', false)
    end
    
    def server
      SiteSetting.get('imap_server', '')
    end
    
    def port
      SiteSetting.get('imap_port', '993').to_i
    end
    
    def email
      SiteSetting.get('imap_email', '')
    end
    
    def password
      SiteSetting.get('imap_password', '')
    end
    
    def ssl?
      SiteSetting.get('imap_ssl', 'true') == 'true'
    end
    
    def folder
      SiteSetting.get('imap_folder', 'INBOX')
    end
    
    def mark_as_read?
      SiteSetting.get('post_by_email_mark_as_read', true)
    end
    
    def delete_after_import?
      SiteSetting.get('post_by_email_delete_after_import', false)
    end
    
    def default_category_id
      SiteSetting.get('post_by_email_default_category', nil)
    end
    
    def default_author_id
      SiteSetting.get('post_by_email_default_author', User.first&.id)
    end
    
    def connect_to_imap
      imap = Net::IMAP.new(server, port: port, ssl: ssl?)
      imap.login(email, password)
      imap
    rescue => e
      Rails.logger.error "Failed to connect to IMAP server: #{e.message}"
      raise "IMAP connection failed: #{e.message}"
    end
    
    def create_post_from_email(email)
      # Extract subject as title
      title = email.subject.presence || "Post from #{email.from.first}"
      
      # Extract body
      body_html = extract_body(email)
      
      # Find or create author
      author = User.find_by(id: default_author_id) || User.first
      
      unless author
        Rails.logger.error "No author found for post by email"
        return false
      end
      
      # Create the post
      post = Post.new(
        title: title,
        body_html: body_html,
        status: 'draft', # Always create as draft
        user_id: author.id,
        excerpt: generate_excerpt(body_html),
        created_at: email.date || Time.current
      )
      
      # Assign category if configured
      if default_category_id.present?
        category = Term.for_taxonomy('category').find_by(id: default_category_id)
        post.categories << category if category
      end
      
      if post.save
        Rails.logger.info "Created post ##{post.id} from email: #{title}"
        
        # Handle attachments
        process_attachments(email, post) if email.attachments.any?
        
        true
      else
        Rails.logger.error "Failed to create post from email: #{post.errors.full_messages.join(', ')}"
        false
      end
    rescue => e
      Rails.logger.error "Error creating post from email: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    end
    
    def extract_body(email)
      if email.html_part
        # Prefer HTML if available
        email.html_part.decoded
      elsif email.text_part
        # Convert plain text to HTML
        text = email.text_part.decoded
        text.gsub(/\n/, '<br>')
      elsif email.body
        # Fallback to body
        body_content = email.body.decoded
        
        # Check if it's HTML
        if body_content =~ /<[^>]+>/
          body_content
        else
          # Convert plain text to HTML
          body_content.gsub(/\n/, '<br>')
        end
      else
        ''
      end
    rescue => e
      Rails.logger.error "Error extracting email body: #{e.message}"
      ''
    end
    
    def generate_excerpt(html)
      # Strip HTML tags and get first 150 characters
      text = ActionView::Base.full_sanitizer.sanitize(html)
      text.truncate(150, separator: ' ')
    end
    
    def process_attachments(email, post)
      email.attachments.each do |attachment|
        begin
          # Skip if not an image (you can extend this to handle other types)
          next unless attachment.content_type.start_with?('image/')
          
          # Create a temporary file
          tempfile = Tempfile.new([attachment.filename, File.extname(attachment.filename)])
          tempfile.binmode
          tempfile.write(attachment.decoded)
          tempfile.rewind
          
          # Attach to post using ActiveStorage
          post.featured_image.attach(
            io: tempfile,
            filename: attachment.filename,
            content_type: attachment.content_type
          )
          
          tempfile.close
          tempfile.unlink
          
          Rails.logger.info "Attached #{attachment.filename} to post ##{post.id}"
        rescue => e
          Rails.logger.error "Error processing attachment #{attachment.filename}: #{e.message}"
        end
      end
    end
  end
end




