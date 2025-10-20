/**
 * RailsPress Analytics Examples
 * 
 * Real-world examples for developers implementing analytics
 * 
 * @version 1.0.0
 * @author RailsPress
 */

/**
 * EXAMPLE 1: Basic Content Analytics Plugin
 * ========================================
 * 
 * This example shows how to implement analytics for content tracking
 */

class RailsPressContentAnalyticsPlugin {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Initialize content analytics
    window.railspressAnalytics.initContent({
      trackReadingTime: true,
      trackScrollDepth: true,
      trackEngagement: true
    })

    // Register plugin
    window.railspressAnalytics.registerPlugin('railspress-content-analytics', {
      version: '1.0.0',
      type: 'content-analytics'
    })

    // Setup tracking
    this.setupContentTracking()
    this.setupReadingTracking()
    this.setupEngagementTracking()
    this.setupInteractionTracking()
  }

  setupContentTracking() {
    // Track content page views
    if (this.isContentPage()) {
      const content = this.getCurrentContent()
      window.railspressAnalytics.trackContentView(content)
    }

    // Track content impressions on listing pages
    document.querySelectorAll('.content-item, .post-item').forEach(item => {
      const content = this.getContentFromElement(item)
      window.railspressAnalytics.trackContentImpressions([content])
    })
  }

  setupReadingTracking() {
    // Track reading time
    let startTime = Date.now()
    let readingTime = 0

    // Update reading time every 5 seconds
    setInterval(() => {
      readingTime = Math.round((Date.now() - startTime) / 1000)
      window.railspressAnalytics.trackReadingTime(readingTime)
    }, 5000)
  }

  setupEngagementTracking() {
    // Track scroll depth
    let maxScrollDepth = 0
    window.addEventListener('scroll', () => {
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      if (scrollDepth > maxScrollDepth) {
        maxScrollDepth = scrollDepth
        window.railspressAnalytics.trackScrollDepth(scrollDepth)
      }
    })
  }

  setupInteractionTracking() {
    // Track user interactions
    document.addEventListener('click', (event) => {
      if (event.target.matches('.content-link, .cta-button, .social-share, .read-more')) {
        window.railspressAnalytics.trackEvent('content_interaction', {
          element: event.target.tagName,
          text: event.target.textContent,
          href: event.target.href
        })
      }
    })
  }

  isContentPage() {
    return document.body.classList.contains('content-page') || 
           document.body.classList.contains('post-page') ||
           document.body.classList.contains('page-page')
  }

  getCurrentContent() {
    return {
      id: document.querySelector('[data-content-id]')?.dataset.contentId,
      title: document.querySelector('.content-title, .post-title, .page-title')?.textContent,
      type: document.body.classList.contains('post-page') ? 'post' : 'page',
      category: document.querySelector('[data-content-category]')?.dataset.contentCategory,
      author: document.querySelector('[data-content-author]')?.dataset.contentAuthor
    }
  }

  getContentFromElement(element) {
    return {
      id: element.querySelector('[data-content-id]')?.dataset.contentId,
      title: element.querySelector('.content-title, .post-title')?.textContent,
      type: 'content',
      category: element.querySelector('[data-content-category]')?.dataset.contentCategory
    }
  }
}

/**
 * EXAMPLE 2: Newsletter Subscription Analytics
 * ===========================================
 * 
 * Track newsletter subscriptions and email engagement
 */

class RailsPressNewsletterPlugin {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Register plugin
    window.railspressAnalytics.registerPlugin('railspress-newsletter', {
      version: '1.0.0',
      type: 'newsletter'
    })

    // Setup tracking
    this.setupSubscriptionTracking()
    this.setupEmailTracking()
  }

  setupSubscriptionTracking() {
    // Track newsletter subscriptions
    document.addEventListener('submit', (event) => {
      if (event.target.matches('.newsletter-form, .subscribe-form')) {
        const email = event.target.querySelector('input[type="email"]')?.value
        if (email) {
          window.railspressAnalytics.trackEvent('newsletter_subscribe', {
            email: email,
            source: event.target.dataset.source || 'unknown'
          })
        }
      }
    })
  }

  setupEmailTracking() {
    // Track email link clicks (for email campaigns)
    document.addEventListener('click', (event) => {
      if (event.target.matches('a[href*="email-campaign"]')) {
        window.railspressAnalytics.trackEvent('email_click', {
          campaign_id: event.target.dataset.campaignId,
          link_text: event.target.textContent,
          url: event.target.href
        })
      }
    })
  }
}

/**
 * EXAMPLE 3: Form Analytics Plugin
 * ================================
 * 
 * Track form submissions and user interactions
 */

class RailsPressFormAnalyticsPlugin {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Register plugin
    window.railspressAnalytics.registerPlugin('railspress-form-analytics', {
      version: '1.0.0',
      type: 'form-analytics'
    })

    // Setup tracking
    this.setupFormTracking()
    this.setupFieldTracking()
  }

  setupFormTracking() {
    // Track form submissions
    document.addEventListener('submit', (event) => {
      const form = event.target
      if (form.tagName === 'FORM') {
        window.railspressAnalytics.trackEvent('form_submit', {
          form_id: form.id || 'unnamed-form',
          form_action: form.action,
          form_method: form.method,
          field_count: form.querySelectorAll('input, textarea, select').length
        })
      }
    })
  }

  setupFieldTracking() {
    // Track form field interactions
    document.addEventListener('focus', (event) => {
      if (event.target.matches('input, textarea, select')) {
        window.railspressAnalytics.trackEvent('form_field_focus', {
          field_name: event.target.name,
          field_type: event.target.type,
          form_id: event.target.closest('form')?.id || 'unknown'
        })
      }
    })

    // Track form abandonment
    let formStartTime = null
    document.addEventListener('focus', (event) => {
      if (event.target.matches('input, textarea, select')) {
        if (!formStartTime) {
          formStartTime = Date.now()
        }
      }
    })

    document.addEventListener('blur', (event) => {
      if (event.target.matches('input, textarea, select') && formStartTime) {
        const timeSpent = Date.now() - formStartTime
        window.railspressAnalytics.trackEvent('form_field_time', {
          field_name: event.target.name,
          time_spent: timeSpent
        })
      }
    })
  }
}

/**
 * EXAMPLE 4: Search Analytics Plugin
 * ==================================
 * 
 * Track search queries and search result interactions
 */

class RailsPressSearchAnalyticsPlugin {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Register plugin
    window.railspressAnalytics.registerPlugin('railspress-search-analytics', {
      version: '1.0.0',
      type: 'search-analytics'
    })

    // Setup tracking
    this.setupSearchTracking()
    this.setupResultTracking()
  }

  setupSearchTracking() {
    // Track search queries
    document.addEventListener('submit', (event) => {
      if (event.target.matches('.search-form, .search-box')) {
        const query = event.target.querySelector('input[name="q"], input[name="search"]')?.value
        if (query) {
          window.railspressAnalytics.trackEvent('search_query', {
            query: query,
            results_count: this.getSearchResultsCount()
          })
        }
      }
    })
  }

  setupResultTracking() {
    // Track search result clicks
    document.addEventListener('click', (event) => {
      if (event.target.matches('.search-result a, .search-result-item a')) {
        window.railspressAnalytics.trackEvent('search_result_click', {
          result_title: event.target.textContent,
          result_url: event.target.href,
          result_position: this.getResultPosition(event.target)
        })
      }
    })
  }

  getSearchResultsCount() {
    const resultsContainer = document.querySelector('.search-results, .search-result-list')
    return resultsContainer ? resultsContainer.children.length : 0
  }

  getResultPosition(element) {
    const results = Array.from(document.querySelectorAll('.search-result, .search-result-item'))
    return results.indexOf(element.closest('.search-result, .search-result-item')) + 1
  }
}

/**
 * EXAMPLE 5: Social Media Analytics Plugin
 * ========================================
 * 
 * Track social media sharing and engagement
 */

class RailsPressSocialAnalyticsPlugin {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Register plugin
    window.railspressAnalytics.registerPlugin('railspress-social-analytics', {
      version: '1.0.0',
      type: 'social-analytics'
    })

    // Setup tracking
    this.setupSocialTracking()
    this.setupShareTracking()
  }

  setupSocialTracking() {
    // Track social media link clicks
    document.addEventListener('click', (event) => {
      if (event.target.matches('a[href*="facebook.com"], a[href*="twitter.com"], a[href*="linkedin.com"], a[href*="instagram.com"]')) {
        window.railspressAnalytics.trackEvent('social_click', {
          platform: this.getSocialPlatform(event.target.href),
          url: event.target.href,
          text: event.target.textContent
        })
      }
    })
  }

  setupShareTracking() {
    // Track social sharing
    document.addEventListener('click', (event) => {
      if (event.target.matches('.share-button, .social-share')) {
        window.railspressAnalytics.trackEvent('social_share', {
          platform: event.target.dataset.platform,
          content_url: window.location.href,
          content_title: document.title
        })
      }
    })
  }

  getSocialPlatform(url) {
    if (url.includes('facebook.com')) return 'facebook'
    if (url.includes('twitter.com')) return 'twitter'
    if (url.includes('linkedin.com')) return 'linkedin'
    if (url.includes('instagram.com')) return 'instagram'
    return 'unknown'
  }
}

/**
 * AUTO-INITIALIZE PLUGINS
 * =======================
 * 
 * Automatically initialize plugins based on page content
 */

document.addEventListener('DOMContentLoaded', () => {
  // Initialize content analytics if on content page
  if (document.body.classList.contains('content-page') || 
      document.body.classList.contains('post-page') ||
      document.body.classList.contains('page-page')) {
    new RailsPressContentAnalyticsPlugin()
  }

  // Initialize newsletter analytics if newsletter forms exist
  if (document.querySelector('.newsletter-form, .subscribe-form')) {
    new RailsPressNewsletterPlugin()
  }

  // Initialize form analytics if forms exist
  if (document.querySelector('form')) {
    new RailsPressFormAnalyticsPlugin()
  }

  // Initialize search analytics if search functionality exists
  if (document.querySelector('.search-form, .search-box')) {
    new RailsPressSearchAnalyticsPlugin()
  }

  // Initialize social analytics if social links exist
  if (document.querySelector('a[href*="facebook.com"], a[href*="twitter.com"], a[href*="linkedin.com"]')) {
    new RailsPressSocialAnalyticsPlugin()
  }
})

/**
 * USAGE EXAMPLES
 * ==============
 * 
 * // Track custom events
 * window.railspressAnalytics.trackEvent('custom_action', {
 *   category: 'user_engagement',
 *   action: 'button_click',
 *   label: 'header_cta'
 * })
 * 
 * // Track page views with custom data
 * window.railspressAnalytics.trackPageview({
 *   title: 'Custom Page Title',
 *   custom_data: {
 *     section: 'features',
 *     version: '2.0'
 *   }
 * })
 * 
 * // Track user properties
 * window.railspressAnalytics.setUserProperties({
 *   subscription_tier: 'premium',
 *   user_type: 'returning'
 * })
 * 
 * // Track conversions
 * window.railspressAnalytics.trackConversion('newsletter_signup', {
 *   value: 1,
 *   currency: 'USD'
 * })
 */