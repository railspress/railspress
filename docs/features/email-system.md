# RailsPress Email System Guide

## Overview

RailsPress includes a comprehensive transactional email system with support for **SMTP** servers and **Resend.com**, complete with email logging and delivery tracking.

## Features

✅ **Multiple Providers**
- SMTP (Gmail, SendGrid, etc.)
- Resend.com API

✅ **Email Logging**
- Track all sent emails
- View delivery status
- Access full email body and metadata
- Search and filter logs

✅ **Test Email Functionality**
- Send test emails to verify configuration
- Real-time delivery status

✅ **Admin Dashboard**
- Beautiful dark-themed email settings UI
- Email logs viewer with stats
- One-click configuration

✅ **Automatic Configuration**
- Settings applied immediately
- No server restart required

## Quick Start

### 1. Access Email Settings

Navigate to: **Admin → Settings → Email**

Or directly: `http://localhost:3000/admin/settings/email`

### 2. Configure Your Provider

#### Option A: SMTP (Gmail Example)

```
Provider: SMTP Server
Host: smtp.gmail.com
Port: 587
Encryption: TLS
Username: your-email@gmail.com
Password: [Your App Password]
Timeout: 10 seconds
```

**Gmail Users:** Use an App Password, not your regular password.
[How to create an App Password](https://support.google.com/accounts/answer/185833)

#### Option B: Resend.com

```
Provider: Resend
API Key: re_xxxxxxxxxxxx
```

Get your API key from: https://resend.com/api-keys

### 3. Set Default Sender

```
From Email: noreply@yourdomain.com
From Name: Your Site Name
```

### 4. Enable Email Logging

☑️ **Enable email logging** (track all sent emails)

### 5. Test Your Configuration

1. Enter a test email address
2. Click "Send Test Email"
3. Check your inbox!

### 6. View Email Logs

Navigate to: **Admin → Email Logs**

Or click "View Email Logs" from the Email Settings page.

## SMTP Configuration

### Gmail

```yaml
Host: smtp.gmail.com
Port: 587
Encryption: TLS
Username: your-email@gmail.com
Password: [App Password]
```

**Important:** Enable "Less secure app access" or use an App Password.

### SendGrid

```yaml
Host: smtp.sendgrid.net
Port: 587
Encryption: TLS
Username: apikey
Password: [Your SendGrid API Key]
```

### Mailgun

```yaml
Host: smtp.mailgun.org
Port: 587
Encryption: TLS
Username: postmaster@your-domain.mailgun.org
Password: [Your Mailgun SMTP Password]
```

### Amazon SES

```yaml
Host: email-smtp.us-east-1.amazonaws.com
Port: 587
Encryption: TLS
Username: [Your SMTP Username]
Password: [Your SMTP Password]
```

### Custom SMTP Server

```yaml
Host: mail.yourdomain.com
Port: 587 (or 465 for SSL, 25 for none)
Encryption: TLS/SSL/None
Username: [Your SMTP Username]
Password: [Your SMTP Password]
Timeout: 10 seconds
```

## Resend.com Configuration

### Why Resend?

- 🚀 Modern, simple API
- 📧 Excellent deliverability
- 💰 Free tier: 3,000 emails/month
- 📊 Built-in analytics
- ⚡ Fast delivery
- 🛡️ DKIM, SPF, DMARC included

### Setup Steps

1. Sign up at https://resend.com
2. Add and verify your domain
3. Create an API key
4. Paste API key in RailsPress
5. Done!

### API Key Format

```
re_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Always starts with `re_`

## Email Logging

### View Logs

**Admin → Email Logs** or `/admin/email_logs`

### What's Logged

- ✉️ From/To addresses
- 📝 Subject line
- 📄 Full email body (HTML)
- 📊 Delivery status (Sent/Failed/Pending)
- 🔧 Provider used (SMTP/Resend)
- ⏰ Timestamp
- 📋 Metadata (CC, BCC, headers)
- ❌ Error messages (if failed)

### Stats Dashboard

- **Total Emails** - All time count
- **Sent Successfully** - Delivered emails
- **Failed** - Failed deliveries
- **Today** - Emails sent today

### Individual Log View

Click any log to see:
- Full email details
- Complete HTML body
- Raw source view
- Toggle between HTML and raw
- Delivery metadata
- Error details (if failed)

### Managing Logs

- **View** - Click eye icon
- **Delete** - Click trash icon
- **Clear All** - Delete all logs at once

## Sending Emails from Your Code

### Basic Email

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    
    mail(
      to: user.email,
      subject: 'Welcome to RailsPress!'
    )
  end
end
```

### With Custom From

```ruby
mail(
  from: "support@mysite.com",
  to: user.email,
  subject: 'Welcome!'
)
```

### With Reply-To

```ruby
mail(
  to: user.email,
  reply_to: "support@mysite.com",
  subject: 'Hello!'
)
```

### Deliver Immediately

```ruby
UserMailer.welcome_email(@user).deliver_now
```

### Deliver Later (Background Job)

```ruby
UserMailer.welcome_email(@user).deliver_later
```

### Deliver at Specific Time

```ruby
UserMailer.welcome_email(@user).deliver_later(wait: 1.hour)
UserMailer.welcome_email(@user).deliver_later(wait_until: Date.tomorrow.noon)
```

## Email Templates

### Create Template

Create view file: `app/views/user_mailer/welcome_email.html.erb`

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .button { background: #4F46E5; color: white; padding: 12px 24px; 
              text-decoration: none; border-radius: 6px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to RailsPress, <%= @user.name %>!</h1>
    <p>Thank you for joining us.</p>
    <a href="<%= root_url %>" class="button">Get Started</a>
  </div>
</body>
</html>
```

### Plain Text Version

Create: `app/views/user_mailer/welcome_email.text.erb`

```
Welcome to RailsPress, <%= @user.name %>!

Thank you for joining us.

Get Started: <%= root_url %>
```

Rails will automatically send multipart emails (HTML + plain text).

## Test Email Feature

### Using the Admin UI

1. Go to **Admin → Settings → Email**
2. Scroll to "Test Email Configuration"
3. Enter test email address
4. Click "Send Test Email"
5. Check result immediately

### Programmatically

```ruby
TestMailer.test_email('test@example.com').deliver_now
```

## Email Logging System

### How It Works

1. Email interceptor catches all outgoing emails
2. Logs details to `email_logs` table
3. Updates status after delivery attempt
4. Stores complete email body and metadata

### Disable Logging

**Admin → Settings → Email**

Uncheck: ☐ Enable email logging

Or programmatically:

```ruby
SiteSetting.set('email_logging_enabled', false, 'boolean')
```

### Custom Logging

```ruby
EmailLog.log_email(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Test Email',
  body: '<h1>Hello</h1>',
  provider: 'smtp',
  status: 'sent',
  metadata: { custom_field: 'value' }
)
```

### Query Logs

```ruby
# Recent emails
EmailLog.recent.limit(10)

# Sent today
EmailLog.today

# Failed emails
EmailLog.status_failed

# By provider
EmailLog.provider_smtp
EmailLog.provider_resend

# Stats
EmailLog.stats
# => { total: 150, sent: 145, failed: 5, pending: 0, today: 12, ... }
```

## Troubleshooting

### Gmail "Less Secure Apps" Error

**Solution:** Use an App Password

1. Go to Google Account → Security
2. Enable 2-Step Verification
3. Go to "App passwords"
4. Generate new app password
5. Use this password in RailsPress

### "Connection Timeout" Error

**Possible causes:**
- Incorrect host or port
- Firewall blocking SMTP
- Server down

**Solutions:**
- Verify host/port settings
- Try port 465 (SSL) or 25
- Increase timeout value
- Check firewall rules

### "Authentication Failed" Error

**Possible causes:**
- Wrong username/password
- 2FA not configured for app passwords

**Solutions:**
- Double-check credentials
- Use app-specific password
- Check username format (some require full email)

### "Relay Access Denied" Error

**Cause:** SMTP server doesn't allow relaying

**Solutions:**
- Enable SMTP authentication
- Use correct username/password
- Check if domain is verified

### Emails Not Being Received

**Check:**
1. Email logs show "sent" status?
2. Check spam folder
3. Verify recipient email address
4. Check sender reputation
5. Verify domain DNS records (SPF, DKIM)

### Test Email Shows Error

**Debug steps:**
1. Check email settings are saved
2. Verify credentials are correct
3. Test with different email address
4. Check email logs for error message
5. Try different provider

## Security Best Practices

### 1. Use App Passwords

Never use your main email password for SMTP.

### 2. Environment Variables (Production)

Store sensitive data in environment variables:

```ruby
# config/initializers/email_production.rb
if Rails.env.production?
  SiteSetting.set('smtp_username', ENV['SMTP_USERNAME'])
  SiteSetting.set('smtp_password', ENV['SMTP_PASSWORD'])
  SiteSetting.set('resend_api_key', ENV['RESEND_API_KEY'])
end
```

### 3. Limit Access

Only administrators can:
- View email settings
- Change configuration
- View email logs
- Send test emails

### 4. Regular Monitoring

Check email logs regularly for:
- Failed deliveries
- Unusual patterns
- Error spikes

### 5. Secure SMTP

Always use:
- TLS encryption (port 587)
- Or SSL encryption (port 465)
- Never unencrypted (port 25 in production)

## API Integration

### Send Email via API

```bash
# Not directly supported
# Use backend mailer classes instead
```

### Query Logs via API

Create custom API endpoint if needed:

```ruby
# app/controllers/api/v1/email_logs_controller.rb
module Api
  module V1
    class EmailLogsController < Api::V1::BaseController
      def index
        @logs = EmailLog.recent.limit(50)
        render json: @logs
      end
      
      def stats
        render json: EmailLog.stats
      end
    end
  end
end
```

## Production Checklist

Before going live:

- [ ] Choose production email provider
- [ ] Configure SMTP or Resend
- [ ] Test email delivery
- [ ] Verify sender domain
- [ ] Set up SPF, DKIM, DMARC records
- [ ] Configure bounce handling
- [ ] Enable email logging
- [ ] Set up monitoring alerts
- [ ] Document credentials securely
- [ ] Test from production environment

## Email Deliverability Tips

### 1. Verify Your Domain

Add these DNS records:

**SPF Record:**
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.google.com ~all
```

**DKIM Record:**
```
Provided by your email provider
```

**DMARC Record:**
```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=none; rua=mailto:admin@yourdomain.com
```

### 2. Use Professional From Address

✅ Good: `noreply@yourdomain.com`
❌ Bad: `no-reply@gmail.com`

### 3. Avoid Spam Triggers

- Don't use all caps in subject
- Avoid spam words ("FREE", "WIN", "ACT NOW")
- Include unsubscribe link
- Balance text and images
- Test with spam checkers

### 4. Warm Up Your IP

If using dedicated IP:
- Start with low volume
- Gradually increase over 2-4 weeks
- Monitor reputation

### 5. Monitor Metrics

Track:
- Delivery rate
- Open rate
- Bounce rate
- Spam complaints
- Unsubscribes

## Advanced Configuration

### Custom Mailer Class

```ruby
class CustomMailer < ApplicationMailer
  default from: 'custom@example.com',
          reply_to: 'support@example.com'
  
  def custom_email(recipient, data)
    @data = data
    
    mail(
      to: recipient,
      subject: 'Custom Email',
      template_path: 'mailers/custom',
      template_name: 'custom_email'
    )
  end
end
```

### Mailer Previews

Create preview: `test/mailers/previews/user_mailer_preview.rb`

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.welcome_email(User.first)
  end
end
```

View at: `http://localhost:3000/rails/mailers`

### Async Email Delivery

Configure Sidekiq:

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq

# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: -> { SiteSetting.get('default_from_email') }
  
  # Deliver all emails in background
  def mail(*args)
    super.tap do |message|
      message.delivery_method.settings.merge!(async: true)
    end
  end
end
```

### Email Interception (Development)

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

All emails will open in browser instead of sending.

## Support

### Documentation
- This guide: `EMAIL_GUIDE.md`
- Settings: `/admin/settings/email`
- Logs: `/admin/email_logs`

### Common Tasks
- **Change provider**: Admin → Settings → Email
- **View sent emails**: Admin → Email Logs
- **Test delivery**: Admin → Settings → Email → Test Email
- **Clear logs**: Admin → Email Logs → Clear All Logs

### Getting Help

1. Check email logs for errors
2. Verify configuration settings
3. Test with known good email
4. Check provider status page
5. Review Rails logs: `log/production.log`

---

**Happy Emailing!** 📧

Send transactional emails with confidence using RailsPress.



