# Fluent Forms Pro for RailsPress

The most advanced form builder plugin for RailsPress with drag-and-drop interface, conditional logic, payment integrations, and 40+ premium features.

## 🎯 Features

### Form Builder
- **Drag & Drop Interface** - Intuitive visual form builder
- **40+ Field Types** - Text, email, file upload, payment, rating, slider, and more
- **Multi-Step Forms** - Break long forms into steps
- **Conditional Logic** - Show/hide fields based on user input
- **Form Templates** - Pre-built templates for common use cases

### Advanced Features
- **Payment Integration** - Stripe and PayPal support
- **File Uploads** - Secure file upload with validation
- **Email Notifications** - Admin notifications & user autoresponders
- **Webhooks** - Real-time integrations with third-party services
- **Form Analytics** - Conversion tracking and insights
- **Entry Management** - View, export, and manage submissions

### Integrations
- **Mailchimp** - Email marketing integration
- **Slack** - Real-time notifications
- **Zapier** - Connect to 3000+ apps
- **Google Sheets** - Auto-sync submissions
- **Custom Webhooks** - Build your own integrations

### Spam Protection
- **Google reCAPTCHA** - v2 and v3 support
- **Honeypot** - Hidden field technique
- **Akismet** - Advanced spam filtering

### Form Restrictions
- **Login Required** - Restrict forms to logged-in users
- **Entry Limits** - Limit number of submissions
- **Form Scheduling** - Set start and end dates
- **Geolocation** - Restrict by country

### Customization
- **Custom CSS** - Full styling control
- **Multiple Themes** - Pre-designed form themes
- **Label Placement** - Top, left, right, or hidden
- **Button Customization** - Custom button text and styling

## 📦 Installation

### 1. Add to Database

```ruby
rails runner "
Plugin.create!(
  name: 'Fluent Forms Pro',
  description: 'Advanced form builder with drag-and-drop interface',
  version: '5.1.0',
  active: false
)
"
```

### 2. Activate Plugin

```ruby
rails runner "
plugin = Plugin.find_by(name: 'Fluent Forms Pro')
plugin.update!(active: true)
"
```

Or activate via admin interface at `/admin/plugins`

### 3. Configure Settings

Navigate to **Admin → Fluent Forms → Settings** to configure:

- Email settings (from name, from email)
- Payment gateways (Stripe, PayPal)
- Spam protection (reCAPTCHA keys)
- File upload limits
- Integration API keys

## 🚀 Usage

### Creating a Form

1. Go to **Admin → Fluent Forms**
2. Click **Create New Form**
3. Choose a template or start from scratch
4. Drag fields from the left panel to the canvas
5. Configure each field by clicking on it
6. Set up notifications, integrations, and appearance
7. Click **Save Form**

### Embedding Forms

Use the shortcode in any post or page:

```
[fluentform id="1"]
```

Or use the helper in views:

```erb
<%= render_fluent_form(1) %>
```

Or the tag helper:

```erb
<%= fluent_form_tag(1) %>
```

### Managing Entries

1. Go to **Admin → Fluent Forms → Entries**
2. Filter by form, status, or search
3. Click on any entry to view details
4. Export entries as CSV or JSON

## 🎨 Form Field Types

### Basic Fields
- **Text Input** - Single line text
- **Email** - Email with validation
- **Textarea** - Multi-line text
- **Select** - Dropdown menu
- **Radio Buttons** - Single choice
- **Checkboxes** - Multiple choices

### Advanced Fields
- **Number** - Numeric input
- **Phone** - Phone number with formatting
- **Date** - Date picker
- **File Upload** - Single or multiple files
- **Hidden Field** - Hidden data
- **Password** - Password input
- **URL** - Website URL with validation

### Special Fields
- **Rating** - Star rating
- **Slider** - Range slider
- **HTML** - Custom HTML content
- **Section Break** - Visual separator
- **Payment** - Stripe/PayPal integration
- **Repeater** - Repeatable field groups
- **Step** - Multi-step form sections

## 🔔 Email Notifications

### Admin Notifications
Receive an email when someone submits a form:

```
To: admin@example.com
Subject: New form submission: Contact Form
Body: [All form data]
```

### User Confirmations (Autoresponders)
Send automatic confirmation to users:

```
To: [user email from form]
Subject: Thank you for your submission
Body: [Custom message]
```

Configure in **Form → Notifications** tab.

## 💳 Payment Integration

### Stripe Setup

1. Get API keys from [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Go to **Settings → Payments**
3. Enable Stripe
4. Enter Publishable and Secret keys
5. Add Payment field to your form
6. Configure amount (fixed or user-defined)

### PayPal Setup

1. Get credentials from [PayPal Developer](https://developer.paypal.com/)
2. Go to **Settings → Payments**
3. Enable PayPal
4. Enter Client ID and Secret
5. Choose mode (sandbox or live)
6. Add Payment field to your form

## 🔗 Integrations

### Slack

Send form submissions to Slack:

1. Create a [Slack Incoming Webhook](https://api.slack.com/messaging/webhooks)
2. Go to **Settings → Integrations**
3. Enter webhook URL
4. Enable Slack in **Form → Integrations**

### Mailchimp

Add subscribers automatically:

1. Get API key from Mailchimp
2. Go to **Settings → Integrations**
3. Enter API key
4. In form, enable Mailchimp integration
5. Select list and map fields

### Custom Webhooks

Send data to any URL:

1. Go to **Form → Integrations**
2. Add webhook URL
3. Choose POST method
4. Data sent as JSON:

```json
{
  "form_id": 1,
  "form_title": "Contact Form",
  "submission_id": 123,
  "serial_number": "1-123-1638000000",
  "data": {
    "name": "John Doe",
    "email": "john@example.com",
    "message": "Hello!"
  },
  "created_at": "2025-10-12T10:30:00Z"
}
```

## 🛡️ Spam Protection

### reCAPTCHA v3 (Recommended)

1. Get keys from [Google reCAPTCHA](https://www.google.com/recaptcha/admin)
2. Go to **Settings → Spam Protection**
3. Enable reCAPTCHA
4. Enter Site Key and Secret Key
5. Select v3 (invisible, better UX)

### Honeypot

Enabled by default. No configuration needed. Hidden field that bots fill but humans don't.

### Akismet

1. Get API key from [Akismet](https://akismet.com/)
2. Go to **Settings → Spam Protection**
3. Enable Akismet
4. Enter API key

## 📊 Analytics

View form performance:

- **Views** - How many times form was loaded
- **Submissions** - Total submissions
- **Conversion Rate** - Submissions / Views
- **Completion Time** - Average time to complete

Access at **Admin → Fluent Forms → Analytics**

## 🎯 Conditional Logic

Show/hide fields based on conditions:

1. Select a field in builder
2. Click **Conditional Logic**
3. Add rule: "Show this field if [field] [is/is not] [value]"
4. Combine multiple conditions with AND/OR

Example: Show "Phone Number" only if "Contact Method" is "Phone"

## 📤 Export Entries

Export submissions in multiple formats:

- **CSV** - Spreadsheet format
- **JSON** - Developer-friendly format
- **PDF** - Individual submission PDFs

Bulk export or export selected entries.

## 🔧 API Reference

### Get Form Data

```ruby
form = FluentFormsPro.new.get_form(1)
```

### Get All Forms

```ruby
forms = FluentFormsPro.all_forms
```

### Get Submissions

```ruby
submissions = FluentFormsPro.get_submissions(1, limit: 50, status: 'unread')
```

### Create Submission

```ruby
submission_id = FluentFormsPro.create_submission(
  form_id,
  {
    response_data: { name: 'John', email: 'john@example.com' },
    source_url: request.url,
    browser: request.user_agent,
    device: 'desktop',
    ip_address: request.remote_ip
  },
  current_user&.id
)
```

## 🎨 Styling

### Custom CSS

Add custom styles in **Form → Appearance → Custom CSS**:

```css
.fluent-form {
  font-family: 'Your Font', sans-serif;
}

.ff-btn-submit {
  background-color: #your-color;
  border-radius: 25px;
}
```

### CSS Classes

Target specific elements:

- `.fluent-form` - Form container
- `.ff-field-group` - Field wrapper
- `.ff-label` - Field label
- `.ff-input` - Text input
- `.ff-textarea` - Textarea
- `.ff-select` - Select dropdown
- `.ff-btn-submit` - Submit button
- `.ff-error-message` - Error message
- `.ff-success-message` - Success message

## 🔒 Security

### Data Protection

- **IP Logging** - Can be disabled for GDPR compliance
- **SQL Injection** - Protected via parameterized queries
- **XSS Prevention** - All user input sanitized
- **CSRF Protection** - Rails authenticity tokens
- **File Upload Validation** - Type and size restrictions

### GDPR Compliance

Enable GDPR mode in settings:

- Disable IP logging
- Add consent checkbox
- Data export for users
- Right to be forgotten

## 📱 Mobile Responsive

All forms are mobile-responsive by default:

- Touch-friendly inputs
- Optimized layouts
- Swipe for multi-step forms
- Mobile-specific validation

## 🌐 Multi-Language Support

Forms support internationalization:

- Translatable field labels
- Translatable messages
- RTL support for Arabic, Hebrew
- Date/time formatting

## ⚡ Performance

Optimized for high performance:

- **AJAX Submissions** - No page reload
- **Lazy Loading** - Load forms on scroll
- **Caching** - Form configs cached
- **Background Jobs** - Email/integrations async
- **Database Indexes** - Fast queries

## 🐛 Troubleshooting

### Forms Not Showing

1. Check plugin is activated
2. Verify form status is "Published"
3. Check shortcode ID is correct
4. Look for JavaScript errors in console

### Submissions Not Saving

1. Check database tables exist
2. Verify CSRF token is present
3. Check file upload limits
4. Review server logs for errors

### Emails Not Sending

1. Verify email settings in **Settings → Email**
2. Check spam folder
3. Test with `rails c`: `FluentFormsMailer.test_email.deliver_now`
4. Check Action Mailer configuration

### Payment Issues

1. Verify API keys are correct
2. Check keys are for correct mode (test/live)
3. Test with Stripe test cards
4. Check webhook configuration

## 📚 Resources

- **Documentation** - Full docs at `/admin/fluent-forms/docs`
- **Support** - GitHub Issues
- **Examples** - Sample forms included
- **Updates** - Automatic update notifications

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Submit a pull request

## 📄 License

GPL-3.0 License - See LICENSE file

## 🎉 Credits

Built with ❤️ for the RailsPress community.

Inspired by Fluent Forms for WordPress.

---

**Version:** 5.1.0  
**Last Updated:** October 2025  
**Author:** RailsPress Team  
**Website:** https://github.com/railspress/fluent-forms-pro

## Quick Start Example

```ruby
# 1. Create a simple contact form
rails runner "
form_data = {
  title: 'Contact Us',
  form_fields: {
    fields: [
      {
        element: 'input_name',
        attributes: { name: 'name', 'data-required': true },
        settings: { label: 'Your Name' }
      },
      {
        element: 'input_email',
        attributes: { name: 'email', 'data-required': true },
        settings: { label: 'Email Address' }
      },
      {
        element: 'textarea',
        attributes: { name: 'message', 'data-required': true, rows: 4 },
        settings: { label: 'Message' }
      }
    ],
    submitButton: {
      settings: {
        button_ui: { text: 'Send Message' }
      }
    }
  },
  settings: {
    confirmation: {
      messageToShow: 'Thank you! We will get back to you soon.'
    }
  },
  status: 'published'
}

ActiveRecord::Base.connection.execute(
  \"INSERT INTO ff_forms (title, form_fields, settings, status, created_at, updated_at) 
   VALUES (?, ?, ?, ?, ?, ?)\",
  form_data[:title],
  form_data[:form_fields].to_json,
  form_data[:settings].to_json,
  form_data[:status],
  Time.current,
  Time.current
)

puts 'Contact form created! Add [fluentform id=\"1\"] to any page.'
"
```

That's it! Your form is ready to use. 🚀

