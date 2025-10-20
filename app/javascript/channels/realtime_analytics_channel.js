import consumer from "./consumer"

console.log("Loading RealtimeAnalyticsChannel...")

const subscription = consumer.subscriptions.create("RealtimeAnalyticsChannel", {
  connected() {
    console.log("✅ Connected to RealtimeAnalyticsChannel")
  },

  disconnected() {
    console.log("❌ Disconnected from RealtimeAnalyticsChannel")
  },

  rejected() {
    console.log("❌ Rejected from RealtimeAnalyticsChannel")
  },

  received(data) {
    console.log("Received real-time analytics data:", data)
    
    if (data.type === 'new_pageview' || data.type === 'stats_update') {
      this.updateRealtimeMetrics(data)
      this.updateActivityFeed(data.recent_views)
    }
  },

  updateRealtimeMetrics(data) {
    // Update active users
    const activeUsersEl = document.querySelector('[data-realtime-analytics-target="activeUsers"]')
    if (activeUsersEl && data.stats) {
      activeUsersEl.textContent = data.stats.active_users || 0
    }

    // Update pageviews
    const pageviewsEl = document.querySelector('[data-realtime-analytics-target="pageviewsHour"]')
    if (pageviewsEl && data.stats) {
      pageviewsEl.textContent = data.stats.current_pageviews || 0
    }

    // Update unique sessions
    const sessionsEl = document.querySelector('[data-realtime-analytics-target="uniqueSessions"]')
    if (sessionsEl && data.stats) {
      sessionsEl.textContent = data.stats.unique_sessions || 0
    }

    // Update active countries
    const countriesEl = document.querySelector('[data-realtime-analytics-target="activeCountries"]')
    if (countriesEl && data.stats) {
      countriesEl.textContent = data.stats.active_countries || 0
    }
  },

  updateActivityFeed(activities) {
    const feedEl = document.querySelector('[data-realtime-analytics-target="activityFeed"]')
    if (!feedEl || !activities) return

    // Clear existing content
    feedEl.innerHTML = ''

    if (activities.length === 0) {
      feedEl.innerHTML = '<div class="text-center py-8"><p class="text-gray-400">No recent activity</p></div>'
      return
    }

    // Add new activities
    activities.slice(0, 10).forEach(activity => {
      const activityElement = this.createActivityElement(activity)
      feedEl.appendChild(activityElement)
    })
  },

  createActivityElement(activity) {
    const div = document.createElement('div')
    div.className = 'flex items-center space-x-3 py-2 px-3 bg-gray-700/30 rounded-lg'
    
    const timeAgo = this.timeAgo(activity.created_at)
    const path = activity.path || 'Homepage'
    const country = activity.country || 'Unknown location'
    const browser = activity.browser || 'Unknown'
    const device = activity.device || 'Unknown'
    
    div.innerHTML = `
      <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
      <div class="flex-1 min-w-0">
        <p class="text-sm text-gray-200 truncate">${path}</p>
        <p class="text-xs text-gray-400">${country} • ${timeAgo}</p>
      </div>
      <div class="text-right">
        <p class="text-xs text-gray-400">${browser}</p>
        <p class="text-xs text-gray-500">${device}</p>
      </div>
    `
    
    return div
  },

  timeAgo(dateString) {
    const date = new Date(dateString)
    const now = new Date()
    const diffInSeconds = Math.floor((now - date) / 1000)
    
    if (diffInSeconds < 60) {
      return 'Just now'
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60)
      return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`
    } else {
      const hours = Math.floor(diffInSeconds / 3600)
      return `${hours} hour${hours !== 1 ? 's' : ''} ago`
    }
  }
})