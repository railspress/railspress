import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["testIp", "testResult", "testResultContent", "testModal", "modalContent"]

  connect() {
    console.log("Geolocation settings controller connected")
  }

  providerChanged(event) {
    const provider = event.target.value
    console.log("Provider changed to:", provider)
    
    // Show/hide relevant sections based on provider
    this.toggleProviderSections(provider)
  }

  toggleProviderSections(provider) {
    // Hide all provider-specific sections
    const sections = document.querySelectorAll('[data-provider-section]')
    sections.forEach(section => section.classList.add('hidden'))
    
    // Show relevant section
    const relevantSection = document.querySelector(`[data-provider-section="${provider}"]`)
    if (relevantSection) {
      relevantSection.classList.remove('hidden')
    }
  }

  async testConnection() {
    try {
      const response = await fetch('/admin/geolocation_settings/test_connection', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const result = await response.json()
      
      if (result.success) {
        this.showNotification('Connection test successful!', 'success')
      } else {
        this.showNotification(`Connection test failed: ${result.message}`, 'error')
      }
    } catch (error) {
      console.error('Connection test error:', error)
      this.showNotification('Connection test failed', 'error')
    }
  }

  async testLookup() {
    const ipAddress = this.testIpTarget.value || '8.8.8.8'
    
    try {
      const response = await fetch('/admin/geolocation_settings/test_lookup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ test_ip: ipAddress })
      })
      
      const result = await response.json()
      
      // Display result
      this.showTestResult(result, ipAddress)
      
    } catch (error) {
      console.error('Lookup test error:', error)
      this.showNotification('Lookup test failed', 'error')
    }
  }

  showTestResult(result, ipAddress) {
    const resultContent = this.testResultContentTarget
    const resultDiv = this.testResultTarget
    
    let content = `IP Address: ${ipAddress}\n`
    content += `Provider: ${result.provider || 'Unknown'}\n`
    content += `Success: ${result.success ? 'Yes' : 'No'}\n`
    content += `Message: ${result.message}\n\n`
    
    if (result.success && result.data) {
      content += `Geolocation Data:\n`
      content += `Country: ${result.data.country_name} (${result.data.country_code})\n`
      if (result.data.city) content += `City: ${result.data.city}\n`
      if (result.data.region) content += `Region: ${result.data.region}\n`
      if (result.data.latitude) content += `Latitude: ${result.data.latitude}\n`
      if (result.data.longitude) content += `Longitude: ${result.data.longitude}\n`
      if (result.data.timezone) content += `Timezone: ${result.data.timezone}\n`
      if (result.data.isp) content += `ISP: ${result.data.isp}\n`
    }
    
    resultContent.textContent = content
    resultDiv.classList.remove('hidden')
    
    // Scroll to result
    resultDiv.scrollIntoView({ behavior: 'smooth' })
  }

  async updateCountryDb() {
    await this.updateDatabase('country')
  }

  async updateCityDb() {
    await this.updateDatabase('city')
  }

  async updateDatabase(type) {
    try {
      const response = await fetch('/admin/geolocation_settings/update_maxmind', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ type: type })
      })
      
      const result = await response.json()
      
      if (result.success) {
        this.showNotification(`${type.capitalize} database updated successfully!`, 'success')
        // Reload page to show updated database info
        setTimeout(() => window.location.reload(), 2000)
      } else {
        this.showNotification(`Failed to update ${type} database: ${result.message}`, 'error')
      }
    } catch (error) {
      console.error('Database update error:', error)
      this.showNotification(`Failed to update ${type} database`, 'error')
    }
  }

  async scheduleAutoUpdate() {
    try {
      const response = await fetch('/admin/geolocation_settings/schedule_auto_update', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const result = await response.json()
      
      if (result.success) {
        this.showNotification('Auto-update scheduled successfully!', 'success')
      } else {
        this.showNotification(`Auto-update failed: ${result.message}`, 'error')
      }
    } catch (error) {
      console.error('Auto-update error:', error)
      this.showNotification('Auto-update failed', 'error')
    }
  }

  showModal(content) {
    this.modalContentTarget.innerHTML = content
    this.testModalTarget.classList.remove('hidden')
  }

  closeModal() {
    this.testModalTarget.classList.add('hidden')
  }

  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg transition-all duration-300 transform translate-x-full`
    
    // Set colors based on type
    switch (type) {
      case 'success':
        notification.className += ' bg-green-600 text-white'
        break
      case 'error':
        notification.className += ' bg-red-600 text-white'
        break
      case 'warning':
        notification.className += ' bg-yellow-600 text-white'
        break
      default:
        notification.className += ' bg-blue-600 text-white'
    }
    
    notification.textContent = message
    
    // Add to page
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 100)
    
    // Remove after 5 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 5000)
  }
}
