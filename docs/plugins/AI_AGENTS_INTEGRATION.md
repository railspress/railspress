# AI Agents Plugin Integration Guide

## Overview

This guide shows how plugins can easily create and use AI Agents in RailsPress.

## Quick Start for Plugins

### 1. Create an AI Agent from Your Plugin

```ruby
# In your plugin's initialization
Railspress::AiAgentPluginHelper.create_agent(
  name: 'My Custom Analyzer',
  agent_type: 'custom_analyzer',
  prompt: 'You are a custom content analyzer. Analyze the following content:',
  content: 'Focus on key metrics and insights.',
  guidelines: 'Be concise and actionable.',
  rules: 'Do not include personal opinions.',
  tasks: 'Extract key metrics, identify trends, suggest improvements.',
  provider_type: 'openai',  # or 'cohere', 'anthropic', 'google'
  active: true
)
```

### 2. Execute an AI Agent

```ruby
# Execute by agent type
result = Railspress::AiAgentPluginHelper.execute('content_summarizer', 'Text to summarize')

# Execute by agent name
result = Railspress::AiAgentPluginHelper.execute_by_name('My Custom Analyzer', 'Text to analyze')
```

### 3. Check if Agent Exists

```ruby
if Railspress::AiAgentPluginHelper.agent_exists?('content_summarizer')
  # Use the agent
  result = Railspress::AiAgentPluginHelper.execute('content_summarizer', input_text)
end
```

### 4. List Available Agents

```ruby
agents = Railspress::AiAgentPluginHelper.available_agents
agents.each do |agent|
  puts "#{agent.name} (#{agent.agent_type})"
end
```

### 5. Batch Execute Multiple Agents

```ruby
results = Railspress::AiAgentPluginHelper.batch_execute([
  { type: 'content_summarizer', input: 'Long article text...' },
  { type: 'seo_analyzer', input: 'Page content...' },
  { type: 'post_writer', input: 'Topic: AI in healthcare' }
])

results.each do |result|
  if result[:status] == 'success'
    puts "#{result[:agent_type]}: #{result[:result]}"
  else
    puts "Error: #{result[:error]}"
  end
end
```

## Plugin Helper API Reference

### Creating Agents

#### `create_agent(name:, agent_type:, prompt:, provider_type:, **options)`
Creates a new AI Agent for your plugin.

**Parameters:**
- `name` (required) - Unique name for the agent
- `agent_type` (required) - Unique type identifier (e.g., 'custom_analyzer')
- `prompt` (required) - The base prompt for the agent
- `provider_type` (optional) - 'openai', 'cohere', 'anthropic', or 'google' (default: 'openai')
- `content` (optional) - Content guidelines
- `guidelines` (optional) - Additional guidelines
- `rules` (optional) - Rules for the agent
- `tasks` (optional) - Specific tasks
- `master_prompt` (optional) - Master prompt (applied to all agents)
- `active` (optional) - Whether agent is active (default: true)
- `position` (optional) - Display order (default: 0)

**Returns:** Created AiAgent object

**Example:**
```ruby
agent = Railspress::AiAgentPluginHelper.create_agent(
  name: 'Product Description Generator',
  agent_type: 'product_description_generator',
  prompt: 'Generate product descriptions',
  content: 'Focus on benefits and features',
  provider_type: 'openai'
)
```

### Executing Agents

#### `execute(agent_type, input)`
Execute an AI Agent by its type.

**Parameters:**
- `agent_type` (required) - The agent type to execute
- `input` (required) - The input text/data for the agent

**Returns:** Generated content as string

**Raises:** Error if agent not found or execution fails

**Example:**
```ruby
summary = Railspress::AiAgentPluginHelper.execute('content_summarizer', @post.content)
```

#### `execute_by_name(name, input)`
Execute an AI Agent by its name.

**Parameters:**
- `name` (required) - The agent name
- `input` (required) - The input text/data

**Returns:** Generated content as string

**Example:**
```ruby
result = Railspress::AiAgentPluginHelper.execute_by_name('Product Description Generator', product_data)
```

#### `batch_execute(agent_requests)`
Execute multiple agents at once.

**Parameters:**
- `agent_requests` (required) - Array of hashes with `:type` and `:input` keys

**Returns:** Array of hashes with results/errors

**Example:**
```ruby
results = Railspress::AiAgentPluginHelper.batch_execute([
  { type: 'content_summarizer', input: 'Article text' },
  { type: 'seo_analyzer', input: 'Page content' }
])
```

### Managing Agents

#### `available_agents`
Get all active AI Agents.

**Returns:** ActiveRecord::Relation of AiAgent objects

**Example:**
```ruby
agents = Railspress::AiAgentPluginHelper.available_agents
```

#### `available_providers`
Get all active AI Providers.

**Returns:** ActiveRecord::Relation of AiProvider objects

**Example:**
```ruby
providers = Railspress::AiAgentPluginHelper.available_providers
```

#### `agent_exists?(agent_type)`
Check if an agent type exists and is active.

**Returns:** Boolean

**Example:**
```ruby
if Railspress::AiAgentPluginHelper.agent_exists?('content_summarizer')
  # Agent is available
end
```

#### `get_agent(agent_type)`
Get an agent by type.

**Returns:** AiAgent object or nil

**Example:**
```ruby
agent = Railspress::AiAgentPluginHelper.get_agent('content_summarizer')
puts agent.prompt
```

#### `update_agent(agent_type, **attributes)`
Update an existing agent.

**Example:**
```ruby
Railspress::AiAgentPluginHelper.update_agent('content_summarizer',
  prompt: 'Updated prompt...',
  active: false
)
```

#### `delete_agent(agent_type)`
Delete an agent.

**Example:**
```ruby
Railspress::AiAgentPluginHelper.delete_agent('old_agent_type')
```

#### `register_agent_type(type, description)`
Register a new agent type.

**Example:**
```ruby
Railspress::AiAgentPluginHelper.register_agent_type('product_analyzer', 'Analyzes product data')
```

## API Endpoints

### Authentication
All API endpoints require authentication. Include user credentials or API token.

### AI Agents API

#### List All Agents
```http
GET /api/v1/ai_agents
```

**Response:**
```json
{
  "success": true,
  "agents": [
    {
      "id": 1,
      "name": "Content Summarizer",
      "type": "content_summarizer",
      "active": true,
      "provider": {
        "id": 1,
        "name": "OpenAI GPT-4",
        "type": "openai"
      }
    }
  ],
  "total": 1
}
```

#### Get Single Agent
```http
GET /api/v1/ai_agents/:id
```

**Response:**
```json
{
  "success": true,
  "agent": {
    "id": 1,
    "name": "Content Summarizer",
    "type": "content_summarizer",
    "prompt": "Summarize the following content:",
    "content": "Focus on key points.",
    "guidelines": "Keep it concise.",
    "rules": "No personal opinions.",
    "tasks": "Extract main ideas.",
    "master_prompt": "You are an AI assistant.",
    "active": true,
    "position": 1,
    "provider": {
      "id": 1,
      "name": "OpenAI GPT-4",
      "type": "openai"
    },
    "created_at": "2025-10-12T10:00:00Z",
    "updated_at": "2025-10-12T10:00:00Z"
  }
}
```

#### Create Agent
```http
POST /api/v1/ai_agents
Content-Type: application/json

{
  "ai_provider_id": 1,
  "ai_agent": {
    "name": "Custom Agent",
    "agent_type": "custom_type",
    "prompt": "Your prompt here",
    "content": "Content guidelines",
    "active": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "agent": { ... },
  "message": "AI Agent created successfully"
}
```

#### Update Agent
```http
PATCH /api/v1/ai_agents/:id
Content-Type: application/json

{
  "ai_agent": {
    "prompt": "Updated prompt",
    "active": false
  }
}
```

#### Delete Agent
```http
DELETE /api/v1/ai_agents/:id
```

**Response:**
```json
{
  "success": true,
  "message": "AI Agent deleted successfully"
}
```

#### Execute Agent by ID
```http
POST /api/v1/ai_agents/:id/execute
Content-Type: application/json

{
  "user_input": "Text to process",
  "context": {}
}
```

**Response:**
```json
{
  "success": true,
  "result": "Generated content...",
  "agent": {
    "id": 1,
    "name": "Content Summarizer",
    "type": "content_summarizer"
  }
}
```

#### Execute Agent by Type
```http
POST /api/v1/ai_agents/execute/content_summarizer
Content-Type: application/json

{
  "user_input": "Text to summarize",
  "context": {}
}
```

### AI Providers API

#### List All Providers
```http
GET /api/v1/ai_providers
```

#### Get Single Provider
```http
GET /api/v1/ai_providers/:id
```

#### Create Provider (Admin Only)
```http
POST /api/v1/ai_providers
Content-Type: application/json

{
  "ai_provider": {
    "name": "My OpenAI Provider",
    "provider_type": "openai",
    "api_key": "sk-...",
    "model_identifier": "gpt-4",
    "max_tokens": 4000,
    "temperature": 0.7,
    "active": true
  }
}
```

#### Update Provider (Admin Only)
```http
PATCH /api/v1/ai_providers/:id
```

#### Delete Provider (Admin Only)
```http
DELETE /api/v1/ai_providers/:id
```

#### Toggle Provider (Admin Only)
```http
PATCH /api/v1/ai_providers/:id/toggle
```

## Real-World Plugin Examples

### Example 1: SEO Plugin with AI

```ruby
class SeoPlugin < Railspress::Plugin
  def initialize
    super
    
    # Create custom SEO analyzer agent
    Railspress::AiAgentPluginHelper.create_agent(
      name: 'SEO Meta Generator',
      agent_type: 'seo_meta_generator',
      prompt: 'Generate SEO-optimized meta titles and descriptions',
      content: 'Titles under 60 chars, descriptions under 160 chars',
      tasks: 'Analyze content, suggest meta title, suggest meta description, suggest keywords',
      provider_type: 'openai'
    )
  end
  
  # Hook into post creation
  Railspress::PluginSystem.add_action('post_created') do |post|
    # Generate SEO metadata
    seo_data = Railspress::AiAgentPluginHelper.execute('seo_meta_generator', post.content)
    
    # Save SEO data
    post.update(seo_metadata: seo_data)
  end
end
```

### Example 2: Content Recommendation Plugin

```ruby
class ContentRecommendationPlugin < Railspress::Plugin
  def initialize
    super
    
    # Create recommendation agent
    Railspress::AiAgentPluginHelper.create_agent(
      name: 'Content Recommender',
      agent_type: 'content_recommender',
      prompt: 'Recommend related content based on user interests',
      provider_type: 'cohere'
    )
  end
  
  def recommend_for_user(user)
    # Get user's reading history
    history = user.read_posts.last(10).map(&:content).join("\n\n")
    
    # Get recommendations
    recommendations = Railspress::AiAgentPluginHelper.execute('content_recommender', history)
    
    recommendations
  end
end
```

### Example 3: Comment Moderation Plugin

```ruby
class SmartModerationPlugin < Railspress::Plugin
  def initialize
    super
    
    # Create moderation agent
    Railspress::AiAgentPluginHelper.create_agent(
      name: 'Comment Moderator',
      agent_type: 'comment_moderator',
      prompt: 'Analyze if this comment is spam, toxic, or appropriate',
      tasks: 'Classify as: spam, toxic, inappropriate, or safe',
      provider_type: 'anthropic'
    )
  end
  
  # Hook into comment creation
  Railspress::PluginSystem.add_action('comment_created') do |comment|
    # Analyze comment
    analysis = Railspress::AiAgentPluginHelper.execute('comment_moderator', comment.content)
    
    # Auto-moderate based on analysis
    if analysis.include?('spam') || analysis.include?('toxic')
      comment.update(status: 'rejected', moderation_note: analysis)
    else
      comment.update(status: 'approved')
    end
  end
end
```

## Error Handling

Always wrap AI calls in error handling:

```ruby
begin
  result = Railspress::AiAgentPluginHelper.execute('content_summarizer', text)
  # Use result
rescue => e
  Rails.logger.error "AI Agent error: #{e.message}"
  # Fallback behavior
  result = text.truncate(200)
end
```

## Best Practices

### 1. Check Agent Availability
```ruby
if Railspress::AiAgentPluginHelper.agent_exists?('my_agent_type')
  # Use agent
else
  # Fallback or create agent
end
```

### 2. Use Batch Execution for Multiple Calls
```ruby
# Better performance
results = Railspress::AiAgentPluginHelper.batch_execute([
  { type: 'summarizer', input: text1 },
  { type: 'analyzer', input: text2 }
])

# vs multiple individual calls
```

### 3. Cache AI Results
```ruby
def get_summary(content)
  cache_key = "ai_summary_#{Digest::MD5.hexdigest(content)}"
  
  Rails.cache.fetch(cache_key, expires_in: 1.day) do
    Railspress::AiAgentPluginHelper.execute('content_summarizer', content)
  end
end
```

### 4. Provide Fallbacks
```ruby
def smart_excerpt(content)
  Railspress::AiAgentPluginHelper.execute('content_summarizer', content)
rescue
  content.truncate(200)  # Fallback to simple truncation
end
```

## Testing Your Plugin's AI Integration

```ruby
require 'test_helper'

class MyPluginTest < ActiveSupport::TestCase
  setup do
    # Create test provider
    @provider = AiProvider.create!(
      name: 'Test Provider',
      provider_type: 'openai',
      api_key: 'test-key',
      model_identifier: 'gpt-4'
    )
    
    # Create test agent
    @agent = Railspress::AiAgentPluginHelper.create_agent(
      name: 'Test Agent',
      agent_type: 'test_type',
      prompt: 'Test prompt',
      provider_type: 'openai'
    )
  end
  
  test "should execute agent" do
    # Mock AI response
    AiService.any_instance.stubs(:generate).returns("Mocked response")
    
    result = Railspress::AiAgentPluginHelper.execute('test_type', 'test input')
    assert_equal "Mocked response", result
  end
end
```

## Advanced Usage

### Custom Agent Types

```ruby
# Register custom agent type
Railspress::AiAgentPluginHelper.register_agent_type('product_analyzer')

# Now you can create agents of this type
Railspress::AiAgentPluginHelper.create_agent(
  name: 'Product Analyzer',
  agent_type: 'product_analyzer',
  prompt: 'Analyze product data...',
  provider_type: 'openai'
)
```

### Updating Existing Agents

```ruby
# Update an agent's configuration
Railspress::AiAgentPluginHelper.update_agent('content_summarizer',
  prompt: 'New improved prompt...',
  max_tokens: 2000
)
```

### Monitoring Agent Usage

```ruby
agent = Railspress::AiAgentPluginHelper.get_agent('content_summarizer')

# Check execution count
puts "Executed #{agent.execution_count} times"

# Check last execution
puts "Last run: #{agent.last_executed_at}"
```

## Troubleshooting

### Agent Not Found
**Error:** "No active agent found for type: content_summarizer"

**Solutions:**
1. Check if agent exists: `Railspress::AiAgentPluginHelper.agent_exists?('content_summarizer')`
2. Create the agent if needed
3. Verify agent is active
4. Check agent_type spelling

### Provider Not Available
**Error:** "No active AI provider found for type: openai"

**Solutions:**
1. Configure provider in Admin > AI Agents > Providers
2. Check provider is active
3. Verify API key is set
4. Use different provider type

### Rate Limiting
If you hit API rate limits, implement caching:

```ruby
Rails.cache.fetch("ai_result_#{input_hash}", expires_in: 1.hour) do
  Railspress::AiAgentPluginHelper.execute('agent_type', input)
end
```

## Security Considerations

1. **API Keys** - Never expose API keys in your plugin code
2. **Input Validation** - Sanitize user input before sending to AI
3. **Output Sanitization** - Sanitize AI output before displaying
4. **Rate Limiting** - Implement rate limiting for public-facing features
5. **Caching** - Cache results to minimize API costs

## Complete Example Plugin

```ruby
# plugins/ai_content_enhancer/plugin.rb
class AiContentEnhancerPlugin < Railspress::Plugin
  def initialize
    super
    setup_agents
    setup_hooks
  end
  
  private
  
  def setup_agents
    # Create agents if they don't exist
    unless Railspress::AiAgentPluginHelper.agent_exists?('content_enhancer')
      Railspress::AiAgentPluginHelper.create_agent(
        name: 'Content Enhancer',
        agent_type: 'content_enhancer',
        prompt: 'Enhance the following content for better readability and engagement',
        content: 'Improve grammar, clarity, and flow',
        guidelines: 'Maintain original meaning and tone',
        tasks: 'Fix grammar, improve readability, enhance engagement',
        provider_type: 'openai'
      )
    end
  end
  
  def setup_hooks
    # Add action hook for post enhancement
    Railspress::PluginSystem.add_action('before_post_publish') do |post|
      enhance_post_content(post)
    end
  end
  
  def enhance_post_content(post)
    return if post.content.blank?
    
    begin
      enhanced = Railspress::AiAgentPluginHelper.execute('content_enhancer', post.content)
      post.enhanced_content = enhanced
    rescue => e
      Rails.logger.error "Content enhancement failed: #{e.message}"
    end
  end
end
```

---

**Version:** 1.0
**Last Updated:** October 12, 2025
**Status:** Production Ready





