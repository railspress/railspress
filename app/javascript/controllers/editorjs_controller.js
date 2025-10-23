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
      console.error('Editor.js not available.')
      return
    }

    // Initialize Editor.js with all available tools
    try {
      // Debug: Check what tools are available
      console.log('Available EditorJS tools:', {
        Header: !!window.Header,
        ImageTool: !!window.ImageTool,
        SimpleImage: !!window.SimpleImage,
        List: !!window.EditorjsList,
        Quote: !!window.Quote,
        Code: !!window.CodeTool,
        Delimiter: !!window.Delimiter,
        Table: !!window.Table,
        RawTool: !!window.RawTool,
        Warning: !!window.Warning,
        Checklist: !!window.Checklist,
        LinkTool: !!window.LinkTool,
        AttachesTool: !!window.AttachesTool,
        Embed: !!window.Embed,
        InlineCode: !!window.InlineCode,
        Marker: !!window.Marker,
        Undo: !!window.Undo
      })

      this.editor = new window.EditorJS({
        holder: 'editorjs',
        placeholder: this.placeholderValue || 'Start writing...',
        autofocus: true,
        data: initialData,
        
        // Essential tools configuration with SVG icons
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
                    title: 'Paragraph',
                    icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 4h14M3 8h14M3 12h10M3 16h8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>'
                  }
                }
              },
              inlineToolbar: true
            },
            // Header
            header: window.Header ? {
              class: window.Header,
              icon: '<svg width="18" height="18" xmlns="http://www.w3.org/2000/svg"><text x="1" y="14" font-size="14" font-family="sans-serif" font-weight="bold">H</text></svg>',
              inlineToolbar: ['marker', 'inlineCode', 'convertTo'],
              config: {
                placeholder: 'Enter a header',
                levels: [1, 2, 3, 4, 5, 6],
                defaultLevel: 2
              }
            } : undefined,
            // Image (Advanced)
            image: window.ImageTool ? {
              class: window.ImageTool,
              config: {
                endpoints: {
                  byFile: '/admin/uploads/image',
                  byUrl: '/admin/uploads/image_by_url'
                },
                field: 'image',
                types: 'image/*',
                captionPlaceholder: 'Enter image caption',
                buttonContent: 'Select an image',
              }
            } : undefined,
            // Simple Image (URL-based)
            simpleImage: window.SimpleImage ? {
              class: window.SimpleImage,
              inlineToolbar: true,
              config: {
                placeholder: 'Paste image URL'
              }
            } : undefined,
            // List
            list: window.EditorjsList ? {
              class: window.EditorjsList,
              inlineToolbar: true,
              config: {
                defaultStyle: 'unordered'
              }
            } : undefined,
            // Code
            code: window.CodeTool ? {
              class: window.CodeTool,
              config: {
                placeholder: 'Enter code here...'
              }
            } : undefined,
            // Quote
            quote: window.Quote ? {
              class: window.Quote,
              inlineToolbar: true,
              config: {
                quotePlaceholder: 'Enter a quote',
                captionPlaceholder: "Quote's author"
              }
            } : undefined,
            // Delimiter
            delimiter: window.Delimiter ? {
              class: window.Delimiter,
            } : undefined,
            // Table
            table: window.Table ? {
              class: window.Table,
              inlineToolbar: true,
              config: {
                rows: 2,
                cols: 3
              }
            } : undefined,
            // Raw HTML
            raw: window.RawTool ? {
              class: window.RawTool,
              config: {
                placeholder: 'Enter raw HTML code...'
              }
            } : undefined,
            // Warning
            warning: window.Warning ? {
              class: window.Warning,
              inlineToolbar: true,
              config: {
                titlePlaceholder: 'Title',
                messagePlaceholder: 'Message'
              }
            } : undefined,
            // Checklist
            checklist: window.Checklist ? {
              class: window.Checklist,
              inlineToolbar: true
            } : undefined,
            // Link
            linkTool: window.LinkTool ? {
              class: window.LinkTool,
              config: {
                endpoint: '/admin/uploads/link_preview'
              }
            } : undefined,
            // Attaches
            attaches: window.AttachesTool ? {
              class: window.AttachesTool,
              config: {
                endpoint: '/admin/uploads/attaches'
              }
            } : undefined,
            // Embed
            embed: window.Embed ? {
              class: window.Embed,
              config: {
                services: {
                  youtube: true,
                  codepen: true,
                  instagram: true,
                  twitter: true,
                  vimeo: true,
                  github: true
                }
              }
            } : undefined,
            // Inline tools
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
      if (window.EditorJS) {
        resolve()
      } else {
        const checkInterval = setInterval(() => {
          if (window.EditorJS) {
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

  
}

