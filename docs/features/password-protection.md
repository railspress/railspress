# Password Protection System - Complete Guide

## Overview

RailsPress includes WordPress-style password protection for both posts and pages. Protect sensitive content while keeping it publicly accessible to those with the password.

---

## Features

✅ **Post Protection** - Password-protect individual blog posts  
✅ **Page Protection** - Password-protect any page  
✅ **Password Hints** - Optional hints for users  
✅ **Session Memory** - Remembers verified passwords during session  
✅ **Admin Bypass** - Admins/editors/authors bypass password  
✅ **Beautiful UI** - Clean password entry form  
✅ **Flexible** - Can be combined with any status  
✅ **Secure** - Passwords validated server-side  

---

## How It Works

### 1. Set a Password

In admin when creating/editing a post or page:

**Post/Page Editor:**
- Scroll to "Password Protection" section
- Enter a password (minimum 4 characters)
- Optionally add a password hint
- Save the post/page

### 2. Visitor Experience

When someone visits a password-protected post/page:

1. **They see a password form** instead of content
2. **Password hint is displayed** (if you provided one)
3. **They enter the password**
4. **If correct**: Content is shown
5. **If incorrect**: Error message displayed
6. **Session remembers** correct password for that item

### 3. Who Bypasses Password?

These users see content without entering password:
- ✅ **Administrators** - Full access
- ✅ **Editors** - Full access
- ✅ **Post/Page Author** - Their own content
- ❌ **Other visitors** - Must enter password

---

## Usage Examples

### Example 1: Client Preview

**Scenario**: Share draft with client before publishing

```ruby
post = Post.create!(
  title: 'New Website Design',
  content: 'Here is the new design...',
  status: :draft,        # Not public yet
  password: 'client2024', # But accessible with password
  password_hint: 'Your project year',
  user: current_user
)
```

**Share**: Send client the URL + password  
**Benefit**: No login required, but content is protected

### Example 2: Members-Only Content

**Scenario**: Content for team members

```ruby
page = Page.create!(
  title: 'Team Resources',
  content: 'Internal documents...',
  status: :published,
  password: 'team2024',
  password_hint: 'Our team code',
  user: current_user
)
```

**Use Case**: 
- Team can bookmark the page
- Password remembered in session
- No individual user accounts needed

### Example 3: Temporary Protection

**Scenario**: Protect during beta/preview period

```ruby
post = Post.create!(
  title: 'Product Launch Details',
  status: :published,
  password: 'beta2024'
)

# Later, remove password to make fully public
post.update(password: nil)
```

### Example 4: Private Notes with Password

**Scenario**: Personal notes but accessible if needed

```ruby
page = Page.create!(
  title: 'Private Notes',
  status: :private_page,  # Only logged-in users
  password: 'mynotes',     # Extra password layer
  user: current_user
)
```

**Protection Level**: Must be logged in AND know password

---

## Admin Interface

### Password Protection Section

Located in both Post and Page edit forms:

```
┌─────────────────────────────────────┐
│  🔒 Password Protection             │
├─────────────────────────────────────┤
│                                     │
│  Password (optional)                │
│  [                    ]             │
│  ℹ️ Require a password to view      │
│                                     │
│  Password Hint (optional)           │
│  [                    ]             │
│  ℹ️ Shown to users                  │
│                                     │
└─────────────────────────────────────┘
```

**Fields:**
- **Password**: The actual password (minimum 4 chars)
- **Password Hint**: Optional hint shown to visitors

**Location**: 
- Posts: `/admin/posts/:id/edit` → Password Protection section
- Pages: `/admin/pages/:id/edit` → Password Protection section

---

## Frontend Experience

### Password Entry Form

When a visitor accesses protected content:

```
┌─────────────────────────────────────┐
│          🔒                          │
│                                      │
│    Protected Content                 │
│    My Secret Post                    │
│    💡 Hint: Your birth year          │
│                                      │
│    Password                          │
│    [                    ]            │
│                                      │
│    [Submit]                          │
│                                      │
│    Back to Blog                      │
└─────────────────────────────────────┘
```

**Elements:**
- Lock icon
- Post/Page title
- Password hint (if provided)
- Password input field
- Submit button
- Back link

### After Correct Password

- ✅ Redirected to content
- ✅ Success message shown
- ✅ Password remembered in session
- ✅ Can navigate away and return (no re-entry needed)

### After Incorrect Password

- ❌ Stays on password form
- ❌ Error message: "Incorrect password. Please try again."
- ❌ Can retry unlimited times

---

## Technical Implementation

### Database Schema

**Posts Table:**
- `password` (string) - Plain text password
- `password_hint` (string) - Optional hint

**Pages Table:**
- `password` (string) - Plain text password
- `password_hint` (string) - Optional hint

### Model Methods

**Check if Protected:**
```ruby
@post.password_protected?  # true/false
@page.password_protected?  # true/false
```

**Verify Password:**
```ruby
@post.password_matches?('user_input')  # true/false
@page.password_matches?('user_input')  # true/false
```

**Scopes:**
```ruby
Post.password_protected  # Posts with passwords
Post.public_access       # Posts without passwords
```

### Controller Logic

**Public Controller:**
```ruby
def show
  @post = Post.find(params[:id])
  
  # Show password form if protected and not verified
  if @post.password_protected? && !password_verified?(@post)
    render 'password_protected' and return
  end
  
  # Show content
end

def verify_password
  if @post.password_matches?(params[:password])
    session[:verified_posts] << @post.id
    redirect_to @post
  else
    redirect_to @post, alert: 'Incorrect password'
  end
end

def password_verified?(post)
  session[:verified_posts]&.include?(post.id)
end
```

### Session Storage

Verified passwords stored in session:
```ruby
session[:verified_posts] = [1, 5, 12]  # Post IDs
session[:verified_pages] = [3, 8]      # Page IDs
```

**Session expires when:**
- User closes browser
- Session timeout (default: 30 days)
- User logs out
- Session is manually cleared

---

## Combining with Statuses

### Password + Draft
```ruby
Post.create(status: :draft, password: 'secret')
```
- Not visible to public at all
- Admins/editors see it
- Author sees it
- Password only needed if shared externally

### Password + Published
```ruby
Post.create(status: :published, password: 'members2024')
```
- Visible in listings/feeds
- Title and excerpt shown
- Content requires password
- **Most common use case**

### Password + Scheduled
```ruby
Post.create(
  status: :scheduled,
  published_at: 1.week.from_now,
  password: 'preview'
)
```
- Not visible until publish time
- Password allows early access
- Auto-publishes on schedule

### Password + Private
```ruby
Post.create(status: :private_post, password: 'extra')
```
- Must be logged in
- AND must know password
- **Double protection**

---

## Use Cases

### 1. Client Previews
- Share content with clients before going live
- No login required
- Controlled access
- Can revoke by changing password

### 2. Beta/Preview Content
- Launch previews for selected audience
- Product announcements
- Event details before public release

### 3. Team Resources
- Internal documentation
- Company wikis
- Shared knowledge bases
- No individual accounts needed

### 4. Gated Content
- Premium content previews
- Webinar materials
- Course resources
- Download links

### 5. Temporary Protection
- Protect during development
- Remove password when ready
- Gradual rollout strategy

---

## Security Considerations

### Plain Text Passwords

⚠️ **Note**: Passwords are stored in plain text (like WordPress)

**Why?**
- Need to compare exact password
- Not user account passwords
- Content protection, not authentication
- Can be shared freely

**Best Practices:**
- ✅ Use unique passwords per post/page
- ✅ Don't reuse important passwords
- ✅ Change passwords periodically
- ✅ Use random strings for sensitive content
- ❌ Don't use personal passwords
- ❌ Don't use admin passwords

### Admin Access

**Bypass Rules:**
```ruby
# These users bypass password:
- current_user.administrator?
- current_user.editor?
- post.user_id == current_user.id
```

**Why?**
- Admins need to manage content
- Editors need to review content
- Authors need to edit their posts

### Session Security

- Sessions use secure cookies
- HTTPS recommended for production
- Session expires on browser close
- Can be manually cleared

---

## API Considerations

### REST API

Password-protected content in API:

```ruby
# GET /api/v1/posts/:id
def show
  @post = Post.find(params[:id])
  
  if @post.password_protected?
    # Option 1: Return error
    render json: { error: 'Password required' }, status: :forbidden
    
    # Option 2: Return partial data
    render json: {
      id: @post.id,
      title: @post.title,
      excerpt: @post.excerpt,
      password_protected: true,
      password_hint: @post.password_hint
    }
  else
    render json: @post
  end
end

# POST /api/v1/posts/:id/verify
def verify
  if @post.password_matches?(params[:password])
    render json: @post, status: :ok
  else
    render json: { error: 'Invalid password' }, status: :forbidden
  end
end
```

### GraphQL API

```graphql
type Post {
  id: ID!
  title: String!
  content: String  # null if password protected
  passwordProtected: Boolean!
  passwordHint: String
}

mutation verifyPostPassword($id: ID!, $password: String!) {
  verifyPostPassword(id: $id, password: $password) {
    post {
      content
    }
    errors
  }
}
```

---

## Best Practices

### 1. Use Meaningful Hints

```ruby
# Good ✅
password_hint: "The year we started"
password_hint: "Our company slogan"
password_hint: "First word of the article"

# Bad ❌
password_hint: "You know it"
password_hint: "The password"
```

### 2. Communicate Clearly

When sharing password-protected content:
- ✅ Send URL + password separately
- ✅ Include the hint in your message
- ✅ Explain password is case-sensitive
- ✅ Provide expiration date if applicable

### 3. Regular Rotation

For long-term protected content:
```ruby
# Change password monthly
post.update(password: generate_new_password)

# Notify users of change
NotificationMailer.password_changed(post).deliver_later
```

### 4. Remove When Done

```ruby
# After preview period
post.update(password: nil, password_hint: nil)
```

### 5. Combine with Statuses

```ruby
# Start: Password + Draft
post = Post.create(status: :draft, password: 'preview')

# Share for feedback
# ... feedback received ...

# Go live: Remove password, publish
post.update(status: :published, password: nil)
```

---

## Troubleshooting

### Password Not Working

**Check:**
1. Is password correct? (case-sensitive)
2. Is post/page actually protected?
3. Check cookies enabled
4. Check session working

**Debug:**
```ruby
# In Rails console
post = Post.find(1)
post.password_protected?  # => true
post.password  # => "secret123"
post.password_matches?('secret123')  # => true
```

### Session Not Persisting

**Causes:**
- Cookies disabled
- Browser in private mode
- Session store misconfigured

**Fix:**
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, 
  key: '_railspress_session',
  expire_after: 30.days
```

### Admin Can't See Content

**Check:**
1. Are you logged in as admin?
2. Check `current_user.administrator?`
3. Verify bypass logic

**Should work for:**
```ruby
current_user.administrator?  # ✅
current_user.editor?          # ✅
post.user == current_user     # ✅
```

---

## Examples

### Protecting Existing Post

```ruby
# In Rails console
post = Post.find_by(slug: 'my-post')
post.update(
  password: 'secret2024',
  password_hint: 'Current year + secret'
)
```

### Bulk Password Protection

```ruby
# Protect multiple posts
Post.where(category: special_category).find_each do |post|
  post.update(
    password: 'category_pass',
    password_hint: 'Category name + pass'
  )
end
```

### Temporary Protection

```ruby
# Protect for 1 week
post.update(password: 'temp_pass')

# Schedule removal
RemovePasswordJob.set(wait: 1.week).perform_later(post.id)
```

### Smart Hints

```ruby
# Contextual hints
post.update(
  password: '2024',
  password_hint: 'The current year'
)

# Question-based hints
page.update(
  password: 'rails',
  password_hint: 'What framework are we using?'
)
```

---

## Frontend Customization

### Password Form Styling

The default form uses Tailwind CSS. Customize in:
- `app/views/posts/password_protected.html.erb`
- `app/views/pages/password_protected.html.erb`

**Change colors:**
```erb
<%= submit_tag 'Submit', 
    class: 'bg-purple-600 hover:bg-purple-700 ...' %>
```

**Add your branding:**
```erb
<div class="text-center">
  <%= image_tag 'logo.png', class: 'mx-auto h-12 mb-4' %>
  <h2>Protected Content</h2>
</div>
```

**Custom messages:**
```erb
<p class="text-sm text-gray-600">
  This content is protected. Please enter the password to continue.
</p>
```

---

## Advanced Features

### Rate Limiting

Prevent brute force attacks:

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('password_verify', limit: 5, period: 1.minute) do |req|
  if req.path.include?('verify_password')
    req.ip
  end
end
```

### Password Expiration

Auto-remove passwords after time:

```ruby
# app/jobs/expire_passwords_job.rb
class ExpirePasswordsJob < ApplicationJob
  def perform
    Post.password_protected
        .where('created_at < ?', 1.month.ago)
        .update_all(password: nil, password_hint: nil)
  end
end

# Run daily
# config/schedule.yml (Sidekiq Cron)
expire_passwords:
  cron: "0 3 * * *"
  class: "ExpirePasswordsJob"
```

### Analytics Integration

Track password attempts:

```ruby
# In verify_password action
if @post.password_matches?(params[:password])
  # Success
  PasswordAttempt.create(
    post: @post,
    success: true,
    ip: request.ip
  )
else
  # Failure
  PasswordAttempt.create(
    post: @post,
    success: false,
    ip: request.ip
  )
end
```

### Email Notifications

Notify on password access:

```ruby
# After successful verification
if @post.password_matches?(params[:password])
  session[:verified_posts] << @post.id
  
  # Notify author
  AuthorMailer.password_access(@post, request.ip).deliver_later
  
  redirect_to @post
end
```

---

## Comparison: Password vs Private Status

| Feature | Password Protected | Private Status |
|---------|-------------------|----------------|
| Requires Login | ❌ No | ✅ Yes |
| Single Secret | ✅ Yes | ❌ No |
| Shareable | ✅ Easy | ❌ Need account |
| Revocable | ✅ Change password | ❌ Must unpublish |
| Trackable | ✅ Can log attempts | ⚠️ Via analytics |
| Security Level | ⭐⭐ Medium | ⭐⭐⭐ High |

**When to Use Password:**
- Temporary sharing
- Client previews
- Simple protection
- No user management wanted

**When to Use Private:**
- Long-term protection
- User-specific content
- Need audit trails
- Higher security required

**Best: Combine Both!**
```ruby
Post.create(
  status: :private_post,  # Must be logged in
  password: 'extra2024'   # AND know password
)
```

---

## Quick Reference

### Set Password (Admin)
```
1. Edit post/page
2. Scroll to "Password Protection"
3. Enter password (4+ chars)
4. Add hint (optional)
5. Save
```

### Check Protection (Code)
```ruby
@post.password_protected?        # true/false
@post.password_matches?('pass')  # true/false
@post.password_hint              # "Hint text"
```

### Verify Password (Frontend)
```
1. Visit protected URL
2. See password form
3. Enter password
4. Submit
5. View content (if correct)
```

### Remove Protection
```
1. Edit post/page
2. Clear password field
3. Clear hint field
4. Save
```

---

## Files Modified

1. `db/migrate/xxx_add_password_to_posts_and_pages.rb` - Database
2. `app/models/post.rb` - Post model logic
3. `app/models/page.rb` - Page model logic
4. `app/controllers/posts_controller.rb` - Password verification
5. `app/controllers/pages_controller.rb` - Password verification
6. `app/views/posts/password_protected.html.erb` - Password form
7. `app/views/pages/password_protected.html.erb` - Password form
8. `app/views/admin/posts/_form.html.erb` - Admin UI
9. `app/views/admin/pages/_form.html.erb` - Admin UI
10. `config/routes.rb` - Verification routes

---

## Testing

### Manual Testing

**1. Protect a Post:**
```
- Edit a post
- Set password: "test123"
- Set hint: "test + 123"
- Save
```

**2. Visit as Guest:**
```
- Go to post URL
- See password form
- Enter wrong password → Error
- Enter "test123" → Success
```

**3. Verify Session:**
```
- View content
- Navigate away
- Return to post
- Should NOT ask for password again
```

**4. Test as Admin:**
```
- Login as admin
- Visit protected post
- Should see content directly
- No password form shown
```

### Automated Tests

```ruby
RSpec.describe 'Password Protection' do
  let(:post) { create(:post, password: 'secret', status: :published) }
  
  context 'as guest' do
    it 'shows password form' do
      get blog_post_path(post)
      expect(response.body).to include('Protected Content')
      expect(response.body).to include('password')
    end
    
    it 'accepts correct password' do
      post verify_password_blog_post_path(post), params: { password: 'secret' }
      expect(session[:verified_posts]).to include(post.id)
    end
    
    it 'rejects incorrect password' do
      post verify_password_blog_post_path(post), params: { password: 'wrong' }
      expect(flash[:alert]).to be_present
    end
  end
  
  context 'as admin' do
    before { sign_in create(:user, :admin) }
    
    it 'bypasses password' do
      get blog_post_path(post)
      expect(response.body).not_to include('Protected Content')
      expect(response.body).to include(post.content.to_s)
    end
  end
end
```

---

## Summary

Password protection in RailsPress:

✅ **Simple** - Just add a password field  
✅ **Flexible** - Works with any status  
✅ **User-Friendly** - Beautiful password form  
✅ **Session-Based** - Remembers verified passwords  
✅ **Secure** - Server-side validation  
✅ **Bypassable** - Admins/editors/authors skip  
✅ **Shareable** - Easy to distribute access  
✅ **Optional** - Only when needed  

Perfect for:
- Client previews
- Beta content
- Team resources
- Temporary protection
- Simple access control

---

**Quick Start:**
1. Edit a post/page in admin
2. Set a password in "Password Protection" section
3. Share URL + password with authorized viewers
4. They enter password once per session

**Access Control Hierarchy:**
1. Admin/Editor - Full access, no password
2. Author - Own content, no password
3. Logged-in + Password - Private content
4. Password Only - Public but protected content
5. Public - No restrictions

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**WordPress Compatible**: Yes  
**Last Updated**: October 12, 2025  

Password protection is now fully integrated! 🔒



