import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "testButton", "flushButton"]

  connect() {
    console.log("Cache controller connected")
  }

  async submitForm(event) {
    event.preventDefault()
    
    const form = event.target
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    // Build form data as URL encoded string (like Rails expects)
    const formData = new URLSearchParams()
    formData.append('authenticity_token', csrfToken)
    
    // Add all form fields
    const inputs = form.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      console.log('Processing input:', input.name, input.type, input.value, input.checked)
      if (input.type === 'checkbox') {
        if (input.checked) {
          formData.append(input.name, input.value)
        }
      } else if (input.type !== 'hidden' || input.name === 'enabled') {
        formData.append(input.name, input.value)
      }
    })
    
    console.log('Form data being sent:', formData.toString())
    
    try {
      const response = await fetch(form.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        credentials: 'same-origin'
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      if (data.success) {
        this.showSuccessToast(data.message)
      } else {
        this.showErrorToast(data.message)
      }
    } catch (error) {
      console.error('Form submission error:', error)
      this.showErrorToast('Failed to save settings')
    }
  }

  async testConnection(event) {
    event.preventDefault()
    
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      
      const response = await fetch('/admin/cache/test_connection', {
        method: 'POST',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: `authenticity_token=${encodeURIComponent(csrfToken)}`,
        credentials: 'same-origin'
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      if (data.success) {
        this.showSuccessToast(data.message)
      } else {
        this.showErrorToast(data.message)
      }
    } catch (error) {
      console.error('Test connection error:', error)
      this.showErrorToast('Connection test failed')
    }
  }

  async flushCache(event) {
    event.preventDefault()
    
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      
      const response = await fetch('/admin/cache/flush', {
        method: 'POST',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: `authenticity_token=${encodeURIComponent(csrfToken)}`,
        credentials: 'same-origin'
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      if (data.success) {
        this.showSuccessToast(data.message)
      } else {
        this.showErrorToast(data.message)
      }
    } catch (error) {
      console.error('Flush cache error:', error)
      this.showErrorToast('Failed to flush cache')
    }
  }

  showSuccessToast(message) {
    if (typeof showSuccessToast === 'function') {
      showSuccessToast(message)
    } else {
      alert('Success: ' + message)
    }
  }

  showErrorToast(message) {
    if (typeof showErrorToast === 'function') {
      showErrorToast(message)
    } else {
      alert('Error: ' + message)
    }
  }
}