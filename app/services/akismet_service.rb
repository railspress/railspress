class AkismetService
  AKISMET_URL = 'https://rest.akismet.com/1.1'
  
  def initialize(api_key, site_url)
    @api_key = api_key
    @site_url = site_url
    @blog = site_url
  end
  
  # Check if a comment is spam
  def spam?(comment_data)
    return false unless @api_key.present?
    
    begin
      response = make_request('comment-check', comment_data)
      Rails.logger.info "Akismet response: #{response}"
      response.strip == 'true'
    rescue => e
      Rails.logger.error "Akismet error: #{e.message}"
      false # Don't block comments if Akismet fails
    end
  end
  
  # Verify the API key is valid
  def verify_key
    return false unless @api_key.present?
    
    begin
      response = make_request('verify-key', {
        key: @api_key,
        blog: @blog
      })
      Rails.logger.info "Akismet key verification: #{response}"
      response.strip == 'valid'
    rescue => e
      Rails.logger.error "Akismet key verification error: #{e.message}"
      false
    end
  end
  
  # Submit a false positive (ham)
  def submit_ham(comment_data)
    return false unless @api_key.present?
    
    begin
      response = make_request('submit-ham', comment_data)
      Rails.logger.info "Akismet submit ham: #{response}"
      response.strip == 'Thanks for making the web a better place.'
    rescue => e
      Rails.logger.error "Akismet submit ham error: #{e.message}"
      false
    end
  end
  
  # Submit a false negative (spam)
  def submit_spam(comment_data)
    return false unless @api_key.present?
    
    begin
      response = make_request('submit-spam', comment_data)
      Rails.logger.info "Akismet submit spam: #{response}"
      response.strip == 'Thanks for making the web a better place.'
    rescue => e
      Rails.logger.error "Akismet submit spam error: #{e.message}"
      false
    end
  end
  
  private
  
  def make_request(action, data)
    uri = URI("#{AKISMET_URL}/#{action}")
    
    # Add API key to the data
    request_data = {
      blog: @blog,
      key: @api_key
    }.merge(data)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.open_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(request_data)
    request['User-Agent'] = "RailsPress/1.0 | Akismet/1.0"
    
    response = http.request(request)
    
    if response.code == '200'
      response.body
    else
      raise "Akismet API error: #{response.code} #{response.message}"
    end
  end
end