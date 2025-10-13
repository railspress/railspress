class AiService
  def initialize(provider)
    @provider = provider
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
  
  private
  
  def call_openai(prompt)
    client = OpenAI::Client.new(access_token: @provider.api_key)
    
    response = client.chat(
      parameters: {
        model: @provider.model_identifier,
        messages: [{ role: "user", content: prompt }],
        max_tokens: @provider.max_tokens,
        temperature: @provider.temperature
      }
    )
    
    response.dig("choices", 0, "message", "content")
  rescue => e
    { error: e.message }
  end
  
  def call_cohere(prompt)
    require 'net/http'
    require 'json'
    
    uri = URI(@provider.api_url || 'https://api.cohere.ai/v1/chat')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@provider.api_key}"
    request['Content-Type'] = 'application/json'
    
    body = {
      model: @provider.model_identifier,
      message: prompt,
      max_tokens: @provider.max_tokens,
      temperature: @provider.temperature,
      stream: false
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['text']
    else
      { error: "Cohere API error: #{response.body}" }
    end
  rescue => e
    { error: e.message }
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
      max_tokens: @provider.max_tokens,
      temperature: @provider.temperature,
      messages: [{ role: "user", content: prompt }]
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['content'][0]['text']
    else
      { error: "Anthropic API error: #{response.body}" }
    end
  rescue => e
    { error: e.message }
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
        maxOutputTokens: @provider.max_tokens,
        temperature: @provider.temperature
      }
    }
    
    request.body = body.to_json
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)['candidates'][0]['content']['parts'][0]['text']
    else
      { error: "Google API error: #{response.body}" }
    end
  rescue => e
    { error: e.message }
  end
end



