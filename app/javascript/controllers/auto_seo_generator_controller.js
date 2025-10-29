import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "loadingIndicator"]
  
  connect() {
    this.callTimestamps = []
    this.isGenerating = false
    this.contentEditor = null
    
    // Load SiteSetting value on connect and set up checkbox
    this.loadSiteSetting()
    
    // Listen for checkbox changes
    this.checkboxTarget.addEventListener('change', async () => {
      const isChecked = this.checkboxTarget.checked
      
      // Save SiteSetting preference
      await this.saveSiteSetting(isChecked)
      
      if (isChecked) {
        this.setupContentEditorListener()
        // If fields are empty, generate immediately
        setTimeout(async () => {
          await this.checkAndGenerateIfEmpty()
        }, 100) // Small delay to ensure editor is ready
      } else {
        this.removeContentEditorListener()
      }
    })
  }
  
  disconnect() {
    this.removeContentEditorListener()
  }
  
  setupContentEditorListener() {
    // Listen to content-editor:changed events
    if (!this.contentEditorListener) {
      this.contentEditorListener = (event) => {
        this.handleContentChange(event)
      }
      // Listen on document with capture phase to catch bubbling events
      document.addEventListener('content-editor:changed', this.contentEditorListener, true)
    }
  }
  
  removeContentEditorListener() {
    if (this.contentEditorListener) {
      document.removeEventListener('content-editor:changed', this.contentEditorListener, true)
      this.contentEditorListener = null
    }
  }
  
  areMetaFieldsEmpty() {
    const metaTitleField = document.querySelector('[name*="[meta_title]"]')
    const metaDescriptionField = document.querySelector('[name*="[meta_description]"]')
    const metaKeywordsField = document.querySelector('[name*="[meta_keywords]"]')
    
    const titleEmpty = !metaTitleField || !metaTitleField.value || metaTitleField.value.trim().length === 0
    const descriptionEmpty = !metaDescriptionField || !metaDescriptionField.value || metaDescriptionField.value.trim().length === 0
    const keywordsEmpty = !metaKeywordsField || !metaKeywordsField.value || metaKeywordsField.value.trim().length === 0
    
    // Return true if at least one field is empty
    return titleEmpty || descriptionEmpty || keywordsEmpty
  }
  
  async checkAndGenerateIfEmpty() {
    // Only generate if fields are empty
    if (!this.areMetaFieldsEmpty()) {
      return
    }
    
    // Get content from editor
    const contentText = await this.extractContent()
    
    // Skip if content is too short
    if (!contentText || contentText.trim().length < 50) {
      console.log('[AutoSEO] Content too short for generation')
      return
    }
    
    // Generate SEO meta tags
    await this.generateMetaTags(contentText)
  }
  
  async handleContentChange(event) {
    // Only proceed if checkbox is checked
    if (!this.checkboxTarget.checked) {
      return
    }
    
    // Check debounce limits
    if (!this.canGenerate()) {
      return
    }
    
    // Get content from editor
    const contentText = await this.extractContent()
    
    // Skip if content is too short
    if (!contentText || contentText.trim().length < 50) {
      return
    }
    
    // Generate SEO meta tags
    await this.generateMetaTags(contentText)
  }
  
  canGenerate() {
    const now = Date.now()
    const oneMinuteAgo = now - 60000 // 60 seconds
    const twentySecondsAgo = now - 20000 // 20 seconds
    
    // Remove timestamps older than 1 minute
    this.callTimestamps = this.callTimestamps.filter(ts => ts > oneMinuteAgo)
    
    // Check if we've made more than 3 calls in the last minute
    if (this.callTimestamps.length >= 3) {
      return false
    }
    
    // Check if at least 20 seconds have passed since last call
    if (this.callTimestamps.length > 0) {
      const lastCall = this.callTimestamps[this.callTimestamps.length - 1]
      if (now - lastCall < 20000) {
        return false
      }
    }
    
    return true
  }
  
  async extractContent() {
    try {
      // Find content-editor controller
      const editorWrapper = document.querySelector('[data-controller*="content-editor"]')
      if (!editorWrapper) {
        console.warn('[AutoSEO] Content editor wrapper not found')
        return null
      }
      
      const contentEditor = this.application.getControllerForElementAndIdentifier(editorWrapper, 'content-editor')
      if (!contentEditor) {
        console.warn('[AutoSEO] Content editor controller not found')
        return null
      }
      
      // Get plain text content
      const text = await contentEditor.getText()
      return text
    } catch (error) {
      console.error('[AutoSEO] Failed to extract content:', error)
      return null
    }
  }
  
  async generateMetaTags(contentText) {
    if (this.isGenerating) {
      return
    }
    
    this.isGenerating = true
    this.showLoading(true)
    
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      
      const response = await fetch('/admin/ai_agents/execute/meta_generator', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          user_input: contentText,
          context: {}
        })
      })
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      
      const data = await response.json()
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to generate SEO meta tags')
      }
      
      // Parse JSON response from agent
      let metaData
      try {
        // The agent returns a JSON string, so we need to parse it
        const result = typeof data.result === 'string' ? JSON.parse(data.result) : data.result
        metaData = result
      } catch (parseError) {
        // Try to extract JSON from the response if it's wrapped in text
        const jsonMatch = data.result.match(/\{[\s\S]*\}/)
        if (jsonMatch) {
          metaData = JSON.parse(jsonMatch[0])
        } else {
          throw new Error('Invalid JSON response from agent')
        }
      }
      
      // Update form fields
      this.updateMetaFields(metaData)
      
      // Trigger autosave after a short delay to ensure FormData captures the updated values
      setTimeout(() => {
        // Dispatch a change event on the form to trigger autosave
        const form = document.querySelector('[data-autosave-target="form"]')
        if (form) {
          form.dispatchEvent(new Event('input', { bubbles: true }))
          // Also manually trigger autosave if available
          if (window.savePost) {
            // Wait a bit more to ensure values are set in DOM
            setTimeout(() => {
              console.log('[AutoSEO] Triggering autosave after meta field update')
              window.savePost()
            }, 300)
          }
        }
      }, 100)
      
      // Record successful call
      this.callTimestamps.push(Date.now())
      
    } catch (error) {
      console.error('[AutoSEO] Failed to generate meta tags:', error)
      // Don't show error to user, just log it
    } finally {
      this.isGenerating = false
      this.showLoading(false)
    }
  }
  
  updateMetaFields(metaData) {
    // Update meta_title
    const metaTitleField = document.querySelector('[name*="[meta_title]"]')
    if (metaTitleField && metaData.meta_title) {
      metaTitleField.value = metaData.meta_title
      // Dispatch both input and change events to ensure autosave picks it up
      metaTitleField.dispatchEvent(new Event('input', { bubbles: true }))
      metaTitleField.dispatchEvent(new Event('change', { bubbles: true }))
    }
    
    // Update meta_description
    const metaDescriptionField = document.querySelector('[name*="[meta_description]"]')
    if (metaDescriptionField && metaData.meta_description) {
      metaDescriptionField.value = metaData.meta_description
      // Dispatch both input and change events to ensure autosave picks it up
      metaDescriptionField.dispatchEvent(new Event('input', { bubbles: true }))
      metaDescriptionField.dispatchEvent(new Event('change', { bubbles: true }))
    }
    
    // Update meta_keywords
    const metaKeywordsField = document.querySelector('[name*="[meta_keywords]"]')
    if (metaKeywordsField && metaData.meta_keywords) {
      metaKeywordsField.value = metaData.meta_keywords
      // Dispatch both input and change events to ensure autosave picks it up
      metaKeywordsField.dispatchEvent(new Event('input', { bubbles: true }))
      metaKeywordsField.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }
  
  showLoading(show) {
    if (this.hasLoadingIndicatorTarget) {
      if (show) {
        this.loadingIndicatorTarget.classList.remove('hidden')
      } else {
        this.loadingIndicatorTarget.classList.add('hidden')
      }
    }
  }
  
  async loadSiteSetting() {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch('/admin/settings/get/ai_gen_post_meta', {
        method: 'GET',
        headers: {
          'X-CSRF-Token': csrfToken
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        // API returns {success: true, data: {key: "...", value: ...}}
        const value = data.data && data.data.value
        const isEnabled = value === true || value === 'true' || value === '1' || value === 1
        this.checkboxTarget.checked = isEnabled
        
        // If enabled, set up listener
        if (isEnabled) {
          this.setupContentEditorListener()
        }
      }
    } catch (error) {
      console.error('[AutoSEO] Failed to load SiteSetting:', error)
    }
  }
  
  async saveSiteSetting(value) {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch('/admin/settings/quick_set', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          key: 'ai_gen_post_meta',
          value: value ? 'true' : 'false',
          setting_type: 'boolean'
        })
      })
      
      if (!response.ok) {
        throw new Error('Failed to save setting')
      }
      
      console.log('[AutoSEO] SiteSetting updated:', value)
    } catch (error) {
      console.error('[AutoSEO] Failed to save SiteSetting:', error)
      // Revert checkbox if save failed
      this.checkboxTarget.checked = !value
    }
  }
}

