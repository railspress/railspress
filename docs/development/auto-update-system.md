# Auto-Update System Documentation

## Overview

RailsPress includes an automatic update checking system that monitors GitHub releases for new versions. This system helps keep your installation secure and up-to-date with the latest features.

## Features

✅ **Automatic Checking** - Checks GitHub daily for new releases  
✅ **Admin Interface** - View updates in admin panel  
✅ **CLI Integration** - Check updates from command line  
✅ **Version Comparison** - Smart semantic versioning  
✅ **Release Notes** - View changelog directly  
✅ **Caching** - Efficient 6-hour cache  
✅ **Background Jobs** - Sidekiq integration  

---

## Configuration

### Environment Variables

```bash
# .env
RAILSPRESS_GITHUB_REPO="yourusername/railspress"
GITHUB_TOKEN="your_github_token_here"  # Optional, increases rate limit
```

### GitHub Token (Optional)

Without a token: 60 requests/hour  
With a token: 5,000 requests/hour

To create a token:
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `public_repo` scope
3. Add to your `.env` file

---

## Usage

### Admin Interface

1. Navigate to **Admin → Updates**
2. View current and latest versions
3. Click "Check for Updates" to force check
4. View release notes if update available
5. Follow update instructions

**URL**: `http://localhost:3000/admin/updates`

### CLI Commands

```bash
# Check for updates
./bin/railspress-cli core check-update

# View current version
./bin/railspress-cli core version
```

Example output:
```
ℹ Checking for updates from GitHub...

Current Version: 1.0.0
Latest Version:  1.1.0

✓ New version available!
  Release: https://github.com/username/railspress/releases/latest

  To update:
  1. Backup your database: ./scripts/backup.sh
  2. Pull latest changes: git pull origin main
  3. Update database: ./bin/railspress-cli core update-db
  4. Restart server: ./railspress restart

Last checked: 2025-10-11 21:45:32
```

### Automatic Checking

The system automatically checks for updates:
- **Schedule**: Daily at 6:00 AM
- **Method**: Sidekiq Cron job
- **Cache**: Results cached for 6 hours

To disable automatic checking:
```ruby
# config/sidekiq.yml
# Comment out the check_updates job
```

---

## API

### Programmatic Access

```ruby
# Check for updates
update_info = Railspress::UpdateChecker.check_for_updates

# Access results
update_info[:current_version]   # "1.0.0"
update_info[:latest_version]    # "1.1.0"
update_info[:update_available]  # true/false
update_info[:release_url]       # GitHub release URL
update_info[:checked_at]        # Timestamp

# Fetch release notes
release_notes = Railspress::UpdateChecker.fetch_release_notes

# Access release info
release_notes[:version]       # "v1.1.0"
release_notes[:name]          # "Version 1.1.0"
release_notes[:body]          # Markdown changelog
release_notes[:html_url]      # Release page URL
release_notes[:published_at]  # Publication date
```

---

## Update Process

### Safe Update Workflow

1. **Backup Everything**
   ```bash
   ./scripts/backup.sh before-update
   ```

2. **Check Current State**
   ```bash
   git status
   ./bin/railspress-cli doctor check
   ```

3. **Pull Latest Changes**
   ```bash
   git fetch origin
   git pull origin main
   ```

4. **Install Dependencies**
   ```bash
   bundle install
   ```

5. **Run Migrations**
   ```bash
   ./bin/railspress-cli core update-db
   # or
   rails db:migrate
   ```

6. **Clear Caches**
   ```bash
   ./bin/railspress-cli cache clear
   rails assets:precompile RAILS_ENV=production
   ```

7. **Restart Server**
   ```bash
   ./railspress restart
   # or
   sudo systemctl restart railspress
   ```

8. **Verify**
   ```bash
   ./bin/railspress-cli core version
   ./bin/railspress-cli doctor check
   ```

---

## Version Comparison

The system uses semantic versioning (SemVer):

```
MAJOR.MINOR.PATCH
  1  .  0  .  0
```

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

Examples:
- `1.0.0` → `1.0.1`: Patch update (safe)
- `1.0.0` → `1.1.0`: Minor update (safe)
- `1.0.0` → `2.0.0`: Major update (may require changes)

---

## Troubleshooting

### Issue: "Update check failed"

**Cause**: GitHub API rate limit or network error

**Solution**:
1. Add GitHub token to `.env`
2. Check internet connection
3. Verify GitHub repo setting
4. Wait and retry (rate limit resets hourly)

### Issue: "No updates available" but new version exists

**Cause**: Cache not expired or version mismatch

**Solution**:
```ruby
# Clear cache
Rails.cache.delete('railspress:update_check')

# Force fresh check
./bin/railspress-cli core check-update
```

### Issue: Update check never runs

**Cause**: Sidekiq not running or cron not configured

**Solution**:
```bash
# Check Sidekiq status
bundle exec sidekiq

# Verify cron jobs
bundle exec sidekiq-cron
```

---

## Architecture

### Components

```
┌─────────────────────────────────────────┐
│      Railspress::UpdateChecker          │
│  - Check GitHub for latest release      │
│  - Compare versions                     │
│  - Cache results                        │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼────────┐   ┌────────▼──────────┐
│ Admin UI       │   │  CLI Command      │
│ /admin/updates │   │  core check-update│
└────────────────┘   └───────────────────┘
        │                     │
        └──────────┬──────────┘
                   │
        ┌──────────▼────────────┐
        │   CheckUpdatesJob     │
        │   (Sidekiq Cron)      │
        │   Daily at 6am        │
        └───────────────────────┘
```

### Files

```
lib/railspress/
└── update_checker.rb          # Core logic

app/controllers/admin/
└── updates_controller.rb      # Admin interface

app/views/admin/updates/
└── index.html.erb             # UI

app/jobs/
└── check_updates_job.rb       # Background job

config/
├── routes.rb                  # Routes
└── sidekiq.yml                # Cron schedule

bin/
└── railspress-cli             # CLI integration
```

---

## Security Considerations

### Rate Limiting

- Without token: 60 requests/hour
- With token: 5,000 requests/hour
- Cache prevents excessive requests

### HTTPS Only

All GitHub API calls use HTTPS for secure communication.

### No Automatic Updates

The system **checks** for updates but **never installs automatically**. You maintain full control.

### Token Security

Store GitHub tokens in:
- `.env` file (not committed)
- Environment variables
- Secrets management system

---

## Future Enhancements

Planned features:

- [ ] Email notifications for administrators
- [ ] In-app notification badges
- [ ] One-click update (with backup)
- [ ] Rollback mechanism
- [ ] Update history tracking
- [ ] Pre/post update hooks
- [ ] Compatibility checking
- [ ] Breaking change warnings

---

## FAQ

### Q: Is this system required?

**A**: No, it's optional but highly recommended for security and features.

### Q: Can I disable it?

**A**: Yes, comment out the Sidekiq cron job and don't access the admin page.

### Q: Does it update automatically?

**A**: No, it only checks. You must manually update following the documented process.

### Q: What if I use a private repo?

**A**: Add a GitHub token with repo access to the `.env` file.

### Q: How do I test it?

**A**: Run `./bin/railspress-cli core check-update` or visit `/admin/updates`.

---

## Support

- **Documentation**: See other `.md` files in root
- **GitHub**: Open an issue on the repository
- **CLI Help**: `./bin/railspress-cli --help`

---

**Version**: 1.0.0  
**Last Updated**: October 2025



