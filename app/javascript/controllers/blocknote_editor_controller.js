import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="blocknote-editor"
export default class extends Controller {
  static targets = ["editor", "input"]

  connect() {
    console.log("BlockNote editor connecting...")
    
    // Load BlockNote dynamically
    if (!window.BlockNote) {
      this.loadBlockNote().then(() => {
        this.initializeEditor()
      })
    } else {
      this.initializeEditor()
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy?.()
    }
  }

  async loadBlockNote() {
    // Load BlockNote CSS
    if (!document.querySelector('link[href*="blocknote"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://cdn.jsdelivr.net/npm/@blocknote/core@0.12.4/dist/style.css'
      document.head.appendChild(link)
    }

    // Load BlockNote React and dependencies
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/@blocknote/core@0.12.4/dist/browser/index.js'
      script.type = 'module'
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  async initializeEditor() {
    try {
      const initialContent = this.inputTarget.value || ''
      
      // Create a simple contenteditable div for now
      // Full BlockNote integration would require React setup
      this.editorTarget.contentEditable = true
      this.editorTarget.className = 'blocknote-editor min-h-[400px] p-4 bg-white border border-gray-300 rounded-lg focus:outline-none focus:border-indigo-500'
      this.editorTarget.innerHTML = initialContent || '<p>Start writing...</p>'
      
      // Update hidden input on content change
      this.editorTarget.addEventListener('input', () => {
        this.inputTarget.value = this.editorTarget.innerHTML
      })
      
      // Basic formatting toolbar
      this.addFormattingToolbar()
      
      console.log("BlockNote editor initialized")
    } catch (error) {
      console.error("Error initializing BlockNote:", error)
      // Fallback to simple textarea
      this.editorTarget.outerHTML = `<textarea class="w-full min-h-[400px] p-4 border rounded" data-blocknote-editor-target="input">${this.inputTarget.value}</textarea>`
    }
  }

  addFormattingToolbar() {
    const toolbar = document.createElement('div')
    toolbar.className = 'blocknote-toolbar flex gap-2 mb-2 p-2 bg-gray-100 border border-gray-300 rounded-t-lg'
    toolbar.innerHTML = `
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatBold" title="Bold (Ctrl+B)">
        <strong>B</strong>
      </button>
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatItalic" title="Italic (Ctrl+I)">
        <em>I</em>
      </button>
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatUnderline" title="Underline (Ctrl+U)">
        <u>U</u>
      </button>
      <div class="border-l border-gray-300 mx-1"></div>
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatHeading" title="Heading">
        H1
      </button>
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatList" title="List">
        ≡
      </button>
      <button type="button" class="px-3 py-1 bg-white border rounded hover:bg-gray-50" data-action="click->blocknote-editor#formatLink" title="Link">
        🔗
      </button>
    `
    
    this.editorTarget.parentNode.insertBefore(toolbar, this.editorTarget)
  }

  formatBold(event) {
    event.preventDefault()
    document.execCommand('bold', false, null)
    this.editorTarget.focus()
  }

  formatItalic(event) {
    event.preventDefault()
    document.execCommand('italic', false, null)
    this.editorTarget.focus()
  }

  formatUnderline(event) {
    event.preventDefault()
    document.execCommand('underline', false, null)
    this.editorTarget.focus()
  }

  formatHeading(event) {
    event.preventDefault()
    document.execCommand('formatBlock', false, 'h2')
    this.editorTarget.focus()
  }

  formatList(event) {
    event.preventDefault()
    document.execCommand('insertUnorderedList', false, null)
    this.editorTarget.focus()
  }

  formatLink(event) {
    event.preventDefault()
    const url = prompt('Enter URL:')
    if (url) {
      document.execCommand('createLink', false, url)
    }
    this.editorTarget.focus()
  }
}








