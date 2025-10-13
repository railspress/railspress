# Webhooks Quick Reference

**One-page cheat sheet for RailsPress Webhooks**

---

## 🚀 Quick Start

### Create Webhook (Admin)
1. Go to **Admin → Webhooks**
2. Click **"Add Webhook"**
3. Fill form and save

### Create Webhook (Console)
```ruby
Webhook.create!(
  name: "My Hook",
  url: "https://example.com/webhook",
  events: ["post.published"],
  active: true
)
```

---

## 📋 Available Events

### Posts
```
post.created      # New post created
post.updated      # Post updated
post.published    # Post published
post.deleted      # Post deleted
```

### Pages
```
page.created      # New page created
page.updated      # Page updated
page.published    # Page published
page.deleted      # Page deleted
```

### Comments
```
comment.created   # Comment submitted
comment.approved  # Comment approved
comment.spam      # Marked as spam
```

### Users & Media
```
user.created      # User registered
user.updated      # User updated
media.uploaded    # File uploaded
```

---

## 🔒 Verify Signature

### Ruby
```ruby
signature = request.headers['X-RailsPress-Signature']
payload = request.body.read
secret = ENV['WEBHOOK_SECRET']

expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
verified = ActiveSupport::SecurityUtils.secure_compare(signature, expected)
```

### Node.js
```javascript
const crypto = require('crypto');
const signature = req.headers['x-railspress-signature'];
const payload = JSON.stringify(req.body);
const expected = crypto.createHmac('sha256', secret).update(payload).digest('hex');
const verified = crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
```

### Python
```python
import hmac, hashlib
signature = request.headers.get('X-RailsPress-Signature')
payload = request.data.decode('utf-8')
expected = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
verified = hmac.compare_digest(signature, expected)
```

---

## 📦 Payload Structure

```json
{
  "event": "post.published",
  "timestamp": "2025-10-12T03:45:00Z",
  "site": {
    "name": "My Site",
    "url": "https://example.com"
  },
  "data": {
    "id": 42,
    "type": "post",
    "title": "Post Title",
    "slug": "post-slug",
    "excerpt": "...",
    "status": "published",
    "url": "https://example.com/blog/post-slug",
    "author": { "id": 1, "email": "author@example.com" },
    "categories": [...],
    "tags": [...]
  }
}
```

---

## 🔧 Request Headers

```http
Content-Type: application/json
User-Agent: RailsPress-Webhooks/1.0
X-RailsPress-Event: post.published
X-RailsPress-Delivery: 550e8400-e29b-41d4-a716-446655440000
X-RailsPress-Signature: abc123...
X-RailsPress-Signature-256: sha256=abc123...
```

---

## 🔁 Retry Schedule

| Attempt | Delay |
|---------|-------|
| 1st | 1 minute |
| 2nd | 5 minutes |
| 3rd | 15 minutes |

Max retries: 3 (configurable 0-10)

---

## ⚡ Quick Examples

### Slack Notification
```ruby
def handle_webhook(data)
  if data['event'] == 'post.published'
    HTTParty.post(ENV['SLACK_URL'], body: {
      text: "New post: #{data['data']['title']}"
    }.to_json)
  end
end
```

### Discord Notification
```javascript
if (event === 'post.published') {
  await fetch(DISCORD_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      content: `📝 New post: ${data.title}\n${data.url}`
    })
  });
}
```

### Email Alert
```ruby
if data['event'] == 'comment.created'
  comment = data['data']
  AdminMailer.new_comment(comment).deliver_later
end
```

---

## 🛠️ Management Commands

### Via Admin UI
- http://localhost:3000/admin/webhooks

### Via Console
```ruby
# List all webhooks
Webhook.all

# Find webhook
webhook = Webhook.find_by(name: "My Hook")

# Update
webhook.update!(active: false)

# Delete
webhook.destroy!

# Test
webhook.deliver('test.webhook', { test: true })
```

---

## 📊 Monitoring

### Check Stats
```ruby
webhook.total_deliveries    # Total
webhook.failed_deliveries   # Failed
webhook.healthy?            # Health status
```

### View Recent Deliveries
```ruby
webhook.webhook_deliveries.recent.limit(10)
```

### Filter Failed
```ruby
WebhookDelivery.failed.recent.limit(20)
```

---

## 🎯 Best Practices

1. ✅ **Always verify signatures**
2. ✅ **Respond quickly** (< 5s)
3. ✅ **Use HTTPS URLs**
4. ✅ **Handle idempotency**
5. ✅ **Log webhook events**
6. ✅ **Monitor failure rates**
7. ✅ **Use background jobs**
8. ✅ **Test before deploying**

---

## 🐛 Debugging

### Test Webhook Locally

```bash
# Use ngrok for local testing
ngrok http 3000

# Create webhook with ngrok URL
Webhook.create!(
  url: "https://abc123.ngrok.io/webhooks",
  events: ["post.created"]
)
```

### Check Sidekiq Queue

```bash
# View queued jobs
bundle exec sidekiq

# Dashboard
http://localhost:3000/admin/sidekiq
```

---

**Full documentation**: `WEBHOOKS_GUIDE.md`

*RailsPress Webhooks v1.0.0*



