# AI Agents API - Quick Start Guide

## 🚀 Quick Start

### Prerequisites
- RailsPress running (default: http://localhost:3000)
- User account with API access
- API authentication token (or use session auth)

## 📋 Common Operations

### 1. List All AI Agents

```bash
curl -X GET http://localhost:3000/api/v1/ai_agents \
  -H "Authorization: Bearer YOUR_TOKEN"
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

### 2. Execute an Agent

```bash
curl -X POST http://localhost:3000/api/v1/ai_agents/execute/content_summarizer \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "user_input": "Long article text to summarize..."
  }'
```

**Response:**
```json
{
  "success": true,
  "result": "Summarized version of the content...",
  "agent": {
    "id": 1,
    "name": "Content Summarizer",
    "type": "content_summarizer"
  }
}
```

### 3. Create a Custom Agent

```bash
curl -X POST http://localhost:3000/api/v1/ai_agents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "ai_provider_id": 1,
    "ai_agent": {
      "name": "Custom Content Generator",
      "agent_type": "custom_generator",
      "prompt": "Generate creative content based on:",
      "content": "Focus on engagement and clarity",
      "active": true
    }
  }'
```

### 4. Update an Agent

```bash
curl -X PATCH http://localhost:3000/api/v1/ai_agents/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "ai_agent": {
      "prompt": "Updated prompt text...",
      "active": true
    }
  }'
```

### 5. Delete an Agent

```bash
curl -X DELETE http://localhost:3000/api/v1/ai_agents/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔌 Plugin Usage Examples

### Example 1: Simple Execution

```ruby
# In your plugin
result = Railspress::AiAgentPluginHelper.execute('content_summarizer', @post.content)
@post.update(summary: result)
```

### Example 2: Create Custom Agent

```ruby
# In plugin initialization
Railspress::AiAgentPluginHelper.create_agent(
  name: 'Product Description Writer',
  agent_type: 'product_description_writer',
  prompt: 'Write compelling product descriptions',
  provider_type: 'openai'
)

# Later in your plugin
description = Railspress::AiAgentPluginHelper.execute(
  'product_description_writer',
  "Product: #{product.name}, Features: #{product.features}"
)
```

### Example 3: Batch Processing

```ruby
# Process multiple posts at once
posts = Post.published.limit(10)

requests = posts.map do |post|
  { type: 'seo_analyzer', input: post.content }
end

results = Railspress::AiAgentPluginHelper.batch_execute(requests)

posts.zip(results).each do |post, result|
  if result[:status] == 'success'
    post.update(seo_score: parse_seo_score(result[:result]))
  end
end
```

## 📊 Response Formats

### Success Response
```json
{
  "success": true,
  "result": "Generated content...",
  "agent": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message"
}
```

### List Response
```json
{
  "success": true,
  "agents": [ ... ],
  "total": 10
}
```

## 🔐 Authentication

### Session-Based (Web)
Already authenticated if logged into admin panel.

### Token-Based (API)
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

Then use the returned token in subsequent requests:
```bash
-H "Authorization: Bearer YOUR_TOKEN"
```

## ⚡ Quick Reference

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List agents | GET | `/api/v1/ai_agents` |
| Get agent | GET | `/api/v1/ai_agents/:id` |
| Create agent | POST | `/api/v1/ai_agents` |
| Update agent | PATCH | `/api/v1/ai_agents/:id` |
| Delete agent | DELETE | `/api/v1/ai_agents/:id` |
| Execute agent | POST | `/api/v1/ai_agents/:id/execute` |
| Execute by type | POST | `/api/v1/ai_agents/execute/:type` |
| List providers | GET | `/api/v1/ai_providers` |
| Get provider | GET | `/api/v1/ai_providers/:id` |
| Create provider | POST | `/api/v1/ai_providers` |
| Update provider | PATCH | `/api/v1/ai_providers/:id` |
| Toggle provider | PATCH | `/api/v1/ai_providers/:id/toggle` |

---

**Ready to go!** 🎉

Visit: http://localhost:3000
API Docs: See `docs/api/` folder
Plugin Docs: See `docs/plugins/` folder





