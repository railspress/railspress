import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "message"]

  connect() {
    // Listen for toast:show events
    document.addEventListener('toast:show', this.handleToastShow.bind(this))
    
    // Expose global toast function
    window.toast = (message) => {
      document.dispatchEvent(new CustomEvent('toast:show', {
        detail: { message }
      }))
    }
  }

  disconnect() {
    document.removeEventListener('toast:show', this.handleToastShow.bind(this))
    
    // Clean up global function
    if (window.toast) {
      delete window.toast
    }
  }

  handleToastShow(event) {
    const message = event.detail?.message || 'Success'
    this.show(message)
  }

  show(message) {
    // Update message text
    this.messageTarget.textContent = message
    
    // Reset any existing animations
    this.containerTarget.classList.remove('toast-show', 'toast-hide')
    
    // Force reflow to restart animation
    void this.containerTarget.offsetWidth
    
    // Show toast with slide-up animation
    this.containerTarget.classList.add('toast-show')
    
    // Clear any existing timeout
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
    }
    
    // Auto-hide after 3 seconds
    this.hideTimeout = setTimeout(() => {
      this.hide()
    }, 5000)
  }

  hide() {
    this.containerTarget.classList.remove('toast-show')
    this.containerTarget.classList.add('toast-hide')
    
    // Clean up after animation completes
    setTimeout(() => {
      this.containerTarget.classList.remove('toast-hide')
    }, 300)
  }
}

