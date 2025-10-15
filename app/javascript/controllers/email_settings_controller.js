import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["providerSelect", "smtpConfig", "resendConfig", "testEmailInput", "testResult"]
  
  connect() {
    this.setupEventListeners()
  }
  
  disconnect() {
    // Event listeners will be automatically cleaned up
  }
  
  setupEventListeners() {
    if (this.hasProviderSelectTarget) {
      this.providerSelectTarget.addEventListener('change', this.toggleProviderConfig.bind(this))
    }
  }
  
  toggleProviderConfig() {
    const provider = this.providerSelectTarget.value
    
    if (provider === 'smtp') {
      if (this.hasSmtpConfigTarget) {
        this.smtpConfigTarget.style.display = 'block'
      }
      if (this.hasResendConfigTarget) {
        this.resendConfigTarget.style.display = 'none'
      }
    } else {
      if (this.hasSmtpConfigTarget) {
        this.smtpConfigTarget.style.display = 'none'
      }
      if (this.hasResendConfigTarget) {
        this.resendConfigTarget.style.display = 'block'
      }
    }
  }
  
  sendTestEmail() {
    const email = this.testEmailInputTarget?.value
    const resultDiv = this.testResultTarget
    
    if (!email) {
      this.showTestResult('Please enter an email address', 'error')
      return
    }
    
    resultDiv.innerHTML = '<div class="text-gray-400">Sending test email...</div>'
    resultDiv.classList.remove('hidden')
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    fetch('/admin/settings/test_email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        email: email
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showTestResult(data.message, 'success')
      } else {
        this.showTestResult(data.errors.join(', '), 'error')
      }
    })
    .catch(error => {
      this.showTestResult('Failed to send test email', 'error')
      console.error(error)
    })
  }
  
  showTestResult(message, type) {
    const resultDiv = this.testResultTarget
    const colorClass = type === 'success' ? 'text-green-400' : 'text-red-400'
    
    resultDiv.innerHTML = `<div class="${colorClass}">${message}</div>`
    resultDiv.classList.remove('hidden')
  }
}

