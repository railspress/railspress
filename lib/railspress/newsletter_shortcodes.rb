# frozen_string_literal: true

module Railspress
  # Newsletter-specific shortcodes
  class NewsletterShortcodes
    def self.register_all
      # [newsletter] - Basic newsletter signup form
      Railspress::ShortcodeProcessor.register('newsletter') do |attrs, content|
        render_newsletter_form(attrs, content)
      end
      
      # [newsletter_inline] - Inline newsletter form (horizontal)
      Railspress::ShortcodeProcessor.register('newsletter_inline') do |attrs, content|
        render_inline_form(attrs, content)
      end
      
      # [newsletter_popup] - Popup newsletter form
      Railspress::ShortcodeProcessor.register('newsletter_popup') do |attrs, content|
        render_popup_form(attrs, content)
      end
      
      # [newsletter_count] - Display subscriber count
      Railspress::ShortcodeProcessor.register('newsletter_count') do |attrs, content|
        count = Subscriber.confirmed.count
        "<span class=\"newsletter-count\">#{number_with_delimiter(count)}</span>"
      end
      
      # [newsletter_stats] - Display newsletter statistics
      Railspress::ShortcodeProcessor.register('newsletter_stats') do |attrs, content|
        render_stats(attrs)
      end
    end
    
    private
    
    def self.render_newsletter_form(attrs, content)
      title = attrs['title'] || 'Subscribe to our Newsletter'
      description = attrs['description'] || 'Get the latest updates delivered to your inbox.'
      button_text = attrs['button'] || 'Subscribe'
      source = attrs['source'] || 'shortcode'
      style = attrs['style'] || 'default'
      
      <<~HTML
        <div class="newsletter-form #{style}-style" data-controller="newsletter-form">
          <div class="newsletter-header">
            <h3 class="newsletter-title">#{title}</h3>
            <p class="newsletter-description">#{description}</p>
          </div>
          
          <form action="/subscribe" method="post" class="newsletter-form-fields" data-action="submit->newsletter-form#submit">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            <input type="hidden" name="source" value="#{source}">
            
            <div class="form-group">
              <input type="email" 
                     name="subscriber[email]" 
                     placeholder="Enter your email" 
                     required 
                     class="newsletter-email-input">
            </div>
            
            <div class="form-group">
              <input type="text" 
                     name="subscriber[name]" 
                     placeholder="Your name (optional)" 
                     class="newsletter-name-input">
            </div>
            
            <button type="submit" class="newsletter-submit-btn">
              #{button_text}
            </button>
            
            <p class="newsletter-privacy">
              We respect your privacy. Unsubscribe at any time.
            </p>
          </form>
        </div>
        
        <style>
          .newsletter-form {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            border-radius: 12px;
            max-width: 500px;
            margin: 2rem auto;
          }
          .newsletter-form.minimal-style {
            background: #f9fafb;
            color: #1f2937;
            border: 1px solid #e5e7eb;
          }
          .newsletter-title {
            font-size: 1.5rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
          }
          .newsletter-description {
            opacity: 0.9;
            margin-bottom: 1.5rem;
          }
          .newsletter-email-input,
          .newsletter-name-input {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid rgba(255,255,255,0.3);
            border-radius: 8px;
            font-size: 1rem;
            margin-bottom: 1rem;
          }
          .newsletter-form.minimal-style input {
            border: 1px solid #e5e7eb;
            background: white;
          }
          .newsletter-submit-btn {
            width: 100%;
            padding: 0.75rem 1rem;
            background: white;
            color: #667eea;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 1rem;
            cursor: pointer;
            transition: transform 0.2s;
          }
          .newsletter-form.minimal-style .newsletter-submit-btn {
            background: #667eea;
            color: white;
          }
          .newsletter-submit-btn:hover {
            transform: translateY(-2px);
          }
          .newsletter-privacy {
            margin-top: 1rem;
            font-size: 0.875rem;
            opacity: 0.7;
            text-align: center;
          }
        </style>
      HTML
    end
    
    def self.render_inline_form(attrs, content)
      button_text = attrs['button'] || 'Subscribe'
      source = attrs['source'] || 'inline_shortcode'
      placeholder = attrs['placeholder'] || 'Enter your email'
      
      <<~HTML
        <div class="newsletter-inline-form" data-controller="newsletter-form">
          <form action="/subscribe" method="post" class="inline-form" data-action="submit->newsletter-form#submit">
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
            <input type="hidden" name="source" value="#{source}">
            
            <div class="inline-form-wrapper">
              <input type="email" 
                     name="subscriber[email]" 
                     placeholder="#{placeholder}" 
                     required 
                     class="inline-email-input">
              <button type="submit" class="inline-submit-btn">
                #{button_text}
              </button>
            </div>
          </form>
        </div>
        
        <style>
          .newsletter-inline-form {
            margin: 2rem 0;
          }
          .inline-form-wrapper {
            display: flex;
            gap: 0.5rem;
            max-width: 500px;
            margin: 0 auto;
          }
          .inline-email-input {
            flex: 1;
            padding: 0.75rem 1rem;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            font-size: 1rem;
          }
          .inline-submit-btn {
            padding: 0.75rem 2rem;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            white-space: nowrap;
          }
          .inline-submit-btn:hover {
            background: #5568d3;
          }
        </style>
      HTML
    end
    
    def self.render_popup_form(attrs, content)
      # Popup newsletter form (requires JavaScript)
      button_text = attrs['button'] || 'Subscribe'
      trigger_text = attrs['trigger'] || 'Join Newsletter'
      
      <<~HTML
        <button class="newsletter-popup-trigger" data-action="click->newsletter-popup#open">
          #{trigger_text}
        </button>
        
        <div class="newsletter-popup-overlay" data-newsletter-popup-target="overlay" style="display: none;">
          <div class="newsletter-popup-modal">
            <button class="newsletter-popup-close" data-action="click->newsletter-popup#close">×</button>
            
            <h3 class="newsletter-popup-title">Subscribe to our Newsletter</h3>
            <p class="newsletter-popup-description">Get the latest updates delivered to your inbox.</p>
            
            <form action="/subscribe" method="post" data-action="submit->newsletter-popup#submit">
              <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
              <input type="hidden" name="source" value="popup">
              
              <input type="email" name="subscriber[email]" placeholder="Email" required class="newsletter-popup-input">
              <input type="text" name="subscriber[name]" placeholder="Name (optional)" class="newsletter-popup-input">
              
              <button type="submit" class="newsletter-popup-submit">#{button_text}</button>
            </form>
          </div>
        </div>
        
        <style>
          .newsletter-popup-trigger {
            padding: 0.75rem 1.5rem;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
          }
          .newsletter-popup-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0,0,0,0.7);
            display: flex;
            align-items: center;
            justify-center;
            z-index: 9999;
          }
          .newsletter-popup-modal {
            background: white;
            padding: 2rem;
            border-radius: 12px;
            max-width: 500px;
            width: 90%;
            position: relative;
          }
          .newsletter-popup-close {
            position: absolute;
            top: 1rem;
            right: 1rem;
            background: none;
            border: none;
            font-size: 2rem;
            cursor: pointer;
            color: #9ca3af;
          }
          .newsletter-popup-title {
            font-size: 1.5rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
            color: #1f2937;
          }
          .newsletter-popup-description {
            color: #6b7280;
            margin-bottom: 1.5rem;
          }
          .newsletter-popup-input {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            margin-bottom: 1rem;
          }
          .newsletter-popup-submit {
            width: 100%;
            padding: 0.75rem;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
          }
        </style>
      HTML
    end
    
    def self.render_stats(attrs)
      stats = Subscriber.stats
      
      <<~HTML
        <div class="newsletter-stats">
          <div class="stat-grid">
            <div class="stat-card">
              <div class="stat-value">#{number_with_delimiter(stats[:total])}</div>
              <div class="stat-label">Total Subscribers</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">#{number_with_delimiter(stats[:confirmed])}</div>
              <div class="stat-label">Confirmed</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">#{stats[:confirmation_rate]}%</div>
              <div class="stat-label">Confirmation Rate</div>
            </div>
          </div>
        </div>
        
        <style>
          .newsletter-stats {
            margin: 2rem 0;
          }
          .stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 1rem;
          }
          .stat-card {
            background: #f9fafb;
            padding: 1.5rem;
            border-radius: 8px;
            text-align: center;
          }
          .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
          }
          .stat-label {
            font-size: 0.875rem;
            color: #6b7280;
            margin-top: 0.5rem;
          }
        </style>
      HTML
    end
    
    def self.form_authenticity_token
      # This would need to be passed from the view context
      ''
    end
    
    def self.number_with_delimiter(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end

# Register shortcodes on load
Railspress::NewsletterShortcodes.register_all






