import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosave"
export default class extends Controller {
  static targets = ["form", "title", "content", "saveButton", "saveSpinner", "saveText"]
  static values = { 
    url: String,
    interval: { type: Number, default: 30000 }, // 30 seconds default, overridden by site setting
    debounce: { type: Number, default: 2000 }   // 2 seconds
  }

  connect() {
    console.log("Autosave controller connected")
    this.hasChanges = false
    this.isSaving = false
    this.saveTimeout = null
    this.isOfflineMode = false
    this.offlineSyncInterval = null
    // Store the original URL for new posts (before slug is generated)
    this.originalUrl = this.urlValue
    this.setupEventListeners()
    this.startPeriodicSave()
    
    // Monitor online/offline events
    window.addEventListener('online', () => this.handleOnline())
    window.addEventListener('offline', () => this.handleOffline())
    
    // Restore from localStorage for NEW posts only
    this.restoreFromLocalStorage()
  }

  disconnect() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    if (this.periodicSaveInterval) {
      clearInterval(this.periodicSaveInterval)
    }
    if (this.offlineSyncInterval) {
      clearInterval(this.offlineSyncInterval)
    }
    if (this.retryInterval) {
      clearInterval(this.retryInterval)
    }
    window.removeEventListener('online', () => this.handleOnline())
    window.removeEventListener('offline', () => this.handleOffline())
  }

  setupEventListeners() {
    // Listen for changes in title and content
    if (this.hasTitleTarget) {
      this.titleTarget.addEventListener('input', () => this.handleChange())
    }
    
    if (this.hasContentTarget) {
      this.contentTarget.addEventListener('input', () => this.handleChange())
    }

    // Listen for form changes (for other fields)
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('input', () => this.handleChange())
    }

    // Listen for custom editor events
    document.addEventListener('editor:content-changed', () => this.handleChange())

    // Listen for keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault()
        this.saveNow()
      }
    })

    // Warn user before leaving if there are unsaved changes
    window.addEventListener('beforeunload', (e) => {
      if (this.hasChanges && !this.isSaving) {
        e.preventDefault()
        e.returnValue = 'You have unsaved changes. Are you sure you want to leave?'
        return e.returnValue
      }
    })
  }

  handleChange() {
    this.hasChanges = true
    
    // Clear existing debounce timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    
    // Start new debounce timer - save after 5 seconds of inactivity
    this.debounceTimer = setTimeout(() => {
      if (this.hasChanges && !this.isSaving) {
        this.save()
      }
    }, 5000) // 5 seconds
  }

  startPeriodicSave() {
    // Periodic save as backup - runs every X seconds based on site setting
    // This ensures saves happen even if user is continuously typing
    this.periodicSaveInterval = setInterval(() => {
      if (this.hasChanges && !this.isSaving) {
        this.save()
      }
    }, this.intervalValue)
    
    console.log(`Periodic save enabled: every ${this.intervalValue / 1000}s`)
  }

  async save() {
    if (this.isSaving) return
    
    // Clear debounce timer if it exists
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
    
    this.isSaving = true
    this.showSaving()
    this.showSaveButtonLoading() // Show spinner on save button
    
    const startTime = Date.now() // Track when save started
    const minDuration = 200 // Minimum 200ms to show spinner
    
    try {
      const formData = new FormData(this.formTarget)
      
      // Add autosave parameter
      formData.append('autosave', 'true')
      
      // Determine if this is a new post or existing post
      // Check if URL ends with a number (existing post) or is the base posts path
      const isNewPost = this.urlValue.includes('posts') && !this.urlValue.match(/\/\d+$/)
      const method = isNewPost ? 'POST' : 'PATCH'
      
      // For new posts, use the original URL (base posts path) instead of the form action
      // which might have been updated with a slug
      const saveUrl = isNewPost ? this.originalUrl : this.urlValue
      
      const response = await fetch(saveUrl, {
        method: method,
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.hasChanges = false
        
        // SUCCESS - clear localStorage and exit offline mode
        this.clearLocalStorage()
        this.setOfflineMode(false)
        
        // If this was a new post, update the URL for future saves
        if (isNewPost && data.id && data.edit_url) {
          this.urlValue = data.edit_url
          // Update the form action
          this.formTarget.action = data.edit_url
        }
        
        this.showSaved()
      } else {
        const errorData = await response.json().catch(() => ({}))
        
        // Handle specific error types
        if (errorData.errors) {
          if (errorData.errors.slug && errorData.errors.slug.includes('has already been taken')) {
            console.warn('Slug conflict detected, clearing slug and retrying...')
            // Clear the slug field and try again
            const slugField = document.querySelector('[name*="slug"]')
            if (slugField) {
              slugField.value = ''
            }
            // Don't enter offline mode for slug conflicts, just retry
            this.save()
            return
          }
        }
        
        throw new Error(errorData.errors || 'Save failed')
      }
    } catch (error) {
      console.error('Autosave failed:', error)
      
      // FAILURE - enter offline mode and save to localStorage
      this.setOfflineMode(true)
      this.saveToLocalStorage()
      
      this.showError(error.message)
    } finally {
      this.isSaving = false
      
      // Ensure minimum duration for spinner visibility
      const elapsed = Date.now() - startTime
      const remaining = Math.max(0, minDuration - elapsed)
      
      setTimeout(() => {
        this.hideSaveButtonLoading() // Hide spinner on save button
      }, remaining)
    }
  }

  showSaveButtonLoading() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = true
      this.saveButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
    if (this.hasSaveSpinnerTarget) {
      this.saveSpinnerTarget.classList.remove('hidden')
    }
    if (this.hasSaveTextTarget) {
      this.saveTextTarget.textContent = 'Saving...'
    }
  }

  hideSaveButtonLoading() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = false
      this.saveButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
    if (this.hasSaveSpinnerTarget) {
      this.saveSpinnerTarget.classList.add('hidden')
    }
    if (this.hasSaveTextTarget) {
      this.saveTextTarget.textContent = 'Save'
    }
  }

  showSaving() {
    const indicator = document.querySelector('.autosave-indicator')
    if (!indicator) return

    const spinner = indicator.querySelector('.animate-spin')
    const checkmark = indicator.querySelector('.text-green-500')
    const text = indicator.querySelector('.autosave-text')

    if (spinner) spinner.classList.remove('hidden')
    if (checkmark) checkmark.classList.add('hidden')
    if (text) text.textContent = 'Saving...'
  }

  showSaved() {
    const indicator = document.querySelector('.autosave-indicator')
    if (!indicator) return

    const spinner = indicator.querySelector('.animate-spin')
    const checkmark = indicator.querySelector('.text-green-500')
    const text = indicator.querySelector('.autosave-text')

    if (spinner) spinner.classList.add('hidden')
    if (checkmark) checkmark.classList.remove('hidden')
    if (text) text.textContent = 'All changes saved'

    // Hide the indicator after 3 seconds
    setTimeout(() => {
      if (checkmark) checkmark.classList.add('hidden')
      if (text) text.textContent = ''
    }, 3000)
  }

  showError(errorMessage = 'Save failed') {
    const indicator = document.querySelector('.autosave-indicator')
    if (!indicator) return

    const spinner = indicator.querySelector('.animate-spin')
    const checkmark = indicator.querySelector('.text-green-500')
    const text = indicator.querySelector('.autosave-text')

    if (spinner) spinner.classList.add('hidden')
    if (checkmark) checkmark.classList.add('hidden')
    if (text) {
      text.textContent = errorMessage
      text.classList.add('text-red-500')
    }

    // Reset after 5 seconds
    setTimeout(() => {
      if (text) {
        text.textContent = ''
        text.classList.remove('text-red-500')
      }
    }, 5000)
  }

  // Manual save trigger
  saveNow() {
    this.save()
  }

  // Offline mode methods
  setOfflineMode(isOffline) {
    this.isOfflineMode = isOffline
    
    const indicator = document.querySelector('.autosave-indicator')
    if (!indicator) return
    
    if (isOffline) {
      indicator.innerHTML = '<span class="text-orange-500">⚠ Offline Mode</span>'
      
      // Start syncing changes to localStorage
      this.startOfflineSync()
    } else {
      // Stop syncing to localStorage
      // Note: autosave will handle showing "All changes saved"
      this.stopOfflineSync()
    }
  }

  startOfflineSync() {
    // Save to localStorage on every change while offline
    if (this.offlineSyncInterval) return
    
    this.offlineSyncInterval = setInterval(() => {
      this.saveToLocalStorage()
    }, 2000) // Save every 2 seconds while offline
    
    // Retry autosave at half the interval (e.g., every 30s if interval is 60s)
    const retryInterval = this.intervalValue / 2
    this.retryInterval = setInterval(() => {
      console.log(`Retrying autosave while offline... (every ${retryInterval / 1000}s)`)
      this.save()
    }, retryInterval)
  }

  stopOfflineSync() {
    if (this.offlineSyncInterval) {
      clearInterval(this.offlineSyncInterval)
      this.offlineSyncInterval = null
    }
    if (this.retryInterval) {
      clearInterval(this.retryInterval)
      this.retryInterval = null
    }
  }

  // localStorage methods
  saveToLocalStorage() {
    const postId = this.getPostId()
    
    const postData = {
      title: this.titleTarget?.value || '',
      content: this.getEditorContent(),
      slug: document.querySelector('[name*="slug"]')?.value || '',
      status: document.querySelector('[name*="status"]')?.value || '',
      timestamp: Date.now()
    }
    
    localStorage.setItem(`post_backup_${postId}`, JSON.stringify(postData))
    console.log('Saved to localStorage:', postId)
  }

  clearLocalStorage() {
    const postId = this.getPostId()
    localStorage.removeItem(`post_backup_${postId}`)
    console.log('Cleared localStorage:', postId)
  }

  getPostId() {
    // Get post UUID from global RailsPress context
    return window.RailsPress?.getPostUuid() || 'new'
  }

  restoreFromLocalStorage() {
    const postId = this.getPostId()
    
    // ONLY restore for NEW posts
    if (postId !== 'new') {
      console.log('Editing existing post - ignoring localStorage')
      return
    }
    
    const backup = localStorage.getItem(`post_backup_${postId}`)
    if (!backup) return
    
    try {
      const postData = JSON.parse(backup)
      console.log('Found offline backup, restoring...', postData)
      
      // Wait for editors to be ready before restoring content
      setTimeout(() => {
        // Restore title
        if (this.titleTarget && postData.title) {
          this.titleTarget.value = postData.title
          console.log('Restored title:', postData.title)
        }
        
        // Restore content
        if (postData.content) {
          console.log('Restoring content from localStorage')
          this.setEditorContent(postData.content)
        }
        
        // Restore slug
        const slugField = document.querySelector('[name*="slug"]')
        if (slugField && postData.slug) {
          slugField.value = postData.slug
          console.log('Restored slug:', postData.slug)
        }
        
        // Don't start in offline mode - just restore the content
        // Offline mode should only be triggered by actual autosave failures
        console.log('Content restored from localStorage, ready for normal operation')
      }, 2000) // Wait 2 seconds for editors to initialize
      
    } catch (error) {
      console.error('Failed to restore backup:', error)
    }
  }

  getEditorContent() {
    // SIMPLE: Just get the HTML from the hidden input field
    // ALL editors save HTML to the hidden input, so just use that
    const hiddenInput = document.querySelector('input[type="hidden"][name*="content"]')
    if (hiddenInput) {
      return hiddenInput.value || ''
    }
    
    // Fallback to contentTarget
    return this.contentTarget?.value || ''
  }

  setEditorContent(content) {
    // SIMPLE: Just set the HTML to the hidden input field
    // ALL editors will pick it up from there on initialization
    const hiddenInput = document.querySelector('input[type="hidden"][name*="content"]')
    if (hiddenInput) {
      hiddenInput.value = content
      console.log('Restored content to hidden input')
    } else if (this.contentTarget) {
      this.contentTarget.value = content
      console.log('Restored content to textarea')
    }
  }

  // Connection event handlers
  handleOffline() {
    console.log('Connection lost')
    this.setOfflineMode(true)
  }

  handleOnline() {
    console.log('Connection restored - triggering autosave')
    // Trigger autosave to sync with server
    this.save()
    // save() will automatically exit offline mode on success
  }
}
