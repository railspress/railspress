# Post & Page Status System - Complete Guide

## Overview

RailsPress implements a comprehensive WordPress-style status system for posts and pages with 6 different statuses, each with specific behaviors and permissions.

---

## Available Statuses

### 1. Draft (0)
**Icon**: 📝  
**Color**: Gray  
**Description**: Work in progress, not visible to public

**Characteristics:**
- ✅ Visible only to admins, editors, and the author
- ❌ Not shown on public site
- ❌ Not included in feeds/archives
- ✅ Can be edited freely
- ✅ Can be previewed by authorized users

**Use Cases:**
- Writing new content
- Major revisions before publishing
- Content awaiting completion

### 2. Published (1)
**Icon**: ✅  
**Color**: Green  
**Description**: Live and visible to everyone

**Characteristics:**
- ✅ Visible to all visitors
- ✅ Shown in blog listings/archives
- ✅ Included in RSS feeds
- ✅ Indexed by search engines
- ✅ Trackable in analytics

**Use Cases:**
- Regular published content
- Blog posts going live immediately
- Pages ready for public access

### 3. Scheduled (2)
**Icon**: ⏰  
**Color**: Blue  
**Description**: Will be published automatically at specified time

**Characteristics:**
- ⏳ Not visible until `published_at` datetime
- ✅ Auto-publishes when time arrives
- ❌ Hidden from public before publish time
- ✅ Visible to admins/editors for review
- ✅ Can be rescheduled

**Use Cases:**
- Time-sensitive announcements
- Content calendars
- Automated publishing workflows
- Future-dated posts

### 4. Pending Review (3)
**Icon**: 👀  
**Color**: Yellow  
**Description**: Awaiting editor/admin approval

**Characteristics:**
- ❌ Not visible to public
- ✅ Visible to admins and editors
- ⚠️ Author cannot publish directly
- ✅ Requires approval to publish
- ✅ Notification to editors

**Use Cases:**
- Multi-author blogs with approval workflow
- Content moderation
- Editorial review process
- Guest post submissions

### 5. Private (4)
**Icon**: 🔒  
**Color**: Purple  
**Description**: Only visible to logged-in users

**Characteristics:**
- ❌ Not visible to anonymous visitors
- ✅ Visible to any logged-in user
- ❌ Not in public listings/feeds
- ✅ Can be shared via direct link
- ✅ Still indexed in internal search

**Use Cases:**
- Members-only content
- Internal documentation
- Premium content for subscribers
- Private company updates

### 6. Trash (5)
**Icon**: 🗑️  
**Color**: Red  
**Description**: Soft-deleted, can be restored

**Characteristics:**
- ❌ Not visible anywhere
- ✅ Can be permanently deleted
- ✅ Can be restored
- ⏳ Auto-purge after 30 days (optional)
- ❌ Not in any public queries

**Use Cases:**
- Soft delete before permanent removal
- Accidental deletion recovery
- Content archival
- Compliance with data retention

---

## Status Flow Diagram

```
┌─────────┐
│  Draft  │ ←──────────────┐
└────┬────┘                │
     │                     │
     │ Submit for Review   │ Reject
     ↓                     │
┌──────────────┐          │
│Pending Review│ ─────────┘
└──────┬───────┘
       │
       │ Approve
       ↓
┌───────────┐
│ Published │
└───────────┘
       │
       │ Schedule
       ↓
┌───────────┐
│ Scheduled │ ─→ Auto-publish at time → Published
└───────────┘

Any Status ─→ Private (Restrict access)
Any Status ─→ Trash (Soft delete)
Trash ─────→ Restore → Previous Status
```

---

## Permission Matrix

| Status | Public | Logged-in | Author | Editor | Admin |
|--------|--------|-----------|--------|--------|-------|
| Draft | ❌ | ❌ | ✅ | ✅ | ✅ |
| Published | ✅ | ✅ | ✅ | ✅ | ✅ |
| Scheduled (future) | ❌ | ❌ | ✅ | ✅ | ✅ |
| Scheduled (past) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pending Review | ❌ | ❌ | ✅ view | ✅ | ✅ |
| Private | ❌ | ✅ | ✅ | ✅ | ✅ |
| Trash | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## Implementation

### Model Scopes

**Posts:**
```ruby
Post.visible_to_public    # Published + scheduled (past publish time)
Post.not_trashed          # All except trash
Post.trashed              # Only trashed
Post.awaiting_review      # Pending review
Post.scheduled_future     # Scheduled for future
Post.scheduled_past       # Scheduled but publish time passed
Post.draft_status         # Only drafts
Post.published_status     # Only published
```

**Pages:**
```ruby
Page.visible_to_public    # Published + scheduled (past publish time)
Page.not_trashed          # All except trash
Page.trashed              # Only trashed
Page.awaiting_review      # Pending review
Page.scheduled_future     # Scheduled for future
Page.scheduled_past       # Scheduled but publish time passed
```

### Instance Methods

**Check Visibility:**
```ruby
@post.visible_to_public?   # true/false
@page.visible_to_public?   # true/false
```

**Auto-Publish Scheduled:**
```ruby
@post.check_scheduled_publish  # Publishes if time has come
@page.check_scheduled_publish  # Publishes if time has come
```

**Status Checks:**
```ruby
@post.draft_status?
@post.published_status?
@post.scheduled_status?
@post.pending_review_status?
@post.private_post_status?
@post.trash_status?
```

---

## Usage Examples

### Create Draft Post
```ruby
post = Post.create!(
  title: 'My Draft',
  content: 'Draft content',
  status: :draft,
  user: current_user
)
```

### Schedule Post for Future
```ruby
post = Post.create!(
  title: 'Future Post',
  content: 'Will publish tomorrow',
  status: :scheduled,
  published_at: 1.day.from_now,
  user: current_user
)
```

### Submit for Review
```ruby
post.update(status: :pending_review)
# Notify editors
EditorMailer.review_requested(post).deliver_later
```

### Approve and Publish
```ruby
post.update(
  status: :published,
  published_at: Time.current
)
```

### Make Private
```ruby
post.update(status: :private_post)
# Now only logged-in users can see it
```

### Move to Trash
```ruby
post.update(status: :trash)
# Soft deleted, can be restored
```

### Restore from Trash
```ruby
post.update(status: :draft)
# Or set to previous status
```

### Permanent Delete
```ruby
post.destroy
# Only do this for trashed items
```

---

## Admin Interface

### Status Filters

**In Admin Posts List:**
```
All | Draft | Published | Scheduled | Pending | Private | Trash
```

**Filter by URL:**
```
/admin/posts?status=draft
/admin/posts?status=scheduled
/admin/posts?show_trash=true
```

### Bulk Actions

**Available for all statuses:**
- Move to Trash
- Restore from Trash
- Publish Selected
- Mark as Draft
- Submit for Review
- Make Private

### Status Badges

Each post/page shows a colored badge:
- **Draft** - Gray badge
- **Published** - Green badge
- **Scheduled** - Blue badge  
- **Pending** - Yellow badge
- **Private** - Purple badge
- **Trash** - Red badge

---

## Automatic Scheduled Publishing

### How It Works

1. **Create Scheduled Post:**
   ```ruby
   post = Post.create(
     status: :scheduled,
     published_at: 2.hours.from_now
   )
   ```

2. **Automatic Check:**
   - When post is viewed (public or admin)
   - Via Sidekiq cron job (recommended)
   - Manual trigger via rake task

3. **Auto-Publish:**
   ```ruby
   # Happens automatically
   post.check_scheduled_publish
   # Changes status from :scheduled to :published
   ```

### Sidekiq Cron Job (Recommended)

```ruby
# config/schedule.yml
publish_scheduled_posts:
  cron: "*/5 * * * *"  # Every 5 minutes
  class: "PublishScheduledPostsJob"
```

```ruby
# app/jobs/publish_scheduled_posts_job.rb
class PublishScheduledPostsJob < ApplicationJob
  def perform
    # Publish scheduled posts
    Post.scheduled_past.find_each do |post|
      post.check_scheduled_publish
    end
    
    # Publish scheduled pages
    Page.scheduled_past.find_each do |page|
      page.check_scheduled_publish
    end
  end
end
```

---

## Frontend Handling

### Only Show Public Content

**Blog Index:**
```ruby
@posts = Post.visible_to_public.recent.page(params[:page])
```

**Show Post:**
```ruby
@post = Post.friendly.find(params[:id])
raise ActiveRecord::RecordNotFound unless @post.visible_to_public?
```

**Categories/Tags:**
```ruby
@posts = @category.posts.visible_to_public.recent
```

### Handle Private Content

```ruby
def can_view_post?(post)
  return true if post.visible_to_public?
  return false unless user_signed_in?
  
  # Admins/editors can view all
  return true if current_user.administrator? || current_user.editor?
  
  # Authors can view their own
  return true if post.user_id == current_user.id
  
  # Private content visible to logged-in users
  return true if post.private_post_status?
  
  false
end
```

---

## API Considerations

### REST API

```ruby
# GET /api/v1/posts
# Only return published by default
def index
  @posts = Post.visible_to_public.recent
  
  # Admins can request all statuses
  if current_user&.administrator? && params[:all_statuses]
    @posts = Post.not_trashed
  end
  
  render json: @posts
end
```

### GraphQL API

```ruby
field :posts, [Types::PostType], null: false do
  argument :status, String, required: false
end

def posts(status: nil)
  posts = Post.visible_to_public
  
  # Admins can filter by status
  if context[:current_user]&.administrator? && status
    posts = Post.not_trashed.where(status: status)
  end
  
  posts
end
```

---

## Workflow Examples

### Basic Blog Workflow

1. Author creates draft
2. Author writes content
3. Author saves as draft
4. Author publishes directly

### Editorial Workflow

1. Contributor creates draft
2. Contributor submits for review → `pending_review`
3. Editor reviews content
4. Editor approves → `published` OR rejects → `draft`

### Scheduled Publishing

1. Author creates post
2. Author sets future `published_at`
3. Author sets status to `scheduled`
4. System auto-publishes at specified time

### Members-Only Content

1. Create post
2. Set status to `private_post`
3. Only logged-in users can view
4. Share direct link with members

---

## Status Transitions

### Allowed Transitions

```ruby
# From Draft
draft → published        ✅
draft → scheduled        ✅
draft → pending_review   ✅
draft → private_post     ✅
draft → trash            ✅

# From Published  
published → draft        ✅ (Unpublish)
published → scheduled    ✅ (Reschedule)
published → private_post ✅
published → trash        ✅

# From Scheduled
scheduled → published    ✅ (Auto or manual)
scheduled → draft        ✅
scheduled → trash        ✅

# From Pending Review
pending_review → published ✅ (Approve)
pending_review → draft     ✅ (Reject)
pending_review → trash     ✅

# From Private
private_post → published  ✅
private_post → draft      ✅
private_post → trash      ✅

# From Trash
trash → draft            ✅ (Restore)
trash → [deleted]        ✅ (Permanent)
```

---

## Helper Methods

### Status Badges

```erb
<%= status_badge(@post) %>
<!-- Outputs: colored badge with status -->
```

### Status Icons

```erb
<%= status_icon(@post.status) %>
<!-- Outputs: emoji icon -->
```

### Status Counts

```ruby
counts = post_status_counts
# => { total: 100, draft: 20, published: 60, ... }
```

---

## Database Queries

### Get Public Posts
```ruby
Post.visible_to_public
  .recent
  .limit(10)
```

### Get Drafts
```ruby
Post.draft_status
  .where(user: current_user)
  .order(updated_at: :desc)
```

### Get Scheduled Posts
```ruby
Post.scheduled_future
  .order(published_at: :asc)
```

### Get Posts Awaiting Review
```ruby
Post.awaiting_review
  .includes(:user)
  .order(created_at: :asc)
```

---

## Security

### Public Controllers

**Always filter by status:**
```ruby
# Good ✅
@posts = Post.visible_to_public

# Bad ❌
@posts = Post.all  # Exposes drafts!
```

**Check permissions:**
```ruby
def show
  @post = Post.find(params[:id])
  
  unless @post.visible_to_public? || can_view?(@post)
    raise ActiveRecord::RecordNotFound
  end
end
```

### Admin Controllers

**Default to not_trashed:**
```ruby
# Good ✅
@posts = Post.not_trashed

# Show trash only explicitly
if params[:show_trash]
  @posts = Post.trashed
end
```

---

## Notifications

### On Status Change

```ruby
# In Post model callback
after_update :notify_status_change, if: :saved_change_to_status?

def notify_status_change
  case status
  when 'pending_review'
    # Notify editors
    User.editor.find_each do |editor|
      ReviewMailer.new_submission(self, editor).deliver_later
    end
  when 'published'
    # Notify author
    AuthorMailer.post_published(self).deliver_later if published_at_previously_changed?
  when 'trash'
    # Log deletion
    Rails.logger.info "Post #{id} moved to trash by #{Current.user&.email}"
  end
end
```

---

## Best Practices

### 1. Always Use Scopes

```ruby
# Good ✅
Post.visible_to_public
Page.not_trashed

# Avoid ❌
Post.where(status: 1)  # Magic numbers
Post.where.not(status: 5)
```

### 2. Check Visibility

```ruby
# Good ✅
if @post.visible_to_public?
  # Show content
end

# Better ✅✅
if @post.visible_to_public? || can_view?(@post, current_user)
  # Show with permission check
end
```

### 3. Handle Scheduled

```ruby
# Always check scheduled posts
@post.check_scheduled_publish

# Or use Sidekiq cron for automation
```

### 4. Provide Clear UI

```ruby
# Show status clearly
<%= status_badge(@post) %>

# Add filters
link_to "Drafts (#{Post.draft_status.count})", admin_posts_path(status: 'draft')
```

### 5. Audit Trail

```ruby
# Use PaperTrail to track status changes
post.versions.where("object_changes LIKE '%status%'")
```

---

## Analytics Integration

### Track by Status

```ruby
# Don't track drafts/pending
def track_pageview(post)
  return unless post.visible_to_public?
  
  Pageview.track(request, post_id: post.id)
end
```

### Filter Analytics

```ruby
# Show analytics only for published content
Pageview.where(post_id: Post.published_status.pluck(:id))
```

---

## Sitemap Generation

### Only Include Public

```ruby
# config/sitemap.rb
Post.visible_to_public.find_each do |post|
  add post_path(post), lastmod: post.updated_at
end
```

---

## RSS Feeds

### Only Published

```ruby
# app/views/posts/feed.rss.builder
@posts = Post.published_status.recent.limit(20)

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  @posts.each do |post|
    # Add items
  end
end
```

---

## Testing

### Model Tests

```ruby
describe Post do
  describe 'scopes' do
    it 'visible_to_public includes only published and past scheduled' do
      draft = create(:post, status: :draft)
      published = create(:post, status: :published)
      scheduled_future = create(:post, status: :scheduled, published_at: 1.day.from_now)
      scheduled_past = create(:post, status: :scheduled, published_at: 1.day.ago)
      
      expect(Post.visible_to_public).to include(published, scheduled_past)
      expect(Post.visible_to_public).not_to include(draft, scheduled_future)
    end
  end
  
  describe '#visible_to_public?' do
    it 'returns false for drafts' do
      draft = create(:post, status: :draft)
      expect(draft.visible_to_public?).to be false
    end
    
    it 'returns true for published' do
      published = create(:post, status: :published)
      expect(published.visible_to_public?).to be true
    end
  end
end
```

### Controller Tests

```ruby
describe PostsController do
  describe 'GET #show' do
    it 'shows published posts' do
      post = create(:post, status: :published)
      get :show, params: { id: post.slug }
      expect(response).to be_successful
    end
    
    it 'hides draft posts' do
      post = create(:post, status: :draft)
      expect {
        get :show, params: { id: post.slug }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'shows private posts to logged-in users' do
      post = create(:post, status: :private_post)
      sign_in create(:user)
      get :show, params: { id: post.slug }
      expect(response).to be_successful
    end
  end
end
```

---

## Troubleshooting

### Scheduled Posts Not Publishing

**Check:**
1. Is `published_at` set correctly?
2. Is Sidekiq running?
3. Check cron job configuration

**Fix:**
```ruby
# Manual publish
Post.scheduled_past.each(&:check_scheduled_publish)
```

### Private Posts Visible to All

**Check:**
1. Are you using `visible_to_public?` method?
2. Check `can_view_page?` logic
3. Verify user authentication

**Fix:**
```ruby
# In controller
unless @post.visible_to_public? || can_view_post?(@post)
  raise ActiveRecord::RecordNotFound
end
```

### Trash Not Hiding Items

**Check:**
1. Are you using `.not_trashed` scope?
2. Check admin filters

**Fix:**
```ruby
# In admin controller index
@posts = Post.not_trashed

# Show trash separately
@trashed_posts = Post.trashed if params[:show_trash]
```

---

## Quick Reference

### Status Values
```ruby
draft: 0
published: 1
scheduled: 2
pending_review: 3
private_post/private_page: 4
trash: 5
```

### Common Queries
```ruby
Post.visible_to_public           # Public site
Post.not_trashed                 # Admin lists
Post.awaiting_review             # Review queue
Post.scheduled_future            # Upcoming posts
```

### Status Changes
```ruby
post.draft!                      # Set to draft
post.published!                  # Publish now
post.scheduled!                  # Schedule (set published_at too)
post.pending_review!             # Submit for review
post.private_post!               # Make private
post.trash!                      # Soft delete
```

---

**Status**: ✅ Production Ready  
**Statuses**: 6 (Draft, Published, Scheduled, Pending, Private, Trash)  
**Scopes**: 7+ helper scopes  
**Permissions**: Role-based access control  
**Auto-Publish**: Scheduled posts auto-publish  

All statuses are now properly honored throughout RailsPress! 🎉



