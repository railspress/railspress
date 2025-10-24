class AiService
  def initialize(provider, agent = nil)
    @provider = provider
    @agent = agent
  end
  
  # Use agent-specific settings only (agents must have their own settings)
  def temperature
    @agent&.effective_temperature || 0.7
  end
  
  def max_tokens
    @agent&.effective_max_tokens || 4000
  end
  
  def generate(prompt)
    case @provider.provider_type
    when 'openai'
      call_openai(prompt)
    when 'cohere'
      call_cohere(prompt)
    when 'anthropic'
      call_anthropic(prompt)
    when 'google'
      call_google(prompt)
    else
      raise "Unsupported provider type: #{@provider.provider_type}"
    end
  end
  
  def generate_streaming(prompt, attachments: [], &block)
    case @provider.provider_type
    when 'openai'
      stream_openai(prompt, attachments: attachments, &block)
    when 'anthropic'
      stream_anthropic(prompt, attachments: attachments, &block)
    when 'cohere'
      stream_cohere(prompt, attachments: attachments, &block)
    else
      # Fallback: simulate streaming by yielding word by word
      result = generate(prompt)
      if block_given?
        # Simulate streaming by yielding word by word
        words = result.to_s.split(/\s+/)
        words.each do |word|
          yield "#{word} "
          sleep 0.01 # Small delay to simulate streaming
        end
      end
    end
  end
  
  private
  
  def call_openai(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@provider.api_key}"
    request['Content-Type'] = 'application/json'
    
    body = {
      model: @provider.model_identifier,
      messages: [{ role: "user", content: prompt }],
      max_tokens: max_tokens,
      temperature: temperature
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      parsed_response = JSON.parse(response.body)
      content = parsed_response.dig('choices', 0, 'message', 'content')
      raise "Invalid response format: missing content" if content.nil?
      content
    else
      raise "OpenAI API error: #{response.body}"
    end
  rescue => e
    raise e
  end
  
  def call_cohere(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.cohere.ai/v1/chat')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@provider.api_key}"
    request['Content-Type'] = 'application/json'
    
    body = {
      model: @provider.model_identifier,
      message: prompt,
      max_tokens: max_tokens.to_i,
      temperature: temperature.to_f,
      stream: false
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['text']
    else
      raise "Cohere API error: #{response.body}"
    end
  rescue => e
    raise e
  end
  
  def call_anthropic(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = @provider.api_key
    request['Content-Type'] = 'application/json'
    request['anthropic-version'] = '2023-06-01'
    
    body = {
      model: @provider.model_identifier,
      max_tokens: max_tokens,
      temperature: temperature,
      messages: [{ role: "user", content: prompt }]
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['content'][0]['text']
    else
      raise "Anthropic API error: #{response.body}"
    end
  rescue => e
    raise e
  end
  
  def call_google(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@provider.model_identifier}:generateContent")
    uri.query = URI.encode_www_form(key: @provider.api_key)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        maxOutputTokens: max_tokens,
        temperature: temperature
      }
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['candidates'][0]['content']['parts'][0]['text']
    else
      raise "Google API error: #{response.body}"
    end
  rescue => e
    raise e
  end
  
  def stream_openai(prompt, attachments: [], &block)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@provider.api_key}"
    request['Content-Type'] = 'application/json'
    
    # Build content array for multi-modal support
    content = [{ type: "text", text: prompt }]
    
    # Add image attachments if present
    if attachments.present?
      attachments.each do |att|
        if att['type']&.start_with?('image/') && att['url']
          content << {
            type: "image_url",
            image_url: { url: att['url'] }
          }
        end
      end
    end
    
    body = {
      model: @provider.model_identifier,
      messages: [{ role: "user", content: content }],
      max_tokens: max_tokens,
      temperature: temperature,
      stream: true
    }
    
    request.body = body.to_json
    
    http.request(request) do |response|
      response.read_body do |chunk|
        # Process Server-Sent Events from OpenAI
        chunk.split("\n").each do |line|
          next if line.strip.empty?
          next unless line.start_with?('data: ')
          
          data = line[6..-1] # Remove 'data: ' prefix
          next if data == '[DONE]'
          
          begin
            parsed = JSON.parse(data)
            content = parsed.dig('choices', 0, 'delta', 'content')
            yield content if content && block_given?
          rescue JSON::ParserError
            # Skip malformed JSON
          end
        end
      end
    end
  rescue => e
    raise e
  end
  
  def stream_anthropic(prompt, attachments: [], &block)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = @provider.api_key
    request['Content-Type'] = 'application/json'
    request['anthropic-version'] = '2023-06-01'
    
    # Build content array for multi-modal support
    content = [{ type: "text", text: prompt }]
    
    # Add image attachments if present
    if attachments.present?
      attachments.each do |att|
        if att['type']&.start_with?('image/') && att['url']
          content << {
            type: "image",
            source: {
              type: "url",
              url: att['url']
            }
          }
        end
      end
    end
    
    body = {
      model: @provider.model_identifier,
      max_tokens: max_tokens,
      temperature: temperature,
      messages: [{ role: "user", content: content }],
      stream: true
    }
    
    request.body = body.to_json
    
    http.request(request) do |response|
      response.read_body do |chunk|
        # Process Server-Sent Events from Anthropic
        chunk.split("\n").each do |line|
          next if line.strip.empty?
          next unless line.start_with?('data: ')
          
          data = line[6..-1] # Remove 'data: ' prefix
          
          begin
            parsed = JSON.parse(data)
            content = parsed.dig('content_block', 'text')
            yield content if content && block_given?
          rescue JSON::ParserError
            # Skip malformed JSON
          end
        end
      end
    end
  rescue => e
    raise e
  end
  
  def stream_cohere(prompt, attachments: [], &block)
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.cohere.ai/v2/chat')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@provider.api_key}"
    request['Content-Type'] = 'application/json'
    
    # Note: Cohere doesn't support images, but we can include image URLs in the prompt for context
    prompt_with_attachments = prompt.dup
    if attachments.present?
      image_attachments = attachments.select { |att| att['type']&.start_with?('image/') && att['url'] }
      if image_attachments.any?
        prompt_with_attachments += "\n\nAttached Images:\n"
        image_attachments.each do |att|
          prompt_with_attachments += "- #{att['name']}: #{att['url']}\n"
        end
      end
    end
    
    body = {
      model: @provider.model_identifier,
      messages: [{ role: "user", content: prompt_with_attachments }],
      max_tokens: max_tokens.to_i,
      temperature: temperature.to_f,
      stream: true
    }
    
    request.body = body.to_json
    
    Rails.logger.info "Cohere streaming request: #{body.inspect}"
    
    http.request(request) do |response|
      Rails.logger.info "Cohere streaming response code: #{response.code}"
      
      response.read_body do |chunk|
        Rails.logger.debug "Cohere chunk received: #{chunk.inspect}"
        
        # Process Server-Sent Events from Cohere
        chunk.split("\n").each do |line|
          next if line.strip.empty?
          next unless line.start_with?('data: ')
          
          data = line[6..-1] # Remove 'data: ' prefix
          
          begin
            parsed = JSON.parse(data)
            Rails.logger.debug "Cohere parsed event: #{parsed.inspect}"
            
            # Cohere V2 streaming format: look for content-delta events
            if parsed['type'] == 'content-delta'
              content = parsed.dig('delta', 'message', 'content', 'text')
              Rails.logger.info "Cohere content extracted: #{content.inspect}"
              yield content if content && block_given?
            end
          rescue JSON::ParserError => e
            Rails.logger.error "Failed to parse Cohere data: #{e.message}"
          end
        end
      end
    end
  rescue => e
    Rails.logger.error "Cohere streaming error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise e
  end
end






