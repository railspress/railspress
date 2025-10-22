import { Controller } from "@hotwired/stimulus"

// Applies theme classes to elements (e.g., .editorjs--light)
export default class extends Controller {
  connect() {
    this.applyTheme()
    
    // Listen for theme changes from theme-toggle controller
    document.addEventListener('theme:changed', () => {
      this.applyTheme()
    })
  }
  
  disconnect() {
    document.removeEventListener('theme:changed', this.applyTheme)
  }
  
  applyTheme() {
    const isDark = document.documentElement.classList.contains('dark')
    
    if (isDark) {
      this.element.classList.remove('editorjs--light')
    } else {
      this.element.classList.add('editorjs--light')
    }
  }
}
