import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["testForm", "settingsForm", "testResult", "statusIndicator"]
  static values = { testUrl: String, settingsUrl: String }
  
  connect() {
    // Controller is ready
  }
  
  disconnect() {
    // Cleanup if needed
  }
  
  async testConnection(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    this.showLoading('Checking mailbox...')
    
    try {
      const response = await fetch(this.testUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.showSuccess(data.message)
        if (this.hasStatusIndicatorTarget) {
          this.statusIndicatorTarget.classList.remove('bg-red-500', 'bg-yellow-500')
          this.statusIndicatorTarget.classList.add('bg-green-500')
        }
      } else {
        this.showError(data.message)
        if (this.hasStatusIndicatorTarget) {
          this.statusIndicatorTarget.classList.remove('bg-green-500', 'bg-yellow-500')
          this.statusIndicatorTarget.classList.add('bg-red-500')
        }
      }
    } catch (error) {
      this.showError('Network error: ' + error.message)
    }
  }
  
  async saveSettings(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    this.showLoading('Saving settings...')
    
    try {
      const response = await fetch(this.settingsUrlValue, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        this.showSuccess('Settings saved successfully!')
      } else {
        const data = await response.json()
        this.showError(data.message || 'Failed to save settings')
      }
    } catch (error) {
      this.showError('Network error: ' + error.message)
    }
  }
  
  showLoading(message) {
    if (this.hasTestResultTarget) {
      this.testResultTarget.innerHTML = `
        <div class="flex items-center gap-2 text-yellow-400">
          <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-yellow-400"></div>
          ${message}
        </div>
      `
      this.testResultTarget.classList.remove('hidden')
    }
  }
  
  showSuccess(message) {
    if (this.hasTestResultTarget) {
      this.testResultTarget.innerHTML = `
        <div class="flex items-center gap-2 text-green-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
          </svg>
          ${message}
        </div>
      `
      this.testResultTarget.classList.remove('hidden')
    }
  }
  
  showError(message) {
    if (this.hasTestResultTarget) {
      this.testResultTarget.innerHTML = `
        <div class="flex items-center gap-2 text-red-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
          ${message}
        </div>
      `
      this.testResultTarget.classList.remove('hidden')
    }
  }
}


