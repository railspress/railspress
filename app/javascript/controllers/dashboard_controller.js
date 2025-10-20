import { Controller } from "@hotwired/stimulus"
import * as Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = ["trafficChart", "referrersChart", "activityFeed"]

  connect() {
    console.log("Dashboard controller connected")
    this.initializeCharts()
    this.startRealTimeUpdates()
  }

  disconnect() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval)
    }
    if (this.activityInterval) {
      clearInterval(this.activityInterval)
    }
  }

  initializeCharts() {
    this.initializeTrafficChart()
    this.initializeReferrersChart()
  }

  initializeTrafficChart() {
    if (!this.hasTrafficChartTarget) return

    const ctx = this.trafficChartTarget.getContext('2d')
    
    // Sample data - in real implementation, this would come from the server
    const trafficData = {
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      datasets: [{
        label: 'Pageviews',
        data: [1200, 1900, 3000, 5000, 2000, 3000, 4500],
        borderColor: 'rgb(99, 102, 241)',
        backgroundColor: 'rgba(99, 102, 241, 0.1)',
        tension: 0.4,
        fill: true
      }, {
        label: 'Unique Visitors',
        data: [800, 1200, 1800, 2500, 1500, 2000, 2800],
        borderColor: 'rgb(16, 185, 129)',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true
      }]
    }

    this.trafficChart = new Chart(ctx, {
      type: 'line',
      data: trafficData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: {
              color: '#e5e7eb'
            }
          }
        },
        scales: {
          x: {
            ticks: {
              color: '#9ca3af'
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          },
          y: {
            ticks: {
              color: '#9ca3af'
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          }
        },
        interaction: {
          intersect: false,
          mode: 'index'
        }
      }
    })
  }

  initializeReferrersChart() {
    if (!this.hasReferrersChartTarget) return

    const ctx = this.referrersChartTarget.getContext('2d')
    
    // Sample data - in real implementation, this would come from the server
    const referrerData = {
      labels: ['Direct', 'Google', 'Facebook', 'Twitter', 'LinkedIn', 'Other'],
      datasets: [{
        data: [35, 25, 15, 10, 8, 7],
        backgroundColor: [
          'rgba(99, 102, 241, 0.8)',
          'rgba(16, 185, 129, 0.8)',
          'rgba(59, 130, 246, 0.8)',
          'rgba(236, 72, 153, 0.8)',
          'rgba(245, 158, 11, 0.8)',
          'rgba(107, 114, 128, 0.8)'
        ],
        borderColor: [
          'rgb(99, 102, 241)',
          'rgb(16, 185, 129)',
          'rgb(59, 130, 246)',
          'rgb(236, 72, 153)',
          'rgb(245, 158, 11)',
          'rgb(107, 114, 128)'
        ],
        borderWidth: 2
      }]
    }

    this.referrersChart = new Chart(ctx, {
      type: 'doughnut',
      data: referrerData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#e5e7eb',
              padding: 20,
              usePointStyle: true
            }
          }
        }
      }
    })
  }

  startRealTimeUpdates() {
    // Update charts every 30 seconds
    this.updateInterval = setInterval(() => {
      this.updateCharts()
    }, 30000)

    // Update activity feed every 10 seconds
    this.activityInterval = setInterval(() => {
      this.updateActivityFeed()
    }, 10000)

    // Initial load
    this.updateActivityFeed()
  }

  async updateCharts() {
    try {
      // In a real implementation, you would fetch updated data from the server
      // For now, we'll simulate some data updates
      if (this.trafficChart) {
        const newData = this.generateRandomTrafficData()
        this.trafficChart.data.datasets[0].data = newData.pageviews
        this.trafficChart.data.datasets[1].data = newData.visitors
        this.trafficChart.update('none') // 'none' for smooth update
      }

      if (this.referrersChart) {
        const newData = this.generateRandomReferrerData()
        this.referrersChart.data.datasets[0].data = newData
        this.referrersChart.update('none')
      }
    } catch (error) {
      console.error('Failed to update charts:', error)
    }
  }

  async updateActivityFeed() {
    if (!this.hasActivityFeedTarget) return

    try {
      // In a real implementation, you would fetch real-time activity from the server
      const activities = this.generateSampleActivities()
      this.renderActivityFeed(activities)
    } catch (error) {
      console.error('Failed to update activity feed:', error)
    }
  }

  renderActivityFeed(activities) {
    if (!this.hasActivityFeedTarget) return

    const feed = this.activityFeedTarget
    feed.innerHTML = ''

    if (activities.length === 0) {
      feed.innerHTML = '<div class="text-center text-gray-500 py-4">No recent activity</div>'
      return
    }

    activities.forEach(activity => {
      const activityElement = document.createElement('div')
      activityElement.className = 'flex items-center space-x-3 p-3 bg-[#0a0a0a] rounded-lg hover:bg-[#1a1a1a] transition-colors'
      
      activityElement.innerHTML = `
        <div class="w-2 h-2 bg-green-400 rounded-full"></div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium">${activity.title}</p>
          <p class="text-gray-500 text-xs">${activity.description}</p>
        </div>
        <div class="text-right">
          <p class="text-gray-400 text-xs">${activity.time}</p>
        </div>
      `
      
      feed.appendChild(activityElement)
    })
  }

  generateRandomTrafficData() {
    return {
      pageviews: Array.from({ length: 7 }, () => Math.floor(Math.random() * 3000) + 1000),
      visitors: Array.from({ length: 7 }, () => Math.floor(Math.random() * 2000) + 500)
    }
  }

  generateRandomReferrerData() {
    return Array.from({ length: 6 }, () => Math.floor(Math.random() * 40) + 5)
  }

  generateSampleActivities() {
    const activities = [
      { title: 'New visitor from United States', description: 'Viewed homepage', time: '2 min ago' },
      { title: 'User completed contact form', description: 'Lead captured', time: '5 min ago' },
      { title: 'Returning visitor from Google', description: 'Read blog post', time: '8 min ago' },
      { title: 'New subscriber', description: 'Email newsletter signup', time: '12 min ago' },
      { title: 'Social media referral', description: 'From Facebook', time: '15 min ago' }
    ]
    
    return activities.slice(0, Math.floor(Math.random() * 3) + 2)
  }

  // Method to refresh all dashboard data
  refreshDashboard() {
    this.updateCharts()
    this.updateActivityFeed()
  }

  // Method to handle period changes
  changePeriod(period) {
    // Update URL and reload data
    const url = new URL(window.location)
    url.searchParams.set('period', period)
    window.location.href = url.toString()
  }
}
