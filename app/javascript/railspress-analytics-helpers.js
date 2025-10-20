/**
 * RailsPress Analytics Helpers
 * 
 * Common tracking patterns and utilities for developers
 * 
 * @version 1.0.0
 * @author RailsPress
 */

/**
 * Auto-tracking for common elements
 */
class RailsPressAnalyticsAutoTracker {
  constructor() {
    this.initialize()
  }

  initialize() {
    this.setupAutoTracking()
    this.setupFormTracking()
    this.setupLinkTracking()
    this.setupVideoTracking()
    this.setupScrollTracking()
    this.setupErrorTracking()
  }

  /**
   * Setup automatic tracking for elements with data attributes
   */
  setupAutoTracking() {
    // Track clicks on elements with data-analytics-track attribute
    document.addEventListener('click', (event) => {
      const element = event.target.closest('[data-analytics-track]')
      if (element) {
        const eventName = element.dataset.analyticsTrack
        const properties = this.parseDataAttributes(element, 'analytics')
        
        window.railspressAnalytics.track(eventName, properties)
      }
    })

    // Track views for elements with data-analytics-view attribute
    this.setupViewTracking()
  }

  /**
   * Parse data attributes for analytics
   */
  parseDataAttributes(element, prefix) {
    const properties = {}
    const attributes = element.dataset
    
    Object.keys(attributes).forEach(key => {
      if (key.startsWith(prefix)) {
        const propertyName = key.replace(prefix, '').replace(/^[A-Z]/, match => match.toLowerCase())
        properties[propertyName] = attributes[key]
      }
    })
    
    return properties
  }

  /**
   * Setup view tracking for elements
   */
  setupViewTracking() {
    const elementsToTrack = document.querySelectorAll('[data-analytics-view]')
    
    if (elementsToTrack.length === 0) return

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const element = entry.target
          const eventName = element.dataset.analyticsView
          const properties = this.parseDataAttributes(element, 'analytics')
          
          window.railspressAnalytics.track(eventName, properties)
          
          // Unobserve after first view
          observer.unobserve(element)
        }
      })
    }, {
      threshold: 0.5 // Track when 50% of element is visible
    })

    elementsToTrack.forEach(element => {
      observer.observe(element)
    })
  }

  /**
   * Setup automatic form tracking
   */
  setupFormTracking() {
    document.addEventListener('submit', (event) => {
      const form = event.target
      
      // Skip if form has data-analytics-skip attribute
      if (form.dataset.analyticsSkip) return
      
      const formName = form.name || form.id || 'unknown_form'
      const formType = form.dataset.analyticsFormType || 'contact'
      
      // Track form submission
      window.railspressAnalytics.trackFormSubmit(formName, {
        type: formType,
        success: true // Will be updated if form submission fails
      })
      
      // Track individual field interactions
      const fields = form.querySelectorAll('input, textarea, select')
      fields.forEach(field => {
        if (field.dataset.analyticsTrack) {
          window.railspressAnalytics.track('form_field_interaction', {
            form_name: formName,
            field_name: field.name || field.id,
            field_type: field.type || field.tagName.toLowerCase(),
            field_value: field.value ? 'filled' : 'empty'
          })
        }
      })
    })
  }

  /**
   * Setup automatic link tracking
   */
  setupLinkTracking() {
    document.addEventListener('click', (event) => {
      const link = event.target.closest('a')
      if (!link) return
      
      const href = link.href
      const text = link.textContent?.trim()
      
      // Track external links
      if (href && !href.startsWith(window.location.origin)) {
        window.railspressAnalytics.track('external_link_click', {
          link_url: href,
          link_text: text,
          link_domain: new URL(href).hostname
        })
      }
      
      // Track internal links to specific pages
      if (href && href.includes('/blog/')) {
        window.railspressAnalytics.track('blog_link_click', {
          link_url: href,
          link_text: text
        })
      }
      
      // Track download links
      if (href && this.isDownloadLink(href)) {
        const fileName = href.split('/').pop()
        const fileType = fileName.split('.').pop()
        
        window.railspressAnalytics.trackDownload(fileName, fileType, 0)
      }
    })
  }

  /**
   * Check if link is a download link
   */
  isDownloadLink(href) {
    const downloadExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'zip', 'rar', 'mp4', 'mp3', 'jpg', 'png', 'gif']
    const extension = href.split('.').pop()?.toLowerCase()
    return downloadExtensions.includes(extension)
  }

  /**
   * Setup automatic video tracking
   */
  setupVideoTracking() {
    const videos = document.querySelectorAll('video, [data-video-id]')
    
    videos.forEach(video => {
      const videoId = video.dataset.videoId || video.id || 'unknown'
      
      // Track play events
      video.addEventListener('play', () => {
        window.railspressAnalytics.trackVideo(videoId, 'play', 0)
      })
      
      // Track pause events
      video.addEventListener('pause', () => {
        const progress = (video.currentTime / video.duration) * 100
        window.railspressAnalytics.trackVideo(videoId, 'pause', progress)
      })
      
      // Track completion
      video.addEventListener('ended', () => {
        window.railspressAnalytics.trackVideo(videoId, 'complete', 100)
      })
      
      // Track progress milestones
      const milestones = [25, 50, 75]
      milestones.forEach(milestone => {
        video.addEventListener('timeupdate', () => {
          const progress = (video.currentTime / video.duration) * 100
          if (progress >= milestone && progress < milestone + 5) {
            window.railspressAnalytics.trackVideo(videoId, `progress_${milestone}`, progress)
          }
        })
      })
    })
  }

  /**
   * Setup automatic scroll tracking
   */
  setupScrollTracking() {
    let maxScrollDepth = 0
    let scrollTimeout
    
    window.addEventListener('scroll', () => {
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      
      if (scrollDepth > maxScrollDepth) {
        maxScrollDepth = scrollDepth
        
        // Track scroll milestones
        const milestones = [25, 50, 75, 90, 100]
        if (milestones.includes(scrollDepth)) {
          window.railspressAnalytics.track('scroll_milestone', {
            scroll_depth: scrollDepth,
            max_scroll_depth: maxScrollDepth
          })
        }
      }
      
      // Clear timeout and set new one
      clearTimeout(scrollTimeout)
      scrollTimeout = setTimeout(() => {
        window.railspressAnalytics.track('scroll_complete', {
          final_scroll_depth: maxScrollDepth
        })
      }, 1000)
    })
  }

  /**
   * Setup automatic error tracking
   */
  setupErrorTracking() {
    // Track JavaScript errors
    window.addEventListener('error', (event) => {
      window.railspressAnalytics.track('javascript_error', {
        error_message: event.message,
        error_filename: event.filename,
        error_lineno: event.lineno,
        error_colno: event.colno,
        error_stack: event.error?.stack || null
      })
    })
    
    // Track unhandled promise rejections
    window.addEventListener('unhandledrejection', (event) => {
      window.railspressAnalytics.track('promise_rejection', {
        error_message: event.reason?.message || 'Unknown error',
        error_stack: event.reason?.stack || null
      })
    })
    
    // Track resource loading errors
    window.addEventListener('error', (event) => {
      if (event.target !== window) {
        window.railspressAnalytics.track('resource_error', {
          resource_type: event.target.tagName,
          resource_url: event.target.src || event.target.href,
          error_message: 'Failed to load resource'
        })
      }
    }, true)
  }
}

/**
 * E-commerce tracking helpers
 */
class RailsPressEcommerceTracker {
  constructor() {
    this.cart = []
    this.currency = 'USD'
    this.initialize()
  }

  initialize() {
    // Initialize e-commerce tracking
    window.railspressAnalytics.initEcommerce({
      currency: this.currency
    })
  }

  /**
   * Add item to cart
   */
  addToCart(item) {
    this.cart.push(item)
    window.railspressAnalytics.trackAddToCart(item)
  }

  /**
   * Remove item from cart
   */
  removeFromCart(item) {
    const index = this.cart.findIndex(cartItem => cartItem.id === item.id)
    if (index > -1) {
      this.cart.splice(index, 1)
      window.railspressAnalytics.trackRemoveFromCart(item)
    }
  }

  /**
   * Track product view
   */
  viewProduct(product) {
    window.railspressAnalytics.trackProductView(product)
  }

  /**
   * Track checkout progress
   */
  beginCheckout() {
    window.railspressAnalytics.trackCheckoutProgress(1, 'cart_review')
  }

  /**
   * Complete purchase
   */
  purchase(transaction) {
    window.railspressAnalytics.trackTransaction(transaction)
    this.cart = [] // Clear cart after purchase
  }

  /**
   * Get cart value
   */
  getCartValue() {
    return this.cart.reduce((total, item) => total + (item.price * item.quantity), 0)
  }

  /**
   * Get currency
   */
  getCurrency() {
    return this.currency
  }
}

/**
 * Performance tracking helpers
 */
class RailsPressPerformanceTracker {
  constructor() {
    this.initialize()
  }

  initialize() {
    // Track page load performance
    window.addEventListener('load', () => {
      this.trackPageLoadPerformance()
    })
    
    // Track resource loading
    this.setupResourceTracking()
  }

  /**
   * Track page load performance
   */
  trackPageLoadPerformance() {
    const perfData = performance.getEntriesByType('navigation')[0]
    if (!perfData) return
    
    const paintEntries = performance.getEntriesByType('paint')
    const firstPaint = paintEntries.find(entry => entry.name === 'first-paint')
    const firstContentfulPaint = paintEntries.find(entry => entry.name === 'first-contentful-paint')
    
    window.railspressAnalytics.track('page_performance', {
      load_time: perfData.loadEventEnd - perfData.loadEventStart,
      dom_content_loaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
      first_paint: firstPaint?.startTime || 0,
      first_contentful_paint: firstContentfulPaint?.startTime || 0,
      page_size: perfData.transferSize || 0,
      dom_elements: document.querySelectorAll('*').length
    })
  }

  /**
   * Setup resource loading tracking
   */
  setupResourceTracking() {
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach(entry => {
        if (entry.entryType === 'resource') {
          window.railspressAnalytics.track('resource_load', {
            resource_type: entry.initiatorType,
            resource_url: entry.name,
            load_time: entry.duration,
            resource_size: entry.transferSize || 0,
            cached: entry.transferSize === 0
          })
        }
      })
    })
    
    observer.observe({ entryTypes: ['resource'] })
  }
}

/**
 * Utility functions for common tracking patterns
 */
const RailsPressAnalyticsUtils = {
  /**
   * Track element visibility
   */
  trackVisibility: (selector, eventName, options = {}) => {
    const elements = document.querySelectorAll(selector)
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          window.railspressAnalytics.track(eventName, {
            element_id: entry.target.id,
            element_class: entry.target.className,
            visibility_ratio: entry.intersectionRatio,
            ...options
          })
          observer.unobserve(entry.target)
        }
      })
    }, {
      threshold: options.threshold || 0.5
    })
    
    elements.forEach(element => observer.observe(element))
  },

  /**
   * Track time spent on page
   */
  trackTimeOnPage: () => {
    const startTime = Date.now()
    
    window.addEventListener('beforeunload', () => {
      const timeSpent = Date.now() - startTime
      window.railspressAnalytics.track('time_on_page', {
        time_spent: timeSpent,
        time_spent_minutes: Math.round(timeSpent / 60000)
      })
    })
  },

  /**
   * Track user engagement score
   */
  trackEngagement: () => {
    let engagementScore = 0
    let lastActivity = Date.now()
    
    // Track various user activities
    const activities = ['click', 'scroll', 'keydown', 'mousemove']
    activities.forEach(activity => {
      document.addEventListener(activity, () => {
        lastActivity = Date.now()
        engagementScore += 1
      })
    })
    
    // Calculate engagement score every minute
    setInterval(() => {
      const timeSinceActivity = Date.now() - lastActivity
      if (timeSinceActivity < 30000) { // Active within last 30 seconds
        window.railspressAnalytics.track('engagement_score', {
          score: Math.min(engagementScore, 100),
          time_since_activity: timeSinceActivity
        })
      }
    }, 60000)
  },

  /**
   * Track form abandonment
   */
  trackFormAbandonment: (formSelector) => {
    const forms = document.querySelectorAll(formSelector)
    
    forms.forEach(form => {
      const fields = form.querySelectorAll('input, textarea, select')
      let filledFields = 0
      
      fields.forEach(field => {
        field.addEventListener('input', () => {
          filledFields++
          
          if (filledFields === fields.length) {
            window.railspressAnalytics.track('form_completed', {
              form_id: form.id,
              form_name: form.name,
              completion_rate: 100
            })
          }
        })
      })
      
      // Track abandonment on page unload
      window.addEventListener('beforeunload', () => {
        if (filledFields > 0 && filledFields < fields.length) {
          window.railspressAnalytics.track('form_abandonment', {
            form_id: form.id,
            form_name: form.name,
            completion_rate: (filledFields / fields.length) * 100,
            filled_fields: filledFields,
            total_fields: fields.length
          })
        }
      })
    })
  }
}

// Initialize auto-tracking when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new RailsPressAnalyticsAutoTracker()
  })
} else {
  new RailsPressAnalyticsAutoTracker()
}

// Make helpers available globally
window.railspressEcommerce = new RailsPressEcommerceTracker()
window.railspressPerformance = new RailsPressPerformanceTracker()
window.railspressAnalyticsUtils = RailsPressAnalyticsUtils
