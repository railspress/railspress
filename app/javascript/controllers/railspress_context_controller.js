import { Controller } from "@hotwired/stimulus"

// Global context controller that injects RailsPress namespace
export default class extends Controller {
  static values = {
    post: Object,
    user: Object,
    settings: Object
  }

  connect() {
    // Initialize global RailsPress namespace
    window.RailsPress = window.RailsPress || {}
    
    // Inject post data
    if (this.hasPostValue) {
      window.RailsPress.post = this.postValue
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
    window.RailsPress.getPostUuid = () => {
      return window.RailsPress.post?.uuid || 'new'
    }
    
    window.RailsPress.getPostId = () => {
      return window.RailsPress.post?.id || null
    }
    
    window.RailsPress.getPost = () => {
      return window.RailsPress.post
    }
    
    console.log('RailsPress context loaded:', window.RailsPress)
  }
  
  disconnect() {
    // Optional: cleanup on disconnect
  }
}

