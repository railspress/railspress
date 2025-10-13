# RailsPress Webhooks System Guide

**Real-time integrations for posts, pages, comments, and more**

---

## 📚 Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Available Events](#available-events)
- [Webhook Payload](#webhook-payload)
- [Security & Verification](#security--verification)
- [Retry Logic](#retry-logic)
- [Admin Interface](#admin-interface)
- [Implementation Examples](#implementation-examples)
- [Troubleshooting](#troubleshooting)

---

## Introduction

The RailsPress webhooks system allows you to subscribe to events and receive real-time HTTP notifications when those events occur. This enables powerful integrations with:

- ✅ **External services** - Zapier, IFTTT, custom APIs
- ✅ **Analytics platforms** - Track content creation
- ✅ **Notification systems** - Slack, Discord, email services
- ✅ **Content syndication** - Auto-post to social media
- ✅ **Search indexing** - Update search engines instantly
- ✅ **Backup systems** - Archive content automatically

---

## Quick Start

### 1. Create a Webhook

**Via Admin Interface:**
1. Go to Admin → Webhooks
2. Click "Add Webhook"
3. Fill in the form:
   - **Name**: My Integration
   - **URL**: https://example.com/webhooks
   - **Events**: Select events to subscribe to
4. Click "Create Webhook"

**Via Rails Console:**

```ruby
webhook = Webhook.create!(
  name: "My Integration",
  url: "https://example.com/webhooks",
  events: ["post.created", "post.published"],
  active: true
)

puts "Secret Key: #{webhook.secret_key}"
```

### 2. Implement Your Webhook Handler

```ruby
# Ruby/Rails example
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def railspress
    # Verify signature
    signature = request.headers['X-RailsPress-Signature']
    payload = request.body.read
    
    unless verify_signature(payload, signature)
      return head :unauthorized
    end
    
    # Process event
    data = JSON.parse(payload)
    
    case data['event']
    when 'post.published'
      post_data = data['data']
      # Do something with the published post
      notify_team("New post published: #{post_data['title']}")
    end
    
    head :ok
  end
  
  private
  
  def verify_signature(payload, signature)
    secret_key = ENV['RAILSPRESS_WEBHOOK_SECRET']
    expected = OpenSSL::HMAC.hexdigest('SHA256', secret_key, payload)
    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end
end
```

### 3. Test Your Webhook

Click "Send Test" in the admin interface or use the console:

```ruby
webhook = Webhook.first
webhook.deliver('test.webhook', { message: 'Test payload' })
```

---

## Available Events

### Post Events

| Event | Description | Payload Includes |
|-------|-------------|------------------|
| `post.created` | New post created | Post data, author, categories, tags |
| `post.updated` | Post updated | Updated post data |
| `post.published` | Post published | Published post data |
| `post.deleted` | Post deleted | Post ID, title |

### Page Events

| Event | Description | Payload Includes |
|-------|-------------|------------------|
| `page.created` | New page created | Page data, author |
| `page.updated` | Page updated | Updated page data |
| `page.published` | Page published | Published page data |
| `page.deleted` | Page deleted | Page ID, title |

### Comment Events

| Event | Description | Payload Includes |
|-------|-------------|------------------|
| `comment.created` | New comment | Comment data, post/page |
| `comment.approved` | Comment approved | Comment data |
| `comment.spam` | Comment marked spam | Comment data |

### User Events

| Event | Description | Payload Includes |
|-------|-------------|------------------|
| `user.created` | New user registered | User data (no password) |
| `user.updated` | User profile updated | Updated user data |

### Media Events

| Event | Description | Payload Includes |
|-------|-------------|------------------|
| `media.uploaded` | File uploaded | Media data, file info |

---

## Webhook Payload

### Structure

Every webhook payload follows this structure:

```json
{
  "event": "post.published",
  "timestamp": "2025-10-12T03:45:00Z",
  "site": {
    "name": "RailsPress",
    "url": "https://example.com"
  },
  "data": {
    // Event-specific data
  }
}
```

### Post Event Payload Example

```json
{
  "event": "post.published",
  "timestamp": "2025-10-12T03:45:00Z",
  "site": {
    "name": "My Blog",
    "url": "https://myblog.com"
  },
  "data": {
    "id": 42,
    "type": "post",
    "title": "My Awesome Post",
    "slug": "my-awesome-post",
    "excerpt": "This is an amazing post...",
    "status": "published",
    "published_at": "2025-10-12T03:45:00Z",
    "url": "https://myblog.com/blog/my-awesome-post",
    "author": {
      "id": 1,
      "email": "admin@myblog.com"
    },
    "categories": [
      {
        "id": 5,
        "name": "Technology",
        "slug": "technology"
      }
    ],
    "tags": [
      {
        "id": 10,
        "name": "Rails",
        "slug": "rails"
      }
    ],
    "created_at": "2025-10-11T10:30:00Z",
    "updated_at": "2025-10-12T03:45:00Z"
  }
}
```

---

## Security & Verification

### HMAC Signature

Every webhook request includes a signature header for verification:

```
X-RailsPress-Signature: abc123...
X-RailsPress-Signature-256: sha256=abc123...
```

### Verify in Ruby

```ruby
def verify_railspress_webhook(payload, signature, secret)
  expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  ActiveSupport::SecurityUtils.secure_compare(signature, expected)
end

# Usage
signature = request.headers['X-RailsPress-Signature']
payload = request.body.read

if verify_railspress_webhook(payload, signature, ENV['WEBHOOK_SECRET'])
  # Process webhook
else
  # Reject - invalid signature
  head :unauthorized
end
```

### Verify in Node.js

```javascript
const crypto = require('crypto');

function verifyRailspressWebhook(payload, signature, secret) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
    
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}

// Usage
app.post('/webhooks/railspress', (req, res) => {
  const signature = req.headers['x-railspress-signature'];
  const payload = JSON.stringify(req.body);
  
  if (verifyRailspressWebhook(payload, signature, process.env.WEBHOOK_SECRET)) {
    // Process webhook
    res.sendStatus(200);
  } else {
    res.sendStatus(401);
  }
});
```

### Verify in Python

```python
import hmac
import hashlib

def verify_railspress_webhook(payload, signature, secret):
    expected = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected)

# Usage
@app.route('/webhooks/railspress', methods=['POST'])
def handle_webhook():
    signature = request.headers.get('X-RailsPress-Signature')
    payload = request.data.decode('utf-8')
    
    if verify_railspress_webhook(payload, signature, os.environ['WEBHOOK_SECRET']):
        # Process webhook
        return '', 200
    else:
        return '', 401
```

### Verify in PHP

```php
function verifyRailspressWebhook($payload, $signature, $secret) {
    $expected = hash_hmac('sha256', $payload, $secret);
    return hash_equals($signature, $expected);
}

// Usage
$signature = $_SERVER['HTTP_X_RAILSPRESS_SIGNATURE'];
$payload = file_get_contents('php://input');

if (verifyRailspressWebhook($payload, $signature, getenv('WEBHOOK_SECRET'))) {
    // Process webhook
    http_response_code(200);
} else {
    http_response_code(401);
}
```

---

## Retry Logic

### Automatic Retries

Failed webhooks are automatically retried with exponential backoff:

| Attempt | Delay |
|---------|-------|
| 1st retry | 1 minute |
| 2nd retry | 5 minutes |
| 3rd retry | 15 minutes |

### Retry Conditions

Webhooks are retried when:
- Connection timeout
- Connection refused
- HTTP 5xx errors
- Network errors

Webhooks are **not** retried for:
- HTTP 4xx errors (client errors)
- Invalid URLs
- Maximum retries reached

### Configure Retry Limit

```ruby
webhook.update!(retry_limit: 5)  # 0-10 retries allowed
```

---

## HTTP Request Headers

Every webhook request includes these headers:

```http
Content-Type: application/json
User-Agent: RailsPress-Webhooks/1.0
X-RailsPress-Event: post.published
X-RailsPress-Delivery: 550e8400-e29b-41d4-a716-446655440000
X-RailsPress-Signature: abc123def456...
X-RailsPress-Signature-256: sha256=abc123def456...
```

### Header Descriptions

- **Content-Type**: Always `application/json`
- **User-Agent**: Identifies RailsPress webhooks
- **X-RailsPress-Event**: The event type that triggered this webhook
- **X-RailsPress-Delivery**: Unique ID for this delivery (for debugging)
- **X-RailsPress-Signature**: HMAC-SHA256 signature of the payload
- **X-RailsPress-Signature-256**: Same as above with "sha256=" prefix

---

## Admin Interface

### Managing Webhooks

**Access**: Admin → Webhooks → http://localhost:3000/admin/webhooks

**Features**:
- ✅ Create/edit/delete webhooks
- ✅ Enable/disable webhooks
- ✅ Test webhooks manually
- ✅ View delivery history
- ✅ Monitor success/failure rates
- ✅ See retry attempts
- ✅ View response codes and bodies

### Webhook Health

Webhooks are marked "unhealthy" if:
- Failure rate > 50%
- Multiple consecutive failures

---

## Implementation Examples

### Example 1: Slack Notification

```ruby
# Webhook handler that posts to Slack
class SlackWebhookHandler
  def self.handle(webhook_data)
    event = webhook_data['event']
    data = webhook_data['data']
    
    if event == 'post.published'
      message = {
        text: "📝 New post published: #{data['title']}",
        attachments: [
          {
            title: data['title'],
            title_link: data['url'],
            text: data['excerpt'],
            color: "good",
            fields: [
              {
                title: "Author",
                value: data['author']['email'],
                short: true
              },
              {
                title: "Categories",
                value: data['categories'].map { |c| c['name'] }.join(', '),
                short: true
              }
            ]
          }
        ]
      }
      
      # Send to Slack
      HTTParty.post(ENV['SLACK_WEBHOOK_URL'], body: message.to_json)
    end
  end
end
```

### Example 2: Update External Search Index

```javascript
// Node.js webhook handler
const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());

app.post('/webhooks/railspress', async (req, res) => {
  // Verify signature
  const signature = req.headers['x-railspress-signature'];
  const payload = JSON.stringify(req.body);
  const secret = process.env.RAILSPRESS_WEBHOOK_SECRET;
  
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  
  if (signature !== expected) {
    return res.sendStatus(401);
  }
  
  // Process event
  const { event, data } = req.body;
  
  switch (event) {
    case 'post.published':
      // Update search index
      await algolia.saveObject({
        objectID: data.id,
        title: data.title,
        content: data.excerpt,
        url: data.url,
        categories: data.categories,
        publishedAt: data.published_at
      });
      break;
      
    case 'post.deleted':
      // Remove from search index
      await algolia.deleteObject(data.id);
      break;
  }
  
  res.sendStatus(200);
});
```

### Example 3: Social Media Auto-Post

```python
# Python webhook handler with Twitter integration
from flask import Flask, request
import hmac
import hashlib
import tweepy

app = Flask(__name__)

@app.route('/webhooks/railspress', methods=['POST'])
def handle_webhook():
    # Verify signature
    signature = request.headers.get('X-RailsPress-Signature')
    payload = request.data.decode('utf-8')
    secret = os.environ['WEBHOOK_SECRET']
    
    expected = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    if not hmac.compare_digest(signature, expected):
        return '', 401
    
    # Process event
    data = request.json
    
    if data['event'] == 'post.published':
        post = data['data']
        
        # Post to Twitter
        tweet = f"📝 New blog post: {post['title']} {post['url']}"
        twitter_client.create_tweet(text=tweet)
    
    return '', 200
```

### Example 4: Discord Webhook

```javascript
// Send to Discord when posts are published
const Discord = require('discord.js');

async function handlePostPublished(postData) {
  const embed = {
    title: postData.title,
    description: postData.excerpt,
    url: postData.url,
    color: 0x5865F2,
    author: {
      name: postData.author.email
    },
    fields: [
      {
        name: 'Categories',
        value: postData.categories.map(c => c.name).join(', '),
        inline: true
      },
      {
        name: 'Tags',
        value: postData.tags.map(t => t.name).join(', '),
        inline: true
      }
    ],
    timestamp: postData.published_at
  };
  
  await discordWebhook.send({ embeds: [embed] });
}
```

---

## Retry Logic

### Failure Handling

When a webhook delivery fails, RailsPress:

1. **Logs the error** - Captures error message, status code, response
2. **Schedules retry** - If retry limit not reached
3. **Exponential backoff** - Waits longer between each retry
4. **Updates statistics** - Tracks success/failure rates

### Monitoring

View delivery attempts in Admin → Webhooks → [Your Webhook]:
- ✅ See all delivery attempts
- ✅ View response codes and bodies
- ✅ Check error messages
- ✅ Monitor retry attempts

---

## Webhook Management

### Enable/Disable Webhooks

```ruby
# Via console
webhook.update!(active: false)  # Disable
webhook.update!(active: true)   # Enable
```

### Update Events

```ruby
webhook.update!(events: [
  'post.published',
  'page.published',
  'comment.approved'
])
```

### Check Webhook Health

```ruby
webhook.healthy?  # Returns true/false based on failure rate
```

### View Statistics

```ruby
webhook.total_deliveries   # Total attempts
webhook.failed_deliveries  # Failed attempts
webhook.last_delivered_at  # Last successful delivery
```

---

## Best Practices

### 1. Respond Quickly (< 5 seconds)

❌ **Don't**:
```ruby
def webhook_handler
  # Don't do heavy processing synchronously
  process_post(data)  # Might take minutes!
  send_email(data)
  update_search_index(data)
  
  head :ok
end
```

✅ **Do**:
```ruby
def webhook_handler
  # Queue for background processing
  ProcessWebhookJob.perform_later(request.body.read)
  
  head :ok  # Respond immediately
end
```

### 2. Always Verify Signatures

❌ **Don't**:
```ruby
def webhook_handler
  data = JSON.parse(request.body.read)
  # Process without verification - INSECURE!
end
```

✅ **Do**:
```ruby
def webhook_handler
  unless verify_signature
    return head :unauthorized
  end
  
  # Now safe to process
end
```

### 3. Handle Idempotency

Webhooks might be delivered multiple times. Make your handler idempotent:

```ruby
def handle_post_published(post_data)
  # Use find_or_create_by instead of create
  SyncedPost.find_or_create_by(railspress_id: post_data['id']) do |synced|
    synced.title = post_data['title']
    synced.content = post_data['content']
  end
end
```

### 4. Log Webhook Deliveries

```ruby
def webhook_handler
  Rails.logger.info "Received webhook: #{request.headers['X-RailsPress-Event']}"
  
  # Process...
  
  Rails.logger.info "Webhook processed successfully"
end
```

---

## Troubleshooting

### Webhook Not Triggering

**Check**:
1. Is the webhook active?
2. Is the event subscribed?
3. Did the event actually fire?
4. Check Background Jobs (Sidekiq)

```ruby
webhook = Webhook.find(id)
webhook.active?  # Should be true
webhook.events.include?('post.published')  # Should be true
```

### Deliveries Failing

**Check**:
1. Is the URL correct and accessible?
2. Is your endpoint responding with 2xx status?
3. Is there a firewall blocking requests?
4. Check delivery error messages in admin

### Signature Verification Failing

**Check**:
1. Are you using the correct secret key?
2. Are you hashing the raw payload (not parsed JSON)?
3. Are you using HMAC-SHA256?
4. Are you comparing hashes securely?

---

## Advanced Usage

### Custom Event Dispatching

```ruby
# Dispatch custom events
Railspress::WebhookDispatcher.dispatch('custom.event', custom_object)
```

### Programmatic Webhook Creation

```ruby
# Create webhook via API/script
Webhook.create!(
  name: "Production Deployment Hook",
  url: "https://deploy.example.com/hooks",
  events: [
    "post.published",
    "page.published"
  ],
  active: true,
  retry_limit: 5,
  timeout: 30
)
```

### Bulk Testing

```ruby
# Test all active webhooks
Webhook.active.each do |webhook|
  webhook.deliver('test.webhook', { test: true })
end
```

---

## Webhook Endpoint Requirements

Your webhook endpoint should:

1. **Accept POST requests** with JSON payload
2. **Respond quickly** (< 5 seconds)
3. **Return 2xx status** for success
4. **Verify signatures** for security
5. **Handle idempotency** (duplicate deliveries)
6. **Log requests** for debugging

### Example Endpoint (Minimal)

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def railspress
    # 1. Verify signature
    return head :unauthorized unless verify_signature
    
    # 2. Parse payload
    data = JSON.parse(request.body.read)
    
    # 3. Queue for processing
    ProcessRailspressWebhookJob.perform_later(data)
    
    # 4. Respond quickly
    head :ok
  end
  
  private
  
  def verify_signature
    signature = request.headers['X-RailsPress-Signature']
    payload = request.body.read
    secret = ENV['RAILSPRESS_WEBHOOK_SECRET']
    
    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end
end
```

---

## Monitoring & Analytics

### Track Delivery Success

```ruby
# Get webhook stats
webhook = Webhook.find(id)

puts "Total Deliveries: #{webhook.total_deliveries}"
puts "Failed Deliveries: #{webhook.failed_deliveries}"
puts "Success Rate: #{((webhook.total_deliveries - webhook.failed_deliveries).to_f / webhook.total_deliveries * 100).round(2)}%"
puts "Healthy: #{webhook.healthy?}"
```

### Recent Deliveries

```ruby
# Get recent deliveries
deliveries = webhook.webhook_deliveries.recent.limit(20)

deliveries.each do |delivery|
  puts "#{delivery.event_type}: #{delivery.status} (#{delivery.response_code})"
end
```

---

## Security Considerations

### 1. Use HTTPS Only

Always use HTTPS URLs for webhooks:
```ruby
validates :url, format: { with: /\Ahttps:\/\// }
```

### 2. Whitelist IPs (Optional)

Restrict webhook sources:
```ruby
# In your webhook handler
allowed_ips = ['1.2.3.4', '5.6.7.8']
return head :forbidden unless allowed_ips.include?(request.remote_ip)
```

### 3. Rate Limiting

Protect your webhook endpoint:
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('webhooks/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/webhooks/')
end
```

### 4. Secret Key Rotation

Rotate webhook secrets regularly:
```ruby
webhook.update!(secret_key: SecureRandom.hex(32))
```

---

## FAQs

### Q: How do I get the secret key?

**A**: View it in the admin interface (click Show/Hide) or via console:
```ruby
Webhook.find(id).secret_key
```

### Q: Can I have multiple webhooks for the same event?

**A**: Yes! Create multiple webhook subscriptions. Each will receive the event.

### Q: What happens if my endpoint is down?

**A**: The webhook will retry with exponential backoff up to the retry limit, then mark as failed.

### Q: Can I test without triggering real events?

**A**: Yes, use the "Send Test" button in the admin interface.

### Q: Are webhooks sent synchronously?

**A**: No, they're queued via Sidekiq for background delivery.

### Q: Can I disable webhooks temporarily?

**A**: Yes, toggle the "Active" switch in the admin or set `active: false`.

---

## Debugging

### Enable Debug Logging

```ruby
# config/environments/development.rb
config.log_level = :debug
```

### View Sidekiq Queue

```bash
# Check queued webhooks
bundle exec sidekiq

# Visit Sidekiq dashboard
http://localhost:3000/admin/sidekiq
```

### Test Locally with RequestBin

```bash
# Create test webhook with RequestBin
webhook = Webhook.create!(
  name: "Test",
  url: "https://requestbin.io/YOUR_BIN",
  events: ["post.created"]
)

# Create a post to trigger it
Post.create!(title: "Test", status: "published", user: User.first)
```

---

## Resources

- **Admin Interface**: http://localhost:3000/admin/webhooks
- **Sidekiq Dashboard**: http://localhost:3000/admin/sidekiq
- **RequestBin**: https://requestbin.io/
- **Webhook.site**: https://webhook.site/

---

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready

---

*Happy integrating with webhooks! 🚀*



