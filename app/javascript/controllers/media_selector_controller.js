import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dialog", "backdrop", "tab", "uploadTab", "libraryTab", "stockTab", "leftColumn", "rightColumn",
    "uploadZone", "fileInput", "uploadProgress", "progressBar", "uploadFileInfo",
    "searchSection", "searchInput", "mediaGrid", "paginationInfo",
    "attachmentDetails", "previewImage", "fileInfo", "editLink", "deleteLink",
    "altText", "titleField", "caption", "description", "fileUrl", "setButton", "selectedMedia",
    "stockSearchInput", "stockProvider", "stockOrientation", "stockGrid", "stockLoading", "stockEmpty", "importButton",
    "stockShowFilter", "stockBookmarkBtn", "stockBookmarkIcon", "stockBookmarkText",
    "stockRightColumn", "stockDetails", "stockDetailsEmpty", "stockPreviewImage", "stockTitle", "stockDimensions",
    "stockPhotographer", "stockSource", "stockDescription"
  ]
  
  static values = {
    callback: String,
    buttonText: String,
    allowMultiSelect: Boolean
  }

  connect() {
    this.currentTab = "upload"
    this.selectedMediaIds = [] // Changed to array for multi-select
    this.selectedMediaData = [] // Changed to array
    this.mediaData = []
    this.allMediaData = []
    this.selectedStockPhoto = null
    this.currentStockPhoto = null
    this.stockSearchQuery = this.loadStockSearchQuery() // Load saved search
    this.bookmarkedPhotoIds = new Set() // Track bookmarked photo IDs
    this.allStockPhotos = [] // Cache all search results
    
    // Listen for image-edited events
    this.element.addEventListener('image-edited', () => {
      this.loadMediaLibrary()
    })
  }

  openDialog(event) {
    if (event) event.preventDefault()
    this.dialogTarget.classList.remove("hidden")
    this.setButtonTarget.disabled = true
    this.selectedMediaIds = []
    this.selectedMediaData = []
    this.switchTab("upload")
    this.loadMediaLibrary()
    
    // Restore saved stock search query
    if (this.stockSearchQuery && this.hasStockSearchInputTarget) {
      this.stockSearchInputTarget.value = this.stockSearchQuery
    }
    
    // Focus management
    document.body.style.overflow = "hidden"
  }

  closeDialog(event) {
    if (event) event.preventDefault()
    this.dialogTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  switchTab(eventOrTabName) {
    // Prevent default if it's an event
    if (eventOrTabName && typeof eventOrTabName !== 'string') {
      eventOrTabName.preventDefault()
      eventOrTabName.stopPropagation()
    }
    
    const tabName = typeof eventOrTabName === 'string' 
      ? eventOrTabName 
      : eventOrTabName.currentTarget.dataset.tabName
    
    this.currentTab = tabName

    // Update tab appearance
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabName === tabName
      if (isActive) {
        tab.classList.add("active")
      } else {
        tab.classList.remove("active")
      }
    })

    // Show/hide content
    this.uploadTabTarget.classList.toggle("hidden", tabName !== "upload")
    this.libraryTabTarget.classList.toggle("hidden", tabName !== "library")
    if (this.hasStockTabTarget) {
      this.stockTabTarget.classList.toggle("hidden", tabName !== "stock")
    }

    // Update footer button based on active tab
    if (tabName === "stock" && this.hasImportButtonTarget) {
      // On stock photos tab, show the import button instead
      this.setButtonTarget.style.display = "none"
      this.importButtonTarget.style.display = "block"
      this.importButtonTarget.disabled = !this.selectedStockPhoto
    } else {
      // On other tabs, show the regular set button
      this.setButtonTarget.style.display = "block"
      this.setButtonTarget.disabled = this.selectedMediaIds.length === 0
      if (this.hasImportButtonTarget) {
        this.importButtonTarget.style.display = "none"
      }
    }

    if (tabName === "library") {
      this.loadMediaLibrary()
    }
  }

  selectFiles(event) {
    if (event) event.preventDefault()
    this.fileInputTarget.click()
  }

  dragOver(event) {
    event.preventDefault()
    this.uploadZoneTarget.classList.add("dragover")
  }

  dragLeave(event) {
    event.preventDefault()
    this.uploadZoneTarget.classList.remove("dragover")
  }

  drop(event) {
    event.preventDefault()
    this.uploadZoneTarget.classList.remove("dragover")
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }

  handleFileSelect(event) {
    const files = event.target.files
    if (files && files.length > 0) {
      this.uploadFiles(files)
    }
  }

  async uploadFiles(files) {
    // Switch to library tab to show progress
    this.switchTab("library")
    
    // Hide attachment details if visible
    if (this.hasAttachmentDetailsTarget) {
      this.attachmentDetailsTarget.classList.add("hidden")
    }
    
    // Show upload progress
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.remove("hidden")
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "0%"
    }
    
    // Validate files
    const maxSize = 2 * 1024 * 1024 // 2 MB
    for (let file of files) {
      if (file.size > maxSize) {
        alert(`File "${file.name}" exceeds maximum size of 2 MB`)
        return
      }
    }

    // Create FormData
    const formData = new FormData()
    Array.from(files).forEach((file, index) => {
      formData.append(`media[${index}][file]`, file)
      formData.append(`media[${index}][title]`, file.name)
    })

    // Upload files
    const xhr = new XMLHttpRequest()
    
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percentComplete = (e.loaded / e.total) * 100
        if (this.hasProgressBarTarget) {
          this.progressBarTarget.style.width = `${percentComplete}%`
        }
      }
    })

    xhr.addEventListener('load', async () => {
      if (xhr.status === 200) {
        try {
          const data = JSON.parse(xhr.responseText)
          if (data.success) {
            if (this.hasUploadProgressTarget) {
              this.uploadProgressTarget.classList.add("hidden")
            }
            await this.loadMediaLibrary()
            
            // Auto-select the last uploaded image (first in the newly loaded list)
            if (this.mediaData.length > 0) {
              const lastUploadedMedia = this.mediaData[0]
              this.selectMedia(lastUploadedMedia.id)
            }
            
            this.showUploadSuccessMessage(data.message || `Successfully uploaded ${files.length} file(s)`)
          } else {
            if (this.hasUploadProgressTarget) {
              this.uploadProgressTarget.classList.add("hidden")
            }
            alert(data.message || 'Upload failed')
          }
        } catch (error) {
          console.error('Upload response error:', error)
          if (this.hasUploadProgressTarget) {
            this.uploadProgressTarget.classList.add("hidden")
          }
          alert('Upload completed but response was invalid')
        }
      } else {
        if (this.hasUploadProgressTarget) {
          this.uploadProgressTarget.classList.add("hidden")
        }
        alert('Upload failed. Please try again.')
      }
    })

    xhr.addEventListener('error', () => {
      if (this.hasUploadProgressTarget) {
        this.uploadProgressTarget.classList.add("hidden")
      }
      alert('Upload failed. Check your connection and try again.')
    })

    // Update file info
    if (this.hasUploadFileInfoTarget) {
      this.uploadFileInfoTarget.textContent = files.length > 1 
        ? `1/${files.length} - ${files[0].name}` 
        : files[0].name
    }

    xhr.open('POST', '/admin/media/bulk_upload')
    xhr.setRequestHeader('X-CSRF-Token', document.querySelector('meta[name="csrf-token"]').content)
    xhr.send(formData)
  }

  async loadMediaLibrary() {
    try {
      const response = await fetch('/admin/media.json')
      const data = await response.json()
      
      this.allMediaData = data
      this.mediaData = data
      this.renderMediaGrid()
    } catch (error) {
      console.error('Failed to load media:', error)
    }
  }

  renderMediaGrid() {
    this.mediaGridTarget.innerHTML = ''
    
    this.mediaData.forEach((media) => {
      const item = document.createElement('div')
      item.dataset.mediaId = media.id
      item.dataset.action = 'click->media-selector#selectMediaItem'
      item.className = 'relative aspect-square bg-gray-100 rounded border-2 cursor-pointer transition-all hover:border-blue-400'
      
      if (this.selectedMediaIds.includes(media.id)) {
        item.classList.add('border-blue-500')
      }
      
      // Thumbnail or icon
      if (media.thumbnail_url) {
        item.innerHTML = `
          <img src="${media.thumbnail_url}" class="w-full h-full object-cover rounded" />
          ${this.selectedMediaIds.includes(media.id) ? '<div class="absolute top-2 right-2 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center"><svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg></div>' : ''}
        `
      } else {
        item.innerHTML = `
          <div class="flex items-center justify-center h-full">
            <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
          </div>
        `
      }
      
      this.mediaGridTarget.appendChild(item)
    })
    
    // Update pagination info
    const total = this.mediaData.length
    this.paginationInfoTarget.textContent = `Showing 1 of ${total} media item${total !== 1 ? 's' : ''}`
  }

  selectMediaItem(event) {
    const mediaId = parseInt(event.currentTarget.dataset.mediaId)
    this.selectMedia(mediaId)
  }

  selectMedia(mediaId) {
    const isMultiSelect = this.allowMultiSelectValue === true
    
    if (isMultiSelect) {
      // Toggle selection for multi-select
      const index = this.selectedMediaIds.indexOf(mediaId)
      if (index === -1) {
        // Add to selection
        this.selectedMediaIds.push(mediaId)
      } else {
        // Remove from selection
        this.selectedMediaIds.splice(index, 1)
      }
      
      this.selectedMediaData = this.mediaData.filter(m => this.selectedMediaIds.includes(m.id))
    } else {
      // Single select - toggle if clicking same item
      if (this.selectedMediaIds[0] === mediaId) {
        // Deselect
        this.selectedMediaIds = []
        this.selectedMediaData = []
      } else {
        // Select new item
        this.selectedMediaIds = [mediaId]
        this.selectedMediaData = [this.mediaData.find(m => m.id === mediaId)]
      }
    }

    if (!this.selectedMediaData || this.selectedMediaData.length === 0) {
      // No selection - hide details
      if (this.hasAttachmentDetailsTarget) {
        this.attachmentDetailsTarget.classList.add("hidden")
      }
      this.setButtonTarget.disabled = true
    }

    // Update visual selection in grid
    this.mediaGridTarget.querySelectorAll('[data-media-id]').forEach(item => {
      const id = parseInt(item.dataset.mediaId)
      const isSelected = this.selectedMediaIds.includes(id)
      
      if (isSelected) {
        item.classList.add('border-blue-500')
        // Add checkmark
        const existingCheck = item.querySelector('.checkmark-overlay')
        if (!existingCheck) {
          const check = document.createElement('div')
          check.className = 'checkmark-overlay absolute top-2 right-2 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center'
          check.innerHTML = '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>'
          item.appendChild(check)
        }
      } else {
        item.classList.remove('border-blue-500')
        item.querySelector('.checkmark-overlay')?.remove()
      }
    })

    // Show attachment details for single select
    if (!isMultiSelect && this.selectedMediaData.length > 0) {
      this.showAttachmentDetails()
      this.setButtonTarget.disabled = false
    } else if (isMultiSelect && this.selectedMediaData.length > 0) {
      // Enable button if any items selected in multi-select mode
      this.setButtonTarget.disabled = false
    }
  }

  showAttachmentDetails() {
    // Get first selected media for single-select mode
    const media = Array.isArray(this.selectedMediaData) ? this.selectedMediaData[0] : this.selectedMediaData
    if (!media) return

    // Hide upload progress if visible
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.add("hidden")
    }

    // Show attachment details
    if (this.hasAttachmentDetailsTarget) {
      this.attachmentDetailsTarget.classList.remove("hidden")
    }

    // Set preview image
    if (media.thumbnail_url) {
      this.previewImageTarget.innerHTML = `
        <img src="${media.thumbnail_url}" class="w-full rounded" />
      `
    } else {
      this.previewImageTarget.innerHTML = `
        <div class="aspect-square bg-gray-100 rounded flex items-center justify-center">
          <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
          </svg>
        </div>
      `
    }

    // Set file info
    const date = new Date(media.created_at).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })

    // Format file size
    const fileSize = media.file_size || 0
    let sizeStr = ''
    if (fileSize < 1024) {
      sizeStr = `${fileSize} B`
    } else if (fileSize < 1024 * 1024) {
      sizeStr = `${(fileSize / 1024).toFixed(1)} KB`
    } else {
      sizeStr = `${(fileSize / (1024 * 1024)).toFixed(1)} MB`
    }

    this.fileInfoTarget.innerHTML = `
      <div>
        <strong>${media.filename || 'Untitled'}</strong>
      </div>
      <div>Date: ${date}</div>
      <div>Size: ${sizeStr}</div>
      <div>Dimensions: ${media.width || '?'} by ${media.height || '?'} pixels</div>
    `

    // Set metadata fields
    this.titleFieldTarget.value = media.title || ''
    this.altTextTarget.value = media.alt_text || ''
    this.captionTarget.value = media.caption || ''
    this.descriptionTarget.value = media.description || ''

    // Set file URL
    const fileUrl = media.url || ''
    this.fileUrlTarget.value = fileUrl

    // Set edit link - show for all images
    if (this.hasEditLinkTarget) {
      // Show edit link and attach click handler
      this.editLinkTarget.style.display = 'block'
      this.editLinkTarget.href = '#'
      this.editLinkTarget.onclick = (e) => {
        e.preventDefault()
        this.openImageEditor(media.id, media.url)
      }
    }

    // Set delete link
    if (media.delete_url) {
      this.deleteLinkTarget.href = media.delete_url
    }
  }
  
  openImageEditor(mediumId, imageUrl) {
    // Find the image editor controller in the document
    const editorElement = document.querySelector('[data-controller*="image-editor"]')
    if (editorElement) {
      // Get the controller instance
      const editorController = this.application.getControllerForElementAndIdentifier(editorElement, 'image-editor')
      if (editorController) {
        editorController.openEditor(mediumId, imageUrl)
      }
    }
  }

  searchMedia(event) {
    const query = event.target.value.toLowerCase()
    
    if (!query) {
      this.mediaData = [...this.allMediaData]
    } else {
      this.mediaData = this.allMediaData.filter(media => {
        const title = (media.title || '').toLowerCase()
        const filename = (media.filename || '').toLowerCase()
        return title.includes(query) || filename.includes(query)
      })
    }
    
    this.renderMediaGrid()
  }

  filterMedia() {
    const typeFilter = this.typeFilterTarget.value
    const dateFilter = this.dateFilterTarget.value

    let filtered = [...this.allMediaData]

    // Filter by type
    if (typeFilter !== 'all') {
      filtered = filtered.filter(media => {
        return media.file_type && media.file_type.startsWith(typeFilter.slice(0, -1))
      })
    }

    // Filter by date
    if (dateFilter !== 'all') {
      const now = new Date()
      const startDate = new Date()
      
      if (dateFilter === 'today') {
        startDate.setHours(0, 0, 0, 0)
      } else if (dateFilter === 'week') {
        startDate.setDate(now.getDate() - 7)
      } else if (dateFilter === 'month') {
        startDate.setMonth(now.getMonth() - 1)
      }
      
      filtered = filtered.filter(media => {
        const mediaDate = new Date(media.created_at)
        return mediaDate >= startDate
      })
    }

    this.mediaData = filtered
    this.renderMediaGrid()
  }

  copyUrl() {
    const url = this.fileUrlTarget.value
    navigator.clipboard.writeText(url).then(() => {
      const button = event.target
      const originalText = button.textContent
      button.textContent = 'Copied!'
      setTimeout(() => {
        button.textContent = originalText
      }, 2000)
    })
  }

  deleteMedia(event) {
    event.preventDefault()
    
    if (!confirm('Are you sure you want to delete this media permanently?')) {
      return
    }

    const deleteUrl = this.selectedMediaData.delete_url
    if (!deleteUrl) return

    // Make DELETE request
    fetch(deleteUrl, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (response.ok) {
        this.loadMediaLibrary()
        this.selectedMediaIds = []
        this.selectedMediaData = []
        this.attachmentDetailsTarget.classList.add("hidden")
        this.setButtonTarget.disabled = true
      } else {
        alert('Failed to delete media')
      }
    })
    .catch(error => {
      console.error('Delete error:', error)
      alert('Failed to delete media')
    })
  }

  setFeaturedImage() {
    if (!this.selectedMediaData || this.selectedMediaData.length === 0) return

    // Call the callback function if it exists
    if (this.callbackValue && typeof window[this.callbackValue] === 'function') {
      // Pass array or single item depending on multi-select
      const isMultiSelect = this.allowMultiSelectValue === true
      const dataToSend = isMultiSelect ? this.selectedMediaData : (this.selectedMediaData[0] || this.selectedMediaData)
      window[this.callbackValue](dataToSend)
    }

    this.closeDialog()
  }

  showUploadSuccessMessage(message) {
    // Could use a toast library or simple alert
    console.log('Upload success:', message)
  }

  preventEnterSubmit(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    }
  }

  // Stock Photo Methods
  async searchStockPhotos(event) {
    if (event) {
      // Only process Enter key
      if (event.type === 'keyup' && event.key !== 'Enter') return
      
      // For all events, prevent bubbling to backdrop
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    }
    
    const query = this.stockSearchInputTarget.value.trim()
    if (!query) return
    
    // Save the search query to localStorage
    this.saveStockSearchQuery(query)
    
    this.stockLoadingTarget.classList.remove('hidden')
    this.stockEmptyTarget.classList.add('hidden')
    this.stockGridTarget.innerHTML = ''
    this.selectedStockPhoto = null
    this.importButtonTarget.disabled = true
    
    try {
      const params = new URLSearchParams({
        query: query,
        provider: this.stockProviderTarget.value,
        orientation: this.stockOrientationTarget.value
      })
      
      const response = await fetch(`/admin/stock_photos/search?${params}`)
      const data = await response.json()
      
      this.stockLoadingTarget.classList.add('hidden')
      
      if (data.photos && data.photos.length > 0) {
        this.allStockPhotos = data.photos // Cache results
        this.renderStockPhotos(data.photos)
      } else {
        this.stockEmptyTarget.classList.remove('hidden')
      }
    } catch (error) {
      console.error('Stock photo search error:', error)
      this.stockLoadingTarget.classList.add('hidden')
      alert('Failed to search stock photos')
    }
  }

  renderStockPhotos(photos) {
    this.stockGridTarget.innerHTML = ''
    
    photos.forEach(photo => {
      const item = document.createElement('div')
      item.className = 'relative aspect-square bg-gray-100 rounded border-2 cursor-pointer transition-all hover:border-blue-400'
      item.dataset.stockPhotoId = photo.id
      item.dataset.photoData = JSON.stringify(photo)
      item.onclick = () => this.selectStockPhoto(item, photo)
      
      const isBookmarked = this.bookmarkedPhotoIds.has(photo.id)
      
      item.innerHTML = `
        <img src="${photo.thumbnail_url}" class="w-full h-full object-cover rounded" />
        <div class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-70 text-white text-xs p-2">
          <p class="truncate">${photo.photographer}</p>
          <p class="text-gray-300 text-xs">${photo.source}</p>
        </div>
        <button type="button" 
                class="bookmark-heart-btn absolute top-2 right-2 p-1 hover:bg-opacity-80 transition-all rounded-full z-10"
                style="background: rgba(0,0,0,0.5);"
                data-photo-id="${photo.id}"
                data-is-bookmarked="${isBookmarked}">
          <svg class="w-5 h-5" fill="${isBookmarked ? '#ef4444' : 'white'}" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"/>
          </svg>
        </button>
      `
      
      this.stockGridTarget.appendChild(item)
      
      // Attach click handler to heart button
      const heartBtn = item.querySelector('.bookmark-heart-btn')
      if (heartBtn) {
        heartBtn.addEventListener('click', (e) => {
          e.preventDefault()
          e.stopPropagation()
          this.toggleBookmarkByHeart(e)
        })
      }
    })
  }

  selectStockPhoto(element, photo) {
    // Remove previous selection
    this.stockGridTarget.querySelectorAll('.border-blue-500').forEach(el => {
      el.classList.remove('border-blue-500')
    })
    
    // Add selection to clicked item
    element.classList.add('border-blue-500')
    
    // Store selected photo
    this.selectedStockPhoto = photo
    this.currentStockPhoto = photo
    
    // Show details in sidebar
    this.showStockPhotoInSidebar(photo)
    
    this.importButtonTarget.disabled = false
  }
  
  showStockPhotoInSidebar(photo) {
    // Hide empty state, show details
    this.stockDetailsEmptyTarget.classList.add('hidden')
    this.stockDetailsTarget.classList.remove('hidden')
    
    // Populate stock photo data
    this.stockTitleTarget.textContent = photo.title || photo.alt_description || 'Stock Photo'
    this.stockDimensionsTarget.textContent = `${photo.width} × ${photo.height}px`
    
    this.stockPreviewImageTarget.src = photo.preview_url || photo.thumbnail_url
    this.stockPreviewImageTarget.alt = photo.alt_description || photo.title || 'Stock Photo'
    
    this.stockPhotographerTarget.textContent = photo.photographer
    this.stockPhotographerTarget.href = photo.photographer_url || '#'
    
    this.stockSourceTarget.textContent = photo.source
    this.stockSourceTarget.href = photo.source_url || '#'
    
    this.stockDescriptionTarget.textContent = photo.alt_description || photo.title || ''
    
    // Update bookmark button
    if (this.hasStockBookmarkBtnTarget) {
      const isBookmarked = this.bookmarkedPhotoIds.has(photo.id)
      this.stockBookmarkIconTarget.textContent = isBookmarked ? '⭐' : '☆'
      this.stockBookmarkTextTarget.textContent = isBookmarked ? 'Bookmarked' : 'Bookmark Photo'
    }
  }

  async importStockPhoto() {
    if (!this.selectedStockPhoto) return
    
    this.importButtonTarget.disabled = true
    this.importButtonTarget.textContent = 'Importing...'
    
    try {
      const response = await fetch('/admin/stock_photos/import', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ photo_data: JSON.stringify(this.selectedStockPhoto) })
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Remove bookmark from UI if the photo was bookmarked
        if (this.selectedStockPhoto && this.bookmarkedPhotoIds.has(this.selectedStockPhoto.id)) {
          this.bookmarkedPhotoIds.delete(this.selectedStockPhoto.id)
          // Update the heart icon if we're still on the stock photos tab
          const photoElement = this.stockGridTarget.querySelector(`[data-photo-id="${this.selectedStockPhoto.id}"]`)?.closest('[data-stock-photo-id]')
          if (photoElement) {
            const heartBtn = photoElement.querySelector('.bookmark-heart-btn svg')
            if (heartBtn) {
              heartBtn.setAttribute('fill', 'white')
            }
          }
        }
        
        // Switch to Media Library tab
        this.switchTab('library')
        
        // Reload media library
        await this.loadMediaLibrary()
        
        // Auto-select the imported image
        if (data.medium) {
          this.selectMedia(data.medium.id)
        }
        
        this.showUploadSuccessMessage(data.message)
      } else {
        alert(data.message || 'Failed to import photo')
      }
    } catch (error) {
      console.error('Import error:', error)
      alert('Failed to import photo')
    } finally {
      this.importButtonTarget.disabled = false
      this.importButtonTarget.textContent = 'Import Selected Photo'
    }
  }
  
  // localStorage methods for stock search
  saveStockSearchQuery(query) {
    if (query && query.trim()) {
      localStorage.setItem('stockPhotoSearchQuery', query)
      this.stockSearchQuery = query
    }
  }
  
  loadStockSearchQuery() {
    return localStorage.getItem('stockPhotoSearchQuery') || ''
  }
  
  clearStockSearchQuery() {
    localStorage.removeItem('stockPhotoSearchQuery')
    this.stockSearchQuery = ''
  }
  
  // Bookmark methods
  filterStockPhotos() {
    const filterValue = this.stockShowFilterTarget.value
    if (filterValue === 'bookmarked') {
      this.loadBookmarks()
    } else if (this.allStockPhotos.length > 0) {
      this.renderStockPhotos(this.allStockPhotos)
    }
  }
  
  async loadBookmarks() {
    this.stockLoadingTarget.classList.remove('hidden')
    this.stockEmptyTarget.classList.add('hidden')
    this.stockGridTarget.innerHTML = ''
    
    try {
      const response = await fetch('/admin/stock_photos/bookmarks')
      const data = await response.json()
      this.stockLoadingTarget.classList.add('hidden')
      
      if (data.photos && data.photos.length > 0) {
        this.renderStockPhotos(data.photos)
        data.photos.forEach(p => this.bookmarkedPhotoIds.add(p.id))
      } else {
        this.stockEmptyTarget.classList.remove('hidden')
      }
    } catch (error) {
      console.error('Failed to load bookmarks:', error)
      this.stockLoadingTarget.classList.add('hidden')
    }
  }
  
  async toggleBookmark(event) {
    event.preventDefault()
    if (!this.currentStockPhoto) return
    
    const isBookmarked = this.bookmarkedPhotoIds.has(this.currentStockPhoto.id)
    
    try {
      if (isBookmarked) {
        await fetch(`/admin/stock_photos/bookmark/${encodeURIComponent(this.currentStockPhoto.id)}`, {
          method: 'DELETE',
          headers: { 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
        })
        this.bookmarkedPhotoIds.delete(this.currentStockPhoto.id)
        this.stockBookmarkIconTarget.textContent = '☆'
        this.stockBookmarkTextTarget.textContent = 'Bookmark Photo'
        
        if (this.stockShowFilterTarget.value === 'bookmarked') {
          this.loadBookmarks()
        }
      } else {
        await fetch('/admin/stock_photos/bookmark', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ photo_data: JSON.stringify(this.currentStockPhoto) })
        })
        this.bookmarkedPhotoIds.add(this.currentStockPhoto.id)
        this.stockBookmarkIconTarget.textContent = '⭐'
        this.stockBookmarkTextTarget.textContent = 'Bookmarked'
      }
      this.updateStarIndicators()
    } catch (error) {
      console.error('Bookmark error:', error)
    }
  }
  
  updateStarIndicators() {
    this.stockGridTarget.querySelectorAll('[data-stock-photo-id]').forEach(item => {
      const photoId = item.dataset.stockPhotoId
      const existingStar = item.querySelector('.bookmark-star')
      const isBookmarked = this.bookmarkedPhotoIds.has(photoId)
      
      if (isBookmarked && !existingStar) {
        const star = document.createElement('div')
        star.className = 'bookmark-star absolute top-1 right-1 text-xl'
        star.textContent = '⭐'
        item.appendChild(star)
      } else if (!isBookmarked && existingStar) {
        existingStar.remove()
      }
    })
  }
  
  async toggleBookmarkByHeart(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const button = event.currentTarget
    const photoId = button.dataset.photoId
    const photoElement = button.closest('[data-stock-photo-id]')
    const photo = JSON.parse(photoElement.dataset.photoData)
    const isBookmarked = this.bookmarkedPhotoIds.has(photoId)
    
    try {
      if (isBookmarked) {
        // Unbookmark
        await fetch(`/admin/stock_photos/bookmark/${encodeURIComponent(photoId)}`, {
          method: 'DELETE',
          headers: { 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
        })
        this.bookmarkedPhotoIds.delete(photoId)
        
        // Update heart SVG
        const svg = button.querySelector('svg')
        svg.setAttribute('fill', 'white')
        
        // If filtering by bookmarked, reload the list
        if (this.stockShowFilterTarget.value === 'bookmarked') {
          this.loadBookmarks()
        }
      } else {
        // Bookmark
        await fetch('/admin/stock_photos/bookmark', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ photo_data: JSON.stringify(photo) })
        })
        this.bookmarkedPhotoIds.add(photoId)
        
        // Update heart SVG
        const svg = button.querySelector('svg')
        svg.setAttribute('fill', '#ef4444')
      }
    } catch (error) {
      console.error('Bookmark toggle error:', error)
      alert('Failed to toggle bookmark')
    }
  }
}

