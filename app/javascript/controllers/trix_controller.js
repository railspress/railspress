import { Controller } from "@hotwired/stimulus"
import { EditorBase } from "./editor_base"

// Connects to data-controller="trix"
export default class extends Controller {
  connect() {
    this.base = new EditorBase(this)
    this.base.log('connecting')
    this.base.emitState('connecting')
    
    // Setup theme listener
    this.base.setupThemeListener()
    
    // Add autosave event listener
    const trixEditor = this.element.querySelector('trix-editor')
    if (trixEditor) {
      trixEditor.addEventListener('trix-change', () => {
        this.base.notifyAutosave()
      })
    }
    
    this.base.log('Trix editor connected')
  }

  disconnect() {
    this.base.log('disconnect')
    this.base.emitState('destroy')
    this.base.cleanupThemeListener()
  }
}
