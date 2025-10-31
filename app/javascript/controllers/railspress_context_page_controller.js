import { Controller } from "@hotwired/stimulus"

// Global context controller for Pages that injects RailsPress namespace
export default class extends Controller {
  static values = {
    page: Object,
    user: Object,
    settings: Object
  }

  connect() {
    // Initialize global RailsPress namespace
    window.RailsPress = window.RailsPress || {}
    
    // Inject page data
    if (this.hasPageValue) {
      window.RailsPress.page = this.pageValue
    }
    
    // Inject user data (optional)
    if (this.hasUserValue) {
      window.RailsPress.user = this.userValue
    }
    
    // Inject settings (optional)
    if (this.hasSettingsValue) {
      window.RailsPress.settings = this.settingsValue
    }
    
    // Helper methods
    window.RailsPress.getPageId = () => {
      return window.RailsPress.page?.id || 'new'
    }
    
    window.RailsPress.getPage = () => {
      return window.RailsPress.page
    }
    
    // Backward compatibility with autosave controller (which expects getPostUuid and getPostId)
    window.RailsPress.getPostUuid = () => {
      return window.RailsPress.page?.uuid || 'new'
    }
    
    window.RailsPress.getPostId = () => {
      return window.RailsPress.page?.id || null
    }
    
    console.log('RailsPress page context loaded:', window.RailsPress)
  }
  
  disconnect() {
    // Optional: cleanup on disconnect
  }
}

