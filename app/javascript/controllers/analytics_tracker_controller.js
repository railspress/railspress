import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="analytics-tracker"
// GDPR-compliant pageview tracking
export default class extends Controller {
  connect() {
    // Check if user has consented to analytics
    if (this.hasConsent()) {
      this.trackPageview()
      this.trackDuration()
    } else {
      // Show consent banner if not decided yet
      if (!this.hasDecided()) {
        this.showConsentBanner()
      }
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
      consented: true
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
              We use privacy-friendly analytics to understand how you use our site. 
              No personal data is collected.
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
}




