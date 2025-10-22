import { Controller } from "@hotwired/stimulus"

// Applies theme classes to editor elements (e.g., .editorjs--light, .editor--light)
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
    
    // Detect editor type from parent elements
    const editorContainer = this.element.closest('[data-editor-type]')
    const editorType = editorContainer ? editorContainer.dataset.editorType : null
    
    if (isDark) {
      // Remove light theme classes
      this.element.classList.remove('editorjs--light', 'editor--light')
    } else {
      // Add appropriate light theme class based on editor type
      if (editorType === 'editorjs') {
        this.element.classList.add('editorjs--light')
      } else {
        this.element.classList.add('editor--light')
      }
    }
  }
}
