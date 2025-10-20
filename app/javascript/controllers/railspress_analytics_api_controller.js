import { Controller } from "@hotwired/stimulus"

/**
 * RailsPress Analytics API Controller
 * Provides a comprehensive JavaScript API for developers to track custom events
 * Similar to WooCommerce, GA4, and other e-commerce platforms
 */
export default class extends Controller {
  static targets = ["debugConsole"]
  static values = { 
    debug: Boolean,
    apiVersion: String,
    measurementId: String
  }

  connect() {
    this.apiVersion = '1.0.0'
    this.debug = this.debugValue || false
    
    // Initialize the global RailsPress Analytics API
    window.RailsPressAnalytics = this.createAnalyticsAPI()
    
    this.log('RailsPress Analytics API initialized', {
      version: this.apiVersion,
      debug: this.debug
    })
    
    // Auto-track common events
    this.initializeAutoTracking()
  }

  disconnect() {
    // Clean up global API
    if (window.RailsPressAnalytics) {
      delete window.RailsPressAnalytics
    }
  }

  createAnalyticsAPI() {
    return {
      // ==================== CORE TRACKING METHODS ====================
      
      /**
       * Track a custom event
       * @param {string} eventName - Name of the event
       * @param {Object} parameters - Event parameters
       * @param {Object} options - Additional options
       */
      track: (eventName, parameters = {}, options = {}) => {
        this.trackEvent(eventName, parameters, options)
      },

      /**
       * Track page view with custom data
       * @param {string} pageName - Name of the page
       * @param {string} pageTitle - Title of the page
       * @param {Object} customParameters - Custom parameters
       */
      page: (pageName, pageTitle = '', customParameters = {}) => {
        this.trackPageView(pageName, pageTitle, customParameters)
      },

      /**
       * Track user engagement
       * @param {string} engagementType - Type of engagement
       * @param {Object} parameters - Engagement parameters
       */
      engage: (engagementType, parameters = {}) => {
        this.trackEngagement(engagementType, parameters)
      },

      // ==================== E-COMMERCE TRACKING ====================
      
      /**
       * Track product view
       * @param {Object} product - Product information
       */
      viewItem: (product) => {
        this.trackEcommerceEvent('view_item', {
          currency: product.currency || 'USD',
          value: product.price || 0,
          items: [{
            item_id: product.id,
            item_name: product.name,
            item_category: product.category,
            item_brand: product.brand,
            price: product.price,
            quantity: 1
          }]
        })
      },

      /**
       * Track add to cart
       * @param {Object} product - Product information
       * @param {number} quantity - Quantity added
       */
      addToCart: (product, quantity = 1) => {
        this.trackEcommerceEvent('add_to_cart', {
          currency: product.currency || 'USD',
          value: (product.price || 0) * quantity,
          items: [{
            item_id: product.id,
            item_name: product.name,
            item_category: product.category,
            item_brand: product.brand,
            price: product.price,
            quantity: quantity
          }]
        })
      },

      /**
       * Track purchase
       * @param {Object} transaction - Transaction information
       */
      purchase: (transaction) => {
        this.trackEcommerceEvent('purchase', {
          transaction_id: transaction.id,
          currency: transaction.currency || 'USD',
          value: transaction.value || 0,
          items: transaction.items || []
        })
      },

      /**
       * Track begin checkout
       * @param {Object} checkout - Checkout information
       */
      beginCheckout: (checkout) => {
        this.trackEcommerceEvent('begin_checkout', {
          currency: checkout.currency || 'USD',
          value: checkout.value || 0,
          items: checkout.items || []
        })
      },

      // ==================== CONTENT TRACKING ====================
      
      /**
       * Track content engagement
       * @param {string} contentType - Type of content (post, page, video, etc.)
       * @param {Object} content - Content information
       * @param {Object} engagement - Engagement metrics
       */
      contentEngagement: (contentType, content, engagement = {}) => {
        this.trackEvent('content_engagement', {
          content_type: contentType,
          content_id: content.id,
          content_title: content.title,
          content_author: content.author,
          content_category: content.category,
          engagement_type: engagement.type || 'view',
          engagement_duration: engagement.duration || 0,
          engagement_depth: engagement.depth || 0,
          engagement_score: engagement.score || 0
        })
      },

      /**
       * Track video engagement
       * @param {Object} video - Video information
       * @param {Object} engagement - Engagement metrics
       */
      videoEngagement: (video, engagement = {}) => {
        this.trackEvent('video_engagement', {
          video_id: video.id,
          video_title: video.title,
          video_duration: video.duration,
          video_category: video.category,
          engagement_type: engagement.type || 'play',
          current_time: engagement.currentTime || 0,
          duration: engagement.duration || 0,
          progress_percentage: engagement.progress || 0
        })
      },

      /**
       * Track search
       * @param {string} searchTerm - Search term
       * @param {Object} searchResults - Search results information
       */
      search: (searchTerm, searchResults = {}) => {
        this.trackEvent('search', {
          search_term: searchTerm,
          results_count: searchResults.count || 0,
          results_type: searchResults.type || 'general',
          search_category: searchResults.category || 'all'
        })
      },

      // ==================== USER INTERACTION TRACKING ====================
      
      /**
       * Track form interaction
       * @param {string} formType - Type of form
       * @param {Object} formData - Form data
       * @param {string} action - Form action (submit, focus, blur, etc.)
       */
      formInteraction: (formType, formData = {}, action = 'interaction') => {
        this.trackEvent('form_interaction', {
          form_type: formType,
          form_id: formData.id,
          form_action: action,
          field_count: formData.fieldCount || 0,
          required_fields: formData.requiredFields || 0,
          validation_errors: formData.validationErrors || 0
        })
      },

      /**
       * Track button click
       * @param {string} buttonType - Type of button
       * @param {Object} buttonData - Button data
       * @param {Object} context - Context information
       */
      buttonClick: (buttonType, buttonData = {}, context = {}) => {
        this.trackEvent('button_click', {
          button_type: buttonType,
          button_id: buttonData.id,
          button_text: buttonData.text,
          button_location: buttonData.location,
          context_page: context.page,
          context_section: context.section
        })
      },

      /**
       * Track link click
       * @param {Object} link - Link information
       * @param {Object} context - Context information
       */
      linkClick: (link, context = {}) => {
        this.trackEvent('link_click', {
          link_url: link.url,
          link_text: link.text,
          link_domain: this.extractDomain(link.url),
          is_external: this.isExternalLink(link.url),
          context_page: context.page,
          context_section: context.section
        })
      },

      // ==================== CONVERSION TRACKING ====================
      
      /**
       * Track conversion
       * @param {string} conversionType - Type of conversion
       * @param {Object} conversionData - Conversion data
       * @param {number} value - Conversion value
       */
      conversion: (conversionType, conversionData = {}, value = 0) => {
        this.trackEvent('conversion', {
          conversion_type: conversionType,
          conversion_id: conversionData.id,
          conversion_category: conversionData.category,
          conversion_value: value,
          conversion_currency: conversionData.currency || 'USD'
        })
      },

      /**
       * Track goal completion
       * @param {string} goalName - Name of the goal
       * @param {Object} goalData - Goal data
       * @param {number} value - Goal value
       */
      goal: (goalName, goalData = {}, value = 0) => {
        this.trackEvent('goal_completion', {
          goal_name: goalName,
          goal_category: goalData.category,
          goal_value: value,
          goal_duration: goalData.duration || 0,
          goal_steps: goalData.steps || 0
        })
      },

      // ==================== CUSTOM METRICS ====================
      
      /**
       * Track custom metric
       * @param {string} metricName - Name of the metric
       * @param {number} value - Metric value
       * @param {Object} metadata - Additional metadata
       */
      metric: (metricName, value, metadata = {}) => {
        this.trackEvent('custom_metric', {
          metric_name: metricName,
          metric_value: value,
          metric_unit: metadata.unit || 'count',
          metric_category: metadata.category || 'custom',
          metadata: metadata
        })
      },

      /**
       * Track performance metric
       * @param {string} performanceType - Type of performance metric
       * @param {number} value - Performance value
       * @param {Object} context - Performance context
       */
      performance: (performanceType, value, context = {}) => {
        this.trackEvent('performance_metric', {
          performance_type: performanceType,
          performance_value: value,
          performance_unit: context.unit || 'ms',
          context_page: context.page,
          context_component: context.component
        })
      },

      // ==================== ERROR TRACKING ====================
      
      /**
       * Track error
       * @param {string} errorType - Type of error
       * @param {string} errorMessage - Error message
       * @param {Object} errorContext - Error context
       */
      error: (errorType, errorMessage, errorContext = {}) => {
        this.trackEvent('error', {
          error_type: errorType,
          error_message: errorMessage,
          error_stack: errorContext.stack,
          error_url: errorContext.url,
          error_line: errorContext.line,
          error_column: errorContext.column
        })
      },

      // ==================== UTILITY METHODS ====================
      
      /**
       * Set user properties
       * @param {Object} properties - User properties
       */
      setUserProperties: (properties) => {
        this.setUserProperties(properties)
      },

      /**
       * Set custom parameters for all events
       * @param {Object} parameters - Custom parameters
       */
      setCustomParameters: (parameters) => {
        this.setCustomParameters(parameters)
      },

      /**
       * Enable/disable debug mode
       * @param {boolean} enabled - Debug mode enabled
       */
      setDebugMode: (enabled) => {
        this.debug = enabled
        this.log('Debug mode', enabled ? 'enabled' : 'disabled')
      },

      /**
       * Get current session information
       * @returns {Object} Session information
       */
      getSessionInfo: () => {
        return this.getSessionInfo()
      },

      /**
       * Flush pending events
       */
      flush: () => {
        this.flushEvents()
      }
    }
  }

  // ==================== IMPLEMENTATION METHODS ====================

  trackEvent(eventName, parameters = {}, options = {}) {
    const eventData = {
      event_name: eventName,
      parameters: {
        ...parameters,
        timestamp: Date.now(),
        session_id: this.getSessionId(),
        user_id: this.getUserId(),
        page_url: window.location.href,
        page_title: document.title,
        user_agent: navigator.userAgent,
        screen_resolution: `${screen.width}x${screen.height}`,
        viewport_size: `${window.innerWidth}x${window.innerHeight}`,
        ...this.getCustomParameters()
      },
      options: {
        send_to_server: true,
        ...options
      }
    }

    this.log('Tracking event', eventData)

    // Send to server
    if (eventData.options.send_to_server) {
      this.sendEventToServer(eventData)
    }

    // Dispatch custom event for other components
    this.dispatchCustomEvent('railsPress:analytics:event', eventData)
  }

  trackPageView(pageName, pageTitle = '', customParameters = {}) {
    this.trackEvent('page_view', {
      page_name: pageName,
      page_title: pageTitle,
      page_location: window.location.href,
      page_path: window.location.pathname,
      page_referrer: document.referrer,
      ...customParameters
    })
  }

  trackEngagement(engagementType, parameters = {}) {
    this.trackEvent('engagement', {
      engagement_type: engagementType,
      engagement_timestamp: Date.now(),
      ...parameters
    })
  }

  trackEcommerceEvent(eventName, parameters = {}) {
    this.trackEvent(eventName, {
      ecommerce_event: true,
      ...parameters
    })
  }

  sendEventToServer(eventData) {
    fetch('/analytics/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(eventData)
    }).catch(error => {
      this.log('Failed to send event to server', error)
    })
  }

  // ==================== UTILITY METHODS ====================

  getSessionId() {
    return this.getCookie('analytics_session_id') || this.generateId()
  }

  getUserId() {
    return this.getCookie('analytics_user_id') || null
  }

  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(';').shift()
    return null
  }

  setCookie(name, value, days) {
    const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toUTCString()
    document.cookie = `${name}=${value}; expires=${expires}; path=/; SameSite=Lax`
  }

  extractDomain(url) {
    try {
      return new URL(url).hostname
    } catch {
      return url
    }
  }

  isExternalLink(url) {
    try {
      return new URL(url).hostname !== window.location.hostname
    } catch {
      return false
    }
  }

  getCustomParameters() {
    return this.customParameters || {}
  }

  setCustomParameters(parameters) {
    this.customParameters = { ...this.customParameters, ...parameters }
  }

  setUserProperties(properties) {
    this.userProperties = { ...this.userProperties, ...properties }
  }

  getSessionInfo() {
    return {
      session_id: this.getSessionId(),
      user_id: this.getUserId(),
      start_time: this.getCookie('analytics_session_start'),
      page_views: this.getCookie('analytics_page_views') || 0
    }
  }

  flushEvents() {
    // Implement event flushing logic
    this.log('Flushing pending events')
  }

  dispatchCustomEvent(eventName, data) {
    const event = new CustomEvent(eventName, { detail: data })
    window.dispatchEvent(event)
  }

  initializeAutoTracking() {
    // Auto-track common events
    this.trackPageView(document.title, document.title)
    
    // Track form submissions
    document.addEventListener('submit', (event) => {
      const form = event.target
      this.trackEvent('form_submit', {
        form_id: form.id,
        form_class: form.className,
        form_action: form.action,
        form_method: form.method
      })
    })

    // Track external link clicks
    document.addEventListener('click', (event) => {
      const link = event.target.closest('a')
      if (link && this.isExternalLink(link.href)) {
        this.trackEvent('external_link_click', {
          link_url: link.href,
          link_text: link.textContent?.trim()
        })
      }
    })
  }

  log(message, data = null) {
    if (this.debug) {
      console.log(`[RailsPress Analytics API] ${message}`, data)
      
      if (this.hasTarget('debugConsole')) {
        const timestamp = new Date().toLocaleTimeString()
        const logEntry = document.createElement('div')
        logEntry.innerHTML = `<strong>${timestamp}</strong>: ${message} ${data ? JSON.stringify(data, null, 2) : ''}`
        this.debugConsoleTarget.appendChild(logEntry)
      }
    }
  }
}
