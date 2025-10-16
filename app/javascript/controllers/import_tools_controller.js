import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { hasProcessingJobs: Boolean }
  
  connect() {
    if (this.hasProcessingJobsValue) {
      this.startAutoRefresh()
    }
  }
  
  disconnect() {
    this.stopAutoRefresh()
  }
  
  startAutoRefresh() {
    this.refreshInterval = setInterval(() => {
      window.location.reload()
    }, 5000) // Refresh every 5 seconds
  }
  
  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }
}




