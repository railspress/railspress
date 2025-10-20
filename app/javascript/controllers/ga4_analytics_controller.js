import { Controller } from "@hotwired/stimulus"

/**
 * GA4-like Analytics Controller
 * Implements modern analytics tracking with elegant, robust code
 * Uses latest GA4 practices and patterns
 */
export default class extends Controller {
  static targets = ["consentBanner", "consentMessage", "privacyControls"]
  static values = { 
    measurementId: String,
    consentRequired: Boolean,
    debug: Boolean,
    anonymizeIp: Boolean,
    gdprEnabled: Boolean,
    dataRetentionDays: Number
  }

  // Core tracking state
  state = {
    sessionId: null,
    userId: null,
    consent: false,
    startTime: null,
    pageViewSent: false,
    engagementTimer: null,
    scrollDepth: 0,
    maxScrollDepth: 0,
    readingTime: 0,
    isReader: false,
    lastActivity: Date.now(),
    eventQueue: [],
    config: {
      sessionTimeout: 30 * 60 * 1000, // 30 minutes
      engagementThreshold: 10 * 1000, // 10 seconds
      readerThreshold: 30 * 1000, // 30 seconds like Medium
      maxEventQueueSize: 100,
      batchSize: 20,
      flushInterval: 5000 // 5 seconds
    }
  }

  connect() {
    this.log("GA4 Analytics Controller connected")
    
    // Initialize core tracking
    this.initializeSession()
    this.initializeConsent()
    
    // Start tracking if consent is given
    if (this.hasConsent()) {
      this.startTracking()
    }
    
    // Start event queue processing
    this.startEventQueue()
  }

  disconnect() {
    this.log("GA4 Analytics Controller disconnected")
    this.flushEventQueue()
    this.sendEngagementEvent()
  }

  // ==================== CORE TRACKING ====================

  initializeSession() {
    this.state.sessionId = this.getOrCreateSessionId()
    this.state.userId = this.getOrCreateUserId()
    this.state.startTime = Date.now()
    
    this.log(`Session initialized: ${this.state.sessionId}`)
  }

  initializeConsent() {
    if (this.consentRequiredValue) {
      if (!this.hasConsent()) {
        this.showConsentBanner()
        return
      }
    }
    
    // Consent already given or not required
    this.state.consent = true
  }

  startTracking() {
    if (!this.state.consent) return
    
    this.log("Starting analytics tracking")
    
    // Send initial pageview
    this.sendPageView()
    
    // Start engagement tracking
    this.startEngagementTracking()
    
    // Start scroll tracking
    this.startScrollTracking()
    
    // Start reading time tracking
    this.startReadingTimeTracking()
    
    // Start click tracking
    this.startClickTracking()
    
    // Start form tracking
    this.startFormTracking()
    
    // Start exit intent tracking
    this.startExitIntentTracking()
  }

  // ==================== PAGEVIEW TRACKING ====================

  sendPageView() {
    if (this.state.pageViewSent) return
    
    const pageViewData = {
      event_name: 'page_view',
      page_title: document.title,
      page_location: window.location.href,
      page_path: window.location.pathname,
      page_referrer: document.referrer,
      session_id: this.state.sessionId,
      user_id: this.state.userId,
      timestamp: Date.now(),
      properties: {
        // Page metadata
        page_title: document.title,
        page_location: window.location.href,
        page_path: window.location.pathname,
        page_referrer: document.referrer,
        
        // Screen and viewport
        screen_resolution: `${screen.width}x${screen.height}`,
        viewport_size: `${window.innerWidth}x${window.innerHeight}`,
        
        // Browser and device
        user_agent: navigator.userAgent,
        language: navigator.language,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        
        // Connection info
        connection_type: this.getConnectionType(),
        
        // Content analysis
        word_count: this.getWordCount(),
        estimated_reading_time: this.getEstimatedReadingTime(),
        
        // Session info
        session_start: this.state.startTime,
        is_new_session: this.isNewSession(),
        is_returning_visitor: this.isReturningVisitor()
      }
    }
    
    this.queueEvent(pageViewData)
    this.state.pageViewSent = true
    
    this.log("Page view queued", pageViewData)
  }

  // ==================== ENGAGEMENT TRACKING ====================

  startEngagementTracking() {
    this.state.engagementTimer = setInterval(() => {
      const timeOnPage = Date.now() - this.state.startTime
      
      // Send engagement event every 30 seconds
      if (timeOnPage > 0 && timeOnPage % 30000 < 5000) {
        this.sendEngagementEvent()
      }
      
      // Check if user qualifies as a reader (Medium-like)
      if (timeOnPage >= this.state.config.readerThreshold && !this.state.isReader) {
        this.state.isReader = true
        this.sendEvent('reader_qualified', {
          time_to_reader: timeOnPage,
          scroll_depth: this.state.maxScrollDepth,
          engagement_score: this.calculateEngagementScore(timeOnPage)
        })
      }
      
    }, 5000) // Check every 5 seconds
  }

  sendEngagementEvent() {
    const timeOnPage = Date.now() - this.state.startTime
    
    this.sendEvent('engagement', {
      time_on_page: timeOnPage,
      scroll_depth: this.state.maxScrollDepth,
      reading_time: this.state.readingTime,
      is_reader: this.state.isReader,
      engagement_score: this.calculateEngagementScore(timeOnPage),
      session_duration: timeOnPage
    })
  }

  // ==================== SCROLL TRACKING ====================

  startScrollTracking() {
    let scrollTimeout
    let lastScrollTime = 0
    
    const handleScroll = () => {
      const now = Date.now()
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      
      this.state.scrollDepth = scrollDepth
      this.state.maxScrollDepth = Math.max(this.state.maxScrollDepth, scrollDepth)
      
      // Throttle scroll events
      if (now - lastScrollTime > 100) {
        this.sendEvent('scroll', {
          scroll_depth: scrollDepth,
          max_scroll_depth: this.state.maxScrollDepth,
          scroll_percentage: scrollDepth
        })
        
        lastScrollTime = now
      }
      
      // Clear timeout and set new one
      clearTimeout(scrollTimeout)
      scrollTimeout = setTimeout(() => {
        this.sendEvent('scroll_complete', {
          final_scroll_depth: this.state.maxScrollDepth,
          scroll_duration: Date.now() - this.state.startTime
        })
      }, 1000)
    }
    
    window.addEventListener('scroll', handleScroll, { passive: true })
  }

  // ==================== READING TIME TRACKING ====================

  startReadingTimeTracking() {
    let readingStartTime = Date.now()
    let isReading = false
    
    const activityEvents = ['scroll', 'click', 'keydown', 'mousemove', 'touchstart']
    
    activityEvents.forEach(eventType => {
      document.addEventListener(eventType, () => {
        const now = Date.now()
        this.state.lastActivity = now
        
        if (!isReading) {
          readingStartTime = now
          isReading = true
        }
        
        // Calculate reading time based on activity
        if (now - readingStartTime > 1000) { // At least 1 second of activity
          this.state.readingTime += 1000
          readingStartTime = now
        }
      }, { passive: true })
    })
    
    // Send reading progress every 30 seconds
    setInterval(() => {
      if (this.state.readingTime > 0) {
        this.sendEvent('reading_progress', {
          reading_time: this.state.readingTime,
          reading_speed: this.calculateReadingSpeed(),
          completion_rate: this.calculateCompletionRate()
        })
      }
    }, 30000)
  }

  // ==================== CLICK TRACKING ====================

  startClickTracking() {
    document.addEventListener('click', (event) => {
      const element = event.target
      const tagName = element.tagName.toLowerCase()
      
      // Track different types of clicks
      if (tagName === 'a') {
        this.sendEvent('link_click', {
          link_url: element.href,
          link_text: element.textContent?.trim(),
          link_domain: element.hostname,
          is_external: element.hostname !== window.location.hostname
        })
      } else if (tagName === 'button') {
        this.sendEvent('button_click', {
          button_text: element.textContent?.trim(),
          button_class: element.className,
          button_id: element.id
        })
      } else {
        // Generic click tracking
        this.sendEvent('element_click', {
          element_tag: tagName,
          element_class: element.className,
          element_id: element.id,
          element_text: element.textContent?.trim()?.substring(0, 100)
        })
      }
    }, { passive: true })
  }

  // ==================== FORM TRACKING ====================

  startFormTracking() {
    // Track form submissions
    document.addEventListener('submit', (event) => {
      const form = event.target
      
      this.sendEvent('form_submit', {
        form_id: form.id,
        form_class: form.className,
        form_action: form.action,
        form_method: form.method,
        field_count: form.elements.length
      })
    })
    
    // Track form field interactions
    document.addEventListener('focus', (event) => {
      if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
        this.sendEvent('form_field_focus', {
          field_type: event.target.type,
          field_name: event.target.name,
          field_id: event.target.id
        })
      }
    })
  }

  // ==================== EXIT INTENT TRACKING ====================

  startExitIntentTracking() {
    let exitIntentTriggered = false
    
    document.addEventListener('mouseleave', (event) => {
      if (event.clientY <= 0 && !exitIntentTriggered) {
        exitIntentTriggered = true
        
        this.sendEvent('exit_intent', {
          time_on_page: Date.now() - this.state.startTime,
          scroll_depth: this.state.maxScrollDepth,
          reading_time: this.state.readingTime,
          is_reader: this.state.isReader
        })
      }
    })
    
    // Track page unload
    window.addEventListener('beforeunload', () => {
      this.sendEvent('page_unload', {
        time_on_page: Date.now() - this.state.startTime,
        scroll_depth: this.state.maxScrollDepth,
        reading_time: this.state.readingTime,
        is_reader: this.state.isReader,
        session_duration: Date.now() - this.state.startTime
      })
      
      this.flushEventQueue()
    })
  }

  // ==================== CONSENT MANAGEMENT ====================

  showConsentBanner() {
    if (this.hasTarget("consentBanner")) {
      this.consentBannerTarget.classList.remove('hidden')
    }
  }

  hideConsentBanner() {
    if (this.hasTarget("consentBanner")) {
      this.consentBannerTarget.classList.add('hidden')
    }
  }

  acceptConsent() {
    this.state.consent = true
    this.setCookie('analytics_consent', 'true', 365)
    this.hideConsentBanner()
    this.startTracking()
    
    this.sendEvent('consent_given', {
      consent_type: 'analytics',
      consent_timestamp: Date.now()
    })
  }

  rejectConsent() {
    this.state.consent = false
    this.setCookie('analytics_consent', 'false', 365)
    this.hideConsentBanner()
    
    this.sendEvent('consent_rejected', {
      consent_type: 'analytics',
      consent_timestamp: Date.now()
    })
  }

  // ==================== EVENT QUEUE MANAGEMENT ====================

  startEventQueue() {
    // Flush queue every 5 seconds
    setInterval(() => {
      this.flushEventQueue()
    }, this.state.config.flushInterval)
    
    // Flush queue when page becomes visible
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.flushEventQueue()
      }
    })
  }

  queueEvent(eventData) {
    if (!this.state.consent) return
    
    this.state.eventQueue.push({
      ...eventData,
      timestamp: Date.now(),
      session_id: this.state.sessionId,
      user_id: this.state.userId
    })
    
    // Prevent queue from growing too large
    if (this.state.eventQueue.length > this.state.config.maxEventQueueSize) {
      this.state.eventQueue = this.state.eventQueue.slice(-this.state.config.batchSize)
    }
    
    // Auto-flush if queue is getting large
    if (this.state.eventQueue.length >= this.state.config.batchSize) {
      this.flushEventQueue()
    }
  }

  async flushEventQueue() {
    if (this.state.eventQueue.length === 0) return
    
    const eventsToSend = [...this.state.eventQueue]
    this.state.eventQueue = []
    
    try {
      const response = await fetch('/analytics/events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          events: eventsToSend,
          session_id: this.state.sessionId,
          user_id: this.state.userId
        })
      })
      
      if (response.ok) {
        this.log(`Successfully sent ${eventsToSend.length} events`)
      } else {
        this.log(`Failed to send events: ${response.status}`)
        // Re-queue events if sending failed
        this.state.eventQueue.unshift(...eventsToSend)
      }
    } catch (error) {
      this.log(`Error sending events: ${error.message}`)
      // Re-queue events if sending failed
      this.state.eventQueue.unshift(...eventsToSend)
    }
  }

  // ==================== UTILITY METHODS ====================

  sendEvent(eventName, properties = {}) {
    this.queueEvent({
      event_name: eventName,
      properties: properties
    })
  }

  hasConsent() {
    return this.getCookie('analytics_consent') === 'true'
  }

  // Enhanced GDPR consent management
  acceptAllConsent() {
    const consentData = {
      analytics: true,
      marketing: true,
      essential: true
    }
    
    this.updateConsentPreferences(consentData)
    this.state.consent = true
    this.hideConsentBanner()
    this.startTracking()
    this.log("All consent accepted")
  }

  rejectAllConsent() {
    const consentData = {
      analytics: false,
      marketing: false,
      essential: true // Essential cookies cannot be rejected
    }
    
    this.updateConsentPreferences(consentData)
    this.state.consent = false
    this.hideConsentBanner()
    this.log("All consent rejected")
  }

  showConsentPreferences() {
    if (this.hasTarget('privacyControls')) {
      this.privacyControlsTarget.classList.remove('hidden')
    }
  }

  hideConsentPreferences() {
    if (this.hasTarget('privacyControls')) {
      this.privacyControlsTarget.classList.add('hidden')
    }
  }

  toggleAnalyticsConsent(event) {
    const button = event.target.closest('button')
    const isActive = button.classList.contains('bg-indigo-500')
    
    if (isActive) {
      button.classList.remove('bg-indigo-500')
      button.classList.add('bg-gray-300')
      button.querySelector('div').style.transform = 'translateX(0)'
    } else {
      button.classList.add('bg-indigo-500')
      button.classList.remove('bg-gray-300')
      button.querySelector('div').style.transform = 'translateX(24px)'
    }
  }

  toggleMarketingConsent(event) {
    const button = event.target.closest('button')
    const isActive = button.classList.contains('bg-indigo-500')
    
    if (isActive) {
      button.classList.remove('bg-indigo-500')
      button.classList.add('bg-gray-300')
      button.querySelector('div').style.transform = 'translateX(0)'
    } else {
      button.classList.add('bg-indigo-500')
      button.classList.remove('bg-gray-300')
      button.querySelector('div').style.transform = 'translateX(24px)'
    }
  }

  saveConsentPreferences() {
    // Get current consent preferences from UI
    const analyticsConsent = this.getConsentPreference('analytics')
    const marketingConsent = this.getConsentPreference('marketing')
    
    const consentData = {
      analytics: analyticsConsent,
      marketing: marketingConsent,
      essential: true // Always true
    }
    
    this.updateConsentPreferences(consentData)
    this.hideConsentPreferences()
    
    if (analyticsConsent) {
      this.state.consent = true
      this.startTracking()
    } else {
      this.state.consent = false
    }
    
    this.log("Consent preferences saved")
  }

  getConsentPreference(type) {
    const button = document.querySelector(`[data-action*="toggle${type.charAt(0).toUpperCase() + type.slice(1)}Consent"]`)
    return button && button.classList.contains('bg-indigo-500')
  }

  updateConsentPreferences(consentData) {
    fetch('/gdpr/consent', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ consent: consentData })
    }).then(response => response.json())
      .then(data => {
        if (data.success) {
          this.log("Consent preferences updated successfully")
        } else {
          this.log("Failed to update consent preferences")
        }
      })
      .catch(error => {
        this.log("Error updating consent preferences:", error)
      })
  }

  // Data subject rights methods
  requestDataAccess() {
    fetch('/gdpr/data-access', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        request_type: 'data_access',
        timestamp: new Date().toISOString()
      })
    }).then(response => response.json())
      .then(data => {
        if (data.error) {
          alert('Error: ' + data.error)
        } else {
          // Redirect to download page
          window.location.href = `/gdpr/download/${this.state.sessionId}`
        }
      })
      .catch(error => {
        this.log("Error requesting data access:", error)
        alert('Error requesting data access')
      })
  }

  requestDataDeletion() {
    if (!confirm('Are you sure you want to delete all your data? This action cannot be undone.')) {
      return
    }
    
    fetch('/gdpr/data-deletion', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        request_type: 'data_deletion',
        timestamp: new Date().toISOString()
      })
    }).then(response => response.json())
      .then(data => {
        if (data.success) {
          alert(`Successfully deleted ${data.deleted_records} records`)
          // Clear local state
          this.state.consent = false
          this.clearLocalData()
        } else {
          alert('Error: ' + (data.error || 'Failed to delete data'))
        }
      })
      .catch(error => {
        this.log("Error requesting data deletion:", error)
        alert('Error requesting data deletion')
      })
  }

  requestDataPortability() {
    fetch('/gdpr/data-portability', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        request_type: 'data_portability',
        timestamp: new Date().toISOString()
      })
    }).then(response => response.json())
      .then(data => {
        if (data.error) {
          alert('Error: ' + data.error)
        } else {
          // Download the data
          const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = `railspress_data_${this.state.sessionId}_${new Date().toISOString().split('T')[0]}.json`
          document.body.appendChild(a)
          a.click()
          document.body.removeChild(a)
          URL.revokeObjectURL(url)
        }
      })
      .catch(error => {
        this.log("Error requesting data portability:", error)
        alert('Error requesting data portability')
      })
  }

  contactDPO() {
    const email = prompt('Please enter your email address:')
    const message = prompt('Please enter your message:')
    
    if (email && message) {
      fetch('/gdpr/contact-dpo', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          email: email,
          message: message,
          timestamp: new Date().toISOString()
        })
      }).then(response => response.json())
        .then(data => {
          if (data.success) {
            alert('Your message has been sent to our Data Protection Officer')
          } else {
            alert('Error: ' + (data.error || 'Failed to send message'))
          }
        })
        .catch(error => {
          this.log("Error contacting DPO:", error)
          alert('Error contacting DPO')
        })
    }
  }

  clearLocalData() {
    // Clear all local storage and cookies related to analytics
    localStorage.removeItem('analytics_session_id')
    localStorage.removeItem('analytics_user_id')
    localStorage.removeItem('analytics_consent')
    
    // Clear analytics cookies
    const cookies = ['analytics_session_id', 'analytics_consent_analytics', 'analytics_consent_marketing']
    cookies.forEach(cookie => {
      document.cookie = `${cookie}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`
    })
    
    this.log("Local analytics data cleared")
  }

  getOrCreateSessionId() {
    let sessionId = this.getCookie('analytics_session_id')
    
    if (!sessionId) {
      sessionId = this.generateId()
      this.setCookie('analytics_session_id', sessionId, 30) // 30 days
    }
    
    return sessionId
  }

  getOrCreateUserId() {
    let userId = this.getCookie('analytics_user_id')
    
    if (!userId) {
      userId = this.generateId()
      this.setCookie('analytics_user_id', userId, 365) // 1 year
    }
    
    return userId
  }

  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
  }

  setCookie(name, value, days) {
    const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toUTCString()
    document.cookie = `${name}=${value}; expires=${expires}; path=/; SameSite=Lax`
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(';').shift()
    return null
  }

  // ==================== CALCULATION METHODS ====================

  calculateEngagementScore(timeSpent) {
    const scrollScore = Math.min(this.state.maxScrollDepth, 100)
    const timeScore = Math.min((timeSpent / 60000) * 100, 100) // Max at 1 minute
    const readingScore = Math.min((this.state.readingTime / 60000) * 100, 100)
    
    // Weighted score: 40% scroll, 30% time, 30% reading
    return Math.round((scrollScore * 0.4) + (timeScore * 0.3) + (readingScore * 0.3))
  }

  calculateCompletionRate() {
    return Math.min(this.state.maxScrollDepth, 100)
  }

  calculateReadingSpeed() {
    const wordCount = this.getWordCount()
    const readingTimeMinutes = this.state.readingTime / 60000
    return wordCount > 0 && readingTimeMinutes > 0 ? Math.round(wordCount / readingTimeMinutes) : 0
  }

  getWordCount() {
    const text = document.body.innerText || document.body.textContent || ''
    return text.split(/\s+/).filter(word => word.length > 0).length
  }

  getEstimatedReadingTime() {
    const wordCount = this.getWordCount()
    const wordsPerMinute = 200 // Average reading speed
    return Math.ceil(wordCount / wordsPerMinute)
  }

  getConnectionType() {
    return navigator.connection?.effectiveType || 'unknown'
  }

  isNewSession() {
    const lastSession = this.getCookie('analytics_last_session')
    const currentSession = this.state.sessionId
    
    if (!lastSession || lastSession !== currentSession) {
      this.setCookie('analytics_last_session', currentSession, 30)
      return true
    }
    
    return false
  }

  isReturningVisitor() {
    return this.getCookie('analytics_user_id') !== null
  }

  log(message, data = null) {
    if (this.debugValue) {
      console.log(`[GA4 Analytics] ${message}`, data)
    }
  }
}
