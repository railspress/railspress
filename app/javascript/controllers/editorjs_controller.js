import { Controller } from "@hotwired/stimulus"

// Editor.js integration for distraction-free writing
export default class extends Controller {
  static targets = ["input", "toolbar", "title"]
  static values = {
    content: String,
    placeholder: String
  }

  async connect() {
    console.log("Editor.js controller connecting...")
    
    // Wait for Editor.js to be loaded from CDN
    await this.waitForEditorJS()
    
    // Parse existing content if any
    let initialData = null
    if (this.contentValue) {
      try {
        initialData = JSON.parse(this.contentValue)
      } catch (e) {
        // If it's HTML from ActionText, convert to plain text block
        initialData = {
          blocks: [{
            type: 'paragraph',
            data: { text: this.contentValue }
          }]
        }
      }
    }

    // Check if Editor.js is available
    if (typeof window.EditorJS === 'undefined') {
      console.error('Editor.js not available, showing fallback')
      this.showFallbackEditor()
      return
    }

    // Initialize Editor.js with all available tools
    try {
      // Debug: Check what tools are available
      console.log('Available EditorJS tools:', {
        Header: !!window.Header,
        List: !!window.List,
        Quote: !!window.Quote,
        Code: !!window.Code,
        Delimiter: !!window.Delimiter,
        Table: !!window.Table,
        Warning: !!window.Warning,
        Checklist: !!window.Checklist,
        SimpleImage: !!window.SimpleImage,
        InlineCode: !!window.InlineCode,
        Marker: !!window.Marker,
        Undo: !!window.Undo
      })

      this.editor = new window.EditorJS({
        holder: 'editorjs',
        placeholder: this.placeholderValue || 'Start writing...',
        autofocus: true,
        data: initialData,
        
        // Essential tools configuration (only reliable ones)
        tools: Object.fromEntries(
          Object.entries({
            // Essential paragraph tool (EditorJS requires this)
            paragraph: {
              class: window.Paragraph || class {
                constructor({ data, config, api, readOnly }) {
                  this.api = api
                  this.readOnly = readOnly
                  this.data = data || { text: '' }
                }
                
                render() {
                  const wrapper = document.createElement('div')
                  wrapper.classList.add('ce-paragraph')
                  wrapper.contentEditable = !this.readOnly
                  wrapper.innerHTML = this.data.text || ''
                  return wrapper
                }
                
                save(blockContent) {
                  return { text: blockContent.innerHTML }
                }
                
                static get toolbox() {
                  return {
                    title: 'Paragraph'
                  }
                }
              },
              inlineToolbar: true
            },
            // Only use tools that are definitely loaded and working
            header: window.Header ? {
              class: window.Header,
              inlineToolbar: ['marker', 'inlineCode'],
              config: {
                placeholder: 'Enter a header',
                levels: [1, 2, 3, 4, 5, 6],
                defaultLevel: 2
              }
            } : undefined,
            list: window.List ? {
              class: window.List,
              inlineToolbar: true,
              config: {
                defaultStyle: 'unordered'
              }
            } : undefined,
            quote: window.Quote ? {
              class: window.Quote,
              inlineToolbar: true,
              config: {
                quotePlaceholder: 'Enter a quote',
                captionPlaceholder: "Quote's author"
              }
            } : undefined,
            code: window.Code ? {
              class: window.Code,
              config: {
                placeholder: 'Enter code here...'
              }
            } : undefined,
            delimiter: window.Delimiter,
            table: window.Table ? {
              class: window.Table,
              inlineToolbar: true,
              config: {
                rows: 2,
                cols: 3
              }
            } : undefined,
            warning: window.Warning ? {
              class: window.Warning,
              inlineToolbar: true,
              config: {
                titlePlaceholder: 'Title',
                messagePlaceholder: 'Message'
              }
            } : undefined,
            checklist: window.Checklist ? {
              class: window.Checklist,
              inlineToolbar: true
            } : undefined,
            image: window.SimpleImage ? {
              class: window.SimpleImage,
              inlineToolbar: true
            } : undefined,
            inlineCode: window.InlineCode ? {
              class: window.InlineCode
            } : undefined,
            marker: window.Marker ? {
              class: window.Marker
            } : undefined,
            undo: window.Undo ? {
              class: window.Undo
            } : undefined
          }).filter(([key, value]) => value !== undefined)
        ),
        
        onChange: async () => {
          await this.saveContent()
          // Notify autosave controller that content has changed
          this.notifyAutosave()
        },
        
        onReady: () => {
          console.log('Editor.js is ready!')
          this.setupKeyboardShortcuts()
        }
      })
    } catch (error) {
      console.error('Editor.js initialization failed:', error)
      this.showFallbackEditor()
    }
  }

  notifyAutosave() {
    // Find the autosave controller and notify it of changes
    const autosaveController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="autosave"]'), 
      'autosave'
    )
    if (autosaveController) {
      autosaveController.handleChange()
    }
  }

  disconnect() {
    if (this.editor && this.editor.destroy) {
      this.editor.destroy()
    }
  }

  async saveContent() {
    try {
      const outputData = await this.editor.save()
      
      // Convert to HTML for ActionText compatibility
      const html = this.convertToHTML(outputData)
      
      // Store both JSON and HTML
      this.inputTarget.value = html
      
      // Also store JSON in a data attribute for future editing
      this.element.dataset.editorjsContent = JSON.stringify(outputData)
      
      // Auto-save indicator
      this.showSaveIndicator()
    } catch (error) {
      console.error('Saving failed:', error)
    }
  }

  convertToHTML(data) {
    if (!data || !data.blocks) return ''
    
    let html = ''
    
    data.blocks.forEach(block => {
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
          html += `<pre><code>${this.escapeHTML(block.data.code)}</code></pre>`
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

  escapeHTML(str) {
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }

  showSaveIndicator() {
    if (!this.hasToolbarTarget) return
    
    const indicator = this.toolbarTarget.querySelector('.save-indicator')
    if (indicator) {
      indicator.textContent = '✓ Saved'
      indicator.classList.add('text-green-400')
      
      setTimeout(() => {
        indicator.classList.remove('text-green-400')
        indicator.textContent = ''
      }, 2000)
    }
  }

  setupKeyboardShortcuts() {
    // CMD/CTRL + S to trigger form save
    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault()
        this.element.closest('form')?.requestSubmit()
      }
    })
  }

  // Focus on title input
  focusTitle() {
    if (this.hasTitleTarget) {
      this.titleTarget.focus()
    }
  }

  // Toggle fullscreen
  toggleFullscreen() {
    document.body.classList.toggle('editorjs-fullscreen')
    
    if (document.fullscreenEnabled) {
      if (!document.fullscreenElement) {
        this.element.closest('.editorjs-wrapper')?.requestFullscreen()
      } else {
        document.exitFullscreen()
      }
    }
  }
  
  // Helper to wait for Editor.js to load
  waitForEditorJS() {
    return new Promise((resolve) => {
      if (window.EditorJS && window.EditorJSLoaded) {
        resolve()
      } else {
        const checkInterval = setInterval(() => {
          if (window.EditorJS && window.EditorJSLoaded) {
            clearInterval(checkInterval)
            resolve()
          }
        }, 100)
        
        // Timeout after 5 seconds
        setTimeout(() => {
          clearInterval(checkInterval)
          console.warn('Editor.js failed to load within timeout')
          resolve()
        }, 5000)
      }
    })
  }

  triggerAutoSave() {
    // Dispatch event for autosave functionality
    const event = new CustomEvent('editor:content-changed', {
      detail: { content: this.inputTarget.value }
    })
    window.dispatchEvent(event)
  }

  showFallbackEditor() {
    const container = this.element.querySelector('.editorjs-container')
    if (container) {
      container.innerHTML = `
        <div class="p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg text-blue-400 mb-4">
          <p class="font-medium mb-2">📝 Using Rich Text Editor</p>
          <p class="text-sm">Editor.js is loading... Using a rich text editor with formatting toolbar.</p>
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
      }
    }
  }
}

