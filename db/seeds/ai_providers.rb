# AI Providers Seeds
# Creates default AI providers for RailsPress

puts "🤖 Creating AI providers..."

# OpenAI Provider
openai_provider = AiProvider.find_or_create_by!(name: 'OpenAI GPT-4') do |provider|
  provider.provider_type = 'openai'
  provider.api_key = 'sk-your-openai-api-key-here'
  provider.api_url = 'https://api.openai.com/v1/chat/completions'
  provider.model_identifier = 'gpt-4o'
  provider.max_tokens = 4000
  provider.temperature = 0.7
  provider.active = true
  provider.position = 1
end

puts "  ✅ OpenAI GPT-4 provider created"

# OpenAI GPT-3.5 Provider
openai_35_provider = AiProvider.find_or_create_by!(name: 'OpenAI GPT-3.5 Turbo') do |provider|
  provider.provider_type = 'openai'
  provider.api_key = 'sk-your-openai-api-key-here'
  provider.api_url = 'https://api.openai.com/v1/chat/completions'
  provider.model_identifier = 'gpt-3.5-turbo'
  provider.max_tokens = 4000
  provider.temperature = 0.7
  provider.active = true
  provider.position = 2
end

puts "  ✅ OpenAI GPT-3.5 Turbo provider created"

# Anthropic Claude Provider
anthropic_provider = AiProvider.find_or_create_by!(name: 'Anthropic Claude') do |provider|
  provider.provider_type = 'anthropic'
  provider.api_key = 'sk-ant-your-anthropic-api-key-here'
  provider.api_url = 'https://api.anthropic.com/v1/messages'
  provider.model_identifier = 'claude-3-5-sonnet-20241022'
  provider.max_tokens = 4000
  provider.temperature = 0.7
  provider.active = true
  provider.position = 3
end

puts "  ✅ Anthropic Claude provider created"

# Google Gemini Provider
google_provider = AiProvider.find_or_create_by!(name: 'Google Gemini') do |provider|
  provider.provider_type = 'google'
  provider.api_key = 'your-google-ai-api-key-here'
  provider.api_url = 'https://generativelanguage.googleapis.com/v1beta/models'
  provider.model_identifier = 'gemini-1.5-pro'
  provider.max_tokens = 4000
  provider.temperature = 0.7
  provider.active = true
  provider.position = 4
end

puts "  ✅ Google Gemini provider created"

# Cohere Command Provider
cohere_provider = AiProvider.find_or_create_by!(name: 'Cohere Command') do |provider|
  provider.provider_type = 'cohere'
  provider.api_key = 'your-cohere-api-key-here'
  provider.api_url = 'https://api.cohere.ai/v1/generate'
  provider.model_identifier = 'command-r-plus'
  provider.max_tokens = 4000
  provider.temperature = 0.7
  provider.active = true
  provider.position = 5
end

puts "  ✅ Cohere Command provider created"

puts "  🎯 Total AI providers: #{AiProvider.count}"
puts ""

