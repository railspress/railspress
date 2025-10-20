import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="analytics-tracker"
// GDPR-compliant pageview tracking
export default class extends Controller {
  connect() {
    // Check if analytics is enabled
    if (!this.isAnalyticsEnabled()) {
      return
    }
    
    // Check if consent is required
    if (this.isConsentRequired()) {
      if (this.hasConsent()) {
        this.trackPageview()
        this.trackDuration()
      } else if (!this.hasDecided()) {
        this.showConsentBanner()
      }
    } else {
      // No consent required, track immediately
      this.trackPageview()
      this.trackDuration()
    }
  }

  disconnect() {
    this.sendDuration()
  }

  hasConsent() {
    return this.getCookie('analytics_consent') === 'true'
  }

  hasDecided() {
    return this.getCookie('analytics_consent') !== null
  }
  
  isAnalyticsEnabled() {
    // Check if analytics is enabled via meta tag or data attribute
    const meta = document.querySelector('meta[name="analytics-enabled"]')
    return meta ? meta.content === 'true' : true
  }
  
  isConsentRequired() {
    // Check if consent is required via meta tag or data attribute
    const meta = document.querySelector('meta[name="analytics-require-consent"]')
    return meta ? meta.content === 'true' : true
  }
  
  getConsentMessage() {
    // Get custom consent message from meta tag
    const meta = document.querySelector('meta[name="analytics-consent-message"]')
    return meta ? meta.content : 'We use privacy-friendly analytics to understand how you use our site. No personal data is collected.'
  }

  trackPageview() {
    const data = {
      path: window.location.pathname,
      title: document.title,
      referrer: document.referrer || null,
      screen_width: window.screen.width,
      screen_height: window.screen.height,
      viewport_width: window.innerWidth,
      viewport_height: window.innerHeight,
      language: navigator.language,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      user_agent: navigator.userAgent,
      platform: navigator.platform,
      cookie_enabled: navigator.cookieEnabled,
      online_status: navigator.onLine,
      connection_type: navigator.connection?.effectiveType || 'unknown',
      consented: true,
      timestamp: new Date().toISOString(),
      reading_time: this.estimateReadingTime(),
      word_count: this.countWords()
    }

    fetch('/analytics/track', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(data),
      keepalive: true  // Ensure tracking completes even on navigation
    }).catch(err => {
      console.error('Analytics tracking failed:', err)
    })
    
    // Track additional events
    this.trackScrollDepth()
    this.trackClickEvents()
    this.trackFormInteractions()
    this.trackReadingTime()
    this.trackExitIntent()
  }

  trackDuration() {
    this.startTime = Date.now()
  }

  sendDuration() {
    if (!this.hasConsent() || !this.startTime) return

    const duration = Math.floor((Date.now() - this.startTime) / 1000)  // seconds

    if (duration > 0) {
      navigator.sendBeacon('/analytics/duration', JSON.stringify({
        path: window.location.pathname,
        duration: duration
      }))
    }
  }

  showConsentBanner() {
    // Check if banner already shown
    if (document.getElementById('analytics-consent-banner')) return

    const banner = document.createElement('div')
    banner.id = 'analytics-consent-banner'
    banner.className = 'fixed bottom-0 left-0 right-0 bg-gray-900 text-white p-4 shadow-lg z-50 border-t border-gray-700'
    banner.innerHTML = `
      <div class="container mx-auto max-w-6xl">
        <div class="flex items-center justify-between gap-4 flex-wrap">
          <div class="flex-1">
            <p class="text-sm">
              <strong>🍪 We value your privacy.</strong> 
              ${this.getConsentMessage()}
              <a href="/privacy" class="underline hover:text-gray-300">Learn more</a>
            </p>
          </div>
          <div class="flex gap-2">
            <button onclick="window.dispatchEvent(new CustomEvent('analytics:accept'))" 
                    class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded transition">
              Accept
            </button>
            <button onclick="window.dispatchEvent(new CustomEvent('analytics:decline'))" 
                    class="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded transition">
              Decline
            </button>
          </div>
        </div>
      </div>
    `

    document.body.appendChild(banner)

    // Listen for consent events
    window.addEventListener('analytics:accept', () => {
      this.acceptConsent()
      banner.remove()
    })

    window.addEventListener('analytics:decline', () => {
      this.declineConsent()
      banner.remove()
    })
  }

  acceptConsent() {
    this.setCookie('analytics_consent', 'true', 365)
    // Track this pageview now that we have consent
    this.trackPageview()
    this.trackDuration()
  }

  declineConsent() {
    this.setCookie('analytics_consent', 'false', 365)
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) {
      const cookieValue = parts.pop().split(';').shift()
      return cookieValue === 'null' ? null : cookieValue
    }
    return null
  }

  setCookie(name, value, days) {
    const expires = new Date()
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`
  }
  
  // Track scroll depth
  trackScrollDepth() {
    let scrollDepthTracked = false
    
    const trackScroll = () => {
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      
      if (scrollDepth > this.maxScrollDepth) {
        this.maxScrollDepth = scrollDepth
        
        // Track milestones: 25%, 50%, 75%, 100%
        if (scrollDepth >= 25 && !scrollDepthTracked) {
          this.trackEvent('scroll_depth', { depth: 25, path: window.location.pathname })
          scrollDepthTracked = true
        } else if (scrollDepth >= 50) {
          this.trackEvent('scroll_depth', { depth: 50, path: window.location.pathname })
        } else if (scrollDepth >= 75) {
          this.trackEvent('scroll_depth', { depth: 75, path: window.location.pathname })
        } else if (scrollDepth >= 100) {
          this.trackEvent('scroll_depth', { depth: 100, path: window.location.pathname })
        }
      }
    }
    
    window.addEventListener('scroll', trackScroll, { passive: true })
  }
  
  // Track click events
  trackClickEvents() {
    document.addEventListener('click', (event) => {
      const element = event.target
      const tagName = element.tagName.toLowerCase()
      
      let eventData = {
        element_type: tagName,
        element_id: element.id || null,
        element_class: element.className || null,
        element_text: element.textContent?.trim().substring(0, 100) || null,
        path: window.location.pathname
      }
      
      // Track specific types of clicks
      if (tagName === 'a') {
        eventData.href = element.href
        eventData.is_external = !element.href.includes(window.location.hostname)
        this.trackEvent('link_click', eventData)
      } else if (tagName === 'button') {
        this.trackEvent('button_click', eventData)
      } else if (element.matches('input[type="submit"], input[type="button"]')) {
        this.trackEvent('form_submit_click', eventData)
      } else {
        this.trackEvent('element_click', eventData)
      }
    }, { passive: true })
  }
  
  // Track form interactions
  trackFormInteractions() {
    // Track form submissions
    document.addEventListener('submit', (event) => {
      const form = event.target
      if (form.tagName.toLowerCase() === 'form') {
        this.trackEvent('form_submit', {
          form_id: form.id || null,
          form_class: form.className || null,
          form_action: form.action || null,
          form_method: form.method || null,
          field_count: form.elements.length,
          path: window.location.pathname
        })
      }
    })
    
    // Track form field interactions
    document.addEventListener('focus', (event) => {
      const element = event.target
      if (element.matches('input, textarea, select')) {
        this.trackEvent('form_field_focus', {
          field_type: element.type || element.tagName.toLowerCase(),
          field_name: element.name || null,
          field_id: element.id || null,
          path: window.location.pathname
        })
      }
    })
  }
  
  // Generic event tracking method
  trackEvent(eventName, properties = {}) {
    if (!this.hasConsent()) return
    
    const data = {
      event_name: eventName,
      properties: {
        ...properties,
        timestamp: new Date().toISOString(),
        session_id: this.getSessionId(),
        path: window.location.pathname
      }
    }
    
    fetch('/analytics/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(data),
      keepalive: true
    }).catch(err => {
      console.error('Event tracking failed:', err)
    })
  }
  
  // Get or create session ID
  getSessionId() {
    let sessionId = this.getCookie('_railspress_session_id')
    if (!sessionId) {
      sessionId = this.generateSessionId()
      this.setCookie('_railspress_session_id', sessionId, 30) // 30 days
    }
    return sessionId
  }
  
  // Generate session ID
  generateSessionId() {
    return 'sess_' + Math.random().toString(36).substr(2, 9) + Date.now().toString(36)
  }
  
  // Estimate reading time based on content
  estimateReadingTime() {
    const text = document.body.innerText || document.body.textContent || ''
    const wordsPerMinute = 200 // Average reading speed
    const wordCount = text.split(/\s+/).filter(word => word.length > 0).length
    return Math.ceil(wordCount / wordsPerMinute)
  }
  
  // Count words in the page
  countWords() {
    const text = document.body.innerText || document.body.textContent || ''
    return text.split(/\s+/).filter(word => word.length > 0).length
  }
  
  // Track reading time and completion (Medium-like)
  trackReadingTime() {
    this.readingStartTime = Date.now()
    this.maxScrollDepth = 0
    this.timeOnPage = 0
    this.isReader = false // Medium considers 30+ seconds as a "reader"
    this.engagementScore = 0
    
    // Update reading time every 5 seconds for more accurate tracking
    this.readingInterval = setInterval(() => {
      this.timeOnPage += 5
      
      // Check if user qualifies as a "reader" (30+ seconds like Medium)
      if (this.timeOnPage >= 30 && !this.isReader) {
        this.isReader = true
        this.trackEvent('reader_qualified', {
          time_to_reader: this.timeOnPage,
          scroll_depth: this.maxScrollDepth,
          completion_rate: this.calculateCompletionRate()
        })
      }
      
      // Send reading progress every 5 seconds
      this.trackEvent('reading_progress', {
        time_on_page: this.timeOnPage,
        scroll_depth: this.maxScrollDepth,
        completion_rate: this.maxScrollDepth / 100
      })
    }, 10000)
    
    // Track when user leaves the page
    window.addEventListener('beforeunload', () => {
      this.sendReadingData()
    })
  }
  
  // Track exit intent
  trackExitIntent() {
    let exitIntentTracked = false
    
    // Track mouse movement toward top of page (exit intent)
    document.addEventListener('mousemove', (e) => {
      if (exitIntentTracked) return
      
      // If mouse moves to top 5% of the page
      if (e.clientY <= window.innerHeight * 0.05) {
        exitIntentTracked = true
        this.trackEvent('exit_intent', {
          time_on_page: this.timeOnPage || 0,
          scroll_depth: this.maxScrollDepth || 0
        })
      }
    })
  }
  
  // Send reading data when page is unloaded
  sendReadingData() {
    if (!this.hasConsent()) return
    
    const data = {
      path: window.location.pathname,
      reading_time: this.timeOnPage || 0,
      scroll_depth: this.maxScrollDepth || 0,
      completion_rate: this.calculateCompletionRate(),
      exit_intent: true,
      session_id: this.getSessionId(),
      is_reader: this.isReader || false,
      engagement_score: this.calculateEngagementScore(this.timeOnPage || 0)
    }
    
    // Use sendBeacon for reliable tracking on page unload
    if (navigator.sendBeacon) {
      navigator.sendBeacon('/analytics/reading', JSON.stringify(data))
    } else {
      // Fallback to fetch with keepalive
      fetch('/analytics/reading', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data),
        keepalive: true
      }).catch(() => {}) // Ignore errors on page unload
    }
  }
  
  calculateCompletionRate() {
    const scrollDepth = this.maxScrollDepth || 0
    return Math.min(scrollDepth, 100)
  }
  
  calculateEngagementScore(timeSpent) {
    // Calculate engagement score like Medium (0-100)
    const scrollScore = Math.min(this.maxScrollDepth || 0, 100)
    const timeScore = Math.min((timeSpent / 60) * 100, 100) // Max score at 1 minute
    const wordCount = this.countWords()
    const readingSpeed = wordCount > 0 ? (timeSpent / (wordCount / 200)) : 0 // 200 WPM average
    
    // Weighted score: 40% scroll, 40% time, 20% reading speed
    return Math.round((scrollScore * 0.4) + (timeScore * 0.4) + (Math.min(readingSpeed, 100) * 0.2))
  }
}








