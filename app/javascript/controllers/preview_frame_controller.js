import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('load', this.handleLoad.bind(this))
    this.element.addEventListener('error', this.handleError.bind(this))
  }

  handleLoad() {
    // Notify parent that preview is ready
    this.dispatch('preview-ready', { detail: { frame: this.element } })
  }

  handleError() {
    // Handle preview loading errors
    this.dispatch('preview-error', { detail: { frame: this.element } })
  }

  refresh() {
    this.element.src = this.element.src
  }

  setDevice(device) {
    const frame = this.element
    const container = frame.parentElement
    
    // Remove existing device classes
    container.classList.remove('device-desktop', 'device-tablet', 'device-mobile')
    
    // Add device-specific classes
    container.classList.add(`device-${device}`)
    
    // Set device-specific styles
    switch (device) {
      case 'tablet':
        container.style.maxWidth = '768px'
        container.style.margin = '0 auto'
        break
      case 'mobile':
        container.style.maxWidth = '375px'
        container.style.margin = '0 auto'
        break
      default:
        container.style.maxWidth = '100%'
        container.style.margin = '0'
    }
  }
}

