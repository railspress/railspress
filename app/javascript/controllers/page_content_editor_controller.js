import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "previewTab", "codeTab",
    "previewTabIndicator", "codeTabIndicator",
    "previewContent", "codeContent",
    "previewFrame", "contentField"
  ]

  static values = {
    activeTab: { type: String, default: "preview" },
    htmlContent: String
  }

  connect() {
    console.log('[PageContentEditor] Connected')
    this.currentTab = this.activeTabValue || "preview"
    this.monacoEditor = null
    
    // Initialize preview with existing content
    if (this.hasContentFieldTarget && this.contentFieldTarget.value) {
      this.updatePreview(this.contentFieldTarget.value)
    }
    
    this.initializeMonaco()
    this.switchTab(this.currentTab)
    
    // Listen for content changes from the hidden field
    if (this.hasContentFieldTarget) {
      this.contentFieldTarget.addEventListener('input', this.handleContentChange.bind(this))
    }
  }

  disconnect() {
    if (this.monacoEditor) {
      this.monacoEditor.dispose()
      this.monacoEditor = null
    }
  }

  async initializeMonaco() {
    try {
      // Try to load Monaco from CDN
      console.log('[PageContentEditor] Loading Monaco from CDN...')
      await this.loadMonacoFromCDN()
    } catch (error) {
      console.error('[PageContentEditor] Failed to initialize Monaco:', error)
      // Fall back to simple textarea
      this.fallbackToTextarea()
    }
  }

  async loadMonacoFromCDN() {
    return new Promise((resolve, reject) => {
      // Check if Monaco is already loaded
      if (window.monaco) {
        console.log('[PageContentEditor] Monaco already loaded')
        this.setupMonacoEditor()
        resolve()
        return
      }

      // Load Monaco loader script
      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs/loader.min.js'
      script.onload = () => {
        console.log('[PageContentEditor] Monaco loader loaded')
        this.setupMonacoWithLoader()
        resolve()
      }
      script.onerror = () => reject(new Error('Failed to load Monaco loader'))
      document.head.appendChild(script)
    })
  }

  setupMonacoWithLoader() {
    require.config({ 
      paths: { 
        vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs' 
      } 
    })
    require(['vs/editor/editor.main'], () => {
      console.log('[PageContentEditor] Monaco main loaded')
      this.setupMonacoEditor()
    })
  }

  setupMonacoEditor() {
    if (!this.hasCodeContentTarget) return
    
    const container = document.getElementById('monaco-editor-container')
    if (!container) {
      console.error('[PageContentEditor] Monaco container not found')
      return
    }

    try {
      this.monacoEditor = window.monaco.editor.create(container, {
        value: this.contentFieldTarget?.value || '',
        language: 'html',
        theme: 'vs-dark',
        fontSize: 14,
        minimap: { enabled: false },
        automaticLayout: true,
        scrollBeyondLastLine: false,
        wordWrap: 'on',
        lineNumbers: 'on'
      })

      // Sync Monaco changes to hidden textarea
      this.monacoEditor.onDidChangeModelContent(() => {
        if (this.hasContentFieldTarget) {
          const value = this.monacoEditor.getValue()
          this.contentFieldTarget.value = value
          this.updatePreview(value)
          
          // Trigger autosave
          this.contentFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
        }
      })

      console.log('[PageContentEditor] Monaco editor initialized')
    } catch (error) {
      console.error('[PageContentEditor] Failed to create Monaco editor:', error)
      this.fallbackToTextarea()
    }
  }

  fallbackToTextarea() {
    console.log('[PageContentEditor] Falling back to textarea')
    // Replace Monaco container with textarea
    const container = document.getElementById('monaco-editor-container')
    if (container) {
      const textarea = document.createElement('textarea')
      textarea.className = 'w-full h-full font-mono text-sm p-4 resize-none'
      textarea.style.background = 'var(--admin-bg-secondary)'
      textarea.style.color = 'var(--admin-text-primary)'
      textarea.style.border = 'none'
      textarea.style.outline = 'none'
      textarea.value = this.contentFieldTarget?.value || ''
      
      textarea.addEventListener('input', (e) => {
        this.contentFieldTarget.value = e.target.value
        this.updatePreview(e.target.value)
        this.contentFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
      })
      
      container.innerHTML = ''
      container.appendChild(textarea)
    }
  }

  switchTab(event) {
    let targetTab = this.currentTab
    
    if (event && event.currentTarget) {
      event.preventDefault()
      const button = event.currentTarget
      targetTab = button.dataset.tab
    } else if (event && event.dataset && event.dataset.tab) {
      // Called with tab string directly
      targetTab = event.dataset.tab
    }
    
    this.currentTab = targetTab

    // Update tab indicators
    if (targetTab === 'preview') {
      if (this.hasPreviewTabIndicatorTarget) {
        this.previewTabIndicatorTarget.style.opacity = '1'
      }
      if (this.hasCodeTabIndicatorTarget) {
        this.codeTabIndicatorTarget.style.opacity = '0'
      }
      if (this.hasPreviewContentTarget) {
        this.previewContentTarget.classList.remove('hidden')
      }
      if (this.hasCodeContentTarget) {
        this.codeContentTarget.classList.add('hidden')
      }
      
      // Update preview with current content
      const content = this.contentFieldTarget?.value || ''
      this.updatePreview(content)
      
      // Focus on preview area (optional)
    } else if (targetTab === 'code') {
      if (this.hasPreviewTabIndicatorTarget) {
        this.previewTabIndicatorTarget.style.opacity = '0'
      }
      if (this.hasCodeTabIndicatorTarget) {
        this.codeTabIndicatorTarget.style.opacity = '1'
      }
      if (this.hasPreviewContentTarget) {
        this.previewContentTarget.classList.add('hidden')
      }
      if (this.hasCodeContentTarget) {
        this.codeContentTarget.classList.remove('hidden')
      }
      
      // Focus Monaco editor when switching to code tab
      if (this.monacoEditor) {
        setTimeout(() => {
          this.monacoEditor.focus()
        }, 100)
      }
    }
  }

  updatePreview(html) {
    if (!this.hasPreviewFrameTarget) return
    
    const previewFrame = this.previewFrameTarget
    console.log('[PageContentEditor] updatePreview called with HTML length:', html?.length || 0)
    
    if (html && html.trim()) {
      // Use iframe for safer HTML rendering
      let iframe = previewFrame.querySelector('iframe')
      
      if (!iframe) {
        iframe = document.createElement('iframe')
        iframe.style.width = '100%'
        iframe.style.height = '100%'
        iframe.style.border = 'none'
        // Note: Not using sandbox to allow access to contentDocument
        // If you need security, consider using srcdoc instead
        previewFrame.innerHTML = '' // Clear any existing content
        previewFrame.appendChild(iframe)
      }
      
      // Wait for iframe to be attached before accessing contentDocument
      setTimeout(() => {
        try {
          const frameDoc = iframe.contentDocument || iframe.contentWindow.document
          if (frameDoc) {
            frameDoc.open()
            frameDoc.write(html)
            frameDoc.close()
            console.log('[PageContentEditor] Preview updated successfully')
            // Bind click-to-edit interactions inside preview
            this.bindPreviewInteractions(frameDoc)
          } else {
            console.error('[PageContentEditor] Could not access iframe document')
            previewFrame.innerHTML = `<pre style="white-space: pre-wrap; word-wrap: break-word;">${html}</pre>`
          }
        } catch (error) {
          console.error('[PageContentEditor] Failed to update preview:', error)
          // Fallback: display HTML as escaped text
          previewFrame.innerHTML = `<pre style="white-space: pre-wrap; word-wrap: break-word;">${html}</pre>`
        }
      }, 100)
    } else {
      console.log('[PageContentEditor] No HTML to preview, showing empty state')
      previewFrame.innerHTML = '<div class="text-gray-400 text-center py-20">No content to preview. Generate some HTML with AI or paste HTML in the Code tab.</div>'
    }
  }

  bindPreviewInteractions(frameDoc) {
    // Avoid duplicate listeners by resetting handlers
    frameDoc.body.onclick = null
    frameDoc.body.ondblclick = null

    frameDoc.body.addEventListener('click', (e) => {
      const target = e.target
      if (target && target.tagName === 'IMG') {
        e.preventDefault()
        e.stopPropagation()
        this.handleImageReplace(target)
      }
    })

    frameDoc.body.addEventListener('dblclick', (e) => {
      const target = e.target
      if (!target) return
      e.preventDefault()
      e.stopPropagation()
      if (target.tagName !== 'IMG') {
        const current = target.innerHTML
        const updated = prompt('Edit content HTML:', current)
        if (updated !== null) {
          target.innerHTML = updated
          this.replaceOuterHtmlInSource(target, target.outerHTML)
        }
      }
    })
  }

  handleImageReplace(imgEl) {
    const currentSrc = imgEl.getAttribute('src') || ''
    const newSrc = prompt('New image URL:', currentSrc)
    if (newSrc && newSrc !== currentSrc) {
      imgEl.setAttribute('src', newSrc)
      this.replaceOuterHtmlInSource(imgEl, imgEl.outerHTML)
    }
  }

  replaceOuterHtmlInSource(nodeInIframe, newOuterHtml) {
    // Get current source HTML
    const currentHtml = this.monacoEditor ? this.monacoEditor.getValue() : (this.hasContentFieldTarget ? this.contentFieldTarget.value : '')
    if (!currentHtml) return
    try {
      // Find by previous outerHTML using a clone before mutation if available
      // Fallback: regenerate HTML from iframe body
      const iframeDoc = nodeInIframe.ownerDocument
      const latestHtml = iframeDoc.documentElement.outerHTML.includes('<body') ? iframeDoc.body.innerHTML : newOuterHtml
      // Try simple replacement by matching up to the element
      // We attempt to locate the element by its tag and a few attributes
      const tag = nodeInIframe.tagName.toLowerCase()
      let selector = tag
      if (nodeInIframe.id) selector += `#${nodeInIframe.id}`
      // Build a candidate old outerHTML by temporarily changing src back (for IMG) or innerHTML back is not trivial.
      // Use heuristic: replace the first occurrence of a similar element with same tag and innerHTML/src
      let searchFragment = ''
      if (tag === 'img') {
        const src = nodeInIframe.getAttribute('src')
        searchFragment = `<img` // coarse search
      } else {
        const snippet = (nodeInIframe.innerHTML || '').slice(0, 60)
        searchFragment = `<${tag}`
      }
      // Fallback: replace by index using iframe body serialization
      // Safer approach: locate node outerHTML in serialized iframe body and map index in source
      const iframeBodyHtml = iframeDoc.body.innerHTML
      // Update editor with iframe body HTML to keep preview/source in sync
      if (this.monacoEditor) {
        this.monacoEditor.setValue(iframeBodyHtml)
      }
      if (this.hasContentFieldTarget) {
        this.contentFieldTarget.value = iframeBodyHtml
        this.contentFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
      }
      // Re-render preview from updated source
      this.updatePreview(iframeBodyHtml)
    } catch (e) {
      console.error('[PageContentEditor] Failed to replace HTML in source:', e)
    }
  }

  handleContentChange(event) {
    // When content changes (from AI insert or manual edit), update preview if on preview tab
    if (this.currentTab === 'preview') {
      const content = event.target.value
      this.updatePreview(content)
    }
  }

  // Method for AI chat widget to insert HTML
  async setHtml(html) {
    console.log('[PageContentEditor] setHtml called with:', html)
    
    if (this.monacoEditor) {
      // Insert into Monaco editor
      this.monacoEditor.setValue(html)
      this.contentFieldTarget.value = html
      
      // Update preview with the HTML content
      this.updatePreview(html)
      
      // Switch to preview tab to show the result
      setTimeout(() => {
        this.switchTab({ preventDefault: () => {}, currentTarget: { dataset: { tab: 'preview' } } })
      }, 300)
    } else if (this.hasContentFieldTarget) {
      // Fallback: insert into textarea
      this.contentFieldTarget.value = html
      
      // Update preview with the HTML content
      this.updatePreview(html)
      
      // Trigger input event
      this.contentFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
      
      // Switch to preview tab
      setTimeout(() => {
        this.switchTab({ preventDefault: () => {}, currentTarget: { dataset: { tab: 'preview' } } })
      }, 300)
    }
  }

  // Method for getting HTML content (for content-editor compatibility)
  getHtml() {
    if (this.monacoEditor) {
      return this.monacoEditor.getValue()
    } else if (this.hasContentFieldTarget) {
      return this.contentFieldTarget.value
    }
    return ''
  }
}

