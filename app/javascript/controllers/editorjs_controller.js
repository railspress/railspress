import { Controller } from "@hotwired/stimulus"

// Editor.js integration for distraction-free writing
export default class extends Controller {
  static targets = ["input", "toolbar", "title"]
  static values = {
    content: String,
    placeholder: String
  }

  async connect() {
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

    // Initialize Editor.js
    this.editor = new EditorJS({
      holder: this.element.querySelector('.editorjs-container'),
      
      placeholder: this.placeholderValue || 'Start writing...',
      
      autofocus: true,
      
      data: initialData,
      
      tools: {
        header: {
          class: window.Header,
          config: {
            levels: [1, 2, 3, 4, 5, 6],
            defaultLevel: 2
          },
          inlineToolbar: true,
          shortcut: 'CMD+SHIFT+H'
        },
        
        list: {
          class: window.NestedList,
          inlineToolbar: true,
          shortcut: 'CMD+SHIFT+L'
        },
        
        checklist: {
          class: window.Checklist,
          inlineToolbar: true
        },
        
        quote: {
          class: window.Quote,
          inlineToolbar: true,
          config: {
            quotePlaceholder: 'Enter a quote',
            captionPlaceholder: 'Quote author'
          },
          shortcut: 'CMD+SHIFT+Q'
        },
        
        code: {
          class: window.Code,
          shortcut: 'CMD+SHIFT+C'
        },
        
        warning: {
          class: window.Warning,
          inlineToolbar: true,
          config: {
            titlePlaceholder: 'Title',
            messagePlaceholder: 'Message'
          }
        },
        
        delimiter: {
          class: window.Delimiter
        },
        
        table: {
          class: window.Table,
          inlineToolbar: true
        },
        
        raw: {
          class: window.RawTool
        },
        
        image: {
          class: window.ImageTool,
          config: {
            endpoints: {
              byFile: '/admin/upload/image',
              byUrl: '/admin/upload/image_url'
            },
            additionalRequestHeaders: {
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
            }
          }
        },
        
        attaches: {
          class: window.AttachesTool,
          config: {
            endpoint: '/admin/upload/file',
            additionalRequestHeaders: {
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
            }
          }
        },
        
        embed: {
          class: window.Embed,
          config: {
            services: {
              youtube: true,
              vimeo: true,
              twitter: true,
              instagram: true,
              codepen: true,
              github: true
            }
          },
          inlineToolbar: true
        },
        
        // Inline tools
        marker: {
          class: window.Marker,
          shortcut: 'CMD+SHIFT+M'
        },
        
        inlineCode: {
          class: window.InlineCode,
          shortcut: 'CMD+E'
        },
        
        underline: {
          class: window.Underline,
          shortcut: 'CMD+U'
        }
      },
      
      onChange: async () => {
        await this.saveContent()
      },
      
      onReady: () => {
        console.log('Editor.js is ready!')
        this.setupKeyboardShortcuts()
      }
    })
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
        
        // Timeout after 10 seconds
        setTimeout(() => {
          clearInterval(checkInterval)
          console.error('Editor.js failed to load')
          resolve()
        }, 10000)
      }
    })
  }
}

