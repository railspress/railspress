import { Controller } from "@hotwired/stimulus"
import * as Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = [
    "trendChart", "topPagesChart", "referrersChart", "activeUsers", "currentPageviews",
    "engagementChart", "deviceChart", "countryChart", "realtimeChart", "conversionChart",
    "trafficSourceChart", "userFlowChart", "performanceChart", "insightsPanel"
  ]
  static values = { 
    trendData: Array,
    topPagesData: Array,
    referrersData: Array,
    engagementData: Array,
    deviceData: Array,
    countryData: Array,
    realtimeUrl: String,
    insightsUrl: String
  }
  
  connect() {
    this.loadAdvancedChartJs().then(() => {
      this.initializeProfessionalCharts()
      this.startRealtimeUpdates()
      this.initializeInsights()
    })
  }
  
  disconnect() {
    if (this.realtimeInterval) {
      clearInterval(this.realtimeInterval)
    }
    if (this.insightsInterval) {
      clearInterval(this.insightsInterval)
    }
  }
  
  async loadAdvancedChartJs() {
    if (window.Chart && window.Chart.register) {
      // Load additional Chart.js plugins for professional features
      await this.loadChartPlugins()
      return Promise.resolve()
    }
    
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'
      script.onload = () => {
        this.loadChartPlugins().then(resolve).catch(reject)
      }
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
  
  async loadChartPlugins() {
    // Load Chart.js plugins for advanced features
    const plugins = [
      'https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js',
      'https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.min.js',
      'https://cdn.jsdelivr.net/npm/chartjs-plugin-zoom@2.0.1/dist/chartjs-plugin-zoom.min.js'
    ]
    
    for (const pluginUrl of plugins) {
      await this.loadScript(pluginUrl)
    }
  }
  
  loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
  
  initializeProfessionalCharts() {
    this.initializeTrendChart()
    this.initializeEngagementChart()
    this.initializeDeviceChart()
    this.initializeCountryChart()
    this.initializeTrafficSourceChart()
    this.initializePerformanceChart()
    this.initializeRealtimeChart()
    this.initializeConversionChart()
    this.initializeUserFlowChart()
  }
  
  initializeTrendChart() {
    if (!this.hasTrendChartTarget || !this.trendDataValue) return
    
    try {
      const trendData = Array.isArray(this.trendDataValue) ? this.trendDataValue : []
      const ctx = this.trendChartTarget
      
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: trendData.map(d => d.date),
          datasets: [
            {
              label: 'Pageviews',
              data: trendData.map(d => d.count),
              borderColor: '#6366f1',
              backgroundColor: 'rgba(99, 102, 241, 0.1)',
              borderWidth: 3,
              tension: 0.4,
              fill: true,
              pointBackgroundColor: '#6366f1',
              pointBorderColor: '#ffffff',
              pointBorderWidth: 2,
              pointRadius: 6,
              pointHoverRadius: 8
            },
            {
              label: 'Unique Visitors',
              data: trendData.map(d => d.unique || 0),
              borderColor: '#10b981',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              borderWidth: 3,
              tension: 0.4,
              fill: true,
              pointBackgroundColor: '#10b981',
              pointBorderColor: '#ffffff',
              pointBorderWidth: 2,
              pointRadius: 6,
              pointHoverRadius: 8
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: {
            intersect: false,
            mode: 'index'
          },
          plugins: {
            legend: {
              display: true,
              position: 'top',
              labels: {
                color: '#e5e7eb',
                font: { size: 12, weight: '500' },
                usePointStyle: true,
                padding: 20
              }
            },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8,
              displayColors: true,
              titleFont: { size: 14, weight: '600' },
              bodyFont: { size: 13 }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 },
                callback: function(value) {
                  return value >= 1000 ? (value/1000).toFixed(1) + 'k' : value
                }
              }
            },
            x: {
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          },
          elements: {
            point: {
              hoverBackgroundColor: '#ffffff'
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize trend chart:', error)
    }
  }
  
  initializeEngagementChart() {
    if (!this.hasEngagementChartTarget || !this.engagementDataValue) return
    
    try {
      const engagementData = Array.isArray(this.engagementDataValue) ? this.engagementDataValue : []
      const ctx = this.engagementChartTarget
      
      new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: ['High Engagement', 'Medium Engagement', 'Low Engagement'],
          datasets: [{
            data: [
              engagementData.find(d => d.level === 'high')?.count || 0,
              engagementData.find(d => d.level === 'medium')?.count || 0,
              engagementData.find(d => d.level === 'low')?.count || 0
            ],
            backgroundColor: [
              '#10b981',
              '#f59e0b',
              '#ef4444'
            ],
            borderColor: '#1f2937',
            borderWidth: 2,
            hoverBorderWidth: 3
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          cutout: '60%',
          plugins: {
            legend: {
              position: 'bottom',
              labels: {
                color: '#e5e7eb',
                font: { size: 12, weight: '500' },
                usePointStyle: true,
                padding: 15
              }
            },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize engagement chart:', error)
    }
  }
  
  initializeDeviceChart() {
    if (!this.hasDeviceChartTarget || !this.deviceDataValue) return
    
    try {
      const deviceData = Array.isArray(this.deviceDataValue) ? this.deviceDataValue : []
      const ctx = this.deviceChartTarget
      
      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: deviceData.map(d => d.device),
          datasets: [{
            label: 'Visitors',
            data: deviceData.map(d => d.count),
            backgroundColor: [
              '#6366f1',
              '#8b5cf6',
              '#ec4899',
              '#ef4444',
              '#f59e0b'
            ],
            borderColor: [
              '#4f46e5',
              '#7c3aed',
              '#db2777',
              '#dc2626',
              '#d97706'
            ],
            borderWidth: 2,
            borderRadius: 8,
            borderSkipped: false
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            },
            x: {
              grid: { display: false },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize device chart:', error)
    }
  }
  
  initializeCountryChart() {
    if (!this.hasCountryChartTarget || !this.countryDataValue) return
    
    try {
      const countryData = Array.isArray(this.countryDataValue) ? this.countryDataValue : []
      const ctx = this.countryChartTarget
      
      new Chart(ctx, {
        type: 'horizontalBar',
        data: {
          labels: countryData.map(d => d.country),
          datasets: [{
            label: 'Visitors',
            data: countryData.map(d => d.count),
            backgroundColor: '#6366f1',
            borderColor: '#4f46e5',
            borderWidth: 1,
            borderRadius: 4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          indexAxis: 'y',
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8
            }
          },
          scales: {
            x: {
              beginAtZero: true,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            },
            y: {
              grid: { display: false },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize country chart:', error)
    }
  }
  
  initializeTrafficSourceChart() {
    if (!this.hasTrafficSourceChartTarget || !this.referrersDataValue) return
    
    try {
      const referrersData = Array.isArray(this.referrersDataValue) ? this.referrersDataValue : []
      const ctx = this.trafficSourceChartTarget
      
      new Chart(ctx, {
        type: 'pie',
        data: {
          labels: referrersData.map(d => d.referrer || 'Direct'),
          datasets: [{
            data: referrersData.map(d => d.count || d.visits || 0),
            backgroundColor: [
              '#6366f1',
              '#10b981',
              '#f59e0b',
              '#ef4444',
              '#8b5cf6',
              '#ec4899',
              '#06b6d4',
              '#84cc16'
            ],
            borderColor: '#1f2937',
            borderWidth: 2
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'right',
              labels: {
                color: '#e5e7eb',
                font: { size: 12, weight: '500' },
                usePointStyle: true,
                padding: 15,
                generateLabels: function(chart) {
                  const data = chart.data
                  if (data.labels.length && data.datasets.length) {
                    return data.labels.map((label, i) => {
                      const meta = chart.getDatasetMeta(0)
                      const style = meta.controller.getStyle(i)
                      const value = data.datasets[0].data[i]
                      const total = data.datasets[0].data.reduce((a, b) => a + b, 0)
                      const percentage = ((value / total) * 100).toFixed(1)
                      
                      return {
                        text: `${label} (${percentage}%)`,
                        fillStyle: style.backgroundColor,
                        strokeStyle: style.borderColor,
                        lineWidth: style.borderWidth,
                        pointStyle: style.pointStyle,
                        hidden: isNaN(data.datasets[0].data[i]) || meta.data[i].hidden,
                        index: i
                      }
                    })
                  }
                  return []
                }
              }
            },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8,
              callbacks: {
                label: function(context) {
                  const label = context.label || ''
                  const value = context.parsed
                  const total = context.dataset.data.reduce((a, b) => a + b, 0)
                  const percentage = ((value / total) * 100).toFixed(1)
                  return `${label}: ${value} (${percentage}%)`
                }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize traffic source chart:', error)
    }
  }
  
  initializePerformanceChart() {
    if (!this.hasPerformanceChartTarget) return
    
    try {
      const ctx = this.performanceChartTarget
      
      // Performance metrics data (this would come from your backend)
      const performanceData = {
        labels: ['Page Load Time', 'Time to Interactive', 'First Contentful Paint', 'Largest Contentful Paint'],
        datasets: [{
          label: 'Performance Score',
          data: [85, 78, 92, 88],
          backgroundColor: [
            'rgba(16, 185, 129, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(34, 197, 94, 0.8)',
            'rgba(59, 130, 246, 0.8)'
          ],
          borderColor: [
            '#10b981',
            '#f59e0b',
            '#22c55e',
            '#3b82f6'
          ],
          borderWidth: 2,
          borderRadius: 8
        }]
      }
      
      new Chart(ctx, {
        type: 'radar',
        data: performanceData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8
            }
          },
          scales: {
            r: {
              beginAtZero: true,
              max: 100,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)'
              },
              angleLines: {
                color: 'rgba(75, 85, 99, 0.3)'
              },
              pointLabels: {
                color: '#e5e7eb',
                font: { size: 11, weight: '500' }
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 10 },
                backdropColor: 'transparent'
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize performance chart:', error)
    }
  }
  
  initializeRealtimeChart() {
    if (!this.hasRealtimeChartTarget) return
    
    try {
      const ctx = this.realtimeChartTarget
      
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: [],
          datasets: [{
            label: 'Active Users',
            data: [],
            borderColor: '#10b981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            borderWidth: 2,
            tension: 0.4,
            fill: true
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: {
            duration: 750,
            easing: 'easeInOutQuart'
          },
          plugins: {
            legend: { display: false }
          },
          scales: {
            y: {
              beginAtZero: true,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            },
            x: {
              grid: { display: false },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize realtime chart:', error)
    }
  }
  
  initializeConversionChart() {
    if (!this.hasConversionChartTarget) return
    
    try {
      const ctx = this.conversionChartTarget
      
      // Conversion funnel data
      const conversionData = {
        labels: ['Visitors', 'Page Views', 'Engaged Users', 'Readers', 'Conversions'],
        datasets: [{
          label: 'Conversion Funnel',
          data: [1000, 750, 500, 300, 50],
          backgroundColor: [
            'rgba(99, 102, 241, 0.8)',
            'rgba(139, 92, 246, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(16, 185, 129, 0.8)',
            'rgba(239, 68, 68, 0.8)'
          ],
          borderColor: [
            '#6366f1',
            '#8b5cf6',
            '#f59e0b',
            '#10b981',
            '#ef4444'
          ],
          borderWidth: 2,
          borderRadius: 8
        }]
      }
      
      new Chart(ctx, {
        type: 'bar',
        data: conversionData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8,
              callbacks: {
                afterLabel: function(context) {
                  const index = context.dataIndex
                  if (index > 0) {
                    const prevValue = context.dataset.data[index - 1]
                    const currentValue = context.parsed.y
                    const dropoff = ((prevValue - currentValue) / prevValue * 100).toFixed(1)
                    return `Drop-off: ${dropoff}%`
                  }
                  return ''
                }
              }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            },
            x: {
              grid: { display: false },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize conversion chart:', error)
    }
  }
  
  initializeUserFlowChart() {
    if (!this.hasUserFlowChartTarget) return
    
    try {
      const ctx = this.userFlowChartTarget
      
      // This would be a more complex visualization showing user paths
      // For now, we'll create a simple flow representation
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: ['Landing', 'Product Page', 'Checkout', 'Purchase'],
          datasets: [{
            label: 'User Flow',
            data: [100, 65, 35, 15],
            borderColor: '#6366f1',
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            borderWidth: 3,
            tension: 0.4,
            fill: true,
            pointBackgroundColor: '#6366f1',
            pointBorderColor: '#ffffff',
            pointBorderWidth: 2,
            pointRadius: 8
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: 'rgba(0, 0, 0, 0.8)',
              titleColor: '#ffffff',
              bodyColor: '#e5e7eb',
              borderColor: '#374151',
              borderWidth: 1,
              cornerRadius: 8
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              max: 100,
              grid: {
                color: 'rgba(75, 85, 99, 0.3)',
                drawBorder: false
              },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 },
                callback: function(value) {
                  return value + '%'
                }
              }
            },
            x: {
              grid: { display: false },
              ticks: {
                color: '#9ca3af',
                font: { size: 11 }
              }
            }
          }
        }
      })
    } catch (error) {
      console.error('Failed to initialize user flow chart:', error)
    }
  }
  
  startRealtimeUpdates() {
    if (!this.realtimeUrlValue) return
    
    this.realtimeInterval = setInterval(() => {
      this.fetchRealtimeData()
    }, 30000)
    
    this.fetchRealtimeData()
  }
  
  async fetchRealtimeData() {
    try {
      const response = await fetch(this.realtimeUrlValue)
      const data = await response.json()
      
      // Update real-time metrics
      if (this.hasActiveUsersTarget) {
        this.activeUsersTarget.textContent = data.active_users || 0
      }
      
      if (this.hasCurrentPageviewsTarget) {
        this.currentPageviewsTarget.textContent = data.current_pageviews || 0
      }
      
      // Update real-time chart
      this.updateRealtimeChart(data)
      
    } catch (error) {
      console.error('Failed to fetch real-time data:', error)
    }
  }
  
  updateRealtimeChart(data) {
    // Update the real-time chart with new data
    // This would involve adding new data points and removing old ones
  }
  
  initializeInsights() {
    if (!this.insightsUrlValue) return
    
    this.insightsInterval = setInterval(() => {
      this.fetchInsights()
    }, 300000) // Every 5 minutes
    
    this.fetchInsights()
  }
  
  async fetchInsights() {
    try {
      const response = await fetch(this.insightsUrlValue)
      const insights = await response.json()
      
      this.displayInsights(insights)
      
    } catch (error) {
      console.error('Failed to fetch insights:', error)
    }
  }
  
  displayInsights(insights) {
    if (!this.hasInsightsPanelTarget) return
    
    const insightsHtml = insights.map(insight => `
      <div class="bg-gradient-to-r from-indigo-500 to-purple-600 p-4 rounded-lg mb-3">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-white">${insight.title}</p>
            <p class="text-xs text-indigo-100">${insight.description}</p>
          </div>
        </div>
      </div>
    `).join('')
    
    this.insightsPanelTarget.innerHTML = insightsHtml
  }
}
