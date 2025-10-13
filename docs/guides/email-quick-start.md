# Email System Quick Start

## 🚀 5-Minute Setup

### Step 1: Access Email Settings

Navigate to: **Admin → Settings → Email**

URL: `http://localhost:3000/admin/settings/email`

### Step 2: Choose Your Provider

**Option A: Gmail (Quick & Easy)**

```
Provider: SMTP Server
Host: smtp.gmail.com
Port: 587
Encryption: TLS
Username: your-email@gmail.com
Password: [Create App Password]
```

[How to create Gmail App Password](https://support.google.com/accounts/answer/185833)

**Option B: Resend.com (Recommended)**

```
Provider: Resend
API Key: re_xxxxxxxxxxxx
```

1. Sign up at https://resend.com
2. Get API key from https://resend.com/api-keys
3. Paste it in RailsPress

### Step 3: Set Sender Info

```
From Email: noreply@yourdomain.com
From Name: Your Site Name
```

### Step 4: Enable Logging

☑️ Enable email logging (track all sent emails)

### Step 5: Test It!

1. Enter your email address in test box
2. Click "Send Test Email"
3. Check your inbox!

## 📧 Sending Your First Email

### Create a Mailer

```bash
rails generate mailer User welcome_email
```

### Write the Email

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    mail(to: user.email, subject: 'Welcome!')
  end
end
```

### Create Template

```erb
<!-- app/views/user_mailer/welcome_email.html.erb -->
<h1>Welcome, <%= @user.name %>!</h1>
<p>Thanks for joining RailsPress.</p>
```

### Send It!

```ruby
UserMailer.welcome_email(@user).deliver_now
```

## 📊 View Email Logs

Navigate to: **Admin → Email Logs**

Or: `http://localhost:3000/admin/email_logs`

See:
- ✉️ All sent emails
- ✅ Delivery status
- 📄 Full email content
- ⏰ Timestamps
- ❌ Error messages

## 🎯 Quick Tips

✅ **Use Resend for production** - Better deliverability
✅ **Enable logging** - Debug email issues easily
✅ **Test before launch** - Use test email feature
✅ **Monitor logs** - Check for failed deliveries
✅ **Use App Passwords** - Never use main email password

## 📚 Full Documentation

See `EMAIL_GUIDE.md` for complete details:
- All SMTP providers
- Advanced configuration
- Troubleshooting
- Security best practices
- Production checklist
- API integration

## 🆘 Common Issues

### "Authentication Failed"
→ Use App Password, not regular password

### "Connection Timeout"
→ Check host/port, try port 465

### "Emails not received"
→ Check spam folder, verify sender domain

### "Test email failed"
→ Check email logs for error details

---

**Done!** Your email system is ready to use. 🎉

Send emails, track delivery, and monitor everything from your admin dashboard.



