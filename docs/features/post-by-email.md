# 📧 Post by Email Guide

## Overview

The **Post by Email** feature allows you to publish posts to your RailsPress site by sending emails to a designated mailbox. This is perfect for:

- 📱 Publishing on-the-go from your mobile device
- ✉️ Creating posts from your email client
- 📸 Sharing photos and content quickly
- 🔄 Automating content creation via email workflows

## How It Works

1. **Email Reception**: RailsPress checks your configured IMAP mailbox every 5 minutes
2. **Content Parsing**: Email subject becomes the post title, body becomes the content
3. **Draft Creation**: Posts are created as **drafts** for review before publishing
4. **Attachment Handling**: Image attachments are automatically imported to your media library
5. **Email Management**: Emails can be marked as read or deleted after import

---

## Configuration

### 1. Access Settings

Navigate to **Settings > Post by Email** in your admin panel.

### 2. IMAP Server Settings

Configure your email server credentials:

#### Gmail Example
```
IMAP Server: imap.gmail.com
Port: 993
Email: posts@yourdomain.com
Password: [App-Specific Password]
Security: SSL/TLS
Mailbox Folder: INBOX
```

> **Gmail Users**: You must use an [App-Specific Password](https://support.google.com/accounts/answer/185833), not your regular Gmail password.

#### Outlook/Office 365 Example
```
IMAP Server: outlook.office365.com
Port: 993
Email: posts@yourdomain.com
Password: [Your Password]
Security: SSL/TLS
Mailbox Folder: INBOX
```

#### Other Providers
- **Yahoo**: imap.mail.yahoo.com (port 993)
- **iCloud**: imap.mail.me.com (port 993)
- **Custom**: Check your email provider's IMAP settings

### 3. Post Settings

Configure how imported posts are handled:

| Setting | Description |
|---------|-------------|
| **Default Category** | Category to assign to imported posts |
| **Default Author** | User to assign as post author |
| **Mark as Read** | Mark emails as read after import (recommended) |
| **Delete After Import** | Automatically delete emails after creating posts |

### 4. Enable the Feature

Toggle **Enable Post by Email** to activate the feature.

---

## Usage

### Sending an Email to Create a Post

1. **Compose an Email**
   - **To**: Your configured email address (e.g., `posts@yourdomain.com`)
   - **Subject**: This becomes your post title
   - **Body**: This becomes your post content

2. **Add Images** (Optional)
   - Attach images to include them in your media library
   - The first image can be used as the featured image

3. **Send**
   - RailsPress will check for new emails every 5 minutes
   - Your post will be created as a draft

### Email Formatting

#### Plain Text Emails
```
Subject: My Awesome Post Title

This is the content of my post.

It supports multiple paragraphs.

And line breaks!
```

#### HTML Emails
HTML formatting is preserved, including:
- **Bold** and *italic* text
- Links
- Lists
- Headings

---

## Advanced Features

### 1. Manual Check

Click the **Check Now** button to immediately check for new emails without waiting for the 5-minute interval.

### 2. Testing Connection

Use the **Test Connection** button (when available) to verify your IMAP settings are correct.

### 3. Email Filters

Set up email filters in your email client to:
- Automatically label emails destined for your blog
- Forward specific emails to your post-by-email address
- Filter by sender for trusted sources only

---

## Security Best Practices

### 1. Use a Dedicated Email Address
Create a specific email address for posting (e.g., `posts@yourdomain.com`), not your personal email.

### 2. Use App-Specific Passwords
For Gmail and other providers, always use app-specific passwords instead of your main account password.

### 3. Enable Email Filters
Set up spam filtering and sender restrictions to prevent unauthorized posts.

### 4. Use Secure Folders
Consider using a dedicated IMAP folder (e.g., `Blog Posts`) instead of your main INBOX.

### 5. Review Drafts
Posts are always created as drafts, giving you a chance to review before publishing.

---

## Troubleshooting

### Issue: Emails Not Being Imported

**Check:**
1. Is "Enable Post by Email" toggled on?
2. Are your IMAP credentials correct?
3. Is your server running Sidekiq? (`bundle exec sidekiq`)
4. Check Rails logs: `tail -f log/production.log`

**Test:**
1. Click "Check Now" to trigger a manual check
2. Review any error messages in the admin panel
3. Verify your email server allows IMAP connections

### Issue: Connection Failed

**Solutions:**
1. **Gmail Users**: Enable "Less secure app access" or use an App-Specific Password
2. **Two-Factor Authentication**: Must use app-specific passwords
3. **Firewall**: Ensure port 993 (SSL) or 143 (TLS) is not blocked
4. **Server Settings**: Verify hostname, port, and security settings

### Issue: Emails Imported Multiple Times

**Solutions:**
1. Enable "Mark as read after import"
2. Check that Sidekiq cron job is running only once
3. Verify emails are being marked as seen in your mailbox

### Issue: Attachments Not Working

**Check:**
1. Ensure ActiveStorage is properly configured
2. Verify storage permissions
3. Check file size limits
4. Review Rails logs for attachment errors

---

## Technical Details

### Email Checking Schedule

Post by Email uses **Sidekiq Cron** to check your mailbox:

```yaml
# config/schedule.yml
post_by_email_check:
  cron: "*/5 * * * *"  # Every 5 minutes
  class: "PostByEmailWorker"
  queue: default
```

### Processing Flow

```
1. Connect to IMAP server
2. Select configured folder (default: INBOX)
3. Search for unread emails
4. For each unread email:
   a. Parse subject → post title
   b. Parse body → post content
   c. Process attachments → media library
   d. Create post as draft
   e. Assign category and author
   f. Mark as read (if configured)
   g. Delete email (if configured)
5. Disconnect from server
```

### Post Attributes

| Email Field | Post Attribute |
|-------------|---------------|
| Subject | `title` |
| Body (HTML) | `body_html` |
| Body (Plain Text) | `body_html` (converted) |
| Date | `created_at` |
| From | Logged (not used) |
| Attachments | `featured_image` or media library |

### Status

All posts created via email are set to `status: 'draft'` by default for security and quality control.

---

## Cron Job Configuration

### Sidekiq Must Be Running

Ensure Sidekiq is running in production:

```bash
# Start Sidekiq
bundle exec sidekiq

# Or use systemd/Docker/process manager
```

### Checking Cron Jobs

View active Sidekiq Cron jobs:

```ruby
# Rails console
Sidekiq::Cron::Job.all
```

### Modifying Check Frequency

Edit `config/schedule.yml`:

```yaml
post_by_email_check:
  cron: "*/10 * * * *"  # Every 10 minutes instead of 5
  class: "PostByEmailWorker"
  queue: default
```

Then reload:

```ruby
# Rails console
Sidekiq::Cron::Job.load_from_hash(YAML.load_file('config/schedule.yml'))
```

---

## API Reference

### Service: `PostByEmailService`

```ruby
# Manually check for new emails
result = PostByEmailService.check_mail
# => { new_posts: 2, checked: 5 }
```

### Worker: `PostByEmailWorker`

```ruby
# Manually trigger the worker
PostByEmailWorker.perform_async
```

### Settings

All settings are stored in `SiteSetting`:

```ruby
# Enable/disable
SiteSetting.set('post_by_email_enabled', true, 'boolean')

# IMAP configuration
SiteSetting.set('imap_server', 'imap.gmail.com', 'string')
SiteSetting.set('imap_port', '993', 'string')
SiteSetting.set('imap_email', 'posts@example.com', 'string')
SiteSetting.set('imap_password', 'your-password', 'string')
SiteSetting.set('imap_ssl', 'true', 'string')
SiteSetting.set('imap_folder', 'INBOX', 'string')

# Post settings
SiteSetting.set('post_by_email_default_category', '1', 'string')
SiteSetting.set('post_by_email_default_author', '1', 'string')
SiteSetting.set('post_by_email_mark_as_read', true, 'boolean')
SiteSetting.set('post_by_email_delete_after_import', false, 'boolean')
```

---

## WordPress Compatibility

This feature is inspired by WordPress's "Post by Email" feature with improvements:

### Same as WordPress
- Email subject → post title
- Email body → post content
- Attachments → media library
- Posts created as drafts

### Enhancements over WordPress
- ✅ Modern IMAP support (OAuth2 ready)
- ✅ Full HTML email support
- ✅ Better attachment handling
- ✅ Configurable check frequency
- ✅ Manual "Check Now" button
- ✅ Real-time status monitoring
- ✅ Better error handling and logging

---

## FAQs

### Can I publish posts directly without drafts?

No, for security reasons, all posts via email are created as drafts. You must manually publish them after review.

### What happens if I send multiple emails?

Each email creates a separate post. There's no duplicate detection, so be careful!

### Can I use this with Gmail's free tier?

Yes, but you must enable 2FA and create an App-Specific Password.

### Does it work with shared mailboxes?

Yes, as long as the mailbox supports IMAP access.

### Can I customize the email parsing?

Yes! Edit `app/services/post_by_email_service.rb` to customize how emails are parsed.

### What if I want to assign categories via email?

You can extend the service to parse categories from email headers or body tags. Contact support for customization.

---

## Support

For issues or questions:
1. Check the Rails logs: `log/production.log`
2. Verify Sidekiq is running: `ps aux | grep sidekiq`
3. Test your IMAP connection manually
4. Review this guide's troubleshooting section

---

**Last Updated**: October 12, 2025  
**Version**: 1.0.0



