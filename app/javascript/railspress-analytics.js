/**
 * RailsPress Analytics JavaScript API
 * 
 * Comprehensive analytics tracking for RailsPress applications
 * 
 * @version 1.0.0
 * @author RailsPress
 */

class RailsPressAnalytics {
  constructor() {
    this.apiUrl = '/analytics/events'
    this.sessionId = this.getSessionId()
    this.deviceId = this.getDeviceId()
    this.userId = null
    this.userProperties = {}
    this.customParameters = {}
    this.queue = []
    this.debug = false
    this.consent = {
      analytics: false,
      marketing: false,
      essential: true
    }
    
    this.initialize()
  }

  /**
   * Initialize the analytics system
   */
  initialize() {
    // Check for consent
    this.loadConsent()
    
    // Track page view on load
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.trackPageview())
    } else {
      this.trackPageview()
    }
    
    // Set up automatic flushing
    setInterval(() => this.flush(), 30000) // Flush every 30 seconds
    
    // Flush on page unload
    window.addEventListener('beforeunload', () => this.flush())
    
    // Track scroll depth
    this.trackScrollDepth()
    
    // Track reading time
    this.trackReadingTime()
    
    // Track exit intent
    this.trackExitIntent()
  }

  /**
   * Track a custom event
   * @param {string} eventName - Name of the event
   * @param {Object} properties - Event properties
   * @param {Object} options - Tracking options
   */
  track(eventName, properties = {}, options = {}) {
    if (!this.hasConsent('analytics') && !options.force) {
      return
    }

    const event = {
      event_name: eventName,
      properties: {
        ...properties,
        session_id: this.sessionId,
        device_id: this.deviceId,
        user_id: this.userId,
        timestamp: new Date().toISOString(),
        url: window.location.href,
        referrer: document.referrer,
        user_agent: navigator.userAgent,
        screen_resolution: `${screen.width}x${screen.height}`,
        viewport_size: `${window.innerWidth}x${window.innerHeight}`,
        language: navigator.language,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      user_properties: this.userProperties,
      custom_parameters: this.customParameters
    }

    this.queue.push(event)
    
    if (this.debug) {
      console.log('RailsPress Analytics:', event)
    }

    // Auto-flush if queue gets large
    if (this.queue.length >= 20) {
      this.flush()
    }
  }

  /**
   * Track page view
   * @param {string} title - Page title
   * @param {string} path - Page path
   * @param {Object} properties - Additional properties
   */
  trackPageview(title = document.title, path = window.location.pathname, properties = {}) {
    this.track('page_view', {
      page_title: title,
      page_path: path,
      ...properties
    })
  }

  /**
   * Track user engagement
   * @param {string} type - Type of engagement
   * @param {Object} properties - Engagement properties
   */
  trackEngagement(type, properties = {}) {
    this.track('engagement', {
      engagement_type: type,
      ...properties
    })
  }

  /**
   * Track content engagement
   * @param {string} contentType - Type of content
   * @param {Object} content - Content details
   * @param {Object} engagement - Engagement details
   */
  trackContentEngagement(contentType, content, engagement) {
    this.track('content_engagement', {
      content_type: contentType,
      content_id: content.id,
      content_title: content.title,
      content_author: content.author,
      content_category: content.category,
      engagement_type: engagement.type,
      engagement_duration: engagement.duration,
      engagement_depth: engagement.depth,
      engagement_score: engagement.score
    })
  }

  /**
   * Track video engagement
   * @param {Object} video - Video details
   * @param {Object} engagement - Engagement details
   */
  trackVideoEngagement(video, engagement) {
    this.track('video_engagement', {
      video_id: video.id,
      video_title: video.title,
      video_duration: video.duration,
      video_category: video.category,
      engagement_type: engagement.type,
      current_time: engagement.currentTime,
      progress_percentage: engagement.progress
    })
  }

  /**
   * Track search queries
   * @param {string} query - Search query
   * @param {Object} properties - Search properties
   */
  trackSearch(query, properties = {}) {
    this.track('search', {
      search_query: query,
      results_count: properties.count,
      search_type: properties.type,
      search_category: properties.category
    })
  }

  /**
   * Track form interactions
   * @param {string} formType - Type of form
   * @param {Object} formData - Form data
   * @param {string} action - Form action
   */
  trackFormInteraction(formType, formData, action) {
    this.track('form_interaction', {
      form_type: formType,
      form_id: formData.id,
      field_count: formData.fieldCount,
      required_fields: formData.requiredFields,
      validation_errors: formData.validationErrors,
      action: action
    })
  }

  /**
   * Track button clicks
   * @param {string} buttonType - Type of button
   * @param {Object} buttonData - Button data
   * @param {Object} context - Click context
   */
  trackButtonClick(buttonType, buttonData, context = {}) {
    this.track('button_click', {
      button_type: buttonType,
      button_id: buttonData.id,
      button_text: buttonData.text,
      button_location: buttonData.location,
      page: context.page,
      section: context.section
    })
  }

  /**
   * Track link clicks
   * @param {Object} link - Link details
   * @param {Object} context - Click context
   */
  trackLinkClick(link, context = {}) {
    this.track('link_click', {
      link_url: link.url,
      link_text: link.text,
      link_type: link.type || 'external',
      page: context.page,
      section: context.section
    })
  }

  /**
   * Track conversions
   * @param {string} conversionType - Type of conversion
   * @param {Object} conversionData - Conversion data
   * @param {number} value - Conversion value
   */
  trackConversion(conversionType, conversionData, value = 0) {
    this.track('conversion', {
      conversion_type: conversionType,
      conversion_id: conversionData.id,
      conversion_category: conversionData.category,
      conversion_value: value,
      currency: conversionData.currency || 'USD'
    })
  }

  /**
   * Track goal completion
   * @param {string} goalType - Type of goal
   * @param {Object} goalData - Goal data
   * @param {number} value - Goal value
   */
  trackGoal(goalType, goalData, value = 0) {
    this.track('goal_completion', {
      goal_type: goalType,
      goal_category: goalData.category,
      goal_duration: goalData.duration,
      goal_steps: goalData.steps,
      goal_value: value
    })
  }

  /**
   * Track custom metrics
   * @param {string} metricName - Name of the metric
   * @param {number} value - Metric value
   * @param {Object} properties - Metric properties
   */
  trackMetric(metricName, value, properties = {}) {
    this.track('custom_metric', {
      metric_name: metricName,
      metric_value: value,
      metric_unit: properties.unit,
      metric_category: properties.category,
      ...properties
    })
  }

  /**
   * Track performance metrics
   * @param {string} metricName - Name of the performance metric
   * @param {number} value - Metric value
   * @param {Object} properties - Metric properties
   */
  trackPerformance(metricName, value, properties = {}) {
    this.track('performance_metric', {
      performance_metric: metricName,
      metric_value: value,
      metric_unit: properties.unit,
      page: properties.page,
      component: properties.component,
      ...properties
    })
  }

  /**
   * Track errors
   * @param {string} errorType - Type of error
   * @param {string} message - Error message
   * @param {Object} details - Error details
   */
  trackError(errorType, message, details = {}) {
    this.track('error', {
      error_type: errorType,
      error_message: message,
      error_stack: details.stack,
      error_url: details.url,
      error_line: details.line,
      error_column: details.column
    }, { force: true }) // Always track errors
  }

  /**
   * Track scroll depth
   */
  trackScrollDepth() {
    let maxScrollDepth = 0
    
    window.addEventListener('scroll', () => {
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      
      if (scrollDepth > maxScrollDepth) {
        maxScrollDepth = scrollDepth
        this.track('scroll_depth', {
          scroll_depth: scrollDepth
        })
      }
    })
  }

  /**
   * Track reading time
   */
  trackReadingTime() {
    let startTime = Date.now()
    let readingTime = 0
    
    setInterval(() => {
      readingTime = Math.round((Date.now() - startTime) / 1000)
      this.track('reading_time', {
        reading_time: readingTime
      })
    }, 5000)
  }

  /**
   * Track exit intent
   */
  trackExitIntent() {
    let exitIntentTracked = false
    
    document.addEventListener('mouseleave', (event) => {
      if (event.clientY <= 0 && !exitIntentTracked) {
        exitIntentTracked = true
        this.track('exit_intent', {
          exit_intent: true
        })
      }
    })
  }

  /**
   * Set user ID
   * @param {string} userId - User ID
   */
  setUserId(userId) {
    this.userId = userId
  }

  /**
   * Set user properties
   * @param {Object} properties - User properties
   */
  setUserProperties(properties) {
    this.userProperties = { ...this.userProperties, ...properties }
  }

  /**
   * Set custom parameters
   * @param {Object} parameters - Custom parameters
   */
  setCustomParameters(parameters) {
    this.customParameters = { ...this.customParameters, ...parameters }
  }

  /**
   * Set consent preferences
   * @param {Object} consent - Consent preferences
   */
  setConsent(consent) {
    this.consent = { ...this.consent, ...consent }
    this.saveConsent()
  }

  /**
   * Get consent preferences
   * @returns {Object} Consent preferences
   */
  getConsent() {
    return this.consent
  }

  /**
   * Check if user has given consent for a specific type
   * @param {string} type - Consent type
   * @returns {boolean} Has consent
   */
  hasConsent(type) {
    return this.consent[type] === true
  }

  /**
   * Get session ID
   * @returns {string} Session ID
   */
  getSessionId() {
    let sessionId = sessionStorage.getItem('railspress_session_id')
    if (!sessionId) {
      sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
      sessionStorage.setItem('railspress_session_id', sessionId)
    }
    return sessionId
  }

  /**
   * Get device ID
   * @returns {string} Device ID
   */
  getDeviceId() {
    let deviceId = localStorage.getItem('railspress_device_id')
    if (!deviceId) {
      deviceId = 'device_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
      localStorage.setItem('railspress_device_id', deviceId)
    }
    return deviceId
  }

  /**
   * Get user properties
   * @returns {Object} User properties
   */
  getUserProperties() {
    return this.userProperties
  }

  /**
   * Clear user properties
   */
  clearUserProperties() {
    this.userProperties = {}
  }

  /**
   * Set debug mode
   * @param {boolean} enabled - Debug mode enabled
   */
  setDebugMode(enabled) {
    this.debug = enabled
  }

  /**
   * Get session info
   * @returns {Object} Session information
   */
  getSessionInfo() {
    return {
      sessionId: this.sessionId,
      deviceId: this.deviceId,
      userId: this.userId,
      userProperties: this.userProperties,
      customParameters: this.customParameters,
      consent: this.consent,
      queueLength: this.queue.length
    }
  }

  /**
   * Flush the event queue
   */
  async flush() {
    if (this.queue.length === 0) return

    const events = [...this.queue]
    this.queue = []

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ events })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
    } catch (error) {
      console.error('RailsPress Analytics flush error:', error)
      // Re-queue events on error
      this.queue.unshift(...events)
    }
  }

  /**
   * Load consent from localStorage
   */
  loadConsent() {
    const storedConsent = localStorage.getItem('railspress_consent')
    if (storedConsent) {
      this.consent = { ...this.consent, ...JSON.parse(storedConsent) }
    }
  }

  /**
   * Save consent to localStorage
   */
  saveConsent() {
    localStorage.setItem('railspress_consent', JSON.stringify(this.consent))
  }

  /**
   * Register a plugin
   * @param {string} pluginName - Plugin name
   * @param {Object} config - Plugin configuration
   */
  registerPlugin(pluginName, config) {
    this.track('plugin_registered', {
      plugin_name: pluginName,
      plugin_version: config.version,
      plugin_type: config.type
    })
  }

  /**
   * Initialize content tracking
   * @param {Object} config - Content tracking configuration
   */
  initContent(config = {}) {
    this.track('content_tracking_initialized', {
      track_reading_time: config.trackReadingTime,
      track_scroll_depth: config.trackScrollDepth,
      track_engagement: config.trackEngagement
    })
  }

  /**
   * Initialize newsletter tracking
   * @param {Object} config - Newsletter tracking configuration
   */
  initNewsletter(config = {}) {
    this.track('newsletter_tracking_initialized', {
      newsletter_name: config.name,
      newsletter_version: config.version
    })
  }
}

// Create global instance
window.RailsPressAnalytics = new RailsPressAnalytics()

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = RailsPressAnalytics
}