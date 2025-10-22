import { Controller } from "@hotwired/stimulus"
import { EditorBase } from "./editor_base"

// Connects to data-controller="ckeditor5"
export default class extends Controller {
  static targets = ["input"]
  static values = { 
    content: String,
    placeholder: String
  }

  connect() {
    this.base = new EditorBase(this)
    this.base.log('connecting')
    this.base.emitState('connecting')
    
    this.editor = null
    this.initEditor()
  }

  disconnect() {
    this.base.log('disconnect')
    this.base.emitState('destroy')
    
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
    
    this.base.cleanupThemeListener()
  }

  async initEditor() {
    try {
      this.base.log('init:start')
      this.base.emitState('init:start')
      this.base.logTime('init:total')

      // Wait for CKEditor 5 to be loaded globally
      if (!window.ClassicEditor) {
        throw new Error('CKEditor 5 ClassicEditor not available globally')
      }
      
      // Initialize editor
      await this.createEditor()
      
      this.base.logTimeEnd('init:total')
      this.base.log('init:ready')
      this.base.emitState('init:ready')
      
    } catch (error) {
      this.base.log('init:error', error)
      this.base.emitState('init:error', { error: error.message })
      console.error('CKEditor 5 initialization failed:', error)
    }
  }

  async createEditor() {
    const container = this.element.querySelector('#ckeditor5-container')
    if (!container) {
      throw new Error('CKEditor 5 container not found')
    }

    // Set initial content
    const initialContent = this.contentValue || ''
    
    this.base.log('Creating CKEditor 5 instance')
    this.base.logTime('editor:create')

    this.editor = await window.ClassicEditor.create(container, {
      placeholder: this.placeholderValue || 'Start writing...',
      toolbar: {
        items: [
          'heading', '|',
          'bold', 'italic', 'link', '|',
          'alignment', '|',
          'bulletedList', 'numberedList', '|',
          'outdent', 'indent', '|',
          'blockQuote', 'insertTable', '|',
          'undo', 'redo'
        ]
      },
      language: 'en',
      table: {
        contentToolbar: [
          'tableColumn',
          'tableRow',
          'mergeTableCells'
        ]
      }
    })

    this.base.logTimeEnd('editor:create')

    // Set initial content
    if (initialContent) {
      this.editor.setData(initialContent)
    }

    // Bind to hidden input
    this.editor.model.document.on('change:data', () => {
      const data = this.editor.getData()
      if (this.hasInputTarget) {
        this.inputTarget.value = data
      }
      this.base.notifyAutosave()
    })

    // Setup theme listener
    this.base.setupThemeListener()
    
    this.base.log('CKEditor 5 initialized successfully')
  }

  // Public method to get editor data
  getData() {
    return this.editor ? this.editor.getData() : ''
  }

  // Public method to set editor data
  setData(data) {
    if (this.editor) {
      this.editor.setData(data || '')
    }
  }
}