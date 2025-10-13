# AI SEO Plugin - Complete Guide

**Automatically generate and optimize SEO meta tags using AI**

---

## 📚 Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Features](#features)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)

---

## Introduction

The **AI SEO Plugin** uses artificial intelligence to automatically generate optimized meta tags, descriptions, and keywords for your content. It supports multiple AI providers and offers extensive customization.

### Key Benefits

✅ **Save Time** - Auto-generate SEO in seconds  
✅ **Better SEO** - AI-optimized titles and descriptions  
✅ **Multiple Providers** - OpenAI, Anthropic, Google  
✅ **Customizable** - 30+ settings to control behavior  
✅ **API Access** - Integrate with your workflow  
✅ **Rate Limited** - Prevent excessive API usage  
✅ **Cached** - Reduce API calls and costs  

---

## Quick Start

### Step 1: Activate Plugin

1. Go to **Admin → Plugins**
2. Find "AI SEO"
3. Click **"Activate"**

### Step 2: Configure Settings

1. Go to **Plugins → AI SEO → Settings**
2. Choose your AI provider (OpenAI recommended)
3. Enter your API key
4. Select model (GPT-3.5 Turbo for cost, GPT-4 for quality)
5. Configure auto-generation options
6. Click **"Save Settings"**

### Step 3: Use It!

**Automatic:**
- Create or edit a post/page
- AI automatically generates SEO when you save/publish

**Manual:**
- Edit a post/page
- Click **"Generate SEO with AI"** button
- Wait a few seconds
- SEO fields auto-populate!

**API:**
```bash
curl -X POST http://localhost:3000/api/v1/ai_seo/generate \
  -H "Content-Type: application/json" \
  -d '{"content_type": "post", "content_id": 1}'
```

---

## Configuration

### 6 Settings Sections with 30+ Options

### 1. AI Provider (4 settings)

| Setting | Options | Description |
|---------|---------|-------------|
| **AI Provider** | OpenAI, Anthropic, Google, Custom | Choose your AI service |
| **API Key** | String | Your API key (required) |
| **Model** | 7 models | Specific AI model to use |
| **Custom API URL** | URL | For custom API endpoints |

**Supported Models:**
- **OpenAI**: GPT-4 Turbo, GPT-4, GPT-3.5 Turbo
- **Anthropic**: Claude 3 Opus, Sonnet, Haiku
- **Google**: Gemini Pro

### 2. Auto-Generation Settings (9 settings)

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Auto-Generate on Save | Checkbox | ✅ Yes | Generate when content saved |
| Auto-Generate on Publish | Checkbox | ✅ Yes | Generate when published |
| Overwrite Existing | Checkbox | ❌ No | Replace existing meta tags |
| Generate Meta Title | Checkbox | ✅ Yes | Auto-generate title |
| Generate Meta Description | Checkbox | ✅ Yes | Auto-generate description |
| Generate Meta Keywords | Checkbox | ✅ Yes | Auto-generate keywords |
| Generate Open Graph | Checkbox | ✅ Yes | Auto-generate OG tags |
| Generate Twitter Cards | Checkbox | ✅ Yes | Auto-generate Twitter tags |
| Generate Focus Keyphrase | Checkbox | ✅ Yes | Identify focus keyword |

### 3. SEO Guidelines (4 settings)

| Setting | Range | Default | Description |
|---------|-------|---------|-------------|
| Meta Title Max Length | 30-100 | 60 | Character limit for titles |
| Meta Description Max Length | 100-320 | 160 | Character limit for descriptions |
| Number of Keywords | 3-10 | 5 | How many keywords to generate |
| Content Tone | 5 options | Professional | Tone for descriptions |

**Tone Options:**
- Professional
- Casual
- Technical
- Marketing
- Educational

### 4. Content Analysis (4 settings)

| Setting | Description |
|---------|-------------|
| Analyze Readability | Check content readability score |
| Analyze Keyword Density | Calculate keyword density |
| Analyze Sentiment | Determine content sentiment |
| Suggest Improvements | Provide SEO recommendations |

### 5. Rate Limiting (3 settings)

| Setting | Range | Default | Description |
|---------|-------|---------|-------------|
| Max Requests/Hour | 10-1000 | 100 | API call limit |
| Retry Attempts | 1-5 | 3 | Retries on failure |
| Timeout (seconds) | 10-120 | 30 | Request timeout |

### 6. Advanced (4 settings)

| Setting | Description |
|---------|-------------|
| Custom AI Prompt | Override default prompt |
| Log AI Responses | Save responses for debugging |
| Use Response Cache | Cache to reduce API calls |
| Cache TTL (hours) | How long to cache (1-168 hours) |

---

## Features

### Automatic SEO Generation

**Triggers:**
- On content save (if enabled)
- On content publish (if enabled)
- Via API call
- Via admin button

**Generated Fields:**
```
✅ meta_title (SEO-optimized, 60 chars)
✅ meta_description (Compelling, 160 chars)
✅ meta_keywords (5 relevant keywords)
✅ focus_keyphrase (Primary keyword)
✅ og_title (Social media optimized)
✅ og_description (Social sharing)
✅ twitter_title (Twitter card)
✅ twitter_description (Twitter card)
```

### Smart Overwrite Protection

**Default Behavior:**
- ✅ Only generates if fields are empty
- ✅ Preserves manual customization
- ✅ Option to force overwrite

**When to Overwrite:**
```
Overwrite Existing: No  → Only fill empty fields
Overwrite Existing: Yes → Replace all fields
```

### Rate Limiting

**Protection:**
- Hourly request limits
- Prevents excessive API costs
- Automatic throttling
- Warning logs

**Example:**
```
Max: 100 requests/hour
Current: 45 requests
Status: ✅ OK (55 remaining)
```

### Response Caching

**Smart Caching:**
- Cache AI responses for 24 hours
- Reduces API costs by 90%+
- Cache key based on content + timestamp
- Automatic invalidation

**Cache Strategy:**
```
Request 1: Call AI API → Cache response
Request 2 (within 24h): Return cached → No API call
Request 3 (after 24h): Call AI API → Update cache
```

---

## API Reference

### POST /api/v1/ai_seo/generate

Generate SEO for specific content.

**Request:**
```json
{
  "content_type": "post",
  "content_id": 123
}
```

**Response:**
```json
{
  "success": true,
  "message": "SEO generated successfully",
  "data": {
    "meta_title": "AI-Generated Title",
    "meta_description": "Compelling description...",
    "meta_keywords": "keyword1, keyword2, keyword3",
    "focus_keyphrase": "main keyword"
  }
}
```

### POST /api/v1/ai_seo/analyze

Analyze content and get SEO suggestions without saving.

**Request:**
```json
{
  "content": "Your content text here...",
  "title": "Content Title"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Content analyzed successfully",
  "data": {
    "meta_title": "Suggested title",
    "meta_description": "Suggested description",
    "meta_keywords": "keywords",
    "focus_keyphrase": "focus keyword",
    "suggestions": [
      "Add more relevant keywords",
      "Improve readability"
    ]
  }
}
```

### POST /api/v1/ai_seo/batch_generate

Generate SEO for multiple content items at once.

**Request:**
```json
{
  "content_type": "post",
  "content_ids": [1, 2, 3, 4, 5]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Batch generation completed",
  "data": {
    "total": 5,
    "successful": 4,
    "failed": 1,
    "results": [
      {"content_id": 1, "success": true, "data": {...}},
      {"content_id": 2, "success": true, "data": {...}},
      ...
    ]
  }
}
```

### GET /api/v1/ai_seo/status

Check plugin status and configuration.

**Response:**
```json
{
  "active": true,
  "configured": true,
  "provider": "openai",
  "model": "gpt-3.5-turbo",
  "auto_generate": true,
  "rate_limit": {
    "max_per_hour": 100,
    "current": 23
  }
}
```

---

## Usage Examples

### Example 1: Automatic Generation

**Scenario**: You want SEO auto-generated when creating posts

**Configuration:**
```
Auto-Generate on Save: ✅ Yes
Auto-Generate on Publish: ✅ Yes
Overwrite Existing: ❌ No
```

**Usage:**
```ruby
# Create post
post = Post.create(
  title: "10 Tips for Ruby on Rails",
  content: "Rails is a powerful framework..."
)

# AI automatically generates:
# meta_title: "10 Expert Tips for Ruby on Rails Development | 2025 Guide"
# meta_description: "Discover 10 proven Ruby on Rails tips..."
# meta_keywords: "ruby on rails, rails tips, web development"
# focus_keyphrase: "ruby on rails tips"
```

### Example 2: Manual Generation via API

**Scenario**: Generate SEO for existing posts via script

**Code:**
```ruby
# Ruby script
require 'net/http'
require 'json'

uri = URI('http://localhost:3000/api/v1/ai_seo/generate')

request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'

request.body = {
  content_type: 'post',
  content_id: 123
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

result = JSON.parse(response.body)
puts result['data']['meta_title']
```

### Example 3: Batch Processing

**Scenario**: Generate SEO for all posts without meta tags

**Code:**
```ruby
# In Rails console
posts_without_seo = Post.where(meta_title: nil)
post_ids = posts_without_seo.pluck(:id)

# Via API
result = AiSeo.batch_generate('post', post_ids)

puts "Generated SEO for #{result[:successful]} posts"
```

### Example 4: Content Analysis

**Scenario**: Preview SEO suggestions before saving

**Code:**
```javascript
// JavaScript in admin
fetch('/api/v1/ai_seo/analyze', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    content: document.getElementById('post_content').value,
    title: document.getElementById('post_title').value
  })
})
.then(r => r.json())
.then(data => {
  console.log('Suggested meta title:', data.data.meta_title);
  console.log('Suggested description:', data.data.meta_description);
  console.log('Suggestions:', data.data.suggestions);
});
```

---

## AI Provider Setup

### OpenAI Setup

1. **Sign up**: https://platform.openai.com
2. **Get API key**: API Keys → Create new secret key
3. **Add credits**: Billing → Add payment method
4. **Configure plugin**:
   ```
   Provider: OpenAI
   API Key: sk-proj-...
   Model: gpt-3.5-turbo (cheaper) or gpt-4 (better)
   ```

**Costs:**
- GPT-3.5 Turbo: ~$0.002 per request
- GPT-4: ~$0.06 per request

### Anthropic Setup

1. **Sign up**: https://console.anthropic.com
2. **Get API key**: Settings → API Keys
3. **Add credits**: Billing
4. **Configure plugin**:
   ```
   Provider: Anthropic
   API Key: sk-ant-api...
   Model: claude-3-haiku-20240307 (faster) or claude-3-opus-20240229 (better)
   ```

**Costs:**
- Claude 3 Haiku: ~$0.001 per request
- Claude 3 Sonnet: ~$0.015 per request
- Claude 3 Opus: ~$0.075 per request

### Google Gemini Setup

1. **Sign up**: https://ai.google.dev
2. **Get API key**: Google AI Studio
3. **Configure plugin**:
   ```
   Provider: Google
   API Key: AIza...
   Model: gemini-pro
   ```

**Costs:**
- Gemini Pro: Free tier available

---

## Generated Meta Tags

### What Gets Generated

**Meta Title:**
```
Before: "My Blog Post"
After: "Expert Guide to Ruby on Rails: 10 Essential Tips | 2025"

✅ Includes focus keyword
✅ Compelling and clickable
✅ Within 60 characters
✅ SEO-optimized
```

**Meta Description:**
```
Before: (empty)
After: "Discover 10 proven Ruby on Rails tips that will boost your development productivity. Learn best practices, optimization techniques, and expert insights."

✅ Action-oriented
✅ Value proposition clear
✅ Within 160 characters
✅ Includes call-to-action
```

**Meta Keywords:**
```
"ruby on rails, rails development, web development, programming tips, rails best practices"

✅ Relevant to content
✅ Specific and targeted
✅ 5 keywords (configurable)
```

**Focus Keyphrase:**
```
"ruby on rails tips"

✅ Primary keyword identified
✅ Based on content analysis
✅ SEO-friendly
```

**Open Graph Tags:**
```json
{
  "og_title": "10 Ruby on Rails Tips Every Developer Should Know",
  "og_description": "Master Ruby on Rails with these expert tips..."
}
```

**Twitter Card Tags:**
```json
{
  "twitter_title": "10 Ruby on Rails Tips",
  "twitter_description": "Expert Rails development tips and tricks..."
}
```

---

## Settings Reference

### Complete Settings List

#### AI Provider Section
```
1. AI Provider: openai | anthropic | google | custom
2. API Key: Your API key (REQUIRED)
3. Model: Specific model to use
4. Custom API URL: For custom endpoints
```

#### Auto-Generation Section
```
5. Auto-Generate on Save: true/false
6. Auto-Generate on Publish: true/false
7. Overwrite Existing: true/false
8. Generate Meta Title: true/false
9. Generate Meta Description: true/false
10. Generate Meta Keywords: true/false
11. Generate Open Graph: true/false
12. Generate Twitter Cards: true/false
13. Generate Focus Keyphrase: true/false
```

#### SEO Guidelines Section
```
14. Meta Title Max Length: 30-100 chars (default: 60)
15. Meta Description Max Length: 100-320 chars (default: 160)
16. Number of Keywords: 3-10 (default: 5)
17. Content Tone: professional | casual | technical | marketing | educational
```

#### Content Analysis Section
```
18. Analyze Readability: true/false
19. Analyze Keyword Density: true/false
20. Analyze Sentiment: true/false
21. Suggest Improvements: true/false
```

#### Rate Limiting Section
```
22. Max Requests Per Hour: 10-1000 (default: 100)
23. Retry Attempts: 1-5 (default: 3)
24. Timeout: 10-120 seconds (default: 30)
```

#### Advanced Section
```
25. Custom AI Prompt: Custom prompt template
26. Log AI Responses: true/false
27. Use Response Cache: true/false
28. Cache TTL: 1-168 hours (default: 24)
```

---

## API Integration

### Ruby Example

```ruby
# Generate SEO for a post
result = AiSeo.generate_seo('post', 123)

if result[:success]
  puts "Meta Title: #{result[:meta_title]}"
  puts "Meta Description: #{result[:meta_description]}"
else
  puts "Error: #{result[:error]}"
end
```

### JavaScript Example

```javascript
async function generateSEO(contentType, contentId) {
  const response = await fetch('/api/v1/ai_seo/generate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({
      content_type: contentType,
      content_id: contentId
    })
  });
  
  const result = await response.json();
  
  if (result.success) {
    console.log('Generated:', result.data);
    // Update form fields
    document.getElementById('meta_title').value = result.data.meta_title;
    document.getElementById('meta_description').value = result.data.meta_description;
  }
}
```

### cURL Example

```bash
# Generate SEO
curl -X POST http://localhost:3000/api/v1/ai_seo/generate \
  -H "Content-Type: application/json" \
  -H "X-API-Token: your_api_token" \
  -d '{
    "content_type": "post",
    "content_id": 123
  }'

# Analyze content
curl -X POST http://localhost:3000/api/v1/ai_seo/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Your blog post content...",
    "title": "Your Post Title"
  }'

# Check status
curl http://localhost:3000/api/v1/ai_seo/status
```

---

## Best Practices

### 1. Choose the Right Model

**For High Volume (Cost Conscious):**
```
Provider: OpenAI
Model: gpt-3.5-turbo
Cost: ~$0.002/request
Use case: Blogs, frequent updates
```

**For Quality Content (Premium):**
```
Provider: OpenAI or Anthropic
Model: gpt-4 or claude-3-opus
Cost: ~$0.06-0.075/request
Use case: Marketing pages, landing pages
```

**For Budget (Free Tier):**
```
Provider: Google
Model: gemini-pro
Cost: Free tier available
Use case: Testing, low volume
```

### 2. Configure Auto-Generation Wisely

**Recommended:**
```
Auto-Generate on Save: ❌ No
Auto-Generate on Publish: ✅ Yes
Overwrite Existing: ❌ No
```

**Why?**
- Avoid generating SEO on every draft save
- Only generate when content is ready (published)
- Preserve manual edits
- Reduce API costs

### 3. Use Rate Limiting

**Safe Limits:**
```
Max Requests/Hour: 100
Retry Attempts: 3
Timeout: 30 seconds
```

**Prevents:**
- Excessive API costs
- API rate limit errors
- Budget overruns

### 4. Enable Caching

**Recommended:**
```
Use Response Cache: ✅ Yes
Cache TTL: 24 hours
```

**Benefits:**
- 90% cost reduction
- Faster responses
- Reduced API load

### 5. Customize for Your Niche

**Example: Tech Blog**
```
Tone: Technical
Keywords Count: 7
Include technical terms
Focus on programming keywords
```

**Example: Marketing Site**
```
Tone: Marketing
Keywords Count: 5
Action-oriented descriptions
Focus on benefits
```

---

## Troubleshooting

### Issue: "Plugin not active"

**Solution:**
1. Go to Admin → Plugins
2. Find "AI SEO"
3. Click "Activate"

### Issue: "API key not configured"

**Solution:**
1. Go to Plugins → AI SEO → Settings
2. Enter your API key
3. Save settings

### Issue: "Rate limit exceeded"

**Solution:**
1. Wait for the next hour
2. Or increase Max Requests/Hour in settings
3. Or enable caching to reduce requests

### Issue: "Generation failed"

**Possible causes:**
- Invalid API key
- Insufficient credits
- Network timeout
- Content too short

**Solution:**
1. Check API key is correct
2. Check AI provider account has credits
3. Increase timeout in settings
4. Ensure content has at least 100 characters

### Issue: "No meta tags generated"

**Check:**
1. Content is not too short
2. "Overwrite Existing" setting if fields already populated
3. Check browser console for errors
4. Check Rails logs for API errors

---

## Cost Optimization

### Tips to Reduce Costs

**1. Use Caching**
```
Enable: Use Response Cache
TTL: 24-48 hours
Savings: 90%+
```

**2. Choose Cheaper Model**
```
GPT-3.5 Turbo: $0.002/request
Claude 3 Haiku: $0.001/request
Gemini Pro: Free tier
```

**3. Rate Limiting**
```
Max Requests/Hour: 50-100
Prevents: Runaway costs
```

**4. Selective Auto-Generation**
```
On Save: ❌ No
On Publish: ✅ Yes
Result: 70% fewer API calls
```

**5. Batch Processing**
```
Use batch_generate API
Process during off-peak hours
```

### Cost Estimates

**Scenario 1: Small Blog (10 posts/month)**
```
Provider: OpenAI GPT-3.5
Cost: $0.02/month
With caching: $0.002/month
```

**Scenario 2: Medium Blog (100 posts/month)**
```
Provider: OpenAI GPT-3.5
Cost: $0.20/month
With caching: $0.02/month
```

**Scenario 3: Large Site (1000 posts/month)**
```
Provider: Claude 3 Haiku
Cost: $1.00/month
With caching: $0.10/month
```

**Scenario 4: Enterprise (10,000 posts/month)**
```
Provider: Mix of GPT-3.5 and Haiku
Cost: ~$10-15/month
With caching + batch: ~$2-3/month
```

---

## Advanced Usage

### Custom AI Prompt

**Default Prompt:**
```
Analyze the following content and generate SEO-optimized meta tags...
```

**Custom Prompt Example:**
```
You are an expert SEO consultant specializing in {{niche}}.
Analyze this content and generate:
- A click-worthy meta title under 60 characters
- A compelling meta description under 160 characters
- 5 high-value keywords
- Focus on conversion and ranking

Content: {{content}}

Return as JSON.
```

**Variables Available:**
- `{{content}}` - The content text
- Custom variables can be added

### Webhooks Integration

**Trigger SEO generation via webhook:**

```ruby
# In webhook handler
webhook_data = JSON.parse(request.body.read)

if webhook_data['event'] == 'post.created'
  post_id = webhook_data['data']['id']
  AiSeo.generate_seo('post', post_id)
end
```

### Scheduled SEO Updates

**Update SEO periodically for existing content:**

```ruby
# In Sidekiq job
class UpdateSeoJob < ApplicationJob
  def perform
    Post.published.where('updated_at < ?', 30.days.ago).find_each do |post|
      AiSeo.generate_seo('post', post.id)
      sleep 2 # Rate limiting
    end
  end
end
```

---

## FAQ

**Q: Which AI provider is best?**
A: For most users, OpenAI GPT-3.5 Turbo offers the best balance of cost and quality. For premium content, use GPT-4 or Claude 3 Opus.

**Q: How much does it cost?**
A: With GPT-3.5 Turbo and caching enabled, expect $0.002-0.02 per month for a typical blog.

**Q: Will it overwrite my existing SEO?**
A: By default, no. Enable "Overwrite Existing" in settings to replace existing meta tags.

**Q: How do I generate SEO manually?**
A: Click the "Generate SEO with AI" button in the post/page editor, or use the API.

**Q: Can I customize the AI prompts?**
A: Yes! Use the "Custom AI Prompt" setting in Advanced section.

**Q: Does it work offline?**
A: No, it requires internet connection to call AI APIs.

**Q: Is my content sent to third parties?**
A: Yes, content is sent to your chosen AI provider (OpenAI, Anthropic, etc.) for analysis. Review their privacy policies.

---

## Security & Privacy

### Data Handling

**What's sent to AI:**
- Content title
- Content body (first 2000 characters)
- No user data
- No sensitive information

**What's stored:**
- Generated meta tags only
- Optionally: AI responses (if logging enabled)

**Not sent:**
- User information
- Email addresses
- Internal IDs
- Database structure

### API Key Security

**Best practices:**
- Never commit API keys to git
- Use environment variables in production
- Rotate keys periodically
- Monitor usage in AI provider dashboard

### Compliance

- GDPR: Content sent to AI providers
- Privacy Policy: Disclose AI usage
- Data Retention: Configure cache TTL

---

## Resources

### AI Provider Documentation

- **OpenAI**: https://platform.openai.com/docs
- **Anthropic**: https://docs.anthropic.com
- **Google AI**: https://ai.google.dev/docs

### Related Documentation

- Plugin Settings Schema: `PLUGIN_SETTINGS_SCHEMA_GUIDE.md`
- SEO Helper: `app/helpers/seo_helper.rb`
- SEO Fields: Migration `add_seo_fields_to_posts_and_pages`

---

## Changelog

### Version 1.0.0 (October 2025)

**Features:**
- Initial release
- OpenAI GPT-4 & GPT-3.5 support
- Anthropic Claude 3 support
- Google Gemini support
- 30+ configuration options
- API endpoints
- Auto-generation on save/publish
- Rate limiting
- Response caching
- Manual generation UI
- Batch processing
- Content analysis

---

## Support

**Plugin Path**: `lib/plugins/ai_seo/ai_seo.rb`  
**API Controller**: `app/controllers/api/v1/ai_seo_controller.rb`  
**Settings**: http://localhost:3000/admin/plugins/[id]/settings  

**Need help?**
- Check Rails logs: `tail -f log/development.log`
- Enable response logging in settings
- Test API connection with status endpoint

---

**Version**: 1.0.0  
**Status**: ✅ Production Ready  
**Date**: October 2025

---

*Supercharge your SEO with AI!* 🚀✨



