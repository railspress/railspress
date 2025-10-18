import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="blocknote"
export default class extends Controller {
  static targets = ["input"]
  static values = {
    content: String,
    placeholder: String
  }

  connect() {
    this.initializeEditor()
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy?.()
    }
  }

  async initializeEditor() {
    try {
      // Load BlockNote from CDN
      await this.loadBlockNoteFromCDN()
      
      const container = this.element.querySelector("#blocknote-container") || 
                       this.element.querySelector(".blocknote-editor")

      if (!container) {
        console.error("BlockNote container not found")
        this.showFallbackEditor()
        return
      }

      // Check if BlockNote is available
      if (typeof window.BlockNote === 'undefined') {
        console.error("BlockNote not loaded from CDN")
        this.showFallbackEditor()
        return
      }

      // Create a simple contenteditable editor as fallback for now
      // Full BlockNote integration would require React setup
      this.createSimpleEditor(container)

    } catch (error) {
      console.error("Failed to initialize BlockNote:", error)
      this.showFallbackEditor()
    }
  }

  async loadBlockNoteFromCDN() {
    return new Promise((resolve, reject) => {
      // Check if already loaded
      if (window.BlockNote) {
        resolve()
        return
      }

      // Load BlockNote CSS
      if (!document.querySelector('link[href*="blocknote"]')) {
        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = 'https://cdn.jsdelivr.net/npm/@blocknote/mantine@0.12.4/dist/style.css'
        document.head.appendChild(link)
      }

      // Load BlockNote JS
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/@blocknote/core@0.12.4/dist/browser/index.js'
      script.onload = () => {
        // Load React and other dependencies
        this.loadReactDependencies().then(resolve).catch(reject)
      }
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  async loadReactDependencies() {
    return new Promise((resolve, reject) => {
      // Load React
      const reactScript = document.createElement('script')
      reactScript.src = 'https://unpkg.com/react@18/umd/react.production.min.js'
      reactScript.onload = () => {
        // Load React DOM
        const reactDOMScript = document.createElement('script')
        reactDOMScript.src = 'https://unpkg.com/react-dom@18/umd/react-dom.production.min.js'
        reactDOMScript.onload = resolve
        reactDOMScript.onerror = reject
        document.head.appendChild(reactDOMScript)
      }
      reactDOMScript.onerror = reject
      document.head.appendChild(reactScript)
    })
  }

  createSimpleEditor(container) {
    // Create a simple rich text editor as fallback
    container.innerHTML = `
      <div class="simple-rich-editor min-h-[400px] p-4 bg-[#0a0a0a] border border-[#2a2a2a] rounded-lg text-white focus:outline-none focus:border-indigo-500" contenteditable="true">
        ${this.contentValue || '<p>Start writing...</p>'}
      </div>
    `
    
    const editor = container.querySelector('.simple-rich-editor')
    
    // Add basic formatting toolbar
    this.addFormattingToolbar(container, editor)
    
    // Update hidden input on content change
    editor.addEventListener('input', () => {
      this.updateInputFromSimpleEditor(editor)
    })
    
    // Auto-save every 30 seconds
    this.autoSaveInterval = setInterval(() => {
      this.updateInputFromSimpleEditor(editor)
      this.triggerAutoSave()
    }, 30000)
  }

  addFormattingToolbar(container, editor) {
    const toolbar = document.createElement('div')
    toolbar.className = 'blocknote-toolbar flex gap-2 mb-2 p-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded-t-lg'
    toolbar.innerHTML = `
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('bold', false, null); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="Bold (Ctrl+B)">
        <strong>B</strong>
      </button>
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('italic', false, null); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="Italic (Ctrl+I)">
        <em>I</em>
      </button>
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('underline', false, null); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="Underline (Ctrl+U)">
        <u>U</u>
      </button>
      <div class="border-l border-[#3a3a3a] mx-1"></div>
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('formatBlock', false, 'h2'); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="Heading">
        H1
      </button>
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('insertUnorderedList', false, null); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="List">
        ≡
      </button>
      <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="const url = prompt('Enter URL:'); if (url) document.execCommand('createLink', false, url); this.closest('.blocknote-editor').querySelector('.simple-rich-editor').focus()" title="Link">
        🔗
      </button>
    `
    
    container.insertBefore(toolbar, container.firstChild)
  }

  updateInputFromSimpleEditor(editor) {
    if (this.hasInputTarget) {
      this.inputTarget.value = editor.innerHTML
      // Trigger autosave event
      this.triggerAutoSave()
    }
  }

  triggerAutoSave() {
    // Dispatch event for autosave functionality
    const event = new CustomEvent('editor:content-changed', {
      detail: { content: this.inputTarget.value }
    })
    window.dispatchEvent(event)
  }

  parseContent(content) {
    try {
      if (typeof content === 'string') {
        // Try to parse as JSON (BlockNote format)
        const parsed = JSON.parse(content)
        return Array.isArray(parsed) ? parsed : undefined
      }
      return content
    } catch (e) {
      // If not valid JSON, convert HTML to BlockNote format
      return this.htmlToBlocks(content)
    }
  }

  htmlToBlocks(html) {
    // Simple HTML to BlockNote conversion
    // This is a basic implementation - expand as needed
    const div = document.createElement('div')
    div.innerHTML = html
    
    const blocks = []
    const children = Array.from(div.children)
    
    if (children.length === 0) {
      // Plain text
      return [{
        type: "paragraph",
        content: [{ type: "text", text: div.textContent }]
      }]
    }

    children.forEach(child => {
      const tagName = child.tagName.toLowerCase()
      
      switch(tagName) {
        case 'h1':
        case 'h2':
        case 'h3':
          blocks.push({
            type: "heading",
            props: { level: parseInt(tagName[1]) },
            content: [{ type: "text", text: child.textContent }]
          })
          break
        case 'p':
          blocks.push({
            type: "paragraph",
            content: [{ type: "text", text: child.textContent }]
          })
          break
        case 'ul':
        case 'ol':
          Array.from(child.children).forEach(li => {
            blocks.push({
              type: tagName === 'ul' ? "bulletListItem" : "numberedListItem",
              content: [{ type: "text", text: li.textContent }]
            })
          })
          break
        default:
          blocks.push({
            type: "paragraph",
            content: [{ type: "text", text: child.textContent }]
          })
      }
    })

    return blocks.length > 0 ? blocks : undefined
  }

  updateInput() {
    if (this.hasInputTarget && this.editor) {
      const blocks = this.editor.topLevelBlocks
      this.inputTarget.value = JSON.stringify(blocks)
    }
  }

  triggerAutoSave() {
    // Dispatch event for auto-save functionality
    const event = new CustomEvent('editor:autosave', {
      detail: { content: this.inputTarget.value }
    })
    window.dispatchEvent(event)
  }

  showFallbackEditor() {
    const container = this.element.querySelector("#blocknote-container")
    if (container) {
      container.innerHTML = `
        <div class="p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg text-blue-400 mb-4">
          <p class="font-medium mb-2">📝 Using Rich Text Editor</p>
          <p class="text-sm">BlockNote is loading... Using a rich text editor with formatting toolbar.</p>
        </div>
        <div class="rich-text-fallback">
          <div class="toolbar flex gap-2 mb-2 p-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded-t-lg">
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('bold', false, null); document.querySelector('.rich-text-editor').focus()" title="Bold (Ctrl+B)">
              <strong>B</strong>
            </button>
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('italic', false, null); document.querySelector('.rich-text-editor').focus()" title="Italic (Ctrl+I)">
              <em>I</em>
            </button>
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('underline', false, null); document.querySelector('.rich-text-editor').focus()" title="Underline (Ctrl+U)">
              <u>U</u>
            </button>
            <div class="border-l border-[#3a3a3a] mx-1"></div>
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('formatBlock', false, 'h2'); document.querySelector('.rich-text-editor').focus()" title="Heading">
              H1
            </button>
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="document.execCommand('insertUnorderedList', false, null); document.querySelector('.rich-text-editor').focus()" title="List">
              ≡
            </button>
            <button type="button" class="px-3 py-1 bg-[#2a2a2a] border border-[#3a3a3a] rounded hover:bg-[#3a3a3a] text-white" onclick="const url = prompt('Enter URL:'); if (url) document.execCommand('createLink', false, url); document.querySelector('.rich-text-editor').focus()" title="Link">
              🔗
            </button>
          </div>
          <div class="rich-text-editor min-h-[400px] p-4 bg-[#0a0a0a] border border-[#2a2a2a] rounded-b-lg text-white focus:outline-none focus:border-indigo-500" contenteditable="true">
            ${this.contentValue || '<p>Start writing...</p>'}
          </div>
        </div>
      `
      
      // Add event listener to update hidden input
      const editor = container.querySelector('.rich-text-editor')
      if (editor && this.hasInputTarget) {
        editor.addEventListener('input', () => {
          this.inputTarget.value = editor.innerHTML
        })
        
        // Auto-save every 30 seconds
        this.autoSaveInterval = setInterval(() => {
          this.inputTarget.value = editor.innerHTML
          this.triggerAutoSave()
        }, 30000)
      }
    }
  }
}






