# Real-Time Application Logs Viewer - Guide

## Overview

RailsPress includes a powerful real-time log viewer built into the admin panel. View and monitor your Rails application logs directly in your browser with syntax highlighting, search, and real-time streaming.

---

## Features

✅ **Real-Time Streaming** - Logs update automatically using Server-Sent Events (SSE)  
✅ **Syntax Highlighting** - Color-coded log levels (DEBUG, INFO, WARN, ERROR, FATAL)  
✅ **Multiple Log Files** - Switch between development.log, production.log, test.log, etc.  
✅ **Search & Filter** - Find specific log entries instantly  
✅ **Pause & Resume** - Stop streaming to review errors  
✅ **Auto-Scroll** - Automatically scroll to latest entries  
✅ **Download** - Export full log files for offline analysis  
✅ **Copy to Clipboard** - One-click copy of all visible logs  
✅ **File Stats** - See file size and last modified time  
✅ **Clear File** - Truncate log files when needed  

---

## Access

Navigate to: **Developer → App Logs**

Or directly: `/admin/logs`

---

## Interface

### Toolbar Controls

**Left Side:**
- **Status Indicator** - Shows connection status (Connected/Disconnected/Paused)
- **⏸ Pause** - Stop streaming (useful for reviewing errors)
- **⬇ Auto-scroll** - Toggle automatic scrolling to bottom
- **⬆ Top** - Jump to top of logs
- **⬇ Bottom** - Jump to bottom of logs
- **🗑 Clear** - Clear viewer (not the file)

**Right Side:**
- **Search** - Real-time search with highlighting
- **📋 Copy** - Copy all logs to clipboard
- **Clear File** - Permanently clear the log file

### Log File Selector

Switch between different log files:
- `development.log` - Development environment logs
- `production.log` - Production environment logs
- `test.log` - Test suite logs
- `sidekiq.log` - Background job logs (if using Sidekiq)
- Custom logs - Any `.log` file in the `log/` directory

---

## Color Coding

Logs are automatically highlighted by level:

- **DEBUG** → Gray
- **INFO** → Blue
- **WARN** → Yellow
- **ERROR** → Red (bold)
- **FATAL** → Dark Red (bold)

Additional highlighting:
- **Timestamps** → Purple
- **File paths** → Cyan
- **Search matches** → Yellow background

---

## Usage Examples

### Monitor Real-Time Activity

1. Navigate to **Developer → App Logs**
2. Select your log file (e.g., `development`)
3. Logs will stream automatically
4. Watch for errors in real-time

### Debug an Error

1. Reproduce the error in your application
2. Pause the log stream
3. Search for "ERROR" or specific error messages
4. Review the stack trace
5. Copy relevant logs for documentation

### Review Specific Requests

1. Search for a specific path: `/api/users`
2. Or search for a session ID
3. View all related log entries
4. Copy to clipboard for analysis

### Download for Analysis

1. Click **Download** button
2. File downloads as `{log_file}-{date}.log`
3. Open in your preferred text editor
4. Use external tools for deeper analysis

### Clear Old Logs

1. Select the log file
2. Click **Clear File**
3. Confirm the action
4. Log file is truncated to 0 bytes

---

## Keyboard Shortcuts

- **⌘/Ctrl + F** - Focus search input
- **Home** - Scroll to top
- **End** - Scroll to bottom
- **Space** - Pause/Resume (when focused)

---

## Technical Details

### How It Works

1. **Server-Sent Events (SSE)**: Keeps persistent connection for real-time updates
2. **Tail Functionality**: Starts with last 100 lines, then streams new ones
3. **Non-Blocking**: Doesn't impact application performance
4. **Auto-Reconnect**: Automatically reconnects if connection drops

### Performance

- **Memory Management**: Keeps max 1000 lines in browser memory
- **Efficient Streaming**: Only new lines are sent over the network
- **Background Processing**: Runs in separate thread, no blocking

### File Limits

- Display buffer: 1000 lines
- Initial load: Last 100 lines
- Search results: Max 100 matches
- File size: No limit (any size log file)

---

## API Endpoints

### GET /admin/logs
Main logs viewer page

### GET /admin/logs/stream?file={name}
Server-Sent Events stream for real-time logs

**Parameters:**
- `file` - Log file name (default: development)
- `lines` - Number of initial lines (default: 100)

**Response:** text/event-stream

### GET /admin/logs/download?file={name}
Download full log file

**Parameters:**
- `file` - Log file name

**Response:** text/plain attachment

### DELETE /admin/logs/clear?file={name}
Clear (truncate) log file

**Parameters:**
- `file` - Log file name

### GET /admin/logs/search?file={name}&q={query}
Search within log file

**Parameters:**
- `file` - Log file name
- `q` - Search query

**Response:** JSON with search results

---

## Common Use Cases

### Monitoring Production

```bash
# In production, monitor logs in real-time:
1. Navigate to Admin → Logs
2. Select "production" log file
3. Keep window open
4. Watch for errors and warnings
```

### Debugging API Issues

```bash
# Find API-related logs:
1. Search for "/api/"
2. Review request/response logs
3. Check for 4xx/5xx errors
4. Copy relevant logs
```

### Performance Analysis

```bash
# Find slow queries:
1. Search for "Completed in"
2. Look for high millisecond values
3. Identify slow endpoints
4. Copy for optimization
```

### Error Investigation

```bash
# When user reports error:
1. Get timestamp from user
2. Search for that timestamp
3. Review full error context
4. Check stack trace
5. Download logs for team review
```

---

## Tips & Best Practices

### 1. Use Pause for Errors

When you see an error flash by:
- Hit **Pause** immediately
- Scroll up to review
- Search for "ERROR" to highlight all errors
- Take your time to analyze

### 2. Search Effectively

Be specific:
- ✅ Good: "NoMethodError"
- ✅ Good: "POST /api/users"
- ✅ Good: "session_id=abc123"
- ❌ Bad: "error" (too broad)

### 3. Regular Downloads

For production:
- Download logs daily
- Archive for compliance
- Use for trend analysis
- Keep for incident investigation

### 4. Clear Strategically

Only clear when:
- Log file is huge (>100MB)
- You've archived important logs
- Starting fresh debugging session
- Never clear production logs without backup

### 5. Multiple Windows

Power user tip:
- Open multiple browser windows
- Monitor different log files simultaneously
- One for development.log
- One for sidekiq.log
- Spot correlations

---

## Troubleshooting

### Logs Not Streaming

**Check:**
1. Is the server running?
2. Any firewall blocking SSE?
3. Check browser console for errors
4. Try refreshing the page

**Fix:**
```bash
# Restart Rails server
./railspress restart
```

### Connection Drops

**Cause:** Network timeout or server restart

**Fix:** Page auto-reconnects after 3 seconds

### Search Not Working

**Check:**
1. Is search query too broad?
2. Try exact text from logs
3. Search is case-insensitive

### File Not Found

**Cause:** Log file doesn't exist yet

**Fix:** Application creates log files on first write

---

## Advanced Configuration

### Custom Log Files

Add custom log files to appear in selector:

```ruby
# config/application.rb
config.logger = ActiveSupport::Logger.new(Rails.root.join('log', 'custom.log'))
```

### Log Rotation

Prevent logs from growing too large:

```ruby
# config/environments/production.rb
config.logger = ActiveSupport::Logger.new(
  Rails.root.join('log', 'production.log'),
  10,                    # Keep 10 files
  10 * 1024 * 1024       # 10 MB per file
)
```

### Custom Log Format

Improve readability:

```ruby
# config/application.rb
config.log_formatter = ::Logger::Formatter.new
```

### Lograge Integration

For cleaner, single-line logs:

```ruby
# Gemfile
gem 'lograge'

# config/environments/production.rb
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
```

---

## Security Considerations

### Access Control

- ✅ Only administrators can access logs
- ✅ Requires authentication
- ✅ Uses Pundit for authorization
- ✅ Audit trail in admin activity logs

### Sensitive Data

**Be Careful:**
- Don't log passwords
- Don't log credit cards
- Don't log API keys
- Filter sensitive params

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :api_key, :secret, :token, :ssn, :credit_card
]
```

### Production Best Practices

1. **Restrict Access**: Only ops team
2. **Download Only**: No clear in production
3. **Audit Access**: Log who views logs
4. **Rotate Regularly**: Use log rotation
5. **Monitor Size**: Alert on large files

---

## Comparison with Alternatives

### vs tail -f

**RailsPress Logs Advantages:**
- ✅ No SSH required
- ✅ Beautiful UI with colors
- ✅ Search functionality
- ✅ Pause and review
- ✅ Copy to clipboard
- ✅ Access from anywhere

### vs Log Management Services

**RailsPress Logs:**
- ✅ Free, included
- ✅ No external service
- ✅ Full privacy
- ✅ Instant access
- ✅ No data limits

**External Services (Papertrail, Loggly, etc):**
- ✅ Better for multiple servers
- ✅ Long-term storage
- ✅ Advanced analytics
- ✅ Alerting

**Best Approach:** Use both!
- RailsPress for development & quick checks
- External service for production & long-term

---

## Real-World Examples

### Example 1: Production Error

```
User reports: "I got an error when creating a post"

Steps:
1. Go to Admin → Logs
2. Select "production.log"
3. Search for "POST /admin/posts"
4. Find the error: "ActiveRecord::RecordInvalid"
5. See validation: "Title can't be blank"
6. Fix validation message in UI
```

### Example 2: Performance Issue

```
Site is slow, investigate:

1. Open logs
2. Search for "Completed in"
3. Find: "Completed 200 OK in 5432ms"
4. Identify slow query
5. Add database index
```

### Example 3: API Debugging

```
Third-party integration failing:

1. Search for API endpoint
2. Find request parameters
3. See response: "401 Unauthorized"
4. Check API key is correct
5. Copy full request/response for support
```

---

## Files Modified

- `app/controllers/admin/logs_controller.rb` - Controller
- `app/javascript/controllers/log_viewer_controller.js` - Stimulus controller
- `app/views/admin/logs/index.html.erb` - View
- `config/routes.rb` - Routes
- `app/views/layouts/admin.html.erb` - Menu item

---

## Quick Reference

### Access
```
URL: /admin/logs
Menu: Developer → App Logs
```

### Controls
```
Pause/Resume: Toggle streaming
Auto-scroll: Toggle auto-scroll
Search: Filter logs
Download: Export file
Clear: Truncate file
```

### Colors
```
DEBUG: Gray
INFO: Blue
WARN: Yellow
ERROR: Red (bold)
FATAL: Dark Red (bold)
```

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: October 12, 2025  
**Location**: Developer → App Logs

Ready to monitor your application in real-time! 🚀



