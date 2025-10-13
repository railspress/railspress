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
      // Dynamically import BlockNote
      const { BlockNoteEditor } = await import("@blocknote/core")
      const { BlockNoteView } = await import("@blocknote/mantine")
      await import("@blocknote/mantine/style.css")

      const container = this.element.querySelector("#blocknote-container") || 
                       this.element.querySelector(".blocknote-editor")

      if (!container) {
        console.error("BlockNote container not found")
        return
      }

      // Create editor instance
      this.editor = BlockNoteEditor.create({
        initialContent: this.contentValue ? this.parseContent(this.contentValue) : undefined,
        domAttributes: {
          editor: {
            class: "blocknote-editor-dark",
            "data-theme": "dark"
          }
        }
      })

      // Create view
      new BlockNoteView({
        editor: this.editor,
        theme: "dark"
      }).mount(container)

      // Update hidden field on change
      this.editor.onEditorContentChange(() => {
        this.updateInput()
      })

      // Auto-save every 30 seconds
      this.autoSaveInterval = setInterval(() => {
        this.updateInput()
        this.triggerAutoSave()
      }, 30000)

    } catch (error) {
      console.error("Failed to initialize BlockNote:", error)
      this.showFallbackEditor()
    }
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
        <div class="p-4 bg-yellow-500/10 border border-yellow-500/20 rounded-lg text-yellow-400">
          <p class="font-medium mb-2">⚠️ BlockNote editor failed to load</p>
          <p class="text-sm">Using fallback textarea editor. Consider switching to Trix or CKEditor in your preferences.</p>
        </div>
        <textarea 
          name="${this.inputTarget.name}"
          class="w-full mt-4 px-4 py-3 bg-[#0a0a0a] border border-[#2a2a2a] text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 font-mono text-sm min-h-[400px]"
          placeholder="${this.placeholderValue}">${this.contentValue}</textarea>
      `
    }
  }
}


