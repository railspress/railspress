# Spam Protection Plugin
# Protects against comment spam using various techniques

class SpamProtection < Railspress::PluginBase
  plugin_name 'Spam Protection'
  plugin_version '1.0.0'
  plugin_description 'Advanced spam protection for comments'
  plugin_author 'RailsPress'

  # Common spam keywords
  SPAM_KEYWORDS = %w[viagra cialis casino poker gambling loan mortgage]
  
  # Suspicious patterns
  SUSPICIOUS_PATTERNS = [
    /\b\d{10,}\b/,  # Long numbers (phone/credit card)
    /<a\s+href/i,   # HTML links
    /http.*http/i,  # Multiple URLs
    /\[url=/i       # BBCode links
  ]

  def activate
    super
    register_hooks
  end

  private

  def register_hooks
    # Filter comments before creation
    add_filter('comment_before_save', :check_for_spam)
    
    # Action after comment is flagged
    add_action('comment_marked_spam', :log_spam_attempt)
  end

  # Check if comment is spam
  def check_for_spam(comment)
    return comment unless comment.new_record?
    
    spam_score = calculate_spam_score(comment)
    
    if spam_score >= get_setting('spam_threshold', 3)
      comment.status = :spam
      Railspress::PluginSystem.do_action('comment_marked_spam', comment)
    end
    
    comment
  end

  def calculate_spam_score(comment)
    score = 0
    content = comment.content.to_s.downcase
    
    # Check for spam keywords
    SPAM_KEYWORDS.each do |keyword|
      score += 1 if content.include?(keyword)
    end
    
    # Check for suspicious patterns
    SUSPICIOUS_PATTERNS.each do |pattern|
      score += 1 if content.match?(pattern)
    end
    
    # Check for excessive links
    link_count = content.scan(/https?:\/\//).count
    score += 2 if link_count > 3
    
    # Check for ALL CAPS
    if content.length > 20 && content.upcase == content
      score += 1
    end
    
    # Check for repeated characters
    score += 1 if content.match?(/(.)\1{5,}/)
    
    # Very short comments with links are suspicious
    if content.length < 20 && link_count > 0
      score += 2
    end
    
    score
  end

  def log_spam_attempt(comment)
    Rails.logger.warn "Spam detected: #{comment.author_email} - Score: #{calculate_spam_score(comment)}"
  end

  # Public method to check if comment is likely spam
  def self.is_spam?(comment)
    plugin = new
    plugin.calculate_spam_score(comment) >= plugin.get_setting('spam_threshold', 3)
  end
end

# Extend Comment model
if defined?(Comment)
  Comment.class_eval do
    before_validation :apply_spam_protection, on: :create
    
    private
    
    def apply_spam_protection
      if Railspress::PluginSystem.plugin_loaded?('Spam Protection')
        filtered = Railspress::PluginSystem.apply_filters('comment_before_save', self)
      end
    end
  end
end

SpamProtection.new






