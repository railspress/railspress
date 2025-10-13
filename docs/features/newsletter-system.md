# Newsletter & Subscribers System - Complete Guide

## Overview

RailsPress includes a comprehensive, native newsletter and subscriber management system with double opt-in confirmation, unsubscribe handling, APIs, and embeddable signup forms via shortcodes.

---

## Table of Contents

1. [Features](#features)
2. [Admin Interface](#admin-interface)
3. [Managing Subscribers](#managing-subscribers)
4. [Newsletter Shortcodes](#newsletter-shortcodes)
5. [REST API](#rest-api)
6. [GraphQL API](#graphql-api)
7. [Public Endpoints](#public-endpoints)
8. [Email Integration](#email-integration)
9. [Best Practices](#best-practices)
10. [GDPR Compliance](#gdpr-compliance)

---

## Features

### Core Features
- **Subscriber Management**: Full CRUD with Tabulator table interface
- **Double Opt-In**: Confirm subscriptions via email (optional)
- **Unsubscribe Handling**: One-click unsubscribe with unique tokens
- **Status Tracking**: Pending, Confirmed, Unsubscribed, Bounced, Complained
- **Source Tracking**: Know where subscribers came from
- **Tags & Lists**: Organize subscribers with tags and mailing lists
- **CSV Import/Export**: Bulk manage subscribers
- **Statistics Dashboard**: Total, confirmed, pending, growth metrics
- **REST API**: Full API for integrations
- **GraphQL API**: Query subscribers and stats
- **Shortcodes**: Easy newsletter signup forms
- **Multi-tenancy**: Isolated subscribers per tenant

### Subscriber States

| Status | Description | Can Receive Emails? |
|--------|-------------|---------------------|
| Pending | Awaiting email confirmation | No |
| Confirmed | Active subscriber | Yes |
| Unsubscribed | Opted out | No |
| Bounced | Email bounced | No |
| Complained | Marked as spam | No |

---

## Admin Interface

### Access

Navigate to: **Content → Subscribers**

Or directly: `/admin/subscribers`

### Statistics Dashboard

Four key metrics displayed:
- **Total Subscribers**: All subscribers regardless of status
- **Confirmed**: Active, confirmed subscribers
- **Pending**: Awaiting confirmation
- **This Month**: New subscribers this month (with weekly breakdown)

### Subscriber Table

Powered by Tabulator with:
- **Columns**: Email, Name, Status, Source, Tags, Date Added, Actions
- **Features**: Sortable, searchable, filterable, paginated
- **Actions**: Edit, Delete (per row)
- **Bulk Actions**: Confirm, Unsubscribe, Delete, Add Tag, Add to List

### Filters

- **Search**: By email or name
- **Status**: All, Confirmed, Pending, Unsubscribed, Bounced
- **Clear**: Reset all filters

---

## Managing Subscribers

### Add Subscriber Manually

1. Click "Add Subscriber"
2. Enter email address (required)
3. Enter name (optional)
4. Select status (defaults to "Confirmed")
5. Add source (e.g., "manual", "event", etc.)
6. Add notes if needed
7. Click "Add Subscriber"

**Note**: Manually added subscribers are auto-confirmed and skip the confirmation email.

### Edit Subscriber

1. Click Edit icon on subscriber row
2. Update fields as needed
3. Click "Update Subscriber"

### Delete Subscriber

1. Click Delete icon
2. Confirm deletion
3. Subscriber is permanently removed

### Bulk Operations

1. Select multiple subscribers using checkboxes
2. Choose bulk action from dropdown
3. Execute action

**Available Bulk Actions:**
- Confirm selected subscribers
- Unsubscribe selected subscribers
- Delete selected subscribers
- Add tag to selected subscribers
- Add to mailing list

### Import from CSV

1. Click "Import CSV"
2. Upload CSV file with columns:
   - `Email` (required)
   - `Name` (optional)
   - `Source` (optional)
   - `Status` (optional, defaults to "confirmed")
3. Click "Import Subscribers"
4. Review results

**Example CSV:**
```csv
Email,Name,Source,Status
john@example.com,John Doe,homepage,confirmed
jane@example.com,Jane Smith,blog,confirmed
bob@example.com,Bob Johnson,popup,pending
```

### Export to CSV

1. Click "Export CSV"
2. Downloads `subscribers-YYYY-MM-DD.csv`
3. Includes all subscribers with full details

---

## Newsletter Shortcodes

Add newsletter signup forms anywhere in your content using shortcodes.

### [newsletter] - Full Form

Creates a beautiful, gradient newsletter signup form.

**Basic Usage:**
```
[newsletter]
```

**With Custom Options:**
```
[newsletter 
  title="Join Our Community" 
  description="Get weekly tips and exclusive content" 
  button="Join Now"
  source="blog-sidebar"
  style="minimal"]
```

**Attributes:**
- `title` - Heading text (default: "Subscribe to our Newsletter")
- `description` - Subheading (default: "Get the latest updates...")
- `button` - Button text (default: "Subscribe")
- `source` - Track signup source (default: "shortcode")
- `style` - "default" or "minimal" (default: "default")

**Output:**
- Email input field
- Name input field (optional)
- Submit button
- Privacy note

### [newsletter_inline] - Inline Form

Creates a horizontal, compact newsletter form.

**Usage:**
```
[newsletter_inline]
```

**With Options:**
```
[newsletter_inline 
  button="Get Updates" 
  placeholder="your@email.com"
  source="footer"]
```

**Attributes:**
- `button` - Button text (default: "Subscribe")
- `placeholder` - Email placeholder (default: "Enter your email")
- `source` - Track source (default: "inline_shortcode")

**Output:**
- Horizontal layout (email + button)
- Perfect for sidebars and footers

### [newsletter_popup] - Popup Form

Creates a trigger button that opens a modal signup form.

**Usage:**
```
[newsletter_popup]
```

**With Options:**
```
[newsletter_popup 
  trigger="Join Newsletter" 
  button="Subscribe Now"]
```

**Attributes:**
- `trigger` - Trigger button text (default: "Join Newsletter")
- `button` - Submit button text (default: "Subscribe")

**Output:**
- Clickable button
- Modal popup with form
- Close button

### [newsletter_count] - Subscriber Count

Displays the number of confirmed subscribers.

**Usage:**
```
Join [newsletter_count] other subscribers!
```

**Output:**
```
Join 1,234 other subscribers!
```

### [newsletter_stats] - Statistics Grid

Shows subscriber statistics in a grid.

**Usage:**
```
[newsletter_stats]
```

**Output:**
- Total Subscribers card
- Confirmed card
- Confirmation Rate card

---

## REST API

Base URL: `/api/v1/subscribers`

### List Subscribers

**GET** `/api/v1/subscribers`

**Authentication**: Required (Editor or above)

**Query Parameters:**
- `status` - Filter by status (confirmed, pending, etc.)
- `source` - Filter by source
- `q` - Search by email or name
- `page` - Page number
- `per_page` - Results per page

**Example:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://yoursite.com/api/v1/subscribers?status=confirmed
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "email": "john@example.com",
      "name": "John Doe",
      "status": "confirmed",
      "source": "homepage",
      "tags": ["vip", "early-adopter"],
      "lists": ["weekly-newsletter"],
      "created_at": "2025-10-12T06:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 1
  }
}
```

### Subscribe (Public)

**POST** `/api/v1/subscribers`

**Authentication**: Not required (public endpoint)

**Request Body:**
```json
{
  "subscriber": {
    "email": "new@example.com",
    "name": "New Subscriber"
  },
  "source": "api"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Successfully subscribed! Please check your email to confirm.",
    "subscriber": {
      "id": 2,
      "email": "new@example.com",
      "status": "pending"
    }
  }
}
```

### Confirm Subscription (Public)

**POST** `/api/v1/subscribers/confirm`

**Authentication**: Not required

**Request Body:**
```json
{
  "token": "UNSUBSCRIBE_TOKEN_FROM_EMAIL"
}
```

### Unsubscribe (Public)

**POST** `/api/v1/subscribers/unsubscribe`

**Authentication**: Not required

**Request Body:**
```json
{
  "token": "UNSUBSCRIBE_TOKEN_FROM_EMAIL"
}
```

### Get Statistics

**GET** `/api/v1/subscribers/stats`

**Authentication**: Required

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 1234,
    "confirmed": 980,
    "pending": 154,
    "unsubscribed": 80,
    "bounced": 15,
    "growth_this_month": 45,
    "growth_this_week": 12,
    "confirmation_rate": 79.4
  }
}
```

---

## GraphQL API

### Query Subscribers

```graphql
query GetSubscribers {
  subscribers(status: "confirmed", limit: 10) {
    id
    email
    name
    status
    tags
    lists
    confirmedAt
    createdAt
    canReceiveEmails
  }
}
```

### Query Single Subscriber

```graphql
query GetSubscriber($id: ID!) {
  subscriber(id: $id) {
    id
    email
    name
    status
    source
    tags
    lists
    confirmedAt
    unsubscribedAt
    createdAt
  }
}
```

### Query Statistics

```graphql
query GetSubscriberStats {
  subscriberStats
}
```

**Response:**
```json
{
  "data": {
    "subscriberStats": {
      "total": 1234,
      "confirmed": 980,
      "pending": 154,
      "confirmation_rate": 79.4
    }
  }
}
```

---

## Public Endpoints

### Newsletter Signup Form

**POST** `/subscribe`

**Form Fields:**
- `subscriber[email]` - Email address (required)
- `subscriber[name]` - Name (optional)
- `source` - Tracking source (optional)

**Example HTML:**
```html
<form action="/subscribe" method="post">
  <input type="hidden" name="authenticity_token" value="...">
  <input type="hidden" name="source" value="footer">
  
  <input type="email" name="subscriber[email]" required>
  <input type="text" name="subscriber[name]">
  
  <button type="submit">Subscribe</button>
</form>
```

### Confirmation Page

**GET** `/confirm/:token`

Confirms a pending subscription.

**Example:**
```
https://yoursite.com/confirm/abc123xyz789
```

### Unsubscribe Page

**GET** `/unsubscribe/:token`

Unsubscribes a subscriber.

**Example:**
```
https://yoursite.com/unsubscribe/abc123xyz789
```

---

## Email Integration

### Confirmation Emails

When a subscriber signs up, they receive a confirmation email with:
- Welcome message
- Confirmation link: `/confirm/:token`
- Unsubscribe link (for transparency)

**To Enable:**
Configure SMTP settings in Settings → Email

### Welcome Emails

After confirmation, optionally send a welcome email.

### Newsletters

Send newsletters to confirmed subscribers using:
- Bulk email tools (future feature)
- Third-party services (Sendgrid, Mailchimp, etc.)
- Custom integration via API

---

## Best Practices

### 1. Always Use Double Opt-In

```ruby
# Subscribers start as pending
subscriber = Subscriber.create!(
  email: 'user@example.com',
  status: 'pending'  # Requires confirmation
)
```

### 2. Track Sources

Know where subscribers come from:
```ruby
subscriber.update(source: 'homepage_hero')
subscriber.update(source: 'blog_sidebar')
subscriber.update(source: 'exit_intent_popup')
```

### 3. Use Tags for Segmentation

```ruby
subscriber.add_tag('blog-subscriber')
subscriber.add_tag('premium')
subscriber.add_tag('early-bird')

# Query by tag
Subscriber.by_tag('premium')
```

### 4. Organize with Lists

```ruby
subscriber.add_to_list('weekly-digest')
subscriber.add_to_list('product-updates')

# Query by list
Subscriber.by_list('weekly-digest')
```

### 5. Respect Unsubscribes

```ruby
# Always check before sending
if subscriber.can_receive_emails?
  # Send email
end

# Never email unsubscribed users
Subscriber.confirmed.each do |subscriber|
  # Safe to email
end
```

### 6. Monitor Bounces

```ruby
# Mark as bounced when emails fail
subscriber.mark_bounced!

# Don't retry bounced emails
subscribers = Subscriber.confirmed.where.not(status: 'bounced')
```

### 7. Handle Spam Complaints

```ruby
# If user marks as spam
subscriber.mark_complained!

# Never email again
```

---

## GDPR Compliance

### Data Collection

**What We Collect:**
- Email address (required)
- Name (optional)
- IP address (for security)
- User agent (for analytics)
- Subscription timestamp
- Source (where they subscribed)

**Legal Basis:**
- Consent (opt-in)
- Legitimate interest (with opt-out)

### User Rights

**Right to Access:**
```ruby
# API endpoint to get subscriber data
GET /api/v1/subscribers/:id
```

**Right to Erasure:**
```ruby
# Delete subscriber data
DELETE /api/v1/subscribers/:id
```

**Right to Withdraw Consent:**
```ruby
# One-click unsubscribe
GET /unsubscribe/:token
```

### Privacy Features

1. **Unsubscribe Link**: In every email
2. **Data Minimization**: Only collect what's needed
3. **Secure Storage**: Encrypted database
4. **Audit Trail**: PaperTrail version history
5. **Export**: User can request their data

### Consent Management

```ruby
# Track consent timestamp
subscriber.confirmed_at  # When they confirmed

# Track withdrawal
subscriber.unsubscribed_at  # When they unsubscribed

# Source of consent
subscriber.source  # Where they signed up
```

---

## Integration Examples

### React Component

```javascript
function NewsletterForm() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await fetch('/api/v1/subscribers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          subscriber: { email },
          source: 'react-form'
        })
      });
      
      const data = await response.json();
      
      if (data.success) {
        alert('Check your email to confirm!');
        setEmail('');
      } else {
        alert('Error: ' + data.error);
      }
    } catch (error) {
      alert('Network error');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input 
        type="email" 
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="your@email.com"
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Subscribing...' : 'Subscribe'}
      </button>
    </form>
  );
}
```

### WordPress-Style Sidebar Widget

```erb
<!-- In your theme sidebar -->
<div class="widget widget-newsletter">
  <%= raw Railspress::ShortcodeProcessor.process('[newsletter_inline]') %>
</div>
```

### Exit Intent Popup

```html
<script>
document.addEventListener('mouseout', function(e) {
  if (e.clientY < 10 && !sessionStorage.getItem('newsletter-shown')) {
    // Show newsletter popup
    document.getElementById('newsletter-popup').style.display = 'block';
    sessionStorage.setItem('newsletter-shown', 'true');
  }
});
</script>

<div id="newsletter-popup" style="display:none;">
  <%= raw Railspress::ShortcodeProcessor.process('[newsletter_popup]') %>
</div>
```

---

## Programmatic Usage

### Create Subscriber

```ruby
subscriber = Subscriber.create!(
  email: 'user@example.com',
  name: 'User Name',
  status: 'pending',  # or 'confirmed' for auto-confirm
  source: 'api'
)
```

### Confirm Subscriber

```ruby
subscriber.confirm!
# Sets status to 'confirmed' and confirmed_at to current time
```

### Unsubscribe

```ruby
subscriber.unsubscribe!
# Sets status to 'unsubscribed' and unsubscribed_at to current time
```

### Check if Can Email

```ruby
if subscriber.can_receive_emails?
  # Send email
end
```

### Add Tags

```ruby
subscriber.add_tag('vip')
subscriber.add_tag('interested-in-product-a')

# Check tags
subscriber.tags  # => ['vip', 'interested-in-product-a']
```

### Add to Lists

```ruby
subscriber.add_to_list('weekly-digest')
subscriber.add_to_list('monthly-roundup')

# Query subscribers in a list
Subscriber.by_list('weekly-digest')
```

### Query Subscribers

```ruby
# All confirmed subscribers
confirmed_subs = Subscriber.confirmed

# Recent subscribers
recent = Subscriber.recent.limit(10)

# Search
results = Subscriber.search('john')

# By source
from_homepage = Subscriber.by_source('homepage')
```

---

## Testing

### Manual Testing

**1. Test Signup Form:**
- Add `[newsletter]` shortcode to a page
- Visit page and submit form
- Verify subscriber created with "pending" status

**2. Test Confirmation:**
- Check database for unsubscribe_token
- Visit `/confirm/:token`
- Verify status changed to "confirmed"

**3. Test Unsubscribe:**
- Visit `/unsubscribe/:token`
- Verify status changed to "unsubscribed"

**4. Test API:**
```bash
# Create subscriber
curl -X POST http://localhost:3000/api/v1/subscribers \
  -H "Content-Type: application/json" \
  -d '{"subscriber":{"email":"test@example.com"}}'

# Get stats
curl -H "Authorization: Bearer TOKEN" \
     http://localhost:3000/api/v1/subscribers/stats
```

### RSpec Tests

```ruby
RSpec.describe Subscriber, type: :model do
  describe 'validations' do
    it 'requires email' do
      subscriber = Subscriber.new
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to be_present
    end
    
    it 'validates email format' do
      subscriber = Subscriber.new(email: 'invalid')
      expect(subscriber).not_to be_valid
    end
  end
  
  describe '#confirm!' do
    it 'changes status to confirmed' do
      subscriber = Subscriber.create!(email: 'test@example.com', status: 'pending')
      subscriber.confirm!
      expect(subscriber.status).to eq('confirmed')
      expect(subscriber.confirmed_at).to be_present
    end
  end
end
```

---

## Troubleshooting

### Subscriber Not Appearing

**Check:**
1. Database for subscriber record
2. Tenant ID matches
3. No validation errors

### Confirmation Email Not Sending

**Check:**
1. Email settings configured (Settings → Email)
2. SMTP credentials correct
3. Rails logs for errors
4. Email logs table

### Shortcode Not Rendering

**Check:**
1. Shortcode syntax correct
2. Content field is processed through shortcode processor
3. JavaScript loaded (for popup forms)

### Unsubscribe Link Not Working

**Check:**
1. Token is correct (check database)
2. Route is defined
3. Subscriber exists
4. Token hasn't expired

---

## Advanced Usage

### Custom Metadata

```ruby
subscriber.set_metadata('interests', ['tech', 'design'])
subscriber.set_metadata('signup_page', '/blog/cool-post')

# Retrieve
interests = subscriber.get_metadata('interests')
```

### Bulk Operations

```ruby
# Confirm all pending from a specific source
Subscriber.pending.by_source('webinar').each(&:confirm!)

# Add tag to all VIPs
Subscriber.by_tag('vip').each do |sub|
  sub.add_to_list('exclusive-offers')
end
```

### Webhooks Integration

Send webhook when subscriber confirms:

```ruby
# In subscriber model
after_update :trigger_webhooks, if: :saved_change_to_status?

def trigger_webhooks
  if confirmed_status?
    Railspress::WebhookDispatcher.dispatch('subscriber.confirmed', self)
  elsif unsubscribed_status?
    Railspress::WebhookDispatcher.dispatch('subscriber.unsubscribed', self)
  end
end
```

---

## Security

### Token Security

- Unsubscribe tokens are 32-byte random URLs safe Base64
- Tokens are unique per subscriber
- Never expired (allows historical unsubscribes)

### Email Validation

- Format validation via regex
- Blocklist checking
- Duplicate prevention (per tenant)

### Rate Limiting

- Signup forms protected by Rack::Attack
- API endpoints have rate limits
- Prevents spam subscriptions

### Data Protection

- Passwords not stored (no login required)
- IP addresses for fraud detection only
- PaperTrail tracks all changes
- GDPR-compliant data handling

---

## Migration Guide

### From Mailchimp

1. Export subscribers from Mailchimp
2. Format as CSV (Email, Name, Status)
3. Import via RailsPress admin
4. Update your signup forms to use RailsPress

### From WordPress Plugins

1. Export from WordPress newsletter plugin
2. Map fields to RailsPress format
3. Import CSV
4. Replace WordPress shortcodes with RailsPress shortcodes

---

## Future Enhancements

Planned features:
- [ ] Email campaign builder
- [ ] A/B testing for signup forms
- [ ] Subscriber segments
- [ ] Automation workflows
- [ ] Engagement scoring
- [ ] Integration with email services (Sendgrid, Postmark, etc.)
- [ ] Newsletter templates
- [ ] Scheduled sends
- [ ] Open/click tracking
- [ ] Bounce handling automation

---

## Support

### Documentation
- **This Guide**: Complete newsletter system reference
- **API Reference**: See REST API and GraphQL sections above
- **Shortcode Examples**: See Newsletter Shortcodes section

### Code
- Model: `app/models/subscriber.rb`
- Admin Controller: `app/controllers/admin/subscribers_controller.rb`
- API Controller: `app/controllers/api/v1/subscribers_controller.rb`
- Shortcodes: `lib/railspress/newsletter_shortcodes.rb`

---

## Summary

The RailsPress Newsletter & Subscribers system provides:

✅ **Complete subscriber management** with CRUD interface  
✅ **Double opt-in** for legal compliance  
✅ **One-click unsubscribe** for user convenience  
✅ **REST & GraphQL APIs** for integrations  
✅ **Newsletter shortcodes** for easy embedding  
✅ **Statistics dashboard** for insights  
✅ **CSV import/export** for bulk operations  
✅ **Tags & lists** for segmentation  
✅ **GDPR compliant** with full data control  
✅ **Multi-tenant ready** for SaaS  

Perfect for:
- Building mailing lists
- Newsletter management
- Product updates
- Content distribution
- Lead generation
- Community building

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: October 12, 2025  
**Access**: Content → Subscribers



