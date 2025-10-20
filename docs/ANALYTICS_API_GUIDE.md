# RailsPress Analytics API Guide

A comprehensive JavaScript API for tracking custom events and analytics in RailsPress themes and plugins.

## Quick Start

The RailsPress Analytics API is automatically available as `window.railspressAnalytics`:

```javascript
// Track a simple event
railspressAnalytics.track('button_click', {
  button_name: 'subscribe',
  button_location: 'header'
});
```

## Basic Tracking

### Custom Events
```javascript
// Track any custom event
railspressAnalytics.track('custom_event', {
  property1: 'value1',
  property2: 'value2'
});

// Track with options
railspressAnalytics.track('important_event', {
  data: 'important'
}, {
  force: true // Track even without consent
});
```

### E-commerce Tracking
```javascript
// Initialize e-commerce
railspressAnalytics.initEcommerce({
  currency: 'USD',
  storeName: 'My Store'
});

// Track product views
railspressAnalytics.trackProductView({
  id: 'product-123',
  name: 'Awesome Product',
  category: 'Electronics',
  price: 99.99
});

// Track purchases
railspressAnalytics.trackTransaction({
  id: 'order-456',
  value: 199.98,
  currency: 'USD',
  items: [
    { id: 'product-123', name: 'Awesome Product', price: 99.99, quantity: 2 }
  ]
});
```

## Plugin Development

### Register Your Plugin
```javascript
// Register your plugin
railspressAnalytics.registerPlugin('my-awesome-plugin', {
  version: '1.0.0',
  type: 'e-commerce'
});

// Track plugin events
railspressAnalytics.trackPluginEvent('my-awesome-plugin', 'feature_used', {
  feature_name: 'bulk_upload',
  items_uploaded: 50
});
```

### E-commerce Plugin Example
```javascript
class MyEcommercePlugin {
  constructor() {
    // Initialize e-commerce tracking
    railspressAnalytics.initEcommerce({
      currency: this.getCurrency(),
      storeName: this.getStoreName()
    });
    
    // Register plugin
    railspressAnalytics.registerPlugin('my-ecommerce', {
      version: '1.0.0',
      type: 'e-commerce'
    });
    
    this.setupTracking();
  }
  
  setupTracking() {
    // Track add to cart
    document.addEventListener('click', (event) => {
      if (event.target.matches('.add-to-cart')) {
        const product = this.getProductFromElement(event.target);
        railspressAnalytics.trackAddToCart(product);
      }
    });
  }
}
```

## Theme Integration

### Data Attributes
Use data attributes for automatic tracking:

```html
<!-- Track clicks -->
<button data-analytics-track="button_click" 
        data-analytics-button-name="subscribe">
  Subscribe
</button>

<!-- Track views -->
<div data-analytics-view="section_viewed" 
     data-analytics-section-name="hero">
  Hero Section
</div>

<!-- Track custom events -->
<a href="#" data-track-event="custom_click" 
   data-track-data-category="navigation">
  Custom Link
</a>
```

### Theme Events
```javascript
// Track theme-specific events
railspressAnalytics.trackThemeEvent('menu_toggle', {
  menu_location: 'mobile',
  menu_state: 'opened'
});

// Track responsive breakpoint changes
railspressAnalytics.trackBreakpointChange('tablet');
```

## Advanced Features

### User Properties
```javascript
// Set user properties
railspressAnalytics.setUserProperties({
  user_type: 'premium',
  subscription_plan: 'pro'
});

// Set custom dimensions
railspressAnalytics.setCustomDimensions({
  dimension1: 'mobile_user',
  dimension2: 'high_value_customer'
});
```

### Form Tracking
```javascript
// Track form submissions
railspressAnalytics.trackFormSubmit('contact_form', {
  type: 'contact',
  success: true
});

// Track form field interactions
railspressAnalytics.track('form_field_focus', {
  field_name: 'email',
  field_type: 'email'
});
```

### Video Tracking
```javascript
// Track video interactions
railspressAnalytics.trackVideo('intro-video', 'play', 0);
railspressAnalytics.trackVideo('intro-video', 'complete', 100);
```

### Search Tracking
```javascript
// Track search events
railspressAnalytics.trackSearch('laptop computers', {
  resultsCount: 25,
  category: 'electronics'
});
```

## Utility Functions

### Auto-tracking Helpers
```javascript
// Track element visibility
railspressAnalyticsUtils.trackVisibility('.track-view', 'element_viewed');

// Track time on page
railspressAnalyticsUtils.trackTimeOnPage();

// Track form abandonment
railspressAnalyticsUtils.trackFormAbandonment('.contact-form');
```

### Performance Tracking
```javascript
// Track page performance
railspressPerformance.trackPageLoadPerformance();

// Track resource loading
railspressPerformance.setupResourceTracking();
```

## Error Handling

### Track Errors
```javascript
// Track JavaScript errors
window.addEventListener('error', (event) => {
  railspressAnalytics.track('javascript_error', {
    error_message: event.message,
    error_filename: event.filename,
    error_lineno: event.lineno
  });
});

// Track plugin errors
railspressAnalytics.trackPluginError('my-plugin', 'Upload failed', {
  context: 'bulk_upload',
  error_code: 'FILE_TOO_LARGE'
});
```

## Best Practices

### 1. Use Descriptive Event Names
```javascript
// Good
railspressAnalytics.track('product_added_to_cart', { product_id: '123' });

// Bad
railspressAnalytics.track('click', { id: '123' });
```

### 2. Include Relevant Properties
```javascript
// Good
railspressAnalytics.track('newsletter_signup', {
  source: 'footer',
  campaign: 'summer_sale',
  user_type: 'new_visitor'
});

// Bad
railspressAnalytics.track('newsletter_signup', {});
```

### 3. Use Consistent Property Names
```javascript
// Good - consistent naming
railspressAnalytics.track('product_view', { product_id: '123' });
railspressAnalytics.track('product_purchase', { product_id: '123' });

// Bad - inconsistent naming
railspressAnalytics.track('product_view', { product_id: '123' });
railspressAnalytics.track('product_purchase', { item_id: '123' });
```

### 4. Handle Consent
```javascript
// Check consent before tracking
if (railspressAnalytics.consent) {
  railspressAnalytics.track('sensitive_event', { data: 'sensitive' });
}

// Or force tracking for essential events
railspressAnalytics.track('essential_event', { data: 'essential' }, { force: true });
```

## Integration Examples

### WooCommerce-style Plugin
```javascript
class RailsPressEcommerce {
  constructor() {
    railspressAnalytics.initEcommerce({
      currency: 'USD',
      storeName: 'My Store'
    });
    
    this.setupProductTracking();
    this.setupCartTracking();
    this.setupCheckoutTracking();
  }
  
  setupProductTracking() {
    // Track product views
    if (this.isProductPage()) {
      const product = this.getCurrentProduct();
      railspressAnalytics.trackProductView(product);
    }
  }
  
  setupCartTracking() {
    // Track add to cart
    document.addEventListener('click', (event) => {
      if (event.target.matches('.add-to-cart')) {
        const product = this.getProductFromElement(event.target);
        railspressAnalytics.trackAddToCart(product);
      }
    });
  }
}
```

### Membership Plugin
```javascript
class RailsPressMembership {
  constructor() {
    railspressAnalytics.registerPlugin('membership', {
      version: '1.0.0',
      type: 'membership'
    });
    
    this.setupRegistrationTracking();
    this.setupSubscriptionTracking();
  }
  
  setupRegistrationTracking() {
    document.addEventListener('submit', (event) => {
      if (event.target.matches('.registration-form')) {
        railspressAnalytics.trackConversion('user_registration', 0, {
          source: 'registration_page'
        });
      }
    });
  }
}
```

## API Reference

### Core Methods
- `track(eventName, properties, options)` - Track a custom event
- `trackTransaction(transaction)` - Track e-commerce transactions
- `trackProductView(product)` - Track product views
- `trackAddToCart(item)` - Track add to cart events
- `trackSearch(searchTerm, options)` - Track search events
- `trackFormSubmit(formName, formData)` - Track form submissions
- `trackDownload(fileName, fileType, fileSize)` - Track file downloads
- `trackVideo(videoId, action, progress)` - Track video interactions
- `trackEngagement(engagementType, details)` - Track user engagement
- `trackConversion(conversionType, value, details)` - Track conversions

### Plugin Methods
- `registerPlugin(pluginName, pluginData)` - Register a plugin
- `trackPluginEvent(pluginName, eventName, properties)` - Track plugin events
- `trackPluginError(pluginName, error, details)` - Track plugin errors

### Utility Methods
- `setUserProperties(properties)` - Set user properties
- `setCustomDimensions(dimensions)` - Set custom dimensions
- `flush()` - Send queued events to server

### Properties
- `version` - API version
- `sessionId` - Current session ID
- `userId` - Current user ID
- `consent` - User consent status
- `isInitialized` - Initialization status

## Support

For more examples and detailed documentation, see:
- `railspress-analytics-docs.js` - Comprehensive documentation
- `railspress-analytics-helpers.js` - Utility functions
- `railspress-analytics-examples.js` - Real-world examples

## License

This API is part of RailsPress and follows the same license terms.
