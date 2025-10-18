import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="trix"
export default class extends Controller {
  connect() {
    console.log("Trix editor connected")
    
    // Add dark theme styles to Trix editor
    const trixEditor = this.element.querySelector('trix-editor')
    if (trixEditor) {
      trixEditor.style.backgroundColor = 'transparent'
      trixEditor.style.color = '#111827'
      trixEditor.style.border = 'none'
      trixEditor.style.borderRadius = '0'
      trixEditor.style.minHeight = '400px'
      trixEditor.style.padding = '0'
      trixEditor.style.fontSize = '18px'
      trixEditor.style.lineHeight = '1.6'
      
      // Add autosave event listener
      trixEditor.addEventListener('trix-change', () => {
        this.triggerAutoSave()
      })
    }
    
    // Add dark theme to Trix toolbar
    const trixToolbar = this.element.querySelector('trix-toolbar')
    if (trixToolbar) {
      trixToolbar.style.backgroundColor = '#f9fafb'
      trixToolbar.style.border = '1px solid #e5e7eb'
      trixToolbar.style.borderRadius = '0.5rem 0.5rem 0 0'
    }
  }

  triggerAutoSave() {
    // Dispatch event for autosave functionality
    const event = new CustomEvent('editor:content-changed', {
      detail: { content: this.element.querySelector('trix-editor').innerHTML }
    })
    window.dispatchEvent(event)
  }
}
