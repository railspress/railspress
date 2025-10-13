# URL Redirects System - Complete Guide

## Overview

RailsPress includes a comprehensive URL redirect management system that handles 301/302 redirects natively at the middleware level for optimal performance. This system helps preserve SEO value when pages are moved or renamed.

## Features

### Core Features
- **Native Redirect Handling**: Middleware-level processing for maximum performance
- **Multiple Redirect Types**: 301 (Permanent), 302 (Temporary), 303 (See Other), 307 (Temporary New)
- **Wildcard Support**: Redirect entire directory structures with wildcard paths
- **Hit Tracking**: Monitor redirect usage and popularity
- **CSV Import/Export**: Bulk manage redirects via CSV files
- **Active/Inactive Toggle**: Easily enable or disable redirects without deleting
- **Version History**: Full audit trail via PaperTrail
- **Multi-tenancy Support**: Isolated redirects per tenant
- **Circular Redirect Detection**: Prevents infinite redirect loops
- **Query String Preservation**: Maintains URL parameters through redirects

### UI Features
- Modern dark-themed admin interface
- Statistics dashboard (total, active, inactive, total hits)
- Advanced filtering and search
- Bulk actions (activate, deactivate, delete)
- Import/Export functionality
- Inline editing and quick toggle

---

## Quick Start

### 1. Access Redirects Management

Navigate to: **Settings → Redirects** in the admin panel

Or directly: `/admin/redirects`

### 2. Create Your First Redirect

1. Click "Add Redirect"
2. Enter the source path (e.g., `/old-page`)
3. Enter the destination path (e.g., `/new-page`)
4. Choose redirect type (301 recommended for SEO)
5. Click "Create Redirect"

### 3. Test the Redirect

Visit `https://yoursite.com/old-page` and verify it redirects to the new location.

---

## Redirect Types

### 301 - Permanent Redirect
- **Use case**: Page has permanently moved
- **SEO impact**: Search engines transfer page authority to new URL
- **Browser behavior**: Browsers cache the redirect
- **Best for**: Site restructuring, old content moved to new URLs

### 302 - Temporary Redirect
- **Use case**: Page is temporarily at a different location
- **SEO impact**: Search engines keep original URL indexed
- **Browser behavior**: No caching, always checks server
- **Best for**: Maintenance pages, A/B testing, temporary moves

### 303 - See Other
- **Use case**: POST requests redirected to GET
- **SEO impact**: Similar to 302
- **Browser behavior**: Changes request method to GET
- **Best for**: Form submissions, API responses

### 307 - Temporary Redirect (Preserves Method)
- **Use case**: Temporary redirect that preserves HTTP method
- **SEO impact**: Similar to 302
- **Browser behavior**: Maintains POST/GET/etc. method
- **Best for**: API endpoints, webhook endpoints

---

## Path Patterns

### Exact Paths

```
From: /old-blog-post
To:   /blog/new-post
```

Redirects only the exact path `/old-blog-post`.

### Wildcard Paths

```
From: /old-blog/*
To:   /blog/*
```

Redirects all paths starting with `/old-blog/`:
- `/old-blog/post-1` → `/blog/post-1`
- `/old-blog/category/tech` → `/blog/category/tech`

### External URLs

```
From: /link
To:   https://external-site.com/page
```

Redirects to external domains.

### Root Path

```
From: /
To:   /home
```

Redirects the homepage (use with caution).

---

## Admin Interface

### Redirects List

The main redirects page shows:
- **From Path**: Source URL being redirected
- **To Path**: Destination URL
- **Type**: Redirect type and HTTP status code
- **Status**: Active or Inactive
- **Hits**: Number of times redirect was used
- **Actions**: Edit, Toggle, Delete buttons

### Statistics Cards

- **Total Redirects**: All redirects in the system
- **Active**: Currently enabled redirects
- **Inactive**: Disabled redirects
- **Total Hits**: Combined hit count across all redirects

### Filters

Filter redirects by:
- **Search**: Search paths and notes
- **Status**: All, Active, or Inactive
- **Type**: All types or specific redirect type

### Bulk Actions

Select multiple redirects and:
- Activate all selected
- Deactivate all selected
- Delete all selected

---

## Import/Export

### Export to CSV

1. Click "Export CSV" button
2. Downloads `redirects-YYYY-MM-DD.csv`
3. Contains all redirects with full details

### Import from CSV

1. Prepare CSV file with columns:
   - `From Path` (required)
   - `To Path` (required)
   - `Type` (optional, defaults to "permanent")
   - `Notes` (optional)

2. Example CSV:
```csv
From Path,To Path,Type,Notes
/old-page,/new-page,permanent,Page moved
/blog/old-post,/blog/new-post,permanent,
/temp,/temporary,temporary,Temporary redirect
/old-blog/*,/blog/*,permanent,Wildcard redirect
```

3. Click "Import CSV" in admin
4. Upload file
5. Review results

---

## API Reference

### Model: Redirect

#### Attributes

- `from_path` (string, required): Source URL path
- `to_path` (string, required): Destination URL
- `redirect_type` (enum): permanent, temporary, see_other, temporary_new
- `status_code` (integer): HTTP status code (301, 302, 303, 307)
- `hits_count` (integer): Number of redirect hits
- `active` (boolean): Whether redirect is enabled
- `notes` (text): Optional notes
- `tenant_id` (integer): Multi-tenancy support

#### Methods

##### `record_hit!`
Increments the hit counter.

```ruby
redirect.record_hit!
```

##### `http_status_code`
Returns the appropriate HTTP status code.

```ruby
redirect.http_status_code # => 301
```

##### `matches?(path)`
Check if redirect matches a given path.

```ruby
redirect.matches?('/old-page') # => true
redirect.matches?('/other-page') # => false
```

##### `destination_for(request_path)`
Get the destination for a wildcard redirect.

```ruby
redirect = Redirect.new(from_path: '/old/*', to_path: '/new/*')
redirect.destination_for('/old/page') # => '/new/page'
```

#### Scopes

```ruby
Redirect.active          # Active redirects only
Redirect.inactive        # Inactive redirects only
Redirect.by_type(:permanent) # Filter by type
Redirect.most_used       # Order by hits_count DESC
Redirect.recent          # Order by created_at DESC
```

#### Class Methods

##### `find_for_path(path)`
Find the first matching redirect for a path.

```ruby
redirect = Redirect.find_for_path('/old-page')
```

##### `import_redirects(data)`
Bulk import redirects from array of hashes.

```ruby
data = [
  { from_path: '/old-1', to_path: '/new-1', redirect_type: 'permanent' },
  { from_path: '/old-2', to_path: '/new-2', redirect_type: 'temporary' }
]

result = Redirect.import_redirects(data)
# => { imported: 2, errors: [] }
```

##### `to_csv`
Export all redirects to CSV format.

```ruby
csv = Redirect.to_csv
File.write('redirects.csv', csv)
```

---

## Middleware

### RedirectHandler

The `RedirectHandler` middleware intercepts requests and handles redirects before they reach the Rails router.

#### How It Works

1. Request comes in
2. Check if path should skip redirect handling (admin, API, assets, etc.)
3. Look up matching redirect in database
4. If found:
   - Record hit
   - Determine destination (handle wildcards)
   - Preserve query string
   - Return redirect response with appropriate status code
5. If not found:
   - Continue to Rails application

#### Skipped Paths

The middleware automatically skips:
- `/admin/*` - Admin panel
- `/api/*` - API endpoints
- `/assets/*`, `/packs/*`, `/uploads/*` - Static assets
- `/rails/*` - Rails internal paths
- `/cable/*` - Action Cable
- `/up` - Health check

#### Performance

- Runs at Rack middleware level (before Rails router)
- Minimal database queries (indexed lookups)
- Permanent redirects include cache headers
- No impact on non-redirected requests

---

## Best Practices

### SEO Best Practices

1. **Use 301 for Permanent Moves**
   ```ruby
   Redirect.create!(
     from_path: '/old-product',
     to_path: '/products/new-product',
     redirect_type: 'permanent'
   )
   ```

2. **Redirect Old URLs to New URLs Immediately**
   - Don't wait for search engines to notice
   - Implement redirects as soon as you change URL structure

3. **Avoid Redirect Chains**
   - Bad: `/a` → `/b` → `/c`
   - Good: `/a` → `/c` and `/b` → `/c`

4. **Use Descriptive Notes**
   ```ruby
   Redirect.create!(
     from_path: '/blog/2023/old-post',
     to_path: '/blog/seo-optimized-title',
     redirect_type: 'permanent',
     notes: 'Old URL structure migration - Jan 2024'
   )
   ```

### Wildcard Best Practices

1. **Be Specific**
   ```ruby
   # Good
   from_path: '/old-blog/*'
   to_path: '/blog/*'
   
   # Too broad
   from_path: '/*'
   to_path: '/new/*'
   ```

2. **Test Thoroughly**
   - Test with various path depths
   - Verify query strings are preserved
   - Check edge cases

### Performance Best Practices

1. **Keep Active Redirects Minimal**
   - Remove obsolete redirects after 6-12 months
   - Monitor hit counts
   - Deactivate unused redirects

2. **Use Exact Matches When Possible**
   - Exact matches are faster than wildcards
   - Consider multiple exact redirects vs. one wildcard

3. **Monitor Hit Counts**
   - High hit counts indicate important redirects
   - Zero hits after 3+ months might be safe to remove

---

## Testing

### Manual Testing

1. Create a test redirect:
   ```ruby
   Redirect.create!(
     from_path: '/test-old',
     to_path: '/test-new',
     redirect_type: 'permanent',
     active: true
   )
   ```

2. Visit `/test-old` in browser
3. Verify:
   - Redirects to `/test-new`
   - HTTP status is 301
   - Query strings preserved (`/test-old?foo=bar` → `/test-new?foo=bar`)

### RSpec Testing

```ruby
RSpec.describe Redirect, type: :model do
  describe 'validations' do
    it 'requires from_path and to_path' do
      redirect = Redirect.new
      expect(redirect).not_to be_valid
      expect(redirect.errors[:from_path]).to be_present
      expect(redirect.errors[:to_path]).to be_present
    end
    
    it 'prevents circular redirects' do
      Redirect.create!(from_path: '/a', to_path: '/b')
      redirect = Redirect.new(from_path: '/b', to_path: '/a')
      expect(redirect).not_to be_valid
    end
  end
  
  describe '#matches?' do
    it 'matches exact paths' do
      redirect = Redirect.create!(from_path: '/old', to_path: '/new')
      expect(redirect.matches?('/old')).to be true
      expect(redirect.matches?('/other')).to be false
    end
    
    it 'matches wildcard paths' do
      redirect = Redirect.create!(from_path: '/old/*', to_path: '/new/*')
      expect(redirect.matches?('/old/page')).to be true
      expect(redirect.matches?('/old/deep/page')).to be true
      expect(redirect.matches?('/other/page')).to be false
    end
  end
  
  describe '#destination_for' do
    it 'handles wildcard redirects' do
      redirect = Redirect.create!(from_path: '/old/*', to_path: '/new/*')
      expect(redirect.destination_for('/old/page')).to eq('/new/page')
      expect(redirect.destination_for('/old/deep/path')).to eq('/new/deep/path')
    end
  end
end
```

### Integration Testing

```ruby
RSpec.describe 'Redirect Middleware', type: :request do
  it 'redirects matching paths' do
    Redirect.create!(
      from_path: '/old-page',
      to_path: '/new-page',
      redirect_type: 'permanent',
      active: true
    )
    
    get '/old-page'
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('/new-page')
  end
  
  it 'preserves query strings' do
    Redirect.create!(from_path: '/old', to_path: '/new', active: true)
    
    get '/old?foo=bar&baz=qux'
    expect(response).to redirect_to('/new?foo=bar&baz=qux')
  end
  
  it 'does not redirect admin paths' do
    Redirect.create!(from_path: '/admin', to_path: '/elsewhere', active: true)
    
    get '/admin'
    expect(response).not_to be_redirect
  end
end
```

---

## Troubleshooting

### Redirect Not Working

**Symptoms**: Visiting old URL doesn't redirect

**Checks**:
1. Is redirect active? Check the Status column
2. Is the path exact? Remember paths are case-sensitive
3. Is it cached? Try incognito/private browsing
4. Check Rails logs for errors
5. Verify middleware is loaded: `rails middleware | grep Redirect`

### Redirect Loop

**Symptoms**: Browser shows "Too many redirects" error

**Cause**: Circular redirects (A → B → A)

**Fix**:
1. Check for circular references in admin
2. Model validation should prevent this, but check manually:
   ```ruby
   Redirect.where(to_path: Redirect.where(from_path: '/a').pluck(:to_path))
   ```

### Wrong Status Code

**Symptoms**: Redirect works but wrong HTTP status

**Fix**:
1. Check `redirect_type` value
2. Verify `status_code` field
3. Clear browser cache (301s are heavily cached)

### Wildcard Not Working

**Symptoms**: Wildcard redirect only works for exact match

**Checks**:
1. Ensure wildcard is at END of path: `/old/*` not `/*/old`
2. Check `matches?` method in model
3. Verify destination also has wildcard: `/new/*`

---

## Migration Guide

### From WordPress

WordPress `.htaccess` rules can be converted to redirects:

```apache
# WordPress .htaccess
RewriteRule ^old-page$ /new-page [R=301,L]
```

Becomes:

```ruby
Redirect.create!(
  from_path: '/old-page',
  to_path: '/new-page',
  redirect_type: 'permanent'
)
```

For bulk imports, create CSV and use import feature.

### From Nginx

Nginx redirects:

```nginx
rewrite ^/old-page$ /new-page permanent;
```

Convert to RailsPress redirects via CSV import.

---

## Advanced Usage

### Programmatic Creation

```ruby
# In a migration or seed file
Redirect.create!([
  { from_path: '/products/*', to_path: '/shop/*', redirect_type: 'permanent' },
  { from_path: '/blog/category/*', to_path: '/categories/*', redirect_type: 'permanent' },
  { from_path: '/old-contact', to_path: '/contact', redirect_type: 'permanent' }
])
```

### Dynamic Redirects from Database

```ruby
# Redirect all old product SKUs to new URLs
OldProduct.find_each do |old_product|
  Redirect.create!(
    from_path: "/products/#{old_product.sku}",
    to_path: "/shop/#{old_product.slug}",
    redirect_type: 'permanent',
    notes: "Migrated from old product system"
  )
end
```

### Redirect Based on Conditions

```ruby
# In a custom middleware or controller
class FeatureRedirectMiddleware
  def call(env)
    request = Rack::Request.new(env)
    
    if request.path.start_with?('/beta') && !beta_enabled?
      return [301, {'Location' => '/coming-soon'}, ['']]
    end
    
    @app.call(env)
  end
end
```

---

## Monitoring & Maintenance

### Regular Maintenance Tasks

1. **Monthly Review**
   ```ruby
   # Find unused redirects
   Redirect.where('hits_count = 0 AND created_at < ?', 3.months.ago)
   
   # Find most used
   Redirect.most_used.limit(10)
   ```

2. **Quarterly Cleanup**
   - Remove obsolete redirects (zero hits for 6+ months)
   - Archive to CSV before deleting
   - Check for redirect chains

3. **Annual Audit**
   - Review all active redirects
   - Verify destination URLs still exist
   - Update notes with current context

### Analytics Integration

Track redirects in Google Analytics:

```ruby
# Add to application_controller.rb or middleware
def track_redirect(from, to)
  # Send to analytics
  Analytics.track(
    event: 'redirect',
    properties: {
      from_path: from,
      to_path: to,
      timestamp: Time.current
    }
  )
end
```

---

## Summary

The RailsPress Redirects system provides:

✅ **Native redirect handling** at middleware level  
✅ **Multiple redirect types** (301, 302, 303, 307)  
✅ **Wildcard support** for bulk redirects  
✅ **Hit tracking** for monitoring  
✅ **CSV import/export** for bulk management  
✅ **Modern admin UI** with filtering and search  
✅ **SEO-friendly** with proper HTTP status codes  
✅ **Performance optimized** with minimal overhead  
✅ **Multi-tenant ready** for SaaS applications  

Perfect for:
- Site migrations
- URL structure changes
- SEO preservation
- Content reorganization
- Legacy URL support

---

## Support

For issues or questions:
1. Check this guide
2. Review the source code in `/app/models/redirect.rb`
3. Check middleware in `/app/middleware/redirect_handler.rb`
4. Open an issue on GitHub

---

**Version**: 1.0.0  
**Last Updated**: October 12, 2025  
**Status**: ✅ Production Ready



