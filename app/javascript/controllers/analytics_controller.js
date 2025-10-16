import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trendChart", "topPagesChart", "referrersChart"]
  static values = { 
    trendData: Array,
    topPagesData: Array,
    referrersData: Array
  }
  
  connect() {
    this.loadChartJs().then(() => {
      this.initializeCharts()
    })
  }
  
  disconnect() {
    // Cleanup charts if needed
  }
  
  async loadChartJs() {
    if (window.Chart) {
      return Promise.resolve()
    }
    
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
  
  initializeCharts() {
    this.initializeTrendChart()
    this.initializeTopPagesChart()
    this.initializeReferrersChart()
  }
  
  initializeTrendChart() {
    if (!this.hasTrendChartTarget || !this.trendDataValue) return
    
    const trendData = this.trendDataValue
    const ctx = this.trendChartTarget
    
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
  }
  
  initializeTopPagesChart() {
    if (!this.hasTopPagesChartTarget || !this.topPagesDataValue) return
    
    const topPagesData = this.topPagesDataValue
    const ctx = this.topPagesChartTarget
    
    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: topPagesData.map(d => d.page),
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
  }
  
  initializeReferrersChart() {
    if (!this.hasReferrersChartTarget || !this.referrersDataValue) return
    
    const referrersData = this.referrersDataValue
    const ctx = this.referrersChartTarget
    
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: referrersData.map(d => d.referrer),
        datasets: [{
          label: 'Visits',
          data: referrersData.map(d => d.visits),
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
  }
}




