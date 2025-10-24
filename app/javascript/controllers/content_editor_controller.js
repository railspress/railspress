import { Controller } from "@hotwired/stimulus"

// Unified Content Editor Controller
// Provides a clean API for interacting with EditorJS, Trix, and CKEditor5
export default class extends Controller {
  static values = {
    editorType: String
  }

  connect() {
    console.log('[ContentEditor] Connected, detecting editor type...')
    this.detectEditor()
  }

  disconnect() {
    this.editorController = null
    this.editorType = null
  }

  // Detect the active editor and get reference to its controller
  detectEditor() {
    // Get editor type from wrapper or value
    const wrapper = this.element.closest('[data-editor-type]')
    this.editorType = wrapper?.dataset.editorType || this.editorTypeValue

    if (!this.editorType) {
      console.warn('[ContentEditor] No editor type detected')
      return
    }

    console.log(`[ContentEditor] Detected editor type: ${this.editorType}`)

    // Find the specific editor controller based on type
    switch (this.editorType) {
      case 'editorjs':
        this.detectEditorJS()
        break
      case 'trix':
        this.detectTrix()
        break
      case 'ckeditor5':
        this.detectCKEditor5()
        break
      default:
        console.warn(`[ContentEditor] Unknown editor type: ${this.editorType}`)
    }
  }

  detectEditorJS() {
    const editorElement = this.element.querySelector('[data-controller*="editorjs"]')
    console.log('[ContentEditor] EditorJS element found:', editorElement)
    
    if (editorElement) {
      // Try to get the controller
      try {
        this.editorController = this.application.getControllerForElementAndIdentifier(editorElement, 'editorjs')
        console.log('[ContentEditor] EditorJS controller found:', this.editorController)
        console.log('[ContentEditor] EditorJS controller has editor:', !!this.editorController?.editor)
        
        // Setup event listener for EditorJS changes
        this.setupEditorJSListener()
      } catch (error) {
        console.error('[ContentEditor] Failed to get EditorJS controller:', error)
      }
    } else {
      console.warn('[ContentEditor] EditorJS element not found')
    }
  }

  setupEditorJSListener() {
    if (!this.editorController) return
    
    // Wait for editor to be ready, then attach listener
    const checkAndAttach = () => {
      if (this.editorController?.editor) {
        // Listen to EditorJS change events
        this.editorController.editor.on('change', () => {
          this.dispatchChange('edit', null)
        })
        console.log('[ContentEditor] EditorJS change listener attached')
        return true
      }
      return false
    }
    
    // Try immediately
    if (!checkAndAttach()) {
      // Retry after a delay
      setTimeout(() => {
        if (!checkAndAttach()) {
          console.warn('[ContentEditor] EditorJS not ready after retry')
        }
      }, 1000)
    }
  }

  detectTrix() {
    const trixEditor = this.element.querySelector('trix-editor')
    if (trixEditor) {
      this.trixEditor = trixEditor
      console.log('[ContentEditor] Trix editor found')
      
      // Setup event listener for Trix changes
      trixEditor.addEventListener('trix-change', () => {
        this.dispatchChange('edit', null)
      })
      console.log('[ContentEditor] Trix change listener attached')
    }
  }

  detectCKEditor5() {
    const editorElement = this.element.querySelector('[data-controller*="ckeditor5"]')
    if (editorElement) {
      this.editorController = this.application.getControllerForElementAndIdentifier(editorElement, 'ckeditor5')
      console.log('[ContentEditor] CKEditor5 controller found:', !!this.editorController?.editor)
      
      // Setup event listener for CKEditor5 changes
      this.setupCKEditor5Listener()
    }
  }

  setupCKEditor5Listener() {
    if (!this.editorController) return
    
    // Wait for editor to be ready, then attach listener
    const checkAndAttach = () => {
      if (this.editorController?.editor) {
        // Listen to CKEditor5 change events
        this.editorController.editor.model.document.on('change:data', () => {
          this.dispatchChange('edit', null)
        })
        console.log('[ContentEditor] CKEditor5 change listener attached')
        return true
      }
      return false
    }
    
    // Try immediately
    if (!checkAndAttach()) {
      // Retry after a delay
      setTimeout(() => {
        if (!checkAndAttach()) {
          console.warn('[ContentEditor] CKEditor5 not ready after retry')
        }
      }, 1000)
    }
  }

  // GETTERS - Retrieve content in different formats

  async getHtml() {
    switch (this.editorType) {
      case 'editorjs':
        return await this.getEditorJSHtml()
      case 'trix':
        return this.getTrixHtml()
      case 'ckeditor5':
        return this.getCKEditor5Html()
      default:
        return ''
    }
  }

  getText() {
    // Get HTML and strip tags to get plain text
    return this.getHtml().then(html => {
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      return doc.body.textContent || ''
    })
  }

  async getJson() {
    if (this.editorType === 'editorjs') {
      return await this.getEditorJSJson()
    }
    // For other editors, return null or try to serialize
    return null
  }

  // EditorJS specific getters
  async getEditorJSHtml() {
    // Re-detect controller if it's null (might be ready now)
    if (!this.editorController) {
      this.detectEditorJS()
    }
    
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] EditorJS not ready')
      return ''
    }

    try {
      const jsonData = await this.editorController.editor.save()
      return this.convertEditorJSJsonToHtml(jsonData)
    } catch (error) {
      console.error('[ContentEditor] Failed to get EditorJS HTML:', error)
      return ''
    }
  }

  async getEditorJSJson() {
    // Re-detect controller if it's null (might be ready now)
    if (!this.editorController) {
      this.detectEditorJS()
    }
    
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] EditorJS not ready')
      return null
    }

    try {
      return await this.editorController.editor.save()
    } catch (error) {
      console.error('[ContentEditor] Failed to get EditorJS JSON:', error)
      return null
    }
  }

  // Trix specific getters
  getTrixHtml() {
    if (!this.trixEditor) {
      console.warn('[ContentEditor] Trix editor not found')
      return Promise.resolve('')
    }

    try {
      const html = this.trixEditor.editor.getDocument().toString()
      return Promise.resolve(html)
    } catch (error) {
      console.error('[ContentEditor] Failed to get Trix HTML:', error)
      return Promise.resolve('')
    }
  }

  // CKEditor5 specific getters
  getCKEditor5Html() {
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] CKEditor5 not ready')
      return Promise.resolve('')
    }

    try {
      const html = this.editorController.editor.getData()
      return Promise.resolve(html)
    } catch (error) {
      console.error('[ContentEditor] Failed to get CKEditor5 HTML:', error)
      return Promise.resolve('')
    }
  }

  // SETTERS - Set content in different formats

  async setHtml(html) {
    if (!html) {
      console.warn('[ContentEditor] setHtml called with empty content')
      return
    }

    console.log(`[ContentEditor] setHtml called for editor type: ${this.editorType}`)
    console.log('[ContentEditor] HTML content:', html.substring(0, 100) + '...')

    switch (this.editorType) {
      case 'editorjs':
        console.log('[ContentEditor] Setting HTML in EditorJS')
        await this.setEditorJSHtml(html)
        break
      case 'trix':
        console.log('[ContentEditor] Setting HTML in Trix')
        this.setTrixHtml(html)
        break
      case 'ckeditor5':
        console.log('[ContentEditor] Setting HTML in CKEditor5')
        this.setCKEditor5Html(html)
        break
      default:
        console.warn(`[ContentEditor] Unknown editor type: ${this.editorType}`)
    }

    this.dispatchChange('html', html)
  }

  async setText(text) {
    if (!text) return

    // Wrap text in paragraph tag for proper HTML
    const html = `<p>${this.escapeHtml(text)}</p>`
    await this.setHtml(html)
    this.dispatchChange('text', text)
  }

  async setJson(json) {
    if (!json) return

    if (this.editorType === 'editorjs') {
      await this.setEditorJSJson(json)
      this.dispatchChange('json', json)
    } else {
      // For other editors, convert JSON to HTML first
      const html = this.convertEditorJSJsonToHtml(json)
      await this.setHtml(html)
      this.dispatchChange('json', json)
    }
  }

  // EditorJS specific setters
  async setEditorJSHtml(html) {
    console.log('[ContentEditor] setEditorJSHtml called')
    console.log('[ContentEditor] editorController:', this.editorController)
    console.log('[ContentEditor] editor:', this.editorController?.editor)
    
    // If editor not ready, try to detect it again
    if (!this.editorController?.editor) {
      console.log('[ContentEditor] Editor not ready, re-detecting...')
      this.detectEditorJS()
      
      // Wait a bit for editor to initialize
      let retries = 0
      while (!this.editorController?.editor && retries < 10) {
        await new Promise(resolve => setTimeout(resolve, 100))
        retries++
      }
    }
    
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] EditorJS not ready after retries - controller or editor missing')
      return
    }

    try {
      console.log('[ContentEditor] Importing editorjs_converter...')
      // Import HTML to EditorJS converter
      const { htmlToEditorJS } = await import('editorjs_converter')
      console.log('[ContentEditor] Converter imported, converting HTML...')
      
      // Convert HTML to EditorJS JSON
      const editorJSData = htmlToEditorJS(html)
      console.log('[ContentEditor] Converted HTML to EditorJS:', editorJSData)
      
      // Render into EditorJS
      console.log('[ContentEditor] Rendering into EditorJS...')
      await this.editorController.editor.render(editorJSData)
      console.log('[ContentEditor] Rendering complete')
      
      // Trigger saveContent to populate content_json field
      if (this.editorController.saveContent) {
        console.log('[ContentEditor] Triggering saveContent...')
        await this.editorController.saveContent()
        console.log('[ContentEditor] saveContent complete')
      }
    } catch (error) {
      console.error('[ContentEditor] Failed to set EditorJS HTML:', error)
      console.error('[ContentEditor] Error stack:', error.stack)
      throw error
    }
  }

  async setEditorJSJson(json) {
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] EditorJS not ready')
      return
    }

    try {
      await this.editorController.editor.render(json)
      
      // Trigger saveContent to populate content_json field
      if (this.editorController.saveContent) {
        await this.editorController.saveContent()
      }
    } catch (error) {
      console.error('[ContentEditor] Failed to set EditorJS JSON:', error)
      throw error
    }
  }

  // Trix specific setters
  setTrixHtml(html) {
    if (!this.trixEditor) {
      console.warn('[ContentEditor] Trix editor not found')
      return
    }

    try {
      this.trixEditor.editor.loadHTML(html)
    } catch (error) {
      console.error('[ContentEditor] Failed to set Trix HTML:', error)
      throw error
    }
  }

  // CKEditor5 specific setters
  setCKEditor5Html(html) {
    if (!this.editorController?.editor) {
      console.warn('[ContentEditor] CKEditor5 not ready')
      return
    }

    try {
      this.editorController.editor.setData(html)
    } catch (error) {
      console.error('[ContentEditor] Failed to set CKEditor5 HTML:', error)
      throw error
    }
  }

  // Helper methods

  convertEditorJSJsonToHtml(jsonData) {
    if (!jsonData || !jsonData.blocks) return ''
    
    let html = ''
    
    jsonData.blocks.forEach(block => {
      switch (block.type) {
        case 'header':
          html += `<h${block.data.level}>${block.data.text}</h${block.data.level}>`
          break
        
        case 'paragraph':
          html += `<p>${block.data.text}</p>`
          break
        
        case 'list':
          const tag = block.data.style === 'ordered' ? 'ol' : 'ul'
          html += `<${tag}>`
          block.data.items.forEach(item => {
            html += `<li>${item}</li>`
          })
          html += `</${tag}>`
          break
        
        case 'quote':
          html += `<blockquote><p>${block.data.text}</p>`
          if (block.data.caption) {
            html += `<cite>${block.data.caption}</cite>`
          }
          html += `</blockquote>`
          break
        
        case 'code':
          html += `<pre><code>${this.escapeHtml(block.data.code)}</code></pre>`
          break
        
        case 'warning':
          html += `<div class="warning"><strong>${block.data.title}</strong><p>${block.data.message}</p></div>`
          break
        
        case 'delimiter':
          html += '<hr>'
          break
        
        case 'table':
          html += '<table>'
          block.data.content.forEach((row, i) => {
            html += '<tr>'
            row.forEach(cell => {
              const tag = i === 0 && block.data.withHeadings ? 'th' : 'td'
              html += `<${tag}>${cell}</${tag}>`
            })
            html += '</tr>'
          })
          html += '</table>'
          break
        
        case 'image':
          html += `<figure>`
          html += `<img src="${block.data.file.url}" alt="${block.data.caption || ''}">`
          if (block.data.caption) {
            html += `<figcaption>${block.data.caption}</figcaption>`
          }
          html += `</figure>`
          break
        
        case 'embed':
          html += `<div class="embed">${block.data.embed}</div>`
          break
        
        case 'checklist':
          html += '<ul class="checklist">'
          block.data.items.forEach(item => {
            const checked = item.checked ? 'checked' : ''
            html += `<li><input type="checkbox" ${checked} disabled> ${item.text}</li>`
          })
          html += '</ul>'
          break
        
        default:
          html += `<p>${block.data.text || ''}</p>`
      }
    })
    
    return html
  }

  escapeHtml(str) {
    if (!str) return ''
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }

  // Dispatch change event
  dispatchChange(format, content) {
    const event = new CustomEvent('content-editor:changed', {
      detail: {
        editorType: this.editorType,
        format: format,
        content: content
      },
      bubbles: true
    })
    this.element.dispatchEvent(event)
    console.log(`[ContentEditor] Dispatched change event: ${format}`)
  }
}

