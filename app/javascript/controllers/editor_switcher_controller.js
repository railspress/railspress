import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="editor-switcher"
export default class extends Controller {
  static values = { current: String }

  connect() {
    this.menuVisible = false
    this.editors = [
      { value: 'editorjs', label: 'EditorJS' },
      { value: 'trix', label: 'Trix' },
      { value: 'ckeditor5', label: 'CKEditor 5' }
    ]
  }

  disconnect() {
    this.hideMenu()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.menuVisible) {
      this.hideMenu()
    } else {
      this.showMenu()
    }
  }

  showMenu() {
    if (this.menuVisible) return

    // Create menu element
    this.menu = document.createElement('div')
    this.menu.className = 'absolute z-50 w-48 bg-white dark:bg-gray-800 rounded-md shadow-lg border border-gray-200 dark:border-gray-700'
    this.menu.style.bottom = '100%'
    this.menu.style.left = '0'
    this.menu.style.marginBottom = '4px'

    // Create menu items
    this.editors.forEach(editor => {
      const item = document.createElement('button')
      item.className = `w-full text-left px-4 py-2 text-sm transition-colors rounded-md ${
        editor.value === this.currentValue 
          ? 'bg-indigo-600 dark:bg-indigo-600 text-white font-medium' 
          : 'text-gray-900 dark:text-gray-100 hover:bg-gray-100 dark:hover:bg-gray-700'
      }`
      item.textContent = editor.label
      item.dataset.action = 'click->editor-switcher#selectEditor'
      item.dataset.editorSwitcherEditorValue = editor.value
      
      if (editor.value === this.currentValue) {
        const check = document.createElement('span')
        check.className = 'ml-2 text-white'
        check.innerHTML = '✓'
        item.appendChild(check)
      }
      
      this.menu.appendChild(item)
    })

    // Position menu
    this.element.style.position = 'relative'
    this.element.appendChild(this.menu)

    // Add click outside listener
    this.outsideClickListener = (event) => {
      if (!this.element.contains(event.target)) {
        this.hideMenu()
      }
    }
    document.addEventListener('click', this.outsideClickListener)

    // Add escape key listener
    this.escapeKeyListener = (event) => {
      if (event.key === 'Escape') {
        this.hideMenu()
      }
    }
    document.addEventListener('keydown', this.escapeKeyListener)

    this.menuVisible = true
  }

  hideMenu() {
    if (!this.menuVisible) return

    if (this.menu) {
      this.menu.remove()
      this.menu = null
    }

    if (this.outsideClickListener) {
      document.removeEventListener('click', this.outsideClickListener)
      this.outsideClickListener = null
    }

    if (this.escapeKeyListener) {
      document.removeEventListener('keydown', this.escapeKeyListener)
      this.escapeKeyListener = null
    }

    this.menuVisible = false
  }

  async selectEditor(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const editorValue = event.currentTarget.dataset.editorSwitcherEditorValue
    console.log('[editor-switcher] selectEditor called:', editorValue)
    
    if (editorValue === this.currentValue) {
      this.hideMenu()
      return
    }

    this.hideMenu()

    try {
      // Show loading indicator
      this.showLoading()
      
      // Step 1: Trigger autosave (with proper event handling)
      console.log('[editor-switcher] Starting autosave...')
      await this.triggerAutosave()
      
      // Step 2: Update user preference
      console.log('[editor-switcher] Updating preference to:', editorValue)
      await this.updatePreference(editorValue)
      
      // Step 3: Reload page
      console.log('[editor-switcher] Reloading page...')
      window.location.reload()
      
    } catch (error) {
      console.error('Failed to switch editor:', error)
      this.hideLoading()
      this.showError('Failed to switch editor. Please try again.')
    }
  }

  async triggerAutosave() {
    return new Promise((resolve, reject) => {
      const autosaveController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller*="autosave"]'),
        'autosave'
      )

      if (!autosaveController) {
        console.warn('No autosave controller found')
        resolve()
        return
      }

      // Check if there are changes to save
      if (!autosaveController.hasChanges) {
        console.log('No changes to save')
        resolve()
        return
      }

      console.log('Triggering immediate autosave...')
      
      // Trigger save immediately
      autosaveController.saveNow()
      
      // Wait for save to complete (with shorter timeout)
      const timeout = setTimeout(() => {
        console.warn('Autosave timeout - continuing anyway')
        resolve() // Continue anyway
      }, 3000) // Reduced from 5 seconds to 3 seconds

      // Listen for save completion by monitoring the autosave controller state
      const checkSaveComplete = () => {
        if (!autosaveController.isSaving && !autosaveController.hasChanges) {
          clearTimeout(timeout)
          console.log('Autosave completed successfully')
          resolve()
        } else if (!autosaveController.isSaving && autosaveController.hasChanges) {
          // Save failed but we're not saving anymore
          clearTimeout(timeout)
          console.warn('Autosave failed but continuing')
          resolve()
        }
      }
      
      // Check every 100ms
      const checkInterval = setInterval(checkSaveComplete, 100)
      
      // Cleanup function
      const cleanup = () => {
        clearTimeout(timeout)
        clearInterval(checkInterval)
      }
      
      // Cleanup on timeout
      setTimeout(cleanup, 3000)
    })
  }

  async updatePreference(editorValue) {
    const response = await fetch('/admin/profile/editor_preference', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        editor_preference: editorValue
      })
    })

    if (!response.ok) {
      throw new Error(`Failed to update preference: ${response.status}`)
    }

    return response.json()
  }

  showLoading() {
    this.loadingDiv = document.createElement('div')
    this.loadingDiv.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    this.loadingDiv.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 flex items-center space-x-3">
        <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
        <span class="text-gray-900 dark:text-white">Switching editor...</span>
      </div>
    `
    document.body.appendChild(this.loadingDiv)
  }

  hideLoading() {
    if (this.loadingDiv) {
      this.loadingDiv.remove()
      this.loadingDiv = null
    }
  }

  showError(message) {
    // Simple error display - could be enhanced with toast notifications
    const errorDiv = document.createElement('div')
    errorDiv.className = 'fixed top-4 right-4 bg-red-500 text-white px-4 py-2 rounded shadow-lg z-50'
    errorDiv.textContent = message
    document.body.appendChild(errorDiv)
    
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }
}
