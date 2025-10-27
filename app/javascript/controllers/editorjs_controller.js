import { Controller } from "@hotwired/stimulus"
import MediaTool from "editorjs_media_tool"

// Editor.js integration for distraction-free writing
export default class extends Controller {
  static targets = ["input", "toolbar", "title", "jsonInput"]
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
        // Try to parse as JSON first
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
        Paragraph: !!window.Paragraph
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
            
            // Header
            header: window.Header ? {
              class: Header,
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
                  byFile: '/admin/media/upload',
                  byUrl: '/admin/media/upload'
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
              class: window.Embed
              
            } : undefined,
            // Inline tools
            inlineCode: window.InlineCode ? {
              class: window.InlineCode
            } : undefined,
            marker: window.Marker ? {
              class: window.Marker
            } : undefined,
            
            // Media tool
            media: {
              class: MediaTool,
              config: {
                dialogId: 'editorjs-media-selector',
                callback: 'handleEditorJSMediaSelected'
              }
            },
            
            // Plugin tools injection
            ...(window.pluginEditorJsTools || {})
          }).filter(([key, value]) => value !== undefined)
        ),
        
        onChange: async () => {
          await this.saveContent()
          // Notify autosave controller that content has changed
          this.notifyAutosave()
        },
        
        onReady: () => {
          console.log('Editor.js is ready!')
          
          // Initialize Undo plugin after editor is ready
          if (window.Undo) {
            try {
              new window.Undo({ editor: this.editor })
              console.log('Undo plugin initialized')
            } catch (error) {
              console.warn('Failed to initialize Undo plugin:', error)
            }
          }
          
          
        }
      })
    } catch (error) {
      console.error('Editor.js initialization failed:', error)
    }
  }

  notifyAutosave() {
    
    

    const autosaveElement = document.querySelector('[data-controller*="autosave"]')
    if (autosaveElement) {
      autosaveElement.dispatchEvent(new CustomEvent('editor:content-changed'))
      console.log('Autosave controller notified of content changes');
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
      
      // Store JSON in content_json field
      if (this.hasJsonInputTarget) {
        this.jsonInputTarget.value = JSON.stringify(outputData)
      }
      
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
    
    let parser
    if (edjsParser != undefined)
    {
      parser = new edjsParser(); 
    }
    else
    {
      console.log('edjsParser not found');
      return '';
    }
    
    let html = ''
    
    data.blocks.forEach(block => {
      switch (block.type) {

        case 'warning':
          html += `<div class="warning"><strong>${block.data.title}</strong><p>${block.data.message}</p></div>`
          break

        case 'checklist':
          html += '<ul class="checklist">'
          block.data.items.forEach(item => {
            const checked = item.checked ? 'checked' : ''
            html += `<li><input type="checkbox" ${checked} disabled> ${item.text}</li>`
          })
          html += '</ul>'
          break
        
        case 'uppy':
          if (block.data.files && block.data.files.length > 0) {
            html += '<div class="uploaded-files">'
            block.data.files.forEach(file => {
              if (file.type && file.type.startsWith('image/')) {
                const caption = file.caption || file.name;
                html += `<figure><img src="${file.url}" alt="${file.name}"><figcaption>${this.escapeHTML(caption)}</figcaption></figure>`
              } else {
                html += `<p><a href="${file.url}" download="${file.name}" class="file-download">${file.name}</a></p>`
              }
            })
            html += '</div>'
          }
          break

        case 'media':
          const media = block.data.media
          if (!media) break
          
          // Get media type (could be 'type' or 'file_type')
          const mediaType = media.type || media.file_type
          
          // Render based on media type
          if (mediaType && mediaType.startsWith('image/')) {
            // Image
            const alt = this.escapeHTML(media.alt_text || media.title || '')
            const caption = media.caption ? `<figcaption>${this.escapeHTML(media.caption)}</figcaption>` : ''
            html += `<figure class="media-block media-image">
              <img src="${media.url}" alt="${alt}" ${media.width ? `width="${media.width}"` : ''} ${media.height ? `height="${media.height}"` : ''}>
              ${caption}
            </figure>`
          } else if (mediaType && mediaType.startsWith('video/')) {
            // Video
            const caption = media.caption ? `<figcaption>${this.escapeHTML(media.caption)}</figcaption>` : ''
            html += `<figure class="media-block media-video">
              <video controls src="${media.url}" ${media.width ? `width="${media.width}"` : ''} ${media.height ? `height="${media.height}"` : ''}></video>
              ${caption}
            </figure>`
          } else {
            // File/Document or default to image if URL suggests it's an image
            const isImageUrl = media.url && /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(media.url)
            
            if (isImageUrl && !mediaType) {
              // Assume it's an image from URL
              const alt = this.escapeHTML(media.alt_text || media.title || '')
              html += `<figure class="media-block media-image">
                <img src="${media.url}" alt="${alt}">
              </figure>`
            } else {
              // File/Document
              const fileSize = media.file_size ? ` (${this.formatFileSize(media.file_size)})` : ''
              html += `<div class="media-block media-file">
                <a href="${media.url}" download="${media.title || 'file'}" class="file-download">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M5 2H13L17 6V16C17 16.5304 16.7893 17.0391 16.4142 17.4142C16.0391 17.7893 15.5304 18 15 18H5C4.46957 18 3.96086 17.7893 3.58579 17.4142C3.21071 17.0391 3 16.5304 3 16V4C3 3.46957 3.21071 2.96086 3.58579 2.58579C3.96086 2.21071 4.46957 2 5 2Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    <path d="M13 2V6H17" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                  ${this.escapeHTML(media.title || 'File')}${fileSize}
                </a>
              </div>`
            }
          }
          break
        
        default:
          html += parser.parseBlock(block);
      }
    })
    
    console.log(html);
    return html
  }

  escapeHTML(str) {
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }

  formatFileSize(bytes) {
    if (!bytes) return ''
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i]
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

