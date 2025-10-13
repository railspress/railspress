class AiSeo < Railspress::PluginBase
  plugin_name 'AI SEO'
  plugin_version '1.0.0'
  plugin_description 'Automatically generate and optimize SEO meta tags using AI'
  plugin_author 'RailsPress Team'
  
  # Comprehensive settings schema for AI SEO
  settings_schema do
    section 'AI Provider', description: 'Configure your AI service provider' do
      select 'ai_provider', 'AI Provider',
        [
          ['OpenAI (GPT-4, GPT-3.5)', 'openai'],
          ['Anthropic (Claude)', 'anthropic'],
          ['Google (Gemini)', 'google'],
          ['Custom API', 'custom']
        ],
        description: 'Choose your AI service provider',
        required: true,
        default: 'openai'
      
      text 'api_key', 'API Key',
        description: 'Your AI provider API key',
        required: true,
        placeholder: 'sk-...'
      
      select 'model', 'Model',
        [
          ['GPT-4 Turbo', 'gpt-4-turbo-preview'],
          ['GPT-4', 'gpt-4'],
          ['GPT-3.5 Turbo', 'gpt-3.5-turbo'],
          ['Claude 3 Opus', 'claude-3-opus-20240229'],
          ['Claude 3 Sonnet', 'claude-3-sonnet-20240229'],
          ['Claude 3 Haiku', 'claude-3-haiku-20240307'],
          ['Gemini Pro', 'gemini-pro']
        ],
        description: 'Select the AI model to use',
        default: 'gpt-3.5-turbo'
      
      url 'custom_api_url', 'Custom API URL',
        description: 'Custom API endpoint (only if using Custom API)',
        placeholder: 'https://api.example.com/v1/chat'
    end
    
    section 'Auto-Generation Settings', description: 'Configure when and how SEO is generated' do
      checkbox 'auto_generate_on_save', 'Auto-Generate on Save',
        description: 'Automatically generate SEO when content is saved',
        default: true
      
      checkbox 'auto_generate_on_publish', 'Auto-Generate on Publish',
        description: 'Generate SEO when content is published',
        default: true
      
      checkbox 'overwrite_existing', 'Overwrite Existing Meta Tags',
        description: 'Replace existing meta tags with AI-generated ones',
        default: false
      
      checkbox 'generate_meta_title', 'Generate Meta Title',
        description: 'Auto-generate meta title',
        default: true
      
      checkbox 'generate_meta_description', 'Generate Meta Description',
        description: 'Auto-generate meta description',
        default: true
      
      checkbox 'generate_meta_keywords', 'Generate Meta Keywords',
        description: 'Auto-generate meta keywords',
        default: true
      
      checkbox 'generate_og_tags', 'Generate Open Graph Tags',
        description: 'Auto-generate Open Graph title and description',
        default: true
      
      checkbox 'generate_twitter_tags', 'Generate Twitter Card Tags',
        description: 'Auto-generate Twitter card metadata',
        default: true
      
      checkbox 'generate_focus_keyphrase', 'Generate Focus Keyphrase',
        description: 'Identify and set focus keyphrase',
        default: true
    end
    
    section 'SEO Guidelines', description: 'Configure SEO best practices and limits' do
      number 'meta_title_max_length', 'Meta Title Max Length',
        description: 'Maximum characters for meta title',
        default: 60,
        min: 30,
        max: 100
      
      number 'meta_description_max_length', 'Meta Description Max Length',
        description: 'Maximum characters for meta description',
        default: 160,
        min: 100,
        max: 320
      
      number 'meta_keywords_count', 'Number of Keywords',
        description: 'How many keywords to generate',
        default: 5,
        min: 3,
        max: 10
      
      select 'tone', 'Content Tone',
        [
          ['Professional', 'professional'],
          ['Casual', 'casual'],
          ['Technical', 'technical'],
          ['Marketing', 'marketing'],
          ['Educational', 'educational']
        ],
        description: 'Tone for meta descriptions',
        default: 'professional'
    end
    
    section 'Content Analysis', description: 'AI content analysis settings' do
      checkbox 'analyze_readability', 'Analyze Readability',
        description: 'Check content readability score',
        default: true
      
      checkbox 'analyze_keyword_density', 'Analyze Keyword Density',
        description: 'Calculate keyword density',
        default: true
      
      checkbox 'analyze_sentiment', 'Analyze Sentiment',
        description: 'Determine content sentiment',
        default: false
      
      checkbox 'suggest_improvements', 'Suggest Improvements',
        description: 'Provide SEO improvement suggestions',
        default: true
    end
    
    section 'Rate Limiting', description: 'Control API usage' do
      number 'max_requests_per_hour', 'Max Requests Per Hour',
        description: 'Limit API calls to prevent excessive usage',
        default: 100,
        min: 10,
        max: 1000
      
      number 'retry_attempts', 'Retry Attempts',
        description: 'Number of retries on API failure',
        default: 3,
        min: 1,
        max: 5
      
      number 'timeout_seconds', 'Timeout (seconds)',
        description: 'API request timeout',
        default: 30,
        min: 10,
        max: 120
    end
    
    section 'Advanced', description: 'Advanced configuration options' do
      textarea 'custom_prompt', 'Custom AI Prompt',
        description: 'Customize the AI prompt (leave blank for default)',
        rows: 6,
        placeholder: 'You are an SEO expert. Analyze the following content and provide...'
      
      checkbox 'log_ai_responses', 'Log AI Responses',
        description: 'Save AI responses for debugging',
        default: false
      
      checkbox 'use_cache', 'Use Response Cache',
        description: 'Cache AI responses to reduce API calls',
        default: true
      
      number 'cache_ttl_hours', 'Cache TTL (hours)',
        description: 'How long to cache responses',
        default: 24,
        min: 1,
        max: 168
    end
  end
  
  def initialize
    super
    register_hooks if enabled?
    register_ui_blocks
  end
  
  def activate
    super
    validate_configuration
    Rails.logger.info "AI SEO plugin activated"
  end
  
  def enabled?
    get_setting('api_key').present?
  end
  
  # Main API: Generate SEO for content
  def generate_seo_for(content_object)
    return unless should_generate?(content_object)
    
    begin
      # Extract content
      content_text = extract_content_text(content_object)
      
      # Check rate limit
      return if rate_limit_exceeded?
      
      # Check cache
      cache_key = cache_key_for(content_object)
      if get_setting('use_cache', true) && cached_response = fetch_from_cache(cache_key)
        return apply_seo_data(content_object, cached_response)
      end
      
      # Call AI API
      ai_response = call_ai_api(content_text, content_object)
      
      # Parse and apply SEO
      seo_data = parse_ai_response(ai_response)
      apply_seo_data(content_object, seo_data)
      
      # Cache response
      cache_response(cache_key, seo_data) if get_setting('use_cache', true)
      
      # Log if enabled
      log_ai_interaction(content_object, ai_response) if get_setting('log_ai_responses', false)
      
      increment_request_count
      
      Rails.logger.info "AI SEO generated for #{content_object.class.name} ##{content_object.id}"
      true
    rescue => e
      Rails.logger.error "AI SEO generation failed: #{e.message}"
      false
    end
  end
  
  # Public API endpoint for manual generation
  def self.generate_seo(content_type, content_id)
    plugin = Railspress::PluginSystem.get_plugin('ai_seo')
    return { success: false, error: 'Plugin not active' } unless plugin
    
    content = find_content(content_type, content_id)
    return { success: false, error: 'Content not found' } unless content
    
    result = plugin.generate_seo_for(content)
    
    if result
      {
        success: true,
        meta_title: content.meta_title,
        meta_description: content.meta_description,
        meta_keywords: content.meta_keywords,
        focus_keyphrase: content.focus_keyphrase
      }
    else
      { success: false, error: 'Generation failed' }
    end
  end
  
  private
  
  def register_hooks
    # Hook into post/page save
    if get_setting('auto_generate_on_save', true)
      add_action('post_saved', 20) { |post| generate_seo_for(post) }
      add_action('page_saved', 20) { |page| generate_seo_for(page) }
    end
    
    # Hook into publish
    if get_setting('auto_generate_on_publish', true)
      add_action('post_published', 20) { |post| generate_seo_for(post) }
      add_action('page_published', 20) { |page| generate_seo_for(page) }
    end
  end
  
  def register_ui_blocks
    # Register a sidebar block for SEO analysis on post/page edit screens
    register_block(:ai_seo_analyzer, {
      label: 'AI SEO Analyzer',
      description: 'AI-powered SEO analysis and optimization suggestions',
      icon: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>',
      locations: [:post, :page],
      position: :sidebar,
      order: 5,
      partial: 'plugins/ai_seo/analyzer_block',
      can_render: ->(context) { context[:current_user]&.admin? || context[:current_user]&.editor? }
    })
    
    # Register a toolbar block for quick SEO actions
    register_block(:ai_seo_toolbar, {
      label: 'AI SEO Tools',
      description: 'Quick SEO generation actions',
      icon: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>',
      locations: [:post, :page],
      position: :toolbar,
      order: 10,
      partial: 'plugins/ai_seo/toolbar_block'
    })
  end
  
  def should_generate?(content)
    return false unless content.respond_to?(:meta_title)
    
    # Check if we should overwrite
    unless get_setting('overwrite_existing', false)
      return false if content.meta_title.present?
    end
    
    # Check if content has substance
    text = extract_content_text(content)
    text.present? && text.length > 100
  end
  
  def extract_content_text(content)
    text = []
    text << content.title if content.respond_to?(:title)
    
    if content.respond_to?(:content) && content.content.present?
      text << content.content.to_plain_text
    elsif content.respond_to?(:body)
      text << content.body
    end
    
    text.join("\n\n").strip
  end
  
  def call_ai_api(content_text, content_object)
    provider = get_setting('ai_provider', 'openai')
    
    case provider
    when 'openai'
      call_openai_api(content_text, content_object)
    when 'anthropic'
      call_anthropic_api(content_text, content_object)
    when 'google'
      call_google_api(content_text, content_object)
    when 'custom'
      call_custom_api(content_text, content_object)
    else
      raise "Unsupported AI provider: #{provider}"
    end
  end
  
  def call_openai_api(content_text, content_object)
    require 'net/http'
    require 'json'
    
    api_key = get_setting('api_key')
    model = get_setting('model', 'gpt-3.5-turbo')
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    
    prompt = build_seo_prompt(content_text, content_object)
    
    request.body = {
      model: model,
      messages: [
        { role: 'system', content: 'You are an expert SEO specialist. Generate optimized meta tags.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 500
    }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: get_setting('timeout_seconds', 30)) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
  
  def call_anthropic_api(content_text, content_object)
    require 'net/http'
    require 'json'
    
    api_key = get_setting('api_key')
    model = get_setting('model', 'claude-3-sonnet-20240229')
    
    uri = URI('https://api.anthropic.com/v1/messages')
    
    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = api_key
    request['anthropic-version'] = '2023-06-01'
    request['Content-Type'] = 'application/json'
    
    prompt = build_seo_prompt(content_text, content_object)
    
    request.body = {
      model: model,
      max_tokens: 500,
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: get_setting('timeout_seconds', 30)) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
  
  def call_google_api(content_text, content_object)
    # Placeholder for Google Gemini API
    { error: 'Google Gemini API not yet implemented' }
  end
  
  def call_custom_api(content_text, content_object)
    # Placeholder for custom API
    { error: 'Custom API not yet implemented' }
  end
  
  def build_seo_prompt(content_text, content_object)
    custom_prompt = get_setting('custom_prompt')
    return custom_prompt.gsub('{{content}}', content_text) if custom_prompt.present?
    
    max_title = get_setting('meta_title_max_length', 60)
    max_desc = get_setting('meta_description_max_length', 160)
    keyword_count = get_setting('meta_keywords_count', 5)
    tone = get_setting('tone', 'professional')
    
    <<~PROMPT
      Analyze the following content and generate SEO-optimized meta tags.
      
      Content:
      ---
      #{content_text.truncate(2000)}
      ---
      
      Generate the following in JSON format:
      {
        "meta_title": "SEO-optimized title (max #{max_title} chars)",
        "meta_description": "Compelling description (max #{max_desc} chars, #{tone} tone)",
        "meta_keywords": "comma-separated keywords (#{keyword_count} keywords)",
        "focus_keyphrase": "primary keyword phrase",
        "og_title": "Social media optimized title",
        "og_description": "Social media description",
        "twitter_title": "Twitter card title",
        "twitter_description": "Twitter card description",
        "suggestions": ["improvement suggestion 1", "improvement suggestion 2"]
      }
      
      Guidelines:
      - Meta title should be compelling and include the focus keyword
      - Meta description should be action-oriented with a clear value proposition
      - Keywords should be relevant and specific
      - All fields should be within character limits
      - Use #{tone} tone
      
      Respond ONLY with valid JSON, no additional text.
    PROMPT
  end
  
  def parse_ai_response(response)
    # Handle OpenAI response format
    if response['choices']&.first
      content = response['choices'].first['message']['content']
      
      # Extract JSON from response
      json_match = content.match(/\{[\s\S]*\}/)
      return JSON.parse(json_match[0]) if json_match
    end
    
    # Handle Anthropic response format
    if response['content']&.first
      content = response['content'].first['text']
      
      json_match = content.match(/\{[\s\S]*\}/)
      return JSON.parse(json_match[0]) if json_match
    end
    
    {}
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    {}
  end
  
  def apply_seo_data(content, seo_data)
    return unless seo_data.present?
    
    content.meta_title = seo_data['meta_title'] if get_setting('generate_meta_title', true) && seo_data['meta_title']
    content.meta_description = seo_data['meta_description'] if get_setting('generate_meta_description', true) && seo_data['meta_description']
    content.meta_keywords = seo_data['meta_keywords'] if get_setting('generate_meta_keywords', true) && seo_data['meta_keywords']
    content.focus_keyphrase = seo_data['focus_keyphrase'] if get_setting('generate_focus_keyphrase', true) && seo_data['focus_keyphrase']
    
    if get_setting('generate_og_tags', true)
      content.og_title = seo_data['og_title'] if seo_data['og_title']
      content.og_description = seo_data['og_description'] if seo_data['og_description']
    end
    
    if get_setting('generate_twitter_tags', true)
      content.twitter_title = seo_data['twitter_title'] if seo_data['twitter_title']
      content.twitter_description = seo_data['twitter_description'] if seo_data['twitter_description']
    end
    
    content.save(validate: false)
  end
  
  def rate_limit_exceeded?
    max_requests = get_setting('max_requests_per_hour', 100)
    current_count = get_request_count
    
    if current_count >= max_requests
      Rails.logger.warn "AI SEO rate limit exceeded: #{current_count}/#{max_requests}"
      return true
    end
    
    false
  end
  
  def get_request_count
    key = "ai_seo_requests_#{Time.now.hour}"
    Rails.cache.read(key) || 0
  end
  
  def increment_request_count
    key = "ai_seo_requests_#{Time.now.hour}"
    count = get_request_count + 1
    Rails.cache.write(key, count, expires_in: 1.hour)
  end
  
  def cache_key_for(content)
    "ai_seo_#{content.class.name.underscore}_#{content.id}_#{content.updated_at.to_i}"
  end
  
  def fetch_from_cache(cache_key)
    Rails.cache.read(cache_key)
  end
  
  def cache_response(cache_key, seo_data)
    ttl_hours = get_setting('cache_ttl_hours', 24)
    Rails.cache.write(cache_key, seo_data, expires_in: ttl_hours.hours)
  end
  
  def log_ai_interaction(content, response)
    Rails.logger.info "AI SEO Interaction Log:"
    Rails.logger.info "Content: #{content.class.name} ##{content.id}"
    Rails.logger.info "Response: #{response.to_json}"
  end
  
  def validate_configuration
    unless get_setting('api_key').present?
      Rails.logger.warn "AI SEO: API key not configured"
    end
  end
  
  def self.find_content(content_type, content_id)
    case content_type.to_s.downcase
    when 'post'
      Post.find_by(id: content_id)
    when 'page'
      Page.find_by(id: content_id)
    else
      nil
    end
  end
end

# Auto-initialize if active
if Plugin.exists?(name: 'AI SEO', active: true)
  AiSeo.new
end

