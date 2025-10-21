import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosave"
export default class extends Controller {
  static targets = ["form", "title", "content"]
  static values = { 
    url: String,
    interval: { type: Number, default: 30000 }, // 30 seconds
    debounce: { type: Number, default: 2000 }   // 2 seconds
  }

  connect() {
    console.log("Autosave controller connected")
    this.hasChanges = false
    this.isSaving = false
    this.saveTimeout = null
    // Store the original URL for new posts (before slug is generated)
    this.originalUrl = this.urlValue
    this.setupEventListeners()
    this.startPeriodicSave()
  }

  disconnect() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
    if (this.periodicSaveInterval) {
      clearInterval(this.periodicSaveInterval)
    }
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
    this.showSaving()
    
    // Debounce the save
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
    
    this.saveTimeout = setTimeout(() => {
      this.save()
    }, this.debounceValue)
  }

  startPeriodicSave() {
    // Save every 30 seconds if there are changes
    this.periodicSaveInterval = setInterval(() => {
      if (this.hasChanges && !this.isSaving) {
        this.save()
      }
    }, this.intervalValue)
  }

  async save() {
    if (this.isSaving) return
    
    this.isSaving = true
    this.showSaving()

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
        
        // If this was a new post, update the URL for future saves
        if (isNewPost && data.id && data.edit_url) {
          this.urlValue = data.edit_url
          // Update the form action
          this.formTarget.action = data.edit_url
        }
        
        this.showSaved()
      } else {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.errors || 'Save failed')
      }
    } catch (error) {
      console.error('Autosave failed:', error)
      this.showError(error.message)
    } finally {
      this.isSaving = false
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
}
