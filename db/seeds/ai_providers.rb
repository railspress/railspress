# AI Providers Seeds
# Creates default AI providers for RailsPress

puts "🤖 Creating AI providers..."

# OpenAI Provider
openai_provider = AiProvider.find_or_create_by!(slug: 'openai') do |provider|
  provider.name = 'OpenAI GPT-4'
  provider.provider_type = 'openai'
  provider.api_key = 'test-api-key'
  provider.api_url = 'https://api.openai.com/v1/chat/completions'
  provider.model_identifier = 'gpt-4o'
  provider.max_tokens = 4000
  provider.active = false
  provider.position = 1
end

puts "  ✅ OpenAI GPT-4 provider created"

# OpenAI GPT-3.5 Provider
openai_35_provider = AiProvider.find_or_create_by!(slug: 'openai-gpt35') do |provider|
  provider.name = 'OpenAI GPT-3.5 Turbo'
  provider.provider_type = 'openai'
  provider.api_key = 'test-api-key'
  provider.api_url = 'https://api.openai.com/v1/chat/completions'
  provider.model_identifier = 'gpt-3.5-turbo'
  provider.max_tokens = 4000
  provider.active = false
  provider.position = 2
end

puts "  ✅ OpenAI GPT-3.5 Turbo provider created"

# Anthropic Claude Provider
anthropic_provider = AiProvider.find_or_create_by!(slug: 'anthropic') do |provider|
  provider.name = 'Anthropic Claude'
  provider.provider_type = 'anthropic'
  provider.api_key = 'test-api-key'
  provider.api_url = 'https://api.anthropic.com/v1/messages'
  provider.model_identifier = 'claude-3-5-sonnet-20241022'
  provider.max_tokens = 4000
  provider.active = false
  provider.position = 3
end

puts "  ✅ Anthropic Claude provider created"

# Google Gemini Provider
google_provider = AiProvider.find_or_create_by!(slug: 'google') do |provider|
  provider.name = 'Google Gemini'
  provider.provider_type = 'google'
  provider.api_key = 'test-api-key'
  provider.api_url = 'https://generativelanguage.googleapis.com/v1beta/models'
  provider.model_identifier = 'gemini-1.5-pro'
  provider.max_tokens = 4000
  provider.active = false
  provider.position = 4
end

puts "  ✅ Google Gemini provider created"

# Cohere Command Provider
cohere_provider = AiProvider.find_or_create_by!(slug: 'cohere') do |provider|
  provider.name = 'Cohere Command'
  provider.provider_type = 'cohere'
  provider.api_key = 'test-api-key'
  provider.api_url = 'https://api.cohere.ai/v1/chat'
  provider.model_identifier = 'command-a-03-2025'
  provider.max_tokens = 4000
  provider.active = true
  provider.position = 5
end

puts "  ✅ Cohere Command provider created"

puts "  🎯 Total AI providers: #{AiProvider.count}"
puts ""



