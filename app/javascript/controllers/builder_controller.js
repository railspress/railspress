import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "versionSelector", "templateSelector", "sectionsList", "previewFrame", 
    "deviceSelector", "data", "versionList", "snapshotList",
    "sectionTab", "themeTab", "sectionSettingsPanel", "themeSettingsPanel"
  ]

  connect() {
    console.log("Builder controller connected")
    this.themeId = this.dataTarget.dataset.themeId
    this.sections = JSON.parse(this.dataTarget.dataset.sections || '{}')
    this.settings = JSON.parse(this.dataTarget.dataset.settings || '{}')
    this.templates = JSON.parse(this.dataTarget.dataset.templates || '[]')
    this.themeSchema = JSON.parse(this.dataTarget.dataset.themeSchema || '[]')
    this.currentTemplate = 'index'
    this.currentDevice = 'desktop'
    
    this.initializeSections()
    this.initializeSettings()
    this.connectActionCable()
    this.setupTemplateSelector()
    this.setupDevicePreview()
    this.initializeThemeSettings()
    
    // Initialize device preview on load
    this.updatePreviewFrameDevice()
  }

  disconnect() {
    if (this.cableSubscription) {
      this.cableSubscription.unsubscribe()
    }
  }

  // Section Management
  initializeSections() {
    // Sections are now rendered server-side, just initialize SortableJS
    this.initializeSortable()
  }

  initializeSortable() {
    const sectionsList = this.sectionsListTarget
    if (window.Sortable && sectionsList) {
      new Sortable(sectionsList, {
        animation: 150,
        ghostClass: 'opacity-50',
        onEnd: (evt) => {
          this.reorderSections(evt.oldIndex, evt.newIndex)
        }
      })
    }
  }

  createSectionElement(sectionId, sectionData) {
    const div = document.createElement('div')
    div.className = 'bg-white border border-gray-200 rounded-lg p-4 mb-3 cursor-move hover:border-blue-300 transition-colors'
    div.dataset.sectionId = sectionId
    div.innerHTML = `
      <div class="flex items-center justify-between">
        <div class="flex-1">
          <div class="flex items-center space-x-2">
            <div class="w-2 h-2 bg-gray-400 rounded-full"></div>
            <h4 class="font-medium text-gray-900">${this.getSectionDisplayName(sectionData.type || sectionId)}</h4>
          </div>
          <p class="text-sm text-gray-600 mt-1">${this.getSectionDescription(sectionData)}</p>
        </div>
        <div class="flex items-center space-x-1">
          <button class="text-gray-400 hover:text-gray-600 p-1" onclick="builder.editSection('${sectionId}')" title="Edit section">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
            </svg>
          </button>
          <button class="text-red-400 hover:text-red-600 p-1" onclick="builder.removeSection('${sectionId}')" title="Remove section">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
            </svg>
          </button>
        </div>
      </div>
    `
    return div
  }

  getSectionDisplayName(sectionType) {
    const displayNames = {
      'hero': 'Hero',
      'post-list': 'Blog List',
      'rich-text': 'Rich Text',
      'image': 'Image',
      'gallery': 'Image Gallery',
      'contact': 'Contact Form',
      'header': 'Header',
      'footer': 'Footer',
      'menu': 'Menu',
      'search-form': 'Search Form',
      'comments': 'Comments',
      'pagination': 'Pagination',
      'taxonomy-list': 'Category/Tag List',
      'seo-head': 'SEO Head',
      'post-content': 'Post Content',
      'related-posts': 'Related Posts'
    }
    return displayNames[sectionType] || sectionType.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())
  }

  getSectionDescription(sectionData) {
    if (sectionData.settings?.heading) {
      return sectionData.settings.heading
    }
    if (sectionData.settings?.title) {
      return sectionData.settings.title
    }
    if (sectionData.settings?.content) {
      return sectionData.settings.content.substring(0, 50) + '...'
    }
    return 'Click to edit settings'
  }

  reorderSections(oldIndex, newIndex) {
    // Get section IDs from the DOM
    const sectionElements = this.sectionsListTarget.querySelectorAll('[data-section-id]')
    const sectionIds = Array.from(sectionElements).map(el => el.dataset.sectionId)
    
    // Reorder the array
    const [movedSection] = sectionIds.splice(oldIndex, 1)
    sectionIds.splice(newIndex, 0, movedSection)

    // Send reorder request to server
    fetch(`/admin/builder/${this.themeId}/reorder_sections`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        section_ids: sectionIds,
        template: this.currentTemplate
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showNotification('Sections reordered successfully!', 'success')
        // Reload the page to show updated order
        window.location.reload()
      } else {
        this.showNotification('Error reordering sections: ' + (data.errors || 'Unknown error'), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error reordering sections', 'error')
    })
  }

  addSection() {
    // Show add section modal
    this.showAddSectionModal()
  }

  showAddSectionModal() {
    const modal = document.getElementById('addSectionModal')
    const container = document.getElementById('availableSections')
    container.innerHTML = '<div class="text-center py-4"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div><p class="text-sm text-gray-600 mt-2">Loading sections...</p></div>'
    
    modal.classList.remove('hidden')

    // Add click outside to close
    const clickOutsideHandler = (e) => {
      if (!modal.contains(e.target)) {
        this.closeAddSectionModal()
        document.removeEventListener('click', clickOutsideHandler)
      }
    }
    
    // Add the click outside listener after a short delay to prevent immediate closing
    setTimeout(() => {
      document.addEventListener('click', clickOutsideHandler)
    }, 100)

    // Fetch available sections from the current theme
    fetch(`/admin/builder/${this.themeId}/available_sections`)
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.renderAvailableSections(data.sections)
        } else {
          container.innerHTML = '<div class="text-center py-4 text-red-600">Error loading sections: ' + (data.errors || 'Unknown error') + '</div>'
        }
      })
      .catch(error => {
        console.error('Error loading sections:', error)
        container.innerHTML = '<div class="text-center py-4 text-red-600">Error loading sections</div>'
      })
  }

  renderAvailableSections(sections) {
    const container = document.getElementById('availableSections')
    container.innerHTML = ''

    if (!sections || sections.length === 0) {
      container.innerHTML = '<div class="text-center py-4 text-gray-500">No sections available</div>'
      return
    }

    // Group sections by category if they have one, otherwise use "General"
    const sectionCategories = {}
    
    sections.forEach(section => {
      const category = section.category || 'General'
      if (!sectionCategories[category]) {
        sectionCategories[category] = []
      }
      sectionCategories[category].push(section)
    })

    Object.entries(sectionCategories).forEach(([category, categorySections]) => {
      // Add category header
      const categoryDiv = document.createElement('div')
      categoryDiv.className = 'mb-4'
      categoryDiv.innerHTML = `
        <h3 class="text-sm font-semibold text-gray-700 mb-2">${category}</h3>
        <div class="space-y-2">
      `
      
      categorySections.forEach(section => {
        const div = document.createElement('div')
        div.className = 'section-item bg-white border border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-500 hover:bg-blue-50 transition-colors'
        div.dataset.sectionId = section.id
        div.innerHTML = `
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <h4 class="font-medium text-gray-900 text-sm">${section.name}</h4>
              <p class="text-xs text-gray-600 mt-1">${section.description || 'No description available'}</p>
            </div>
            <div class="ml-3">
              <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </div>
          </div>
        `
        div.onclick = () => this.selectSectionForPreview(section)
        categoryDiv.querySelector('.space-y-2').appendChild(div)
      })
      
      categoryDiv.innerHTML += '</div>'
      container.appendChild(categoryDiv)
    })
  }

  selectSectionForPreview(section) {
    // Remove previous selection
    document.querySelectorAll('.section-item').forEach(item => {
      item.classList.remove('border-blue-500', 'bg-blue-50')
    })
    
    // Add selection to current section
    const sectionElement = document.querySelector(`[data-section-id="${section.id}"]`)
    if (sectionElement) {
      sectionElement.classList.add('border-blue-500', 'bg-blue-50')
    }
    
    // Store selected section
    this.selectedSection = section
    
    // Update UI
    document.getElementById('selectedSectionName').textContent = section.name
    document.getElementById('addSelectedSectionBtn').disabled = false
    
    // Show preview
    this.showSectionPreview(section)
  }

  showSectionPreview(section) {
    const previewContainer = document.getElementById('sectionPreview')
    
    // Create a simple preview based on section type
    let previewHTML = ''
    
    switch(section.id) {
      case 'hero':
        previewHTML = `
          <div class="p-8 text-center bg-gradient-to-r from-blue-500 to-purple-600 text-white">
            <h1 class="text-3xl font-bold mb-4">Welcome to Our Site</h1>
            <p class="text-lg mb-6">This is a hero section with compelling content</p>
            <button class="bg-white text-blue-600 px-6 py-2 rounded-lg font-medium">Get Started</button>
          </div>
        `
        break
      case 'rich-text':
        previewHTML = `
          <div class="p-6">
            <h2 class="text-2xl font-bold mb-4">Rich Text Section</h2>
            <p class="text-gray-700 mb-4">This is a rich text section where you can add formatted content, paragraphs, and more.</p>
            <p class="text-gray-700">You can include <strong>bold text</strong>, <em>italic text</em>, and other formatting options.</p>
          </div>
        `
        break
      case 'posts':
        previewHTML = `
          <div class="p-6">
            <h2 class="text-2xl font-bold mb-4">Blog Posts</h2>
            <div class="space-y-4">
              <div class="border-b border-gray-200 pb-4">
                <h3 class="font-semibold text-lg">Sample Blog Post Title</h3>
                <p class="text-gray-600 text-sm">Published on January 15, 2024</p>
                <p class="text-gray-700 mt-2">This is a preview of how blog posts will appear in this section...</p>
              </div>
              <div class="border-b border-gray-200 pb-4">
                <h3 class="font-semibold text-lg">Another Blog Post</h3>
                <p class="text-gray-600 text-sm">Published on January 10, 2024</p>
                <p class="text-gray-700 mt-2">Another example of blog post content...</p>
              </div>
            </div>
          </div>
        `
        break
      case 'header':
        previewHTML = `
          <div class="bg-white border-b border-gray-200 p-4">
            <div class="flex items-center justify-between">
              <div class="text-xl font-bold">Your Logo</div>
              <nav class="flex space-x-6">
                <a href="#" class="text-gray-700 hover:text-blue-600">Home</a>
                <a href="#" class="text-gray-700 hover:text-blue-600">About</a>
                <a href="#" class="text-gray-700 hover:text-blue-600">Contact</a>
              </nav>
            </div>
          </div>
        `
        break
      case 'footer':
        previewHTML = `
          <div class="bg-gray-800 text-white p-6">
            <div class="text-center">
              <div class="text-xl font-bold mb-2">Your Logo</div>
              <p class="text-gray-400 mb-4">Your company description goes here</p>
              <p class="text-gray-500 text-sm">© 2024 Your Company. All rights reserved.</p>
            </div>
          </div>
        `
        break
      default:
        previewHTML = `
          <div class="p-6 text-center">
            <div class="w-16 h-16 bg-gray-200 rounded-lg mx-auto mb-4 flex items-center justify-center">
              <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
              </svg>
            </div>
            <h3 class="font-semibold text-gray-900">${section.name}</h3>
            <p class="text-gray-600 text-sm mt-1">${section.description || 'Section preview'}</p>
          </div>
        `
    }
    
    previewContainer.innerHTML = previewHTML
  }

  createSection(sectionType) {
    const defaultSettings = this.getDefaultSectionSettings(sectionType)
    
    fetch(`/admin/builder/${this.themeId}/add_section`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        section_type: sectionType,
        settings: defaultSettings,
        template: this.currentTemplate
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showNotification('Section added successfully!', 'success')
        this.closeAddSectionModal()
        // Reload the page to show the new section
        window.location.reload()
      } else {
        this.showNotification('Error adding section: ' + (data.errors || 'Unknown error'), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error adding section', 'error')
    })
  }

  getDefaultSectionSettings(sectionType) {
    const defaults = {
      hero: { heading: 'Welcome to our site', subheading: 'This is a hero section', align: 'left' },
      blog: { layout: 'grid', items_per_page: 6 },
      'rich-text': { content: 'Add your content here...' },
      image: { image_url: '', alt_text: '', caption: '' },
      gallery: { images: [], columns: 3 },
      contact: { title: 'Contact Us', email: '', phone: '' }
    }
    return defaults[sectionType] || {}
  }

  editSection(sectionId) {
    // Create a mock event object
    const mockEvent = {
      currentTarget: {
        dataset: {
          sectionId: sectionId
        }
      }
    }
    this.selectSection(mockEvent)
  }

  selectSection(event) {
    const sectionId = event.currentTarget.dataset.sectionId
    
    // Remove previous selection
    this.sectionsListTarget.querySelectorAll('.border-blue-500').forEach(el => {
      el.classList.remove('border-blue-500', 'bg-blue-50')
    })

    // Add selection to current section
    const sectionElement = this.sectionsListTarget.querySelector(`[data-section-id="${sectionId}"]`)
    if (sectionElement) {
      sectionElement.classList.add('border-blue-500', 'bg-blue-50')
    }

    // Show section settings in the right sidebar
    this.showSectionSettings()
    this.renderSectionSettings(sectionId)
  }

  removeSection(sectionId) {
    if (confirm('Are you sure you want to remove this section?')) {
      fetch(`/admin/builder/${this.themeId}/remove_section/${sectionId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ 
          template: this.currentTemplate
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.showNotification('Section removed successfully!', 'success')
          this.clearSettings()
          // Reload the page to show updated sections
          window.location.reload()
        } else {
          this.showNotification('Error removing section: ' + (data.errors || 'Unknown error'), 'error')
        }
      })
      .catch(error => {
        console.error('Error:', error)
        this.showNotification('Error removing section', 'error')
      })
    }
  }

  // Settings Management
  initializeSettings() {
    this.jsonEditor = null
  }

  renderSectionSettings(sectionId) {
    // Get section data from the DOM element
    const sectionElement = this.sectionsListTarget.querySelector(`[data-section-id="${sectionId}"]`)
    if (!sectionElement) return

    const sectionType = sectionElement.dataset.sectionType
    const sectionSettings = JSON.parse(sectionElement.dataset.settings || '{}')

    console.log('Rendering settings for section:', sectionId, 'Type:', sectionType, 'Settings:', sectionSettings)

    const settingsPanel = this.sectionSettingsPanelTarget
    settingsPanel.innerHTML = `
      <div class="mb-4">
        <h3 class="text-lg font-medium text-gray-900 mb-4">${this.getSectionDisplayName(sectionType)} Settings</h3>
        <form id="section-settings-form" class="space-y-4">
          ${this.renderSectionForm(sectionType, sectionSettings)}
        </form>
      </div>
    `

    // Add event listeners for form changes
    this.attachFormListeners(sectionId)
  }

  renderSectionForm(sectionType, settings) {
    const forms = {
      header: `
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Logo Text</label>
            <input type="text" name="logo_text" value="${settings.logo_text || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_search" ${settings.show_search ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Search</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_cart" ${settings.show_cart ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Cart</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_account" ${settings.show_account ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Account</span>
            </label>
          </div>
        </div>
      `,
      hero: `
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Heading</label>
            <input type="text" name="heading" value="${settings.heading || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Subheading</label>
            <input type="text" name="subheading" value="${settings.subheading || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea name="description" rows="3" 
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">${settings.description || ''}</textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Text Alignment</label>
            <select name="text_alignment" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="left" ${settings.text_alignment === 'left' ? 'selected' : ''}>Left</option>
              <option value="center" ${settings.text_alignment === 'center' ? 'selected' : ''}>Center</option>
              <option value="right" ${settings.text_alignment === 'right' ? 'selected' : ''}>Right</option>
            </select>
          </div>
        </div>
      `,
      footer: `
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Logo Text</label>
            <input type="text" name="logo_text" value="${settings.logo_text || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea name="description" rows="3" 
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">${settings.description || ''}</textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Copyright Text</label>
            <input type="text" name="copyright_text" value="${settings.copyright_text || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
        </div>
      `,
      post_header: `
        <div class="space-y-4">
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_breadcrumbs" ${settings.show_breadcrumbs ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Breadcrumbs</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_featured_image" ${settings.show_featured_image ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Featured Image</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_author" ${settings.show_author ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Author</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_date" ${settings.show_date ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Date</span>
            </label>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Background Color</label>
            <input type="color" name="background_color" value="${settings.background_color || '#f8fafc'}" 
                   class="w-full h-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Text Alignment</label>
            <select name="text_alignment" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="left" ${settings.text_alignment === 'left' ? 'selected' : ''}>Left</option>
              <option value="center" ${settings.text_alignment === 'center' ? 'selected' : ''}>Center</option>
              <option value="right" ${settings.text_alignment === 'right' ? 'selected' : ''}>Right</option>
            </select>
          </div>
        </div>
      `,
      post_content: `
        <div class="space-y-4">
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_sidebar" ${settings.show_sidebar ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Sidebar</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_author_bio" ${settings.show_author_bio ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Author Bio</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_related_posts" ${settings.show_related_posts ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Related Posts</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_comments" ${settings.show_comments ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Comments</span>
            </label>
          </div>
        </div>
      `,
      related_posts: `
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Heading</label>
            <input type="text" name="heading" value="${settings.heading || ''}" 
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Posts Count</label>
            <input type="number" name="posts_count" value="${settings.posts_count || 3}" min="1" max="20"
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Layout</label>
            <select name="layout" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="grid" ${settings.layout === 'grid' ? 'selected' : ''}>Grid</option>
              <option value="list" ${settings.layout === 'list' ? 'selected' : ''}>List</option>
            </select>
          </div>
        </div>
      `,
      comments: `
        <div class="space-y-4">
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_comments" ${settings.show_comments ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Comments</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_comment_form" ${settings.show_comment_form ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Comment Form</span>
            </label>
          </div>
          <div class="flex items-center space-x-4">
            <label class="flex items-center">
              <input type="checkbox" name="show_gravatar" ${settings.show_gravatar ? 'checked' : ''} 
                     class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              <span class="ml-2 text-sm text-gray-700">Show Gravatar</span>
            </label>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Max Depth</label>
            <input type="number" name="max_depth" value="${settings.max_depth || 3}" min="1" max="10"
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
          </div>
        </div>
      `
    }
    
    return forms[sectionType] || `
      <div class="text-center text-gray-500 py-4">
        <p>No settings available for this section type.</p>
      </div>
    `
  }

  attachFormListeners(sectionId) {
    const form = document.getElementById('section-settings-form')
    if (!form) return

    // Add change listeners to all form elements
    const inputs = form.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      input.addEventListener('change', () => {
        this.updateSectionSettingsFromForm(sectionId)
      })
      input.addEventListener('input', () => {
        // Debounce rapid changes
        clearTimeout(this.updateTimeout)
        this.updateTimeout = setTimeout(() => {
          this.updateSectionSettingsFromForm(sectionId)
        }, 500)
      })
    })
  }

  updateSectionSettingsFromForm(sectionId) {
    const form = document.getElementById('section-settings-form')
    if (!form) {
      console.error('Form element not found:', 'section-settings-form')
      return
    }

    // Check if it's a proper form element
    if (!(form instanceof HTMLFormElement)) {
      console.error('Element is not a form:', form)
      return
    }

    const formData = new FormData(form)
    const settings = {}

    // Collect all form values
    for (let [key, value] of formData.entries()) {
      if (key.endsWith('[]')) {
        // Handle arrays
        const arrayKey = key.slice(0, -2)
        if (!settings[arrayKey]) settings[arrayKey] = []
        settings[arrayKey].push(value)
      } else {
        settings[key] = value
      }
    }

    // Handle checkboxes (they don't appear in FormData if unchecked)
    const checkboxes = form.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      settings[checkbox.name] = checkbox.checked
    })

    // Update the section settings
    this.updateSectionSettings(sectionId, settings)
  }

  updateSectionSettings(sectionId, settings) {
    console.log('Updating section settings:', { sectionId, settings, template: this.currentTemplate })
    
    fetch(`/admin/builder/${this.themeId}/update_section/${sectionId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        settings: settings,
        template: this.currentTemplate
      })
    })
    .then(response => {
      console.log('Response status:', response.status)
      return response.json()
    })
    .then(data => {
      console.log('Response data:', data)
      if (data.errors) {
        console.error('Server errors:', data.errors)
      }
      if (data.backtrace) {
        console.error('Server backtrace:', data.backtrace)
      }
      if (data.success) {
        // Update the DOM element with new settings
        const sectionElement = this.sectionsListTarget.querySelector(`[data-section-id="${sectionId}"]`)
        if (sectionElement) {
          sectionElement.dataset.settings = JSON.stringify(settings)
        }
        
        // Update the internal sections data structure
        if (this.sections[sectionId]) {
          this.sections[sectionId].settings = settings
        }
        
        // Show success notification
        this.showNotification('Section settings saved successfully!', 'success')
        
        // Update preview
        this.updatePreviewContent()
      } else {
        this.showNotification('Error updating section: ' + (data.errors || 'Unknown error'), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error updating section', 'error')
    })
  }

  clearSettings() {
    this.sectionSettingsPanelTarget.innerHTML = `
      <div class="text-center text-gray-500 py-8">
        <p>Select a section to edit its settings</p>
      </div>
    `
  }

  // Theme Settings
  initializeThemeSettings() {
    this.renderThemeSettings()
  }

  renderThemeSettings() {
    const settingsPanel = this.themeSettingsPanelTarget
    settingsPanel.innerHTML = `
      <div class="mb-4">
        <h3 class="text-lg font-medium text-gray-900 mb-2">Theme Settings</h3>
        <div id="theme-json-editor-container"></div>
      </div>
    `

    // Initialize JSONEditor for theme settings
    if (window.JSONEditor) {
      const container = document.getElementById('theme-json-editor-container')
      this.themeJsonEditor = new JSONEditor(container, {
        schema: this.getThemeSchema(),
        startval: this.settings,
        theme: 'bootstrap4',
        iconlib: 'fontawesome5',
        show_errors: 'always'
      })

      this.themeJsonEditor.on('change', () => {
        const settings = this.themeJsonEditor.getValue()
        this.settings = settings
        // Auto-save and update preview
        this.saveDraft()
      })
    }
  }

  getThemeSchema() {
    // Convert theme schema from Shopify format to JSONEditor format
    if (!this.themeSchema || this.themeSchema.length === 0) {
      return { type: 'object', properties: {} }
    }

    const properties = {}
    
    this.themeSchema.forEach(group => {
      if (group.settings) {
        group.settings.forEach(setting => {
          properties[setting.id] = this.convertSettingToJsonEditor(setting)
        })
      }
    })

    return {
      type: 'object',
      properties: properties
    }
  }

  convertSettingToJsonEditor(setting) {
    const jsonEditorSetting = {
      title: setting.label || setting.id,
      default: setting.default
    }

    switch (setting.type) {
      case 'color':
        jsonEditorSetting.type = 'string'
        jsonEditorSetting.format = 'color'
        break
      case 'range':
        jsonEditorSetting.type = 'number'
        jsonEditorSetting.minimum = setting.min
        jsonEditorSetting.maximum = setting.max
        jsonEditorSetting.step = setting.step
        break
      case 'text':
        jsonEditorSetting.type = 'string'
        break
      case 'textarea':
        jsonEditorSetting.type = 'string'
        jsonEditorSetting.format = 'textarea'
        break
      case 'select':
        jsonEditorSetting.type = 'string'
        jsonEditorSetting.enum = setting.options
        break
      case 'checkbox':
        jsonEditorSetting.type = 'boolean'
        break
      default:
        jsonEditorSetting.type = 'string'
    }

    return jsonEditorSetting
  }

  // Version Management
  createVersion() {
    const label = prompt('Enter version label:', `Version ${new Date().toLocaleString()}`)
    if (!label) return

    fetch(`/admin/builder/${this.themeId}/create_version`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ label })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.href = data.redirect_url
      } else {
        alert('Error creating version: ' + (data.errors || 'Unknown error'))
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error creating version')
    })
  }

  // Save and Publish
  saveDraft() {
    // Collect current sections data from DOM
    const currentSections = {}
    const sectionElements = this.sectionsListTarget.querySelectorAll('[data-section-id]')
    
    sectionElements.forEach(element => {
      const sectionId = element.dataset.sectionId
      const sectionType = element.dataset.sectionType
      const settings = JSON.parse(element.dataset.settings || '{}')
      
      currentSections[sectionId] = {
        type: sectionType,
        settings: settings
      }
    })
    
    const data = {
      sections_data: JSON.stringify(currentSections),
      settings_data: JSON.stringify(this.settings),
      template: this.currentTemplate
    }

    console.log('Saving draft with data:', data)

    fetch(`/admin/builder/${this.themeId}/save_draft`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showNotification('Draft saved successfully!', 'success')
        // Update preview after saving
        this.updatePreviewContent()
      } else {
        this.showNotification('Error saving draft: ' + (data.errors || 'Unknown error'), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error saving draft', 'error')
    })
  }

  publish() {
    if (!confirm('Are you sure you want to publish this theme? This will make it live on your site.')) {
      return
    }

    fetch(`/admin/builder/${this.themeId}/publish`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showNotification('Theme published successfully!', 'success')
      } else {
        this.showNotification('Error publishing theme: ' + (data.errors || 'Unknown error'), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error publishing theme', 'error')
    })
  }

  rollback() {
    this.showRollbackModal()
  }

  showRollbackModal() {
    const modal = document.getElementById('rollbackModal')
    const container = this.snapshotListTarget
    container.innerHTML = ''

    fetch(`/admin/builder/${this.themeId}/snapshots`)
    .then(response => response.json())
    .then(data => {
      data.snapshots.forEach(snapshot => {
        const div = document.createElement('div')
        div.className = 'bg-white border border-gray-200 rounded-lg p-4 cursor-pointer hover:border-orange-500'
        div.innerHTML = `
          <div class="flex items-center justify-between">
            <div>
              <h4 class="font-medium text-gray-900">${new Date(snapshot.created_at).toLocaleString()}</h4>
              <p class="text-sm text-gray-600">by ${snapshot.created_by}</p>
            </div>
            <input type="radio" name="snapshot" value="${snapshot.id}" class="text-orange-600">
          </div>
        `
        container.appendChild(div)
      })
    })

    modal.classList.remove('hidden')
  }

  confirmRollback() {
    const selectedSnapshot = document.querySelector('input[name="snapshot"]:checked')
    if (!selectedSnapshot) {
      alert('Please select a snapshot to rollback to')
      return
    }

    fetch(`/admin/builder/${this.themeId}/rollback`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ snapshot_id: selectedSnapshot.value })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.href = data.redirect_url
      } else {
        alert('Error rolling back: ' + (data.errors || 'Unknown error'))
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error rolling back')
    })
  }

  // Preview Management
  refreshPreview() {
    this.updatePreviewContent()
  }

  // Device Preview
  setupDevicePreview() {
    // Device preview is now handled by the device buttons
    // No need for additional setup
  }


  updatePreviewContent() {
    // Update the iframe src to trigger a reload
    const iframe = this.previewFrameTarget
    if (iframe) {
      const currentSrc = iframe.src
      // Force reload by adding timestamp
      const newSrc = currentSrc.split('?')[0] + `?template=${this.currentTemplate}&t=${Date.now()}`
      iframe.src = newSrc
      console.log('Preview updated with new content:', newSrc)
    } else {
      console.error('Preview iframe not found!')
    }
  }

  // Template Management
  setupTemplateSelector() {
    if (this.hasTemplateSelectorTarget) {
      this.templateSelectorTarget.addEventListener('change', (e) => {
        this.currentTemplate = e.target.value
        this.changeTemplate()
      })
    }
  }

  changeTemplate() {
    // Update the current template and reload sections
    const selectedTemplate = this.templateSelectorTarget.value
    this.currentTemplate = selectedTemplate
    
    // Update the page title
    this.updatePageTitle(selectedTemplate)
    
    // Reload sections for the new template
    this.loadSectionsForTemplate(selectedTemplate)
    
    // Update the preview iframe
    this.updatePreviewIframe(selectedTemplate)
  }

  updatePageTitle(templateName) {
    // Find the template name from the templates array
    const template = this.templates.find(t => t.template === templateName)
    const displayName = template ? template.name : templateName.humanize
    
    // Update the page title in the middle panel
    const titleElement = document.querySelector('[data-split-panel="middle"] h2')
    if (titleElement) {
      titleElement.textContent = `Editing ${displayName}`
    }
  }

  loadSectionsForTemplate(templateName) {
    // Make a request to load sections for the new template
    fetch(`/admin/builder/${this.themeId}/sections/${templateName}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update the sections list
        this.updateSectionsList(data.sections)
      } else {
        console.error('Error loading sections:', data.errors)
      }
    })
    .catch(error => {
      console.error('Error loading sections:', error)
    })
  }

  updateSectionsList(sections) {
    const sectionsList = this.sectionsListTarget
    if (!sectionsList) return

    // Clear existing sections
    sectionsList.innerHTML = ''

    if (sections && sections.length > 0) {
      sections.forEach(section => {
        const sectionElement = this.createSectionElement(section)
        sectionsList.appendChild(sectionElement)
      })
    } else {
      sectionsList.innerHTML = `
        <div class="text-center text-gray-500 py-8">
          <p>No sections added yet</p>
          <p class="text-sm">Click "Add Section" to get started</p>
        </div>
      `
    }

    // Reinitialize sortable
    this.initializeSortable()
  }

  createSectionElement(section) {
    const div = document.createElement('div')
    div.className = 'section-item bg-gray-50 border border-gray-200 rounded-lg p-3 mb-2 cursor-move'
    div.dataset.sectionId = section.section_id
    div.dataset.sectionType = section.section_type
    div.dataset.settings = JSON.stringify(section.settings || {})
    div.setAttribute('data-action', 'click->builder#selectSection')
    div.setAttribute('data-section-id-param', section.section_id)
    
    div.innerHTML = `
      <div class="flex items-center justify-between">
        <div>
          <h4 class="font-medium text-gray-900">${section.section_type.humanize}</h4>
          <p class="text-sm text-gray-600">${section.display_name || section.section_type.humanize}</p>
        </div>
        <button class="text-red-500 hover:text-red-700" data-action="click->builder#removeSection" data-section-id="${section.section_id}">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
          </svg>
        </button>
      </div>
    `
    
    return div
  }

  updatePreviewIframe(templateName) {
    // Update the iframe source with the new template
    const iframe = this.previewFrameTarget
    if (iframe) {
      const currentUrl = new URL(iframe.src)
      currentUrl.searchParams.set('template', templateName)
      iframe.src = currentUrl.toString()
    }
  }

  loadTemplateData(templateType) {
    // Load sections for the selected template
    const encodedPath = encodeURIComponent(`templates/${templateType}.json`)
    fetch(`/admin/builder/${this.themeId}/file/${encodedPath}`)
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          const templateData = JSON.parse(data.file.content)
          this.sections = templateData.sections || {}
          this.renderSections()
        }
      })
      .catch(error => {
        console.error('Error loading template data:', error)
      })
  }

  // ActionCable
  connectActionCable() {
    if (window.App?.cable) {
      this.cableSubscription = window.App.cable.subscriptions.create(
        { channel: "BuilderPreviewChannel", theme_id: this.themeId },
        {
          connected: () => {
            console.log('Connected to builder preview channel')
          },
          received: (data) => {
            console.log('Received preview update:', data)
            if (data.type === 'preview_update') {
              this.refreshPreview()
            }
          }
        }
      )
    }
  }

  // Utility Methods
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`
    notification.textContent = message

    document.body.appendChild(notification)

    // Remove after 3 seconds
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  addSelectedSection() {
    if (!this.selectedSection) {
      this.showNotification('Please select a section first', 'error')
      return
    }
    
    this.createSection(this.selectedSection.id)
  }

  closeAddSectionModal() {
    document.getElementById('addSectionModal').classList.add('hidden')
    
    // Reset selection
    this.selectedSection = null
    document.getElementById('selectedSectionName').textContent = 'No section selected'
    document.getElementById('addSelectedSectionBtn').disabled = true
    
    // Clear preview
    document.getElementById('sectionPreview').innerHTML = '<p class="text-gray-500 text-sm">Select a section to see preview</p>'
    
    // Clear section selection
    document.querySelectorAll('.section-item').forEach(item => {
      item.classList.remove('border-blue-500', 'bg-blue-50')
    })
  }

  // Tab Management
  showSectionSettings() {
    this.sectionSettingsPanelTarget.classList.remove('hidden')
    this.themeSettingsPanelTarget.classList.add('hidden')
    this.sectionTabTarget.classList.add('border-blue-500', 'text-gray-700')
    this.sectionTabTarget.classList.remove('text-gray-500')
    this.themeTabTarget.classList.remove('border-blue-500', 'text-gray-700')
    this.themeTabTarget.classList.add('text-gray-500')
  }

  showThemeSettings() {
    this.sectionSettingsPanelTarget.classList.add('hidden')
    this.themeSettingsPanelTarget.classList.remove('hidden')
    this.themeTabTarget.classList.add('border-blue-500', 'text-gray-700')
    this.themeTabTarget.classList.remove('text-gray-500')
    this.sectionTabTarget.classList.remove('border-blue-500', 'text-gray-700')
    this.sectionTabTarget.classList.add('text-gray-500')
  }

  // Device selection methods
  setDevice(event) {
    const device = event.currentTarget.dataset.device
    console.log('Device button clicked:', device)
    this.currentDevice = device
    console.log('Current device set to:', this.currentDevice)
    
    // Update active state for device buttons
    const deviceButtons = document.querySelectorAll('[data-action*="setDevice"]')
    deviceButtons.forEach(button => {
      if (button.dataset.device === device) {
        button.classList.add('bg-blue-100', 'text-blue-600')
        button.classList.remove('hover:bg-gray-200')
      } else {
        button.classList.remove('bg-blue-100', 'text-blue-600')
        button.classList.add('hover:bg-gray-200')
      }
    })
    
    // Apply device-specific styles to preview frame
    this.updatePreviewFrameDevice()
  }

  updatePreviewFrameDevice() {
    const iframe = this.previewFrameTarget
    if (!iframe) {
      console.error('Preview frame not found!')
      return
    }
    
    // Get the white preview container (the rounded div with bg-white)
    const previewContainer = iframe.parentElement
    // Get the parent container (the one with bg-gray-100 p-4)
    const parentContainer = previewContainer.parentElement
    
    if (!previewContainer || !parentContainer) {
      console.error('Preview containers not found!')
      return
    }
    
    console.log('Setting device to:', this.currentDevice)
    
    // Reset all styles first
    parentContainer.style.maxWidth = ''
    parentContainer.style.width = ''
    previewContainer.style.maxWidth = ''
    previewContainer.style.margin = ''
    previewContainer.style.width = ''
    
    // Parent container always takes full width
    parentContainer.style.maxWidth = '100%'
    parentContainer.style.width = '100%'
    
    // Apply device-specific styles to white container only
    switch (this.currentDevice) {
      case 'desktop':
        // Desktop: white container takes full width
        previewContainer.style.maxWidth = '100%'
        previewContainer.style.width = '100%'
        previewContainer.style.margin = '0'
        console.log('Applied desktop styles')
        break
      case 'tablet':
        // Tablet: white container is 768px centered
        previewContainer.style.maxWidth = '100%'
        previewContainer.style.width = '768px'
        previewContainer.style.margin = '0 auto'
        console.log('Applied tablet styles')
        break
      case 'mobile':
        // Mobile: white container is 375px centered
        previewContainer.style.maxWidth = '100%'
        previewContainer.style.width = '375px'
        previewContainer.style.margin = '0 auto'
        console.log('Applied mobile styles')
        break
    }
  }

  // Fullscreen toggle
  toggleFullscreen() {
    const previewContainer = this.previewFrameTarget?.parentElement?.parentElement
    
    if (previewContainer) {
      if (document.fullscreenElement) {
        document.exitFullscreen()
      } else {
        previewContainer.requestFullscreen()
      }
    }
  }

  // Undo/Redo functionality
  undo() {
    // TODO: Implement undo functionality
    console.log('Undo action')
  }

  redo() {
    // TODO: Implement redo functionality
    console.log('Redo action')
  }

}

// Make builder instance globally available for onclick handlers
window.builder = null
document.addEventListener('DOMContentLoaded', () => {
  const builderElement = document.querySelector('[data-controller*="builder"]')
  if (builderElement) {
    window.builder = builderElement.builder
  }
})
