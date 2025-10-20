# RailsPress Consent Management System

## Overview

The RailsPress Consent Management System is an enterprise-grade solution that rivals OneTrust, providing comprehensive GDPR/CCPA compliance with geolocation-based consent rules, pixel management, and seamless Liquid template integration.

## Features

### 🚀 Core Features

- **OneTrust-Level Functionality**: Comprehensive consent management that matches enterprise solutions
- **GDPR/CCPA Compliance**: Full compliance with privacy regulations
- **Geolocation-Based Rules**: Automatic region detection with specific consent rules
- **Pixel Management**: Consent-aware loading for all tracking pixels
- **Customizable Banner**: Fully customizable consent banner with themes and colors
- **Liquid Integration**: Seamless integration with Liquid templates
- **Admin Interface**: Complete admin interface for consent management
- **API Endpoints**: RESTful API for consent management
- **Analytics**: Built-in analytics and compliance reporting

### 🎯 Key Capabilities

1. **Consent Categories**
   - Necessary Cookies (always required)
   - Analytics Cookies (Google Analytics, etc.)
   - Marketing Cookies (Facebook Pixel, TikTok, etc.)
   - Functional Cookies (Mixpanel, Segment, etc.)

2. **Geolocation Support**
   - EU countries (GDPR opt-in)
   - US states (CCPA opt-out)
   - UK countries (GDPR opt-in)
   - Canada provinces (PIPEDA opt-in)
   - Automatic fallback for unknown regions

3. **Pixel Integration**
   - Google Analytics
   - Google Tag Manager
   - Facebook Pixel
   - TikTok Pixel
   - LinkedIn Insight Tag
   - Twitter Pixel
   - Pinterest Tag
   - Snapchat Pixel
   - Reddit Pixel
   - Hotjar
   - Microsoft Clarity
   - Mixpanel
   - Segment
   - Heap Analytics
   - Custom pixels

## Installation & Setup

### 1. Database Migration

The consent system is automatically installed with RailsPress. Run migrations to create the necessary tables:

```bash
bin/rails db:migrate
```

### 2. Default Configuration

A default consent configuration is automatically created. You can customize it in the admin interface.

### 3. Admin Interface

Access the consent management interface at `/admin/consent`:

- **Dashboard**: Overview of consent statistics and configurations
- **Configurations**: Manage consent configurations
- **Pixel Management**: Configure pixel consent requirements
- **User Consents**: Manage user consent data
- **Analytics**: View consent analytics and reports
- **Compliance**: View compliance status and reports

## Usage

### Liquid Templates

The consent system integrates seamlessly with Liquid templates using simple tags:

#### Basic Usage

```liquid
<!-- Render consent banner and assets -->
{% consent_assets %}

<!-- Or render individual components -->
{% consent_banner %}
{% consent_css %}
{% consent_script %}
```

#### Advanced Usage

```liquid
<!-- Render consent-aware pixel -->
{% consent_pixel pixel_id %}

<!-- Check consent status -->
{% consent_status category %}

<!-- Render consent management link -->
{% consent_management_link "Manage Preferences" %}

<!-- Render consent configuration -->
{% consent_config %}

<!-- Render consent analytics -->
{% consent_analytics %}

<!-- Render compliance information -->
{% consent_compliance %}
```

### JavaScript Integration

The consent system includes a comprehensive JavaScript consent manager:

```javascript
// Initialize consent manager
const consentManager = new ConsentManager({
  config: {
    apiEndpoint: '/api/v1/consent',
    storageKey: 'railspress_consent',
    debug: true
  }
});

// Listen for consent events
consentManager.on('consent_granted', (data) => {
  console.log('Consent granted:', data);
});

consentManager.on('consent_withdrawn', (data) => {
  console.log('Consent withdrawn:', data);
});
```

### API Integration

The consent system provides RESTful API endpoints:

#### Get Consent Configuration

```bash
GET /api/v1/consent/configuration
```

#### Get User Region

```bash
GET /api/v1/consent/region
```

#### Save Consent

```bash
POST /api/v1/consent
Content-Type: application/json

{
  "consent": {
    "analytics": {
      "granted": true,
      "granted_at": "2025-10-18T13:40:00Z",
      "consent_text": "Analytics Cookies",
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0..."
    }
  },
  "region": "us",
  "timestamp": "2025-10-18T13:40:00Z"
}
```

#### Get Consent Status

```bash
GET /api/v1/consent/status
```

#### Get Pixels

```bash
GET /api/v1/consent/pixels
```

## Configuration

### Consent Configuration Model

The `ConsentConfiguration` model manages all consent settings:

```ruby
# Create a new consent configuration
consent_config = ConsentConfiguration.create!(
  name: 'My Consent Configuration',
  banner_type: 'bottom_banner', # or 'modal', 'overlay'
  consent_mode: 'opt_in', # or 'opt_out', 'implied'
  active: true,
  tenant: current_tenant
)
```

### Banner Settings

Customize the consent banner appearance:

```ruby
banner_settings = {
  'enabled' => true,
  'position' => 'bottom',
  'theme' => 'dark',
  'show_manage_preferences' => true,
  'show_reject_all' => true,
  'show_accept_all' => true,
  'show_necessary_only' => true,
  'auto_hide_after_accept' => true,
  'auto_hide_delay' => 3000,
  'animation_duration' => 300,
  'custom_css' => '',
  'text' => {
    'title' => 'We use cookies to enhance your experience',
    'description' => 'We use cookies and similar technologies...',
    'accept_all' => 'Accept All',
    'reject_all' => 'Reject All',
    'necessary_only' => 'Necessary Only',
    'manage_preferences' => 'Manage Preferences',
    'save_preferences' => 'Save Preferences',
    'close' => 'Close'
  },
  'colors' => {
    'primary' => '#3b82f6',
    'secondary' => '#6b7280',
    'background' => '#1f2937',
    'text' => '#ffffff',
    'button_accept' => '#10b981',
    'button_reject' => '#ef4444',
    'button_neutral' => '#6b7280'
  },
  'fonts' => {
    'family' => 'system-ui, -apple-system, sans-serif',
    'size_title' => '18px',
    'size_description' => '14px',
    'size_button' => '14px'
  }
}
```

### Geolocation Settings

Configure region-specific consent rules:

```ruby
geolocation_settings = {
  'enabled' => true,
  'eu_countries' => %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE],
  'us_states' => %w[CA CO CT DE HI IL IA ME MD MA MI MN NH NJ NM NY OR PA RI TX UT VT VA WA],
  'uk_countries' => %w[GB],
  'canada_provinces' => %w[AB BC MB NB NL NS NT NU ON PE QC SK YT],
  'auto_detect' => true,
  'fallback_consent_mode' => 'opt_in',
  'region_specific_settings' => {
    'eu' => {
      'consent_mode' => 'opt_in',
      'show_detailed_preferences' => true,
      'require_explicit_consent' => true
    },
    'us' => {
      'consent_mode' => 'opt_out',
      'show_detailed_preferences' => false,
      'require_explicit_consent' => false
    }
  }
}
```

### Pixel Consent Mapping

Configure which pixels require which consent categories:

```ruby
pixel_consent_mapping = {
  'analytics' => ['google_analytics', 'google_tag_manager', 'clarity', 'hotjar'],
  'marketing' => ['facebook_pixel', 'tiktok_pixel', 'linkedin_insight', 'twitter_pixel', 'pinterest_tag', 'snapchat_pixel', 'reddit_pixel'],
  'functional' => ['mixpanel', 'segment', 'heap']
}
```

## Admin Interface

### Dashboard

The admin dashboard provides an overview of:

- Total consent configurations
- Active configurations
- Total user consents
- Granted consents
- Recent activity

### Configuration Management

- Create and edit consent configurations
- Test banner appearance
- Configure consent categories
- Set up geolocation rules
- Customize banner settings

### Pixel Management

- View all active pixels
- Configure pixel consent requirements
- Map pixels to consent categories
- Test pixel loading

### User Consent Management

- View user consent data
- Export user data
- Withdraw user consent
- Manage consent history

### Analytics & Reporting

- Consent analytics
- Compliance reports
- GDPR/CCPA compliance scores
- User consent trends

## Compliance Features

### GDPR Compliance

- **Data Subject Rights**: Access, rectification, erasure, portability, objection
- **Consent Management**: Explicit consent, consent withdrawal, consent records
- **Data Processing Records**: Processing activities, legal basis, data categories
- **Privacy by Design**: Consent banner, data minimization, purpose limitation

### CCPA Compliance

- **Consumer Rights**: Right to know, right to delete, right to opt-out
- **Opt-out Mechanism**: Clear opt-out process, opt-out confirmation
- **Data Disclosure**: Privacy policy, data categories, third-party sharing

### Compliance Scoring

The system provides automatic compliance scoring:

- **GDPR Score**: Based on implemented data subject rights and consent management
- **CCPA Score**: Based on consumer rights and opt-out mechanisms
- **Overall Score**: Combined compliance score

## Testing

### Test Script

Run the comprehensive test script to verify the consent system:

```bash
ruby test_consent_system.rb
```

### Frontend Demo

Open `test_consent_frontend.html` in a browser to see the consent banner in action.

### API Testing

Test the API endpoints using curl or your preferred API client:

```bash
# Test consent configuration endpoint
curl -X GET http://localhost:3000/api/v1/consent/configuration

# Test region detection
curl -X GET http://localhost:3000/api/v1/consent/region

# Test consent status
curl -X GET http://localhost:3000/api/v1/consent/status
```

## Best Practices

### 1. Consent Banner Placement

- Place the consent banner at the bottom of the page
- Ensure it's visible and accessible
- Use appropriate colors and contrast
- Make buttons clear and actionable

### 2. Consent Categories

- Clearly define consent categories
- Provide detailed descriptions
- Make necessary cookies always enabled
- Allow granular control over optional cookies

### 3. Pixel Management

- Map pixels to appropriate consent categories
- Test pixel loading with different consent states
- Ensure pixels don't load without proper consent
- Monitor pixel performance

### 4. User Experience

- Keep consent requests simple and clear
- Provide easy access to consent preferences
- Allow consent withdrawal at any time
- Respect user choices

### 5. Compliance

- Regularly audit consent records
- Monitor compliance scores
- Update consent configurations as needed
- Document consent processes

## Troubleshooting

### Common Issues

1. **Consent Banner Not Showing**
   - Check if consent configuration is active
   - Verify banner settings are enabled
   - Check user consent history

2. **Pixels Not Loading**
   - Verify pixel consent mapping
   - Check user consent status
   - Test pixel configuration

3. **Geolocation Not Working**
   - Check geolocation settings
   - Verify IP detection
   - Test with different IP addresses

4. **Liquid Tags Not Working**
   - Ensure consent tags are registered
   - Check template syntax
   - Verify consent configuration exists

### Debug Mode

Enable debug mode in the JavaScript consent manager:

```javascript
const consentManager = new ConsentManager({
  debug: true
});
```

This will log detailed information about consent operations.

## Support

For support with the RailsPress Consent Management System:

1. Check the documentation
2. Run the test script
3. Review the admin interface
4. Check the API endpoints
5. Contact the RailsPress team

## Conclusion

The RailsPress Consent Management System provides enterprise-grade consent management that rivals OneTrust, giving you complete control over your privacy compliance without external dependencies. With comprehensive GDPR/CCPA support, geolocation-based rules, and seamless integration, it's the perfect solution for modern web applications.

Your customers will never need to pay for external consent management again!
