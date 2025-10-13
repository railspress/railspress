# RailsPress Tools Section - Complete Guide

## Overview

The Tools section provides WordPress-like import/export functionality, site health monitoring, and GDPR-compliant personal data management.

---

## 🔧 Tools Menu

Located in the admin sidebar, the Tools section includes:

1. **Import** - Import content from WordPress, JSON, or CSV
2. **Export** - Export your content to various formats
3. **Site Health** - Monitor system configuration and performance
4. **Export Personal Data** - GDPR Article 20 compliance
5. **Erase Personal Data** - GDPR Article 17 compliance

---

## 📥 Import

### Supported Formats

#### 1. **WordPress XML (WXR)**
- Standard WordPress export format
- Import posts, pages, categories, tags
- Preserves metadata and custom fields
- Downloads and imports media files

**How to get WordPress XML:**
1. In WordPress: Tools → Export
2. Select "All content"
3. Download the XML file
4. Upload to RailsPress

#### 2. **JSON**
- RailsPress native format
- Complete site backup including settings
- Best for migrating between RailsPress instances

**JSON Structure:**
```json
{
  "posts": [...],
  "pages": [...],
  "users": [...],
  "settings": {...},
  "media": [...]
}
```

#### 3. **CSV**
- Separate CSV files for different content types
- Good for bulk content creation
- Supports: Posts, Pages, Users

**CSV Headers:**
- **Posts**: `title, content, slug, status, excerpt, published_at`
- **Pages**: `title, content, slug, status`
- **Users**: `email, name, role`

### Import Options

- ☑️ **Import Authors** - Create user accounts for authors
- ☑️ **Import Categories/Tags** - Create taxonomies
- ☑️ **Import Media** - Download and attach media files
- ☐ **Import Comments** - Include comments
- ☑️ **Skip Duplicates** - Avoid duplicate content based on slug

### Import Process

1. **Upload File** - Select file and import type
2. **Background Processing** - Large imports run in Sidekiq
3. **Real-time Progress** - Page auto-refreshes to show progress
4. **Completion** - Notification when import finishes

### Import History

- View all past imports
- See status (Pending, Processing, Completed, Failed)
- Progress bar for active imports
- Retry failed imports
- Import metadata and logs

---

## 📤 Export

### Export Formats

#### 1. **JSON (Recommended)**
- Complete site export
- All metadata and custom fields
- Easy to re-import
- Prettified output option

#### 2. **WordPress XML (WXR)**
- Compatible with WordPress import
- Standard WXR format
- Import into WordPress using Tools → Import

#### 3. **CSV**
- Separate files for each content type
- Good for data analysis
- Opens in Excel/Google Sheets

#### 4. **SQL Dump**
- Raw database export
- Advanced users only
- Complete database backup

### Export Options

**Content to Export:**
- ☑️ Posts
- ☑️ Pages
- ☐ Media
- ☐ Comments
- ☐ Users
- ☐ Settings

**Additional Options:**
- ☐ Include drafts
- ☐ Include trash
- ☑️ Include custom fields
- ☑️ Prettify JSON

### Export Process

1. **Select Format** - Choose export type
2. **Choose Content** - Select what to export
3. **Background Generation** - Large exports run in Sidekiq
4. **Download** - Download link appears when ready

### Export History

- All export jobs listed
- Download completed exports
- View export metadata
- Auto-deletion after 30 days

---

## 🏥 Site Health

### Health Check Categories

#### **Critical Checks**
- ✅ Database Connection
- ✅ File Permissions
- ✅ Ruby Version
- ✅ Required Gems

#### **Recommended Checks**
- ⚠️ Redis Connection
- ⚠️ ActiveStorage Configuration
- ⚠️ Email Configuration
- ⚠️ Background Jobs (Sidekiq)
- ⚠️ HTTPS/SSL

#### **Performance Checks**
- 💡 Caching Enabled
- 💡 Disk Space
- 💡 Memory Usage

#### **Informational**
- ℹ️ Rails Version
- ℹ️ Platform Info
- ℹ️ RailsPress Version

### Status Indicators

- **PASS** (Green) - Working correctly
- **WARNING** (Yellow) - Needs attention
- **FAIL** (Red) - Critical issue
- **INFO** (Blue) - Informational

### Health Check Details

Each check includes:
- Status badge
- Description message
- Expandable technical details
- Recommendations for fixes

### Re-run Tests

- Click "Re-run Tests" to refresh all checks
- Tests run in real-time
- Page auto-refreshes with results

### System Information Panel

Displays:
- Ruby version
- Rails version
- Environment (development/production)
- Database adapter
- Platform/OS
- RailsPress version

---

## 🔒 Export Personal Data (GDPR)

### Purpose

Complies with **GDPR Article 20** (Right to Data Portability):
> Users have the right to receive their personal data in a structured, commonly used, machine-readable format.

### Process

1. **Enter User Email** - Input the email of requesting user
2. **Generate Export** - Creates comprehensive JSON file
3. **Background Processing** - Compiled in Sidekiq
4. **Download Link** - Available when ready
5. **Auto-Expiry** - Downloads expire after 7 days

### Data Included

✅ User profile (name, email, bio, etc.)
✅ All posts authored by user
✅ All pages authored by user
✅ All comments submitted
✅ Media files uploaded
✅ Newsletter subscriptions
✅ Activity logs and pageviews
✅ Custom field values
✅ Preferences and settings

### Export Format (JSON)

```json
{
  "request_info": {
    "requested_at": "2025-10-12",
    "email": "user@example.com"
  },
  "user_profile": {...},
  "posts": [...],
  "comments": [...],
  "subscribers": [...],
  "pageviews": {...},
  "metadata": {...}
}
```

### Request Management

- View all export requests
- See request status
- Download completed exports
- Track who requested the export
- Audit trail for compliance

### Compliance Notes

- Exports must be provided within **30 days**
- Data provided in machine-readable format (JSON)
- Includes all personal data held
- Secure download links (tokenized)
- Auto-cleanup after 7 days

---

## 🗑️ Erase Personal Data (GDPR)

### Purpose

Complies with **GDPR Article 17** (Right to Erasure/"Right to be Forgotten"):
> Users have the right to request deletion of their personal data.

### ⚠️ Warning

**THIS ACTION IS PERMANENT AND CANNOT BE UNDONE**

### Two-Step Confirmation Process

1. **Create Request** - Enter email and reason
2. **Review** - Shows what will be deleted
3. **Confirm** - Final confirmation required
4. **Execute** - Background erasure process
5. **Audit** - Logged for compliance

### Data That Gets Erased

🗑️ User account and profile
🗑️ All posts authored by user (or anonymized)
🗑️ All comments submitted
🗑️ Media files uploaded
🗑️ Newsletter subscriptions
🗑️ Analytics/pageviews
🗑️ Custom field values
🗑️ Email logs

### Safety Features

- **Administrator Protection** - Cannot erase admin accounts
- **Two-Step Confirmation** - Prevents accidental deletion
- **Audit Trail** - Full logging of who, when, why
- **Reason Required** - Must document erasure reason
- **Preview Counts** - Shows how many items will be deleted

### Erasure Strategy

**Option 1: Full Deletion**
- Completely removes all user content
- Posts are permanently deleted

**Option 2: Anonymization** (Current)
- User account deleted
- Posts kept but author set to null/anonymous
- Comments anonymized but content preserved
- Maintains content while removing personal data

### Request Status

- **Pending Confirmation** - Awaiting final approval
- **Processing** - Erasure in progress
- **Completed** - Successfully erased
- **Failed** - Error occurred
- **Cancelled** - Request cancelled

### Compliance Notes

- Must complete within **30 days** of request
- Maintain audit log for **3 years**
- Document reason for erasure
- Consider data retention requirements (taxes, legal)
- Some data may be kept for legal obligations

---

## 🔄 Background Processing

All import/export operations use **Sidekiq** for background processing:

### Benefits

- ✅ Non-blocking - Don't wait for long operations
- ✅ Progress tracking - Real-time progress updates
- ✅ Retry logic - Automatic retry on failure
- ✅ Queue management - Prioritize critical tasks
- ✅ Scalable - Handle large datasets

### Queue Priority

1. **Critical** - Personal data erasure
2. **Default** - Imports, exports, GDPR exports
3. **Low** - Cleanup tasks

### Monitoring

- View Sidekiq dashboard at `/admin/sidekiq`
- See job status and progress
- Retry failed jobs
- Monitor queue sizes

---

## 📊 Technical Implementation

### Models

```ruby
# app/models/import_job.rb
class ImportJob < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:tenant)
  
  enum status: [:pending, :processing, :completed, :failed]
end

# app/models/export_job.rb
class ExportJob < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:tenant)
  
  enum status: [:pending, :processing, :completed, :failed]
end

# app/models/personal_data_export_request.rb
class PersonalDataExportRequest < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:tenant)
end

# app/models/personal_data_erasure_request.rb
class PersonalDataErasureRequest < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:tenant)
  
  enum status: [:pending_confirmation, :processing, :completed, :failed]
end
```

### Workers

```ruby
# app/workers/import_worker.rb
class ImportWorker
  include Sidekiq::Worker
  
  def perform(import_job_id)
    # Process import based on type
  end
end

# app/workers/export_worker.rb
class ExportWorker
  include Sidekiq::Worker
  
  def perform(export_job_id)
    # Generate export based on format
  end
end

# app/workers/personal_data_export_worker.rb
class PersonalDataExportWorker
  include Sidekiq::Worker
  
  def perform(request_id)
    # Compile user's personal data
  end
end

# app/workers/personal_data_erasure_worker.rb
class PersonalDataErasureWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical
  
  def perform(request_id)
    # Erase all user data
  end
end
```

### Routes

```ruby
# config/routes.rb
namespace :admin do
  namespace :tools do
    # Import
    get 'import', to: 'import#index'
    post 'import/upload', to: 'import#upload'
    post 'import/process', to: 'import#process'
    
    # Export
    get 'export', to: 'export#index'
    post 'export/generate', to: 'export#generate'
    get 'export/download/:id', to: 'export#download'
    
    # Site Health
    get 'site_health', to: 'site_health#index'
    post 'site_health/run_tests', to: 'site_health#run_tests'
    
    # GDPR - Export
    get 'export_personal_data', to: 'export_personal_data#index'
    post 'export_personal_data/request', to: 'export_personal_data#request'
    get 'export_personal_data/download/:token', to: 'export_personal_data#download'
    
    # GDPR - Erasure
    get 'erase_personal_data', to: 'erase_personal_data#index'
    post 'erase_personal_data/request', to: 'erase_personal_data#request'
    post 'erase_personal_data/confirm/:token', to: 'erase_personal_data#confirm'
  end
end
```

---

## 🎨 UI/UX Features

### Consistent Dark Design

All Tools pages feature:
- Dark background (`#0a0a0a`, `#1a1a1a`)
- Subtle borders (`#2a2a2a`)
- Indigo accent colors
- Clean typography
- Smooth transitions

### Interactive Elements

- **SweetAlert2** - Beautiful toast notifications
- **Progress Bars** - Real-time progress tracking
- **Auto-refresh** - Pages reload when jobs are processing
- **Confirmation Dialogs** - Two-step confirmations for dangerous actions
- **Status Badges** - Color-coded status indicators

### Responsive Design

- Works on all screen sizes
- Mobile-friendly forms
- Adaptive layouts
- Touch-friendly buttons

---

## 🔐 Security Features

### Access Control

- Admin-only access
- Audit logging
- User attribution
- Timestamp tracking

### File Security

- Temporary file storage
- Secure token generation
- Auto-cleanup of old exports
- Path validation

### GDPR Compliance

- Two-step confirmation for erasure
- Audit trail maintenance
- Data retention policies
- Secure download links

---

## 🚀 Usage Examples

### Import WordPress Site

```ruby
# 1. Export from WordPress
# 2. Go to Admin → Tools → Import
# 3. Select "WordPress XML"
# 4. Upload the .xml file
# 5. Check options (authors, categories, media)
# 6. Click "Start Import"
# 7. Wait for completion (auto-refreshes)
```

### Export Site Backup

```ruby
# 1. Go to Admin → Tools → Export
# 2. Select "JSON (Recommended)"
# 3. Check: Posts, Pages, Settings
# 4. Check: Include metadata
# 5. Click "Generate Export"
# 6. Download when ready
```

### Handle GDPR Request

**Export Request:**
```ruby
# 1. User emails requesting their data
# 2. Go to Tools → Export Personal Data
# 3. Enter user's email
# 4. Click "Generate"
# 5. Download link appears when ready
# 6. Send link to user (expires in 7 days)
```

**Erasure Request:**
```ruby
# 1. User emails requesting erasure
# 2. Go to Tools → Erase Personal Data
# 3. Enter email and reason
# 4. Review what will be deleted
# 5. Click "Create Request"
# 6. Confirm the erasure (shows preview)
# 7. Final confirmation required
# 8. Data erased in background
```

### Check Site Health

```ruby
# 1. Go to Tools → Site Health
# 2. Review all checks
# 3. Fix any warnings/failures
# 4. Click "Re-run Tests" to verify
```

---

## 📋 Database Schema

### import_jobs

| Column | Type | Description |
|--------|------|-------------|
| import_type | string | wordpress, json, csv_posts, csv_pages, csv_users |
| file_path | string | Path to uploaded file |
| file_name | string | Original filename |
| user_id | references | Who initiated the import |
| status | string | pending, processing, completed, failed |
| progress | integer | Percentage complete (0-100) |
| total_items | integer | Total items to import |
| imported_items | integer | Successfully imported |
| failed_items | integer | Failed imports |
| error_log | text | Error messages |
| metadata | json | Additional data |
| tenant_id | references | Multi-tenancy |

### export_jobs

| Column | Type | Description |
|--------|------|-------------|
| export_type | string | json, wordpress, csv, sql |
| file_path | string | Generated file path |
| file_name | string | Generated filename |
| content_type | string | MIME type |
| user_id | references | Who created the export |
| status | string | pending, processing, completed, failed |
| progress | integer | Percentage complete |
| total_items | integer | Total items |
| exported_items | integer | Successfully exported |
| options | json | Export options |
| metadata | json | Additional data |

### personal_data_export_requests

| Column | Type | Description |
|--------|------|-------------|
| user_id | references | Target user |
| email | string | User's email |
| requested_by | integer | Admin who created request |
| status | string | pending, processing, completed, failed |
| token | string | Secure download token |
| file_path | string | Export file path |
| metadata | json | Export metadata |

### personal_data_erasure_requests

| Column | Type | Description |
|--------|------|-------------|
| user_id | references | Target user |
| email | string | User's email |
| requested_by | integer | Admin who created request |
| confirmed_by | integer | Admin who confirmed |
| status | string | pending_confirmation, processing, completed, failed |
| token | string | Unique identifier |
| reason | text | Reason for erasure |
| confirmed_at | datetime | When confirmed |
| completed_at | datetime | When completed |
| metadata | json | Erasure details |

---

## ⚙️ Configuration

### Sidekiq Queues

```ruby
# config/sidekiq.yml
:queues:
  - critical    # Personal data erasure
  - default     # Imports, exports
  - low         # Cleanup tasks
```

### File Storage

```ruby
# Temporary uploads
tmp/imports/

# Generated exports
tmp/exports/

# GDPR exports (auto-cleanup)
tmp/personal_data_exports/
```

### Cleanup Tasks

Schedule regular cleanup of old files:

```ruby
# config/initializers/sidekiq_cron.rb
Sidekiq::Cron::Job.create(
  name: 'Cleanup old exports',
  cron: '0 2 * * *', # 2 AM daily
  class: 'CleanupExportsWorker'
)
```

---

## 🧪 Testing

### Import Testing

```ruby
# spec/workers/import_worker_spec.rb
RSpec.describe ImportWorker do
  it 'imports WordPress XML' do
    job = create(:import_job, import_type: 'wordpress')
    ImportWorker.new.perform(job.id)
    expect(job.reload.status).to eq('completed')
  end
end
```

### Export Testing

```ruby
# spec/workers/export_worker_spec.rb
RSpec.describe ExportWorker do
  it 'generates JSON export' do
    job = create(:export_job, export_type: 'json')
    ExportWorker.new.perform(job.id)
    expect(File.exist?(job.reload.file_path)).to be true
  end
end
```

---

## 🎯 Best Practices

### Import

1. **Backup First** - Always backup before importing
2. **Test File** - Verify file format before uploading
3. **Check Duplicates** - Enable skip duplicates option
4. **Monitor Progress** - Stay on page or check back
5. **Review Results** - Check import logs for errors

### Export

1. **Regular Backups** - Schedule weekly exports
2. **Include Everything** - Don't forget settings
3. **Download Promptly** - Exports auto-delete after 30 days
4. **Verify Content** - Test export file before deleting original

### Site Health

1. **Weekly Checks** - Run health checks regularly
2. **Fix Warnings** - Address warnings before they become critical
3. **Monitor Trends** - Track performance over time
4. **Document Changes** - Note what fixes were applied

### GDPR Compliance

1. **Respond Quickly** - GDPR requires 30-day response
2. **Export Before Erase** - Create backup before deletion
3. **Document Requests** - Keep reason and audit trail
4. **Communicate** - Inform user when complete
5. **Legal Review** - Consult legal team for complex cases

---

## 🆘 Troubleshooting

### Import Issues

**Import fails immediately:**
- Check file format matches import type
- Verify file is not corrupted
- Check file size limits

**Import stuck at processing:**
- Check Sidekiq is running
- View Sidekiq dashboard for errors
- Check Rails logs

**Duplicate content:**
- Enable "Skip duplicates" option
- Manually check slugs
- Delete duplicates before re-importing

### Export Issues

**Export never completes:**
- Check Sidekiq is running
- Large exports may take time
- Check disk space

**Download link not working:**
- Check file still exists
- Verify export completed successfully
- Check for expiry (30 days)

### Site Health Failures

**Database connection fail:**
- Check database is running
- Verify database.yml configuration
- Check credentials

**Redis warning:**
- Start Redis server
- Check REDIS_URL environment variable
- Verify Redis connection

**File permissions:**
- Check tmp/, log/, storage/ are writable
- Run: `chmod -R 755 tmp log storage`

---

## 📚 Related Documentation

- [WordPress Import/Export](https://wordpress.org/support/article/tools-export-screen/)
- [GDPR Compliance](https://gdpr.eu/)
- [Sidekiq Best Practices](https://github.com/mperham/sidekiq/wiki/Best-Practices)

---

**✅ Tools Section Complete!**

The Tools section provides enterprise-grade import/export functionality with full GDPR compliance, comprehensive site health monitoring, and production-ready background job processing.



