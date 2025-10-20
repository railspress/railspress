import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "trafficChart", "deviceChart", "totalPageviews", "uniqueVisitors", 
    "avgSessionDuration", "bounceRate", "currentPageviews"
  ]
  static values = { 
    trafficData: Array,
    deviceData: Array,
    realtimeUrl: String
  }
  
  connect() {
    this.loadChartJs().then(() => {
      this.initializeCharts()
      this.startRealtimeUpdates()
    })
  }
  
  disconnect() {
    // Cleanup real-time updates
    if (this.realtimeInterval) {
      clearInterval(this.realtimeInterval)
    }
  }
  
  async loadChartJs() {
    if (window.Chart) {
      return Promise.resolve()
    }
    
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'
      script.onload = () => {
        // Chart.js is now available as window.Chart
        resolve()
      }
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
  
  
  initializeCharts() {
    this.initializeTrafficChart()
    this.initializeDeviceChart()
  }
  
  initializeTrafficChart() {
    if (!this.hasTrafficChartTarget) {
      console.log('Traffic chart target not available')
      return
    }
    
    const ctx = this.trafficChartTarget.getContext('2d')
    new window.Chart(ctx, {
      type: 'line',
      data: {
        labels: this.getTrafficLabels(),
        datasets: [{
          label: 'Pageviews',
          data: this.getTrafficData(),
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: '#9CA3AF'
            }
          },
          y: {
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: '#9CA3AF'
            }
          }
        }
      }
    })
  }
  
  initializeDeviceChart() {
    if (!this.hasDeviceChartTarget) {
      console.log('Device chart target not available')
      return
    }
    
    const ctx = this.deviceChartTarget.getContext('2d')
    new window.Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: this.getDeviceLabels(),
        datasets: [{
          data: this.getDeviceData(),
          backgroundColor: [
            '#3B82F6',
            '#10B981', 
            '#F59E0B',
            '#EF4444',
            '#8B5CF6'
          ],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#9CA3AF',
              padding: 20
            }
          }
        }
      }
    })
  }
  
  getTrafficLabels() {
    // Generate last 7 days labels
    const labels = []
    for (let i = 6; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      labels.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }))
    }
    return labels
  }
  
  getTrafficData() {
    if (this.trafficDataValue && this.trafficDataValue.length > 0) {
      return this.trafficDataValue.map(item => item.count || 0)
    }
    return [0, 0, 0, 0, 0, 0, 0]
  }
  
  getDeviceLabels() {
    if (this.deviceDataValue && this.deviceDataValue.length > 0) {
      return this.deviceDataValue.map(item => item[0])
    }
    return ['Desktop', 'Mobile', 'Tablet', 'Other']
  }
  
  getDeviceData() {
    if (this.deviceDataValue && this.deviceDataValue.length > 0) {
      return this.deviceDataValue.map(item => item[1])
    }
    return [65, 25, 8, 2]
  }
  
  initializeTrendChart() {
    if (!this.hasTrendChartTarget || !this.trendDataValue) {
      console.log('Trend chart target or data not available')
      return
    }
    
    try {
      const trendData = Array.isArray(this.trendDataValue) ? this.trendDataValue : []
      const ctx = this.trendChartTarget
      
      if (!ctx) {
        console.error('Chart context not found')
        return
      }
      
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: trendData.map(d => d.date),
          datasets: [{
            label: 'Pageviews',
            data: trendData.map(d => d.count),
            borderColor: 'rgb(99, 102, 241)',
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            tension: 0.4,
            fill: true
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: { color: '#9ca3af' },
              grid: { color: '#374151' }
            },
            x: {
              ticks: { color: '#9ca3af' },
              grid: { color: '#374151' }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize trend chart:', error)
    }
  }
  
  initializeTopPagesChart() {
    if (!this.hasTopPagesChartTarget || !this.topPagesDataValue) {
      console.log('Top pages chart target or data not available')
      return
    }
    
    try {
      const topPagesData = Array.isArray(this.topPagesDataValue) ? this.topPagesDataValue : []
      const ctx = this.topPagesChartTarget
      
      if (!ctx) {
        console.error('Chart context not found')
        return
      }
      
      new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: topPagesData.map(d => d.title || d.page || 'Unknown'),
          datasets: [{
            data: topPagesData.map(d => d.views),
            backgroundColor: [
              'rgba(99, 102, 241, 0.8)',
              'rgba(16, 185, 129, 0.8)',
              'rgba(245, 158, 11, 0.8)',
              'rgba(239, 68, 68, 0.8)',
              'rgba(139, 92, 246, 0.8)'
            ],
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom',
              labels: {
                color: '#9ca3af',
                padding: 20,
                usePointStyle: true
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize top pages chart:', error)
    }
  }
  
  initializeReferrersChart() {
    if (!this.hasReferrersChartTarget || !this.referrersDataValue) {
      console.log('Referrers chart target or data not available')
      return
    }
    
    try {
      const referrersData = Array.isArray(this.referrersDataValue) ? this.referrersDataValue : []
      const ctx = this.referrersChartTarget
      
      if (!ctx) {
        console.error('Chart context not found')
        return
      }
      
      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: referrersData.map(d => d.referrer || 'Direct'),
          datasets: [{
            label: 'Visits',
            data: referrersData.map(d => d.count || d.visits || 0),
            backgroundColor: 'rgba(99, 102, 241, 0.8)',
            borderColor: 'rgb(99, 102, 241)',
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: { color: '#9ca3af' },
              grid: { color: '#374151' }
            },
            x: {
              ticks: { color: '#9ca3af' },
              grid: { color: '#374151' }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize referrers chart:', error)
    }
  }
  
  startRealtimeUpdates() {
    if (!this.realtimeUrlValue) return
    
    // Update real-time data every 30 seconds
    this.realtimeInterval = setInterval(() => {
      this.fetchRealtimeData()
    }, 30000)
    
    // Initial fetch
    this.fetchRealtimeData()
  }
  
  async fetchRealtimeData() {
    try {
      const response = await fetch(this.realtimeUrlValue)
      const data = await response.json()
      
      // Update active users count
      if (this.hasActiveUsersTarget) {
        this.activeUsersTarget.textContent = data.active_users
      }
      
      // Update current pageviews count
      if (this.hasCurrentPageviewsTarget) {
        this.currentPageviewsTarget.textContent = data.current_pageviews
      }
      
      // Update charts with new data if needed
      this.updateChartsWithRealtimeData(data)
      
    } catch (error) {
      console.error('Failed to fetch real-time data:', error)
    }
  }
  
  updateChartsWithRealtimeData(data) {
    // Update trend chart with latest data point if available
    if (this.trendChart && data.timestamp) {
      // This would update the chart with the latest data
      // Implementation depends on your chart library
    }
  }

  // Professional-grade chart initialization methods
  initializeEngagementChart() {
    if (!this.hasEngagementChartTarget || !this.engagementDataValue) return

    const ctx = this.engagementChartTarget.getContext('2d')
    const data = this.engagementDataValue || [
      { level: 'high', count: 150 },
      { level: 'medium', count: 300 },
      { level: 'low', count: 100 }
    ]

    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: data.map(d => d.level.charAt(0).toUpperCase() + d.level.slice(1)),
        datasets: [{
          data: data.map(d => d.count),
          backgroundColor: [
            'rgba(16, 185, 129, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(239, 68, 68, 0.8)'
          ],
          borderColor: [
            'rgba(16, 185, 129, 1)',
            'rgba(245, 158, 11, 1)',
            'rgba(239, 68, 68, 1)'
          ],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        }
      }
    })
  }

  initializeDeviceChart() {
    if (!this.hasDeviceChartTarget || !this.deviceDataValue) return

    const ctx = this.deviceChartTarget.getContext('2d')
    const data = this.deviceDataValue || [
      { device: 'Mobile', count: 400 },
      { device: 'Desktop', count: 300 },
      { device: 'Tablet', count: 50 }
    ]

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.map(d => d.device),
        datasets: [{
          label: 'Visitors',
          data: data.map(d => d.count),
          backgroundColor: 'rgba(99, 102, 241, 0.8)',
          borderColor: 'rgba(99, 102, 241, 1)',
          borderWidth: 1,
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          },
          x: {
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          }
        }
      }
    })
  }

  initializeCountryChart() {
    if (!this.hasCountryChartTarget || !this.countryDataValue) return

    const ctx = this.countryChartTarget.getContext('2d')
    const data = this.countryDataValue || [
      { country: 'US', count: 250 },
      { country: 'GB', count: 150 },
      { country: 'CA', count: 100 }
    ]

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.map(d => d.country),
        datasets: [{
          label: 'Visitors',
          data: data.map(d => d.count),
          backgroundColor: 'rgba(16, 185, 129, 0.8)',
          borderColor: 'rgba(16, 185, 129, 1)',
          borderWidth: 1,
          borderRadius: 8
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          },
          y: {
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          }
        }
      }
    })
  }

  initializeTrafficSourceChart() {
    if (!this.hasTrafficSourceChartTarget) return

    const ctx = this.trafficSourceChartTarget.getContext('2d')
    const data = this.referrersDataValue || []

    new Chart(ctx, {
      type: 'pie',
      data: {
        labels: data.map(d => d.referrer || 'Direct'),
        datasets: [{
          data: data.map(d => d.count || d.visits || 0),
          backgroundColor: [
            'rgba(99, 102, 241, 0.8)',
            'rgba(16, 185, 129, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(239, 68, 68, 0.8)',
            'rgba(139, 92, 246, 0.8)'
          ],
          borderColor: [
            'rgba(99, 102, 241, 1)',
            'rgba(16, 185, 129, 1)',
            'rgba(245, 158, 11, 1)',
            'rgba(239, 68, 68, 1)',
            'rgba(139, 92, 246, 1)'
          ],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        }
      }
    })
  }

  initializePerformanceChart() {
    if (!this.hasPerformanceChartTarget || !this.performanceDataValue) return

    const ctx = this.performanceChartTarget.getContext('2d')
    const data = this.performanceDataValue || {
      page_load_time: 85,
      time_to_interactive: 78,
      first_contentful_paint: 92,
      largest_contentful_paint: 88
    }

    new Chart(ctx, {
      type: 'radar',
      data: {
        labels: ['Page Load Time', 'Time to Interactive', 'First Contentful Paint', 'Largest Contentful Paint'],
        datasets: [{
          label: 'Performance Score',
          data: [
            data.page_load_time || 85,
            data.time_to_interactive || 78,
            data.first_contentful_paint || 92,
            data.largest_contentful_paint || 88
          ],
          backgroundColor: 'rgba(99, 102, 241, 0.2)',
          borderColor: 'rgba(99, 102, 241, 1)',
          borderWidth: 2,
          pointBackgroundColor: 'rgba(99, 102, 241, 1)',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          r: {
            beginAtZero: true,
            max: 100,
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' },
            pointLabels: { color: '#ffffff' }
          }
        },
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        }
      }
    })
  }

  initializeConversionChart() {
    if (!this.hasConversionChartTarget || !this.conversionDataValue) return

    const ctx = this.conversionChartTarget.getContext('2d')
    const data = this.conversionDataValue || [
      { stage: 'Visitors', count: 1000 },
      { stage: 'Page Views', count: 750 },
      { stage: 'Engaged Users', count: 500 },
      { stage: 'Readers', count: 300 },
      { stage: 'Conversions', count: 50 }
    ]

    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.map(d => d.stage),
        datasets: [{
          label: 'Users',
          data: data.map(d => d.count),
          backgroundColor: 'rgba(236, 72, 153, 0.8)',
          borderColor: 'rgba(236, 72, 153, 1)',
          borderWidth: 1,
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: '#ffffff' }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          },
          x: {
            ticks: { color: '#ffffff' },
            grid: { color: 'rgba(255, 255, 255, 0.1)' }
          }
        }
      }
    })
  }
}




