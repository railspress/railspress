import { Controller } from "@hotwired/stimulus"
import { ImageFilters } from "image_filters"

export default class extends Controller {
  static targets = [
    "overlay", "virtualCanvas", "undoBtn", "redoBtn",
    "tabBtn", "filtersPanel", "cropPanel", "scalePanel", "rotationPanel", "advancedPanel",
    "filterGrid", "filterSearch", "aspectRatio", "scaleWidth", "scaleHeight", "lockAspect",
    "brightnessSlider", "brightnessValue",
    "contrastSlider", "contrastValue",
    "saturationSlider", "saturationValue",
    "hueSlider", "hueValue",
    "vibranceSlider", "vibranceValue",
    "blurSlider", "blurValue",
    "sharpenSlider", "sharpenValue",
    "vignetteSlider", "vignetteValue",
    "temperatureSlider", "temperatureValue",
    "tintSlider", "tintValue",
    "highlightsSlider", "highlightsValue",
    "shadowsSlider", "shadowsValue",
    "whitesSlider", "whitesValue",
    "blacksSlider", "blacksValue",
    "exposureSlider", "exposureValue",
    "sharpeningSlider", "sharpeningValue",
    "radiusSlider", "radiusValue",
    "sharpeningDetailSlider", "sharpeningDetailValue",
    "maskingSlider", "maskingValue",
    "noiseReductionSlider", "noiseReductionValue",
    "noiseDetailSlider", "noiseDetailValue",
    "noiseContrastSlider", "noiseContrastValue",
    "colorNoiseReductionSlider", "colorNoiseReductionValue",
    "colorNoiseDetailSlider", "colorNoiseDetailValue",
    "smoothnessSlider", "smoothnessValue",
    "metaPanel", "metaLoading", "metaEmpty", "metaContent",
    "filterPopover", "popoverFilterName", "dryWetSlider", "dryWetValue"
  ]

  connect() {
    this.mediumId = null
    this.originalImage = null
    this.virtualImage = null // The single source of truth
    this.history = []
    this.historyIndex = -1
    this.currentTab = 'filters'
    this.cropper = null
    this.selectedFilter = 'normal'
    this.metadataChanges = {} // Store EXIF changes
    this.filterIntensity = 100
    this.selectedFilterThumbnail = null
    this.originalVirtualImage = null // Store original for advanced tab reset
    this.advancedBaseImage = null // Store the image before advanced adjustments
    this.selectedFilterIndex = 0 // Track which filter is selected for keyboard navigation
    this.filterNames = ImageFilters.getFilterNames() // Get all filter names
    this.updateAdvancedTimeout = null // For debouncing expensive filter operations
    this.advancedState = {
      brightness: 100,
      contrast: 100,
      saturation: 100,
      hue: 0,
      vibrance: 0,
      blur: 0,
      sharpen: 0,
      vignette: 0,
      temperature: 0,
      tint: 0,
      highlights: 100,
      shadows: 100,
      whites: 50,
      blacks: 50,
      exposure: 0,
      sharpening: 0,
      radius: 1.0,
      sharpeningDetail: 50,
      masking: 0,
      noiseReduction: 0,
      noiseDetail: 50,
      noiseContrast: 50,
      colorNoiseReduction: 0,
      colorNoiseDetail: 50,
      smoothness: 50
    }
    
    // Add keyboard event listener for arrow key navigation
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
    
    // Load Cropper.js dynamically
    this.loadCropperJS()
  }
  
  disconnect() {
    // Remove keyboard event listener
    document.removeEventListener('keydown', this.boundHandleKeydown)
    
    // Clear any pending debounced filter update
    if (this.updateAdvancedTimeout) {
      clearTimeout(this.updateAdvancedTimeout)
      this.updateAdvancedTimeout = null
    }
  }

  loadCropperJS() {
    if (window.Cropper) {
      this.cropperLoaded = true
      return Promise.resolve()
    }

    return new Promise((resolve) => {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.css'
      document.head.appendChild(link)

      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.js'
      script.onload = () => {
        this.cropperLoaded = true
        resolve()
      }
      document.head.appendChild(script)
    })
  }

  async openEditor(mediumId, imageUrl) {
    this.mediumId = mediumId
    this.imageUrl = imageUrl
    this.overlayTarget.classList.remove('hidden')

    // Load original image
    const img = new Image()
    img.crossOrigin = 'anonymous'
    
    await new Promise((resolve, reject) => {
      img.onload = resolve
      img.onerror = reject
      img.src = imageUrl
    })

    this.originalImage = img

    // Initialize virtual canvas
    this.initializeVirtualImage(img)

    // Generate filter thumbnails
    this.generateFilterThumbnails()

    // Switch to Filters tab
    this.switchTab({ target: { dataset: { tab: 'filters' } } })
  }

  initializeVirtualImage(img) {
    const canvas = this.virtualCanvasTarget
    canvas.width = img.width
    canvas.height = img.height

    const ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0)

    this.virtualImage = canvas

    // Save initial state to history
    this.saveToHistory()
  }

  saveToHistory() {
    // Remove any states after current index (for redo)
    this.history = this.history.slice(0, this.historyIndex + 1)

    // Clone current canvas state
    const snapshot = document.createElement('canvas')
    snapshot.width = this.virtualCanvasTarget.width
    snapshot.height = this.virtualCanvasTarget.height
    snapshot.getContext('2d').drawImage(this.virtualCanvasTarget, 0, 0)

    this.history.push(snapshot)
    this.historyIndex = this.history.length - 1

    // Update undo/redo button states
    this.updateHistoryButtons()
  }

  updateHistoryButtons() {
    this.undoBtnTarget.disabled = this.historyIndex <= 0
    this.redoBtnTarget.disabled = this.historyIndex >= this.history.length - 1
  }

  undo(event) {
    if (event) event.preventDefault()
    if (this.historyIndex > 0) {
      this.historyIndex--
      this.restoreFromHistory()
    }
  }

  redo(event) {
    if (event) event.preventDefault()
    if (this.historyIndex < this.history.length - 1) {
      this.historyIndex++
      this.restoreFromHistory()
    }
  }

  restoreFromHistory() {
    const snapshot = this.history[this.historyIndex]
    const canvas = this.virtualCanvasTarget
    canvas.width = snapshot.width
    canvas.height = snapshot.height
    canvas.getContext('2d').drawImage(snapshot, 0, 0)

    this.updateHistoryButtons()
  }

  handleKeydown(event) {
    // Only handle arrow keys when on the Filters tab and editor is open
    if (this.currentTab !== 'filters' || this.overlayTarget.classList.contains('hidden')) {
      return
    }
    
    const key = event.key
    let newIndex = this.selectedFilterIndex
    
    switch(key) {
      case 'ArrowRight':
        event.preventDefault()
        newIndex = (this.selectedFilterIndex + 1) % this.filterNames.length
        break
      case 'ArrowLeft':
        event.preventDefault()
        newIndex = this.selectedFilterIndex > 0 ? this.selectedFilterIndex - 1 : this.filterNames.length - 1
        break
      case 'ArrowDown':
        event.preventDefault()
        // 2-column layout
        newIndex = Math.min(this.selectedFilterIndex + 2, this.filterNames.length - 1)
        break
      case 'ArrowUp':
        event.preventDefault()
        // 2-column layout
        newIndex = Math.max(this.selectedFilterIndex - 2, 0)
        break
      case 'Enter':
      case ' ':
        event.preventDefault()
        // Filter is already applied by arrow keys, so do nothing (or could toggle popover)
        return
      default:
        return
    }
    
    this.selectedFilterIndex = newIndex
    this.highlightFilterByIndex(newIndex)
    
    // Apply the filter immediately when navigating with arrow keys
    const selectedFilterName = this.filterNames[newIndex]
    this.applyFilterOnSelection(selectedFilterName)
  }
  
  highlightFilterByIndex(index) {
    // Remove all borders
    this.filterGridTarget.querySelectorAll('.filter-border').forEach(border => {
      border.classList.add('hidden')
    })
    
    // Add border to selected thumbnail
    const filterName = this.filterNames[index]
    const thumbnail = this.filterGridTarget.querySelector(`[data-filter="${filterName}"]`)
    if (thumbnail) {
      const border = thumbnail.querySelector('.filter-border')
      if (border) {
        border.classList.remove('hidden')
      }
      
      // Scroll the selected thumbnail into view
      thumbnail.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }
  
  applyFilterOnSelection(filterName) {
    // Reset intensity and apply the filter
    this.filterIntensity = 100
    
    // Update selected filter thumbnail reference
    const thumbnail = this.filterGridTarget.querySelector(`[data-filter="${filterName}"]`)
    this.selectedFilterThumbnail = thumbnail
    
    // Show the icon for filters other than 'normal'
    if (thumbnail && filterName !== 'normal') {
      const icon = thumbnail.querySelector('.filter-icon')
      if (icon) {
        icon.classList.remove('hidden')
      }
    }
    
    // Apply the filter to the image
    this.applyFilter(filterName, 100)
  }

  switchTab(event) {
    const tab = event.target.dataset.tab

    // Update active tab button
    this.tabBtnTargets.forEach(btn => {
      const isActive = btn.dataset.tab === tab
      if (isActive) {
        btn.classList.add('tab-btn-active')
        btn.style.backgroundColor = 'var(--admin-primary)'
        btn.style.color = 'white'
      } else {
        btn.classList.remove('tab-btn-active')
        btn.style.backgroundColor = 'transparent'
        btn.style.color = 'var(--admin-text-secondary)'
      }
    })

    // Hide all panels
    this.filtersPanelTarget.classList.add('hidden')
    this.cropPanelTarget.classList.add('hidden')
    this.scalePanelTarget.classList.add('hidden')
    this.rotationPanelTarget.classList.add('hidden')
    this.advancedPanelTarget.classList.add('hidden')
    this.metaPanelTarget.classList.add('hidden')

    // Show active panel
    switch(tab) {
      case 'filters':
        this.filtersPanelTarget.classList.remove('hidden')
        this.destroyCropper()
        break
      case 'crop':
        this.cropPanelTarget.classList.remove('hidden')
        this.initCropper()
        break
      case 'scale':
        this.scalePanelTarget.classList.remove('hidden')
        this.updateScaleInputs()
        this.destroyCropper()
        break
      case 'rotation':
        this.rotationPanelTarget.classList.remove('hidden')
        this.destroyCropper()
        break
      case 'advanced':
        this.advancedPanelTarget.classList.remove('hidden')
        this.destroyCropper()
        break
      case 'meta':
        this.metaPanelTarget.classList.remove('hidden')
        this.destroyCropper()
        if (this.originalImage) {
          this.loadMetadata()
        }
        break
    }

    this.currentTab = tab
  }

  toggleCategory(event) {
    const category = event.currentTarget.dataset.category
    const contentDiv = document.querySelector(`[data-category-content="${category}"]`)
    const header = event.currentTarget

    if (contentDiv) {
      if (contentDiv.hidden) {
        contentDiv.hidden = false
        header.classList.remove('collapsed')
      } else {
        contentDiv.hidden = true
        header.classList.add('collapsed')
      }
    }
  }

  // FILTERS TAB
  generateFilterThumbnails() {
    const filterNames = ImageFilters.getFilterNames()
    const gridHTML = filterNames.map(filterName => {
      const filterData = ImageFilters.getFilterData(filterName)
      return `
        <div class="filter-thumbnail cursor-pointer hover:opacity-80 transition-opacity relative" data-filter="${filterName}">
          <!-- Border indicator (hidden initially) -->
          <div class="filter-border hidden absolute inset-0 border-2 rounded pointer-events-none" 
               style="border-color: var(--admin-primary); z-index: 10;"></div>
          
          <!-- Canvas wrapper with icon inside -->
          <div class="relative">
            ${filterName !== 'normal' ? `
            <div class="filter-icon hidden absolute bottom-5 left-1 cursor-pointer z-20"
                 data-action="click->image-editor#showFilterPopover">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" viewBox="0 0 512 512" fill="currentColor">
                <path d="M257.6,128c7.4-36.5,39.7-64,78.4-64s71,27.5,78.4,64H512v32h-97.6c-7.4,36.5-39.7,64-78.4,64s-71-27.5-78.4-64H0v-32
                  H257.6z M336,192c26.5,0,48-21.5,48-48s-21.5-48-48-48s-48,21.5-48,48S309.5,192,336,192z"/>
                <path d="M97.6,352c7.4-36.5,39.7-64,78.4-64s71,27.5,78.4,64H512v32H254.4c-7.4,36.5-39.7,64-78.4,64s-71-27.5-78.4-64H0v-32H97.6z
                  M176,416c26.5,0,48-21.5,48-48s-21.5-48-48-48s-48,21.5-48,48S149.5,416,176,416z"/>
              </svg>
            </div>
            ` : ''}
            <canvas class="w-full aspect-square rounded mb-1" data-filter-canvas="${filterName}"></canvas>
          </div>
          <p class="text-xs text-center" style="color: var(--admin-text-secondary);">${filterData.name}</p>
        </div>
      `
    }).join('')

    this.filterGridTarget.innerHTML = gridHTML

    // Generate thumbnails
    filterNames.forEach(filterName => {
      const canvas = this.filterGridTarget.querySelector(`[data-filter-canvas="${filterName}"]`)
      this.generateFilterThumbnail(canvas, filterName)
    })

    // Add click handlers
    this.filterGridTarget.querySelectorAll('.filter-thumbnail').forEach(thumb => {
      thumb.addEventListener('click', (e) => {
        // Don't trigger if clicking the icon
        if (e.target.closest('.filter-icon')) return
        
        const filterName = thumb.dataset.filter
        
        // Update selected filter index for keyboard navigation
        this.selectedFilterIndex = this.filterNames.indexOf(filterName)
        
        // Remove selection from previous thumbnail
        if (this.selectedFilterThumbnail) {
          const prevBorder = this.selectedFilterThumbnail.querySelector('.filter-border')
          const prevIcon = this.selectedFilterThumbnail.querySelector('.filter-icon')
          if (prevBorder) prevBorder.classList.add('hidden')
          if (prevIcon) prevIcon.classList.add('hidden')
        }
        
        // Show border and icon on clicked thumbnail
        const border = thumb.querySelector('.filter-border')
        const icon = thumb.querySelector('.filter-icon')
        if (border) border.classList.remove('hidden')
        if (icon) icon.classList.remove('hidden')
        
        this.selectedFilterThumbnail = thumb
        this.filterIntensity = 100  // Reset intensity to 100%
        this.applyFilter(filterName, 100)  // Pass 100 explicitly
      })
    })
  }

  filterFilters(event) {
    const searchTerm = event.target.value.toLowerCase().trim()
    
    // Show all if less than 2 characters
    if (searchTerm.length < 2) {
      this.filterGridTarget.querySelectorAll('.filter-thumbnail').forEach(thumb => {
        thumb.style.display = ''
      })
      return
    }
    
    // Filter thumbnails based on search
    this.filterGridTarget.querySelectorAll('.filter-thumbnail').forEach(thumb => {
      const filterName = thumb.dataset.filter
      const filterData = ImageFilters.getFilterData(filterName)
      const displayName = filterData.name.toLowerCase()
      
      if (displayName.includes(searchTerm)) {
        thumb.style.display = ''
      } else {
        thumb.style.display = 'none'
      }
    })
  }

  generateFilterThumbnail(canvas, filterName) {
    const size = 120
    canvas.width = size
    canvas.height = size

    const ctx = canvas.getContext('2d')
    
    // Calculate scaling to fit original image into thumbnail
    const scale = Math.min(size / this.originalImage.width, size / this.originalImage.height)
    const w = this.originalImage.width * scale
    const h = this.originalImage.height * scale
    const x = (size - w) / 2
    const y = (size - h) / 2

    // Apply filter
    const filterData = ImageFilters.getFilterData(filterName)
    ctx.filter = filterData.css
    ctx.drawImage(this.originalImage, x, y, w, h)
  }

  applyFilter(filterName, intensity = this.filterIntensity, skipHistory = false) {
    this.selectedFilter = filterName
    this.filterIntensity = intensity
    
    const canvas = this.virtualCanvasTarget
    const ctx = canvas.getContext('2d')
    
    if (filterName === 'Normal') {
      // Draw original image
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      ctx.drawImage(this.originalImage, 0, 0)
    } else {
      const filterData = ImageFilters.getFilterData(filterName)
      
      // Create temp canvas and apply filter
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = this.originalImage.width
      tempCanvas.height = this.originalImage.height
      const tempCtx = tempCanvas.getContext('2d')
      tempCtx.filter = filterData.css
      tempCtx.drawImage(this.originalImage, 0, 0)

      // Draw original image first (base layer)
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      ctx.globalAlpha = 1
      ctx.drawImage(this.originalImage, 0, 0)

      // Blend filtered image on top with intensity (0-100%)
      if (intensity > 0) {
        ctx.globalAlpha = intensity / 100
        ctx.drawImage(tempCanvas, 0, 0)
        ctx.globalAlpha = 1
      }

      // Store filtered canvas as base for advanced tab
      this.advancedBaseImage = this.cloneCanvas(tempCanvas)
    }

    // Save to history only if not skipped
    if (!skipHistory) {
      this.saveToHistory()
    }
  }

  cloneCanvas(sourceCanvas) {
    const clone = document.createElement('canvas')
    clone.width = sourceCanvas.width
    clone.height = sourceCanvas.height
    clone.getContext('2d').drawImage(sourceCanvas, 0, 0)
    return clone
  }

  showFilterPopover(event) {
    event.stopPropagation()
    
    const filterName = this.selectedFilterThumbnail?.dataset.filter
    if (!filterName) return
    
    // Toggle visibility
    if (!this.filterPopoverTarget.classList.contains('hidden')) {
      // Already visible, hide it
      this.filterPopoverTarget.classList.add('hidden')
      return
    }
    
    // Get the display name from ImageFilters
    const filterData = ImageFilters.getFilterData(filterName)
    const displayName = filterData ? filterData.name : filterName
    
    // Update popover content with current filter intensity
    this.popoverFilterNameTarget.textContent = displayName
    this.dryWetSliderTarget.value = this.filterIntensity || 100
    this.dryWetValueTarget.textContent = `${this.filterIntensity || 100}%`
    
    // Position popover above the icon, centered
    if (this.selectedFilterThumbnail) {
      const thumbRect = this.selectedFilterThumbnail.getBoundingClientRect()
      const editorRect = this.element.getBoundingClientRect()
      const popover = this.filterPopoverTarget
      
      // Get icon element position (bottom-left of thumbnail)
      const iconElement = this.selectedFilterThumbnail.querySelector('.filter-icon')
      if (!iconElement) return
      
      const iconRect = iconElement.getBoundingClientRect()
      
      // Get icon center position
      const iconCenterX = iconRect.left - editorRect.left + (iconRect.width / 2)
      const iconTop = iconRect.top - editorRect.top
      
      // Center popover horizontally on icon center
      const popoverWidth = 200
      const left = iconCenterX - (popoverWidth / 2)
      
      // Position directly above icon
      const gap = 8  // Small gap for the caret
      const popoverHeight = 110  // Reduced from 120
      const top = iconTop - popoverHeight - gap
      
      popover.style.top = `${top}px`
      popover.style.left = `${left}px`
    }
    
    // Show popover
    this.filterPopoverTarget.classList.remove('hidden')
  }
  
  closeFilterPopover(event) {
    // Don't close the popover if it's not visible
    if (this.filterPopoverTarget.classList.contains('hidden')) return
    
    // Close if clicking anywhere EXCEPT directly on the slider thumb
    if (!event.target.matches('input[type="range"]')) {
      this.filterPopoverTarget.classList.add('hidden')
    }
  }

  updateDryWet(event) {
    const newIntensity = parseInt(event.target.value)
    this.filterIntensity = newIntensity
    this.dryWetValueTarget.textContent = `${newIntensity}%`
    
    if (this.selectedFilter && this.selectedFilter !== 'normal') {
      this.applyFilter(this.selectedFilter, newIntensity, true)  // Skip history
    }
  }

  // CROP TAB
  async initCropper() {
    await this.loadCropperJS()

    if (this.cropper) {
      this.cropper.destroy()
    }

    this.cropper = new Cropper(this.virtualCanvasTarget, {
      viewMode: 1,
      dragMode: 'move',
      autoCropArea: 1,
      restore: false,
      modal: true,
      guides: true,
      highlight: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
    })
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  changeAspectRatio(event) {
    if (!this.cropper) return

    const value = event.target.value
    if (value === 'free') {
      this.cropper.setAspectRatio(NaN)
    } else {
      this.cropper.setAspectRatio(parseFloat(value))
    }
  }

  applyCrop() {
    if (!this.cropper) return

    const croppedCanvas = this.cropper.getCroppedCanvas()
    
    // Update virtual canvas
    const canvas = this.virtualCanvasTarget
    canvas.width = croppedCanvas.width
    canvas.height = croppedCanvas.height
    canvas.getContext('2d').drawImage(croppedCanvas, 0, 0)

    // Destroy cropper and save to history
    this.destroyCropper()
    this.saveToHistory()

    // Switch back to filters tab
    this.switchTab({ target: { dataset: { tab: 'filters' } } })
  }

  // SCALE TAB
  updateScaleInputs() {
    this.scaleWidthTarget.value = this.virtualCanvasTarget.width
    this.scaleHeightTarget.value = this.virtualCanvasTarget.height
  }

  updateScaleHeight(event) {
    if (!this.lockAspectTarget.checked) return

    const width = parseInt(this.scaleWidthTarget.value)
    const canvas = this.virtualCanvasTarget
    const aspectRatio = canvas.width / canvas.height
    this.scaleHeightTarget.value = Math.round(width / aspectRatio)
  }

  updateScaleWidth(event) {
    if (!this.lockAspectTarget.checked) return

    const height = parseInt(this.scaleHeightTarget.value)
    const canvas = this.virtualCanvasTarget
    const aspectRatio = canvas.width / canvas.height
    this.scaleWidthTarget.value = Math.round(height * aspectRatio)
  }

  applyScale() {
    const newWidth = parseInt(this.scaleWidthTarget.value)
    const newHeight = parseInt(this.scaleHeightTarget.value)

    if (!newWidth || !newHeight) {
      alert('Please enter valid dimensions')
      return
    }

    // Create scaled canvas
    const scaledCanvas = document.createElement('canvas')
    scaledCanvas.width = newWidth
    scaledCanvas.height = newHeight

    const ctx = scaledCanvas.getContext('2d')
    ctx.drawImage(this.virtualCanvasTarget, 0, 0, newWidth, newHeight)

    // Update virtual canvas
    const canvas = this.virtualCanvasTarget
    canvas.width = newWidth
    canvas.height = newHeight
    canvas.getContext('2d').drawImage(scaledCanvas, 0, 0)

    // Save to history
    this.saveToHistory()
    this.switchTab({ target: { dataset: { tab: 'filters' } } })
  }

  // ROTATION TAB
  rotateLeft(event) {
    if (event) event.preventDefault()
    this.rotateImage(-90)
  }

  rotateRight(event) {
    if (event) event.preventDefault()
    this.rotateImage(90)
  }

  rotate180(event) {
    if (event) event.preventDefault()
    this.rotateImage(180)
  }

  rotateImage(degrees) {
    const canvas = this.virtualCanvasTarget
    const rotatedCanvas = document.createElement('canvas')

    if (degrees === 90 || degrees === -90) {
      rotatedCanvas.width = canvas.height
      rotatedCanvas.height = canvas.width
    } else {
      rotatedCanvas.width = canvas.width
      rotatedCanvas.height = canvas.height
    }

    const ctx = rotatedCanvas.getContext('2d')
    ctx.translate(rotatedCanvas.width / 2, rotatedCanvas.height / 2)
    ctx.rotate((degrees * Math.PI) / 180)
    ctx.drawImage(canvas, -canvas.width / 2, -canvas.height / 2)

    // Update virtual canvas
    canvas.width = rotatedCanvas.width
    canvas.height = rotatedCanvas.height
    canvas.getContext('2d').drawImage(rotatedCanvas, 0, 0)

    this.saveToHistory()
  }

  flipHorizontal(event) {
    if (event) event.preventDefault()
    this.flipImage('horizontal')
  }

  flipVertical(event) {
    if (event) event.preventDefault()
    this.flipImage('vertical')
  }

  flipImage(direction) {
    const canvas = this.virtualCanvasTarget
    const flippedCanvas = document.createElement('canvas')
    flippedCanvas.width = canvas.width
    flippedCanvas.height = canvas.height

    const ctx = flippedCanvas.getContext('2d')
    
    if (direction === 'horizontal') {
      ctx.translate(canvas.width, 0)
      ctx.scale(-1, 1)
    } else {
      ctx.translate(0, canvas.height)
      ctx.scale(1, -1)
    }

    ctx.drawImage(canvas, 0, 0)

    // Update virtual canvas
    canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height)
    canvas.getContext('2d').drawImage(flippedCanvas, 0, 0)

    this.saveToHistory()
  }

  initializeVirtualImage(img) {
    const canvas = this.virtualCanvasTarget
    canvas.width = img.width
    canvas.height = img.height

    const ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0)

    this.virtualImage = canvas

    // Store original for advanced tab reset
    this.originalVirtualImage = img

    // Save initial state to history
    this.saveToHistory()
  }

  updateAdvanced(event) {
    // Update displayed values
    this.brightnessValueTarget.textContent = this.brightnessSliderTarget.value + '%'
    this.contrastValueTarget.textContent = this.contrastSliderTarget.value + '%'
    this.saturationValueTarget.textContent = this.saturationSliderTarget.value + '%'
    this.hueValueTarget.textContent = this.hueSliderTarget.value + '°'
    this.vibranceValueTarget.textContent = this.vibranceSliderTarget.value
    this.blurValueTarget.textContent = this.blurSliderTarget.value + 'px'
    this.sharpenValueTarget.textContent = this.sharpenSliderTarget.value
    this.vignetteValueTarget.textContent = this.vignetteSliderTarget.value + '%'
    this.temperatureValueTarget.textContent = this.temperatureSliderTarget.value
    this.tintValueTarget.textContent = this.tintSliderTarget.value
    this.highlightsValueTarget.textContent = this.highlightsSliderTarget.value + '%'
    this.shadowsValueTarget.textContent = this.shadowsSliderTarget.value + '%'
    this.whitesValueTarget.textContent = this.whitesSliderTarget.value + '%'
    this.blacksValueTarget.textContent = this.blacksSliderTarget.value + '%'
    this.exposureValueTarget.textContent = this.exposureSliderTarget.value

    // Detail section values
    this.sharpeningValueTarget.textContent = this.sharpeningSliderTarget.value
    // Radius: map 0→0.5px, 50→1.0px, 100→3.0px
    const radiusValue = parseInt(this.radiusSliderTarget.value)
    let radiusPx
    if (radiusValue === 0) {
      radiusPx = 0.5
    } else if (radiusValue === 50) {
      radiusPx = 1.0
    } else if (radiusValue < 50) {
      radiusPx = 0.5 + (radiusValue / 50) * 0.5 // 0.5 to 1.0
    } else {
      radiusPx = 1.0 + ((radiusValue - 50) / 50) * 2.0 // 1.0 to 3.0
    }
    this.radiusValueTarget.textContent = radiusPx.toFixed(1)
    this.sharpeningDetailValueTarget.textContent = this.sharpeningDetailSliderTarget.value
    this.maskingValueTarget.textContent = this.maskingSliderTarget.value
    
    this.noiseReductionValueTarget.textContent = this.noiseReductionSliderTarget.value
    this.noiseDetailValueTarget.textContent = this.noiseDetailSliderTarget.value
    this.noiseContrastValueTarget.textContent = this.noiseContrastSliderTarget.value
    
    this.colorNoiseReductionValueTarget.textContent = this.colorNoiseReductionSliderTarget.value
    this.colorNoiseDetailValueTarget.textContent = this.colorNoiseDetailSliderTarget.value
    this.smoothnessValueTarget.textContent = this.smoothnessSliderTarget.value

    // Enable/disable child sliders based on parent values
    const sharpening = parseInt(this.sharpeningSliderTarget.value)
    const noiseReduction = parseInt(this.noiseReductionSliderTarget.value)
    const colorNoiseReduction = parseInt(this.colorNoiseReductionSliderTarget.value)

    // Sharpening children
    this.radiusSliderTarget.disabled = sharpening === 0
    this.sharpeningDetailSliderTarget.disabled = sharpening === 0
    this.maskingSliderTarget.disabled = sharpening === 0
    
    // Noise Reduction children
    this.noiseDetailSliderTarget.disabled = noiseReduction === 0
    this.noiseContrastSliderTarget.disabled = noiseReduction === 0
    
    // Color Noise Reduction children
    this.colorNoiseDetailSliderTarget.disabled = colorNoiseReduction === 0
    this.smoothnessSliderTarget.disabled = colorNoiseReduction === 0

    // Update opacity of disabled sliders
    const updateSliderOpacity = (slider, value) => {
      const item = slider.closest('.image-editor-slider-item')
      if (item) {
        const labels = item.querySelectorAll('.image-editor-slider-name, .image-editor-slider-value')
        labels.forEach(label => {
          label.style.opacity = slider.disabled ? '0.6' : '1'
        })
      }
    }

    updateSliderOpacity(this.radiusSliderTarget, radiusValue)
    updateSliderOpacity(this.sharpeningDetailSliderTarget, this.sharpeningDetailSliderTarget.value)
    updateSliderOpacity(this.maskingSliderTarget, this.maskingSliderTarget.value)
    updateSliderOpacity(this.noiseDetailSliderTarget, this.noiseDetailSliderTarget.value)
    updateSliderOpacity(this.noiseContrastSliderTarget, this.noiseContrastSliderTarget.value)
    updateSliderOpacity(this.colorNoiseDetailSliderTarget, this.colorNoiseDetailSliderTarget.value)
    updateSliderOpacity(this.smoothnessSliderTarget, this.smoothnessSliderTarget.value)

    // Store current state
    this.advancedState = {
      brightness: parseInt(this.brightnessSliderTarget.value),
      contrast: parseInt(this.contrastSliderTarget.value),
      saturation: parseInt(this.saturationSliderTarget.value),
      hue: parseInt(this.hueSliderTarget.value),
      vibrance: parseInt(this.vibranceSliderTarget.value),
      blur: parseInt(this.blurSliderTarget.value),
      sharpen: parseInt(this.sharpenSliderTarget.value),
      vignette: parseInt(this.vignetteSliderTarget.value),
      temperature: parseInt(this.temperatureSliderTarget.value),
      tint: parseInt(this.tintSliderTarget.value),
      highlights: parseInt(this.highlightsSliderTarget.value),
      shadows: parseInt(this.shadowsSliderTarget.value),
      whites: parseInt(this.whitesSliderTarget.value),
      blacks: parseInt(this.blacksSliderTarget.value),
      exposure: parseInt(this.exposureSliderTarget.value),
      sharpening: parseInt(this.sharpeningSliderTarget.value),
      radius: radiusPx, // Store as actual pixel value (0.5-3.0)
      sharpeningDetail: parseInt(this.sharpeningDetailSliderTarget.value),
      masking: parseInt(this.maskingSliderTarget.value),
      noiseReduction: parseInt(this.noiseReductionSliderTarget.value),
      noiseDetail: parseInt(this.noiseDetailSliderTarget.value),
      noiseContrast: parseInt(this.noiseContrastSliderTarget.value),
      colorNoiseReduction: parseInt(this.colorNoiseReductionSliderTarget.value),
      colorNoiseDetail: parseInt(this.colorNoiseDetailSliderTarget.value),
      smoothness: parseInt(this.smoothnessSliderTarget.value)
    }

    // Debounce expensive filter application for smooth slider interaction
    if (this.updateAdvancedTimeout) {
      clearTimeout(this.updateAdvancedTimeout)
    }
    
    this.updateAdvancedTimeout = setTimeout(() => {
      // Apply filters to virtual canvas after slider movement stops
      this.applyAdvancedFilters()
      this.updateAdvancedTimeout = null
    }, 50) // 50ms delay for debouncing
  }

  applyAdvancedFilters() {
    const brightness = this.advancedState.brightness
    const contrast = this.advancedState.contrast
    const saturation = this.advancedState.saturation
    const hue = this.advancedState.hue
    const vibrance = this.advancedState.vibrance || 0
    const blur = this.advancedState.blur
    const vignette = this.advancedState.vignette || 0  // Ensure 0 if undefined
    const temperature = this.advancedState.temperature
    const tint = this.advancedState.tint
    const shadows = this.advancedState.shadows
    const highlights = this.advancedState.highlights
    const exposure = this.advancedState.exposure
    const whites = this.advancedState.whites || 50
    const blacks = this.advancedState.blacks || 50

    // Detail section values
    const sharpening = this.advancedState.sharpening || 0
    const radius = this.advancedState.radius || 1.0
    const sharpeningDetail = this.advancedState.sharpeningDetail || 50
    const masking = this.advancedState.masking || 0
    const noiseReduction = this.advancedState.noiseReduction || 0
    const noiseDetail = this.advancedState.noiseDetail || 50
    const noiseContrast = this.advancedState.noiseContrast || 50
    const colorNoiseReduction = this.advancedState.colorNoiseReduction || 0
    const colorNoiseDetail = this.advancedState.colorNoiseDetail || 50
    const smoothness = this.advancedState.smoothness || 50

    // Build filter string for CSS-supported filters
    const filters = [
      `brightness(${brightness}%)`,
      `contrast(${contrast}%)`,
      `saturate(${saturation}%)`,
      `hue-rotate(${hue}deg)`,
      blur > 0 ? `blur(${blur}px)` : ''
    ].filter(f => f).join(' ')

    // Use advancedBaseImage if it exists (after filter), otherwise use original
    const sourceImage = this.advancedBaseImage || this.originalImage

    const canvas = this.virtualCanvasTarget
    const tempCanvas = document.createElement('canvas')
    tempCanvas.width = sourceImage.width
    tempCanvas.height = sourceImage.height

    const tempCtx = tempCanvas.getContext('2d', { willReadFrequently: true })
    tempCtx.filter = filters
    tempCtx.drawImage(sourceImage, 0, 0)

    // Apply Detail section processing: Color Noise Reduction (first), then Noise Reduction (luminance)
    let imgData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
    let data = imgData.data
    
    // Color Noise Reduction - smooth chrominance noise
    if (colorNoiseReduction > 0) {
      const strength = (colorNoiseReduction / 100) * 0.7 // Reduce overall strength by 30%
      const detail = colorNoiseDetail / 100 // Higher = preserve more detail
      const smoothnessFactor = smoothness / 100 // Higher = smoother
      const radius = Math.max(1, Math.min(3, Math.floor(1 + smoothnessFactor * 2))) // Max 3px radius
      
      const width = tempCanvas.width
      const height = tempCanvas.height
      const newData = new Uint8ClampedArray(data)
      
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const idx = (y * width + x) * 4
          let sumR = 0, sumG = 0, sumB = 0, count = 0
          
          // Average neighboring pixels within radius
          for (let dy = -radius; dy <= radius; dy++) {
            for (let dx = -radius; dx <= radius; dx++) {
              const nx = x + dx
              const ny = y + dy
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                const nIdx = (ny * width + nx) * 4
                sumR += data[nIdx]
                sumG += data[nIdx + 1]
                sumB += data[nIdx + 2]
                count++
              }
            }
          }
          
          if (count > 0) {
            const avgR = sumR / count
            const avgG = sumG / count
            const avgB = sumB / count
            
            // Blend original with average based on strength and detail
            const originalR = data[idx]
            const originalG = data[idx + 1]
            const originalB = data[idx + 2]
            
            // Preserve detail: if color difference is large, apply less smoothing
            // Improved calculation to prevent artifacts when detail is high
            const colorDiff = Math.abs(originalR - avgR) + Math.abs(originalG - avgG) + Math.abs(originalB - avgB)
            const maxDiff = 255 * 3 // Maximum possible difference
            const detailThreshold = maxDiff * 0.2 * (1 - detail) + maxDiff * 0.05 // Minimum threshold to prevent artifacts
            const detailPreservation = Math.min(1, colorDiff / detailThreshold)
            const effectiveStrength = strength * (1 - detailPreservation * 0.8) // Cap detail preservation
            
            newData[idx] = originalR + (avgR - originalR) * effectiveStrength
            newData[idx + 1] = originalG + (avgG - originalG) * effectiveStrength
            newData[idx + 2] = originalB + (avgB - originalB) * effectiveStrength
            newData[idx + 3] = data[idx + 3] // Preserve alpha
          }
        }
      }
      
      // Create new ImageData with processed data
      imgData = new ImageData(newData, tempCanvas.width, tempCanvas.height)
      tempCtx.putImageData(imgData, 0, 0)
      imgData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
      data = imgData.data
    }
    
    // Noise Reduction (Luminance) - bilateral filter approach
    if (noiseReduction > 0) {
      // Get fresh imageData in case color noise reduction was applied
      imgData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
      data = imgData.data
      
      const strength = noiseReduction / 100
      const detail = noiseDetail / 100 // Higher = preserve more detail
      const contrastPreserve = noiseContrast / 100 // Higher = preserve more local contrast
      const radius = 2 // Fixed radius for stable bilateral filtering
      
      const width = tempCanvas.width
      const height = tempCanvas.height
      const newData = new Uint8ClampedArray(data)
      
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const idx = (y * width + x) * 4
          const r = data[idx]
          const g = data[idx + 1]
          const b = data[idx + 2]
          const lum = r * 0.299 + g * 0.587 + b * 0.114
          
          let sum = 0, weightSum = 0
          
          // Sample neighboring pixels
          for (let dy = -radius; dy <= radius; dy++) {
            for (let dx = -radius; dx <= radius; dx++) {
              const nx = x + dx
              const ny = y + dy
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                const nIdx = (ny * width + nx) * 4
                const nR = data[nIdx]
                const nG = data[nIdx + 1]
                const nB = data[nIdx + 2]
                const nLum = nR * 0.299 + nG * 0.587 + nB * 0.114
                
                // Weight based on luminance similarity (bilateral)
                const lumDiff = Math.abs(lum - nLum)
                const weight = Math.exp(-(lumDiff * lumDiff) / (2 * (255 * 255 * (1 - strength * (1 - detail)))))
                
                sum += nLum * weight
                weightSum += weight
              }
            }
          }
          
          if (weightSum > 0) {
            const smoothLum = sum / weightSum
            const lumDiff = Math.abs(lum - smoothLum)
            
            // Preserve detail: if luminance difference is large, apply less smoothing
            const detailPreservation = Math.min(1, lumDiff / (255 * (1 - detail)))
            const effectiveStrength = strength * (1 - detailPreservation)
            
            // Apply luminance smoothing
            const newLum = lum + (smoothLum - lum) * effectiveStrength
            
            // Preserve local contrast
            const contrastFactor = 1 + (lumDiff / 255) * contrastPreserve * 0.5
            
            // Convert back to RGB maintaining color ratios
            const ratio = newLum / (lum || 0.001)
            let newR = r * ratio * contrastFactor
            let newG = g * ratio * contrastFactor
            let newB = b * ratio * contrastFactor
            
            newData[idx] = Math.max(0, Math.min(255, newR))
            newData[idx + 1] = Math.max(0, Math.min(255, newG))
            newData[idx + 2] = Math.max(0, Math.min(255, newB))
            newData[idx + 3] = data[idx + 3] // Preserve alpha
          }
        }
      }
      
      // Create new ImageData with processed data
      imgData = new ImageData(newData, tempCanvas.width, tempCanvas.height)
      tempCtx.putImageData(imgData, 0, 0)
    }

    // Apply pixel-level adjustments (exposure, temperature, tint, vibrance, shadows, highlights, whites, blacks)
    if (exposure !== 0 || temperature !== 0 || tint !== 0 || vibrance !== 0 || shadows !== 100 || highlights !== 100 || whites !== 50 || blacks !== 50) {
      // Get fresh imageData in case noise reduction or color noise reduction was applied
      imgData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
      const data = imgData.data
      
      for (let i = 0; i < data.length; i += 4) {
        let r = data[i]
        let g = data[i + 1]
        let b = data[i + 2]
        
        // Exposure adjustment
        if (exposure !== 0) {
          const expFactor = Math.pow(2, exposure / 100)
          r = Math.min(255, r * expFactor)
          g = Math.min(255, g * expFactor)
          b = Math.min(255, b * expFactor)
        }
        
        // Temperature (warm/cool) - adjust red and blue channels
        if (temperature !== 0) {
          const temp = temperature / 100
          r = Math.min(255, Math.max(0, r + temp * 10))
          b = Math.min(255, Math.max(0, b - temp * 10))
        }
        
        // Tint (green/magenta) - adjust green channel
        if (tint !== 0) {
          const tintValue = tint / 100
          g = Math.min(255, Math.max(0, g + tintValue * 10))
        }
        
        // Vibrance adjustment (boosts muted colors more than vivid colors)
        if (vibrance !== 0) {
          // Calculate current saturation
          const max = Math.max(r, g, b)
          const min = Math.min(r, g, b)
          const currentSaturation = max === 0 ? 0 : (max - min) / max
          
          // Vibrance applies more to less saturated colors
          // Less saturated pixels get more adjustment
          const vibranceFactor = vibrance / 100
          const saturationBoost = (1 - currentSaturation) * vibranceFactor
          
          if (saturationBoost !== 0 && max > 0) {
            // Adjust RGB to increase/decrease saturation
            const avg = (r + g + b) / 3
            const adjustment = saturationBoost * 0.5 // Scale down for subtle effect
            
            r = Math.min(255, Math.max(0, r + (r - avg) * adjustment))
            g = Math.min(255, Math.max(0, g + (g - avg) * adjustment))
            b = Math.min(255, Math.max(0, b + (b - avg) * adjustment))
          }
        }
        
        // Calculate pixel brightness (luminance) - needed for shadows, highlights, whites, and blacks
        const luminance = (r * 0.299 + g * 0.587 + b * 0.114) / 255
        
        // Shadows and highlights
        if (shadows !== 100 || highlights !== 100) {
          
          // Shadows adjustment (affects darker pixels)
          if (shadows !== 100 && luminance < 0.5) {
            const shadowFactor = shadows / 100
            const shadowAmount = (0.5 - luminance) / 0.5 * (1 - shadowFactor)
            r = r * (1 - shadowAmount)
            g = g * (1 - shadowAmount)
            b = b * (1 - shadowAmount)
          }
          
          // Highlights adjustment (affects brighter pixels)
          if (highlights !== 100 && luminance >= 0.5) {
            const highlightFactor = highlights / 100
            const highlightAmount = (luminance - 0.5) / 0.5 * (1 - highlightFactor)
            r = Math.min(255, r + (255 - r) * highlightAmount)
            g = Math.min(255, g + (255 - g) * highlightAmount)
            b = Math.min(255, b + (255 - b) * highlightAmount)
          }
        }
        
        // Recalculate luminance after shadows/highlights adjustments for whites/blacks
        let finalLuminance = luminance
        if (whites !== 50 || blacks !== 50) {
          finalLuminance = (r * 0.299 + g * 0.587 + b * 0.114) / 255
        }
        
        // Whites adjustment (brightest tones)
        if (whites !== 50 && finalLuminance >= 0.7) {
          const whitesFactor = (whites - 50) / 50  // -1 to 1
          const whitesAmount = ((finalLuminance - 0.7) / 0.3) * whitesFactor
          r = Math.min(255, Math.max(0, r + whitesAmount * 50))
          g = Math.min(255, Math.max(0, g + whitesAmount * 50))
          b = Math.min(255, Math.max(0, b + whitesAmount * 50))
        }
        
        // Blacks adjustment (darkest tones)
        if (blacks !== 50 && finalLuminance <= 0.3) {
          const blacksFactor = (blacks - 50) / 50  // -1 to 1
          const blacksAmount = ((0.3 - finalLuminance) / 0.3) * blacksFactor
          r = Math.min(255, Math.max(0, r - blacksAmount * 50))
          g = Math.min(255, Math.max(0, g - blacksAmount * 50))
          b = Math.min(255, Math.max(0, b - blacksAmount * 50))
        }
        
        data[i] = Math.max(0, Math.min(255, r))
        data[i + 1] = Math.max(0, Math.min(255, g))
        data[i + 2] = Math.max(0, Math.min(255, b))
      }
      
      tempCtx.putImageData(imgData, 0, 0)
    }

    // Apply Sharpening (unsharp mask) - last step for crisp results
    if (sharpening > 0) {
      const effectiveRadius = radius > 0 ? radius : 1.0 // Use default if radius is invalid
      const strength = sharpening / 100
      const radiusPx = effectiveRadius // Already in pixel units (0.5-3.0)
      const detail = sharpeningDetail / 100 // Higher = affects finer details
      const maskingAmount = masking / 100 // Higher = only edges sharpened
      
      // Get current image data (after all previous processing)
      imgData = tempCtx.getImageData(0, 0, tempCanvas.width, tempCanvas.height)
      const originalData = new Uint8ClampedArray(imgData.data) // Keep original for blur calculation
      data = imgData.data
      const width = tempCanvas.width
      const height = tempCanvas.height
      
      // Simple box blur for unsharp mask
      const blurRadius = Math.max(1, Math.floor(radiusPx))
      const blurData = new Uint8ClampedArray(originalData.length)
      
      // Apply box blur to original data
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          let sumR = 0, sumG = 0, sumB = 0, sumA = 0, count = 0
          
          for (let dy = -blurRadius; dy <= blurRadius; dy++) {
            for (let dx = -blurRadius; dx <= blurRadius; dx++) {
              const nx = x + dx
              const ny = y + dy
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                const nIdx = (ny * width + nx) * 4
                sumR += originalData[nIdx]
                sumG += originalData[nIdx + 1]
                sumB += originalData[nIdx + 2]
                sumA += originalData[nIdx + 3]
                count++
              }
            }
          }
          
          const idx = (y * width + x) * 4
          blurData[idx] = sumR / count
          blurData[idx + 1] = sumG / count
          blurData[idx + 2] = sumB / count
          blurData[idx + 3] = sumA / count
        }
      }
      
      // Calculate edge mask and apply unsharp mask
      const newData = new Uint8ClampedArray(data)
      
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const idx = (y * width + x) * 4
          
          // Get original and blurred values
          const originalR = originalData[idx]
          const originalG = originalData[idx + 1]
          const originalB = originalData[idx + 2]
          const originalLum = originalR * 0.299 + originalG * 0.587 + originalB * 0.114
          
          const blurR = blurData[idx]
          const blurG = blurData[idx + 1]
          const blurB = blurData[idx + 2]
          
          // Calculate edge strength (local variance) for masking using original data
          let edgeStrength = 0
          const sampleSize = Math.max(1, Math.floor(radiusPx))
          let maxDiff = 0
          
          for (let dy = -sampleSize; dy <= sampleSize; dy++) {
            for (let dx = -sampleSize; dx <= sampleSize; dx++) {
              const nx = x + dx
              const ny = y + dy
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                const nIdx = (ny * width + nx) * 4
                const nLum = originalData[nIdx] * 0.299 + originalData[nIdx + 1] * 0.587 + originalData[nIdx + 2] * 0.114
                maxDiff = Math.max(maxDiff, Math.abs(originalLum - nLum))
              }
            }
          }
          
          edgeStrength = maxDiff / 255
          
          // Apply masking: higher masking = only sharpen edges
          // masking = 0 means sharpen everywhere, masking = 100 means only sharp edges
          let maskFactor = 1
          if (maskingAmount > 0) {
            // When masking is high, only sharpen where edgeStrength is above threshold
            const threshold = 1 - maskingAmount // 0 (no mask) to 1 (full mask)
            if (edgeStrength < threshold) {
              maskFactor = 0 // Below threshold, don't sharpen
            } else {
              // Above threshold, scale from 0 to 1 based on how far above threshold
              maskFactor = (edgeStrength - threshold) / (1 - threshold || 0.001)
            }
          }
          
          // Adjust detail: detail affects which edges get sharpened
          // detail = 0 means only large edges (high edgeStrength threshold)
          // detail = 100 means fine edges too (low edgeStrength threshold, sharpen more)
          // Default detail = 50 means medium threshold
          // Map detail 0-100 to threshold 0.8-0.0 (inverse relationship)
          const detailThreshold = 0.8 * (1 - detail / 100) // 0.8 (detail=0) to 0.0 (detail=100)
          const detailFactor = edgeStrength >= detailThreshold ? 1 : 
            Math.max(0, edgeStrength / (detailThreshold || 0.001)) // Gradually fade in below threshold
          
          // Get current pixel (after previous adjustments) for unsharp mask
          const currentR = data[idx]
          const currentG = data[idx + 1]
          const currentB = data[idx + 2]
          
          // Calculate unsharp mask: current + (original - blurred) * strength
          const diffR = originalR - blurR
          const diffG = originalG - blurG
          const diffB = originalB - blurB
          
          // Apply sharpening with mask and detail factors
          const sharpeningAmount = strength * maskFactor * detailFactor * 1.0
          
          newData[idx] = Math.max(0, Math.min(255, currentR + diffR * sharpeningAmount))
          newData[idx + 1] = Math.max(0, Math.min(255, currentG + diffG * sharpeningAmount))
          newData[idx + 2] = Math.max(0, Math.min(255, currentB + diffB * sharpeningAmount))
          newData[idx + 3] = data[idx + 3] // Preserve alpha
        }
      }
      
      // Create new ImageData with processed data
      imgData = new ImageData(newData, tempCanvas.width, tempCanvas.height)
      tempCtx.putImageData(imgData, 0, 0)
    }

    // Apply vignette effect if needed
    if (vignette && vignette > 0) {
      // Use a more elliptical/rectangular vignette that covers all corners
      const intensity = Math.max(0, Math.min(1, vignette / 100))
      
      // Create a mask for vignette using multiple radial gradients
      const vignetteCanvas = document.createElement('canvas')
      vignetteCanvas.width = tempCanvas.width
      vignetteCanvas.height = tempCanvas.height
      const vignetteCtx = vignetteCanvas.getContext('2d')
      
      // Create radial gradient from center to corner
      const centerX = vignetteCanvas.width / 2
      const centerY = vignetteCanvas.height / 2
      
      // Calculate max distance from center to corner
      const maxRadius = Math.sqrt(
        (vignetteCanvas.width / 2) ** 2 + 
        (vignetteCanvas.height / 2) ** 2
      )
      
      // Create radial gradient
      const gradient = vignetteCtx.createRadialGradient(
        centerX, centerY, maxRadius * 0.4,  // Start fading at 40% from center
        centerX, centerY, maxRadius          // Full dark at edge
      )
      
      // Add color stops: transparent center, dark edges
      gradient.addColorStop(0, 'transparent')
      gradient.addColorStop(0.7, `rgba(0,0,0,${intensity * 0.5})`)  // Start darkening at 70%
      gradient.addColorStop(1, `rgba(0,0,0,${intensity})`)         // Full dark at edge
      
      // Fill the vignette canvas
      vignetteCtx.fillStyle = gradient
      vignetteCtx.fillRect(0, 0, vignetteCanvas.width, vignetteCanvas.height)
      
      // Apply vignette to the image using multiply blend mode
      tempCtx.globalCompositeOperation = 'multiply'
      tempCtx.globalAlpha = 1
      tempCtx.drawImage(vignetteCanvas, 0, 0)
      tempCtx.globalCompositeOperation = 'source-over'
      tempCtx.globalAlpha = 1
    }

    // Update virtual canvas with filtered result
    const ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(tempCanvas, 0, 0)
  }

  resetAdvanced() {
    this.brightnessSliderTarget.value = 100
    this.contrastSliderTarget.value = 100
    this.saturationSliderTarget.value = 100
    this.hueSliderTarget.value = 0
    this.vibranceSliderTarget.value = 0
    this.blurSliderTarget.value = 0
    this.sharpenSliderTarget.value = 0
    this.vignetteSliderTarget.value = 0
    this.temperatureSliderTarget.value = 0
    this.tintSliderTarget.value = 0
    this.highlightsSliderTarget.value = 100
    this.shadowsSliderTarget.value = 100
    this.whitesSliderTarget.value = 50
    this.blacksSliderTarget.value = 50
    this.exposureSliderTarget.value = 0

    // Detail section reset
    this.sharpeningSliderTarget.value = 0
    this.radiusSliderTarget.value = 50
    this.sharpeningDetailSliderTarget.value = 50
    this.maskingSliderTarget.value = 0
    this.noiseReductionSliderTarget.value = 0
    this.noiseDetailSliderTarget.value = 50
    this.noiseContrastSliderTarget.value = 50
    this.colorNoiseReductionSliderTarget.value = 0
    this.colorNoiseDetailSliderTarget.value = 50
    this.smoothnessSliderTarget.value = 50

    this.advancedState = {
      brightness: 100,
      contrast: 100,
      saturation: 100,
      hue: 0,
      vibrance: 0,
      blur: 0,
      sharpen: 0,
      vignette: 0,
      temperature: 0,
      tint: 0,
      highlights: 100,
      shadows: 100,
      whites: 50,
      blacks: 50,
      exposure: 0,
      sharpening: 0,
      radius: 1.0,
      sharpeningDetail: 50,
      masking: 0,
      noiseReduction: 0,
      noiseDetail: 50,
      noiseContrast: 50,
      colorNoiseReduction: 0,
      colorNoiseDetail: 50,
      smoothness: 50
    }

    // Reset virtual canvas to base (with filter if applied, otherwise original)
    const canvas = this.virtualCanvasTarget
    const sourceImage = this.advancedBaseImage || this.originalImage
    canvas.width = sourceImage.width
    canvas.height = sourceImage.height
    canvas.getContext('2d').drawImage(sourceImage, 0, 0)

    // Clear any pending debounced filter update
    if (this.updateAdvancedTimeout) {
      clearTimeout(this.updateAdvancedTimeout)
      this.updateAdvancedTimeout = null
    }

    // Force synchronous update of all displays and states (skip debounce)
    // Update displayed values
    this.brightnessValueTarget.textContent = this.brightnessSliderTarget.value + '%'
    this.contrastValueTarget.textContent = this.contrastSliderTarget.value + '%'
    this.saturationValueTarget.textContent = this.saturationSliderTarget.value + '%'
    this.hueValueTarget.textContent = this.hueSliderTarget.value + '°'
    this.vibranceValueTarget.textContent = this.vibranceSliderTarget.value
    this.blurValueTarget.textContent = this.blurSliderTarget.value + 'px'
    this.sharpenValueTarget.textContent = this.sharpenSliderTarget.value
    this.vignetteValueTarget.textContent = this.vignetteSliderTarget.value + '%'
    this.temperatureValueTarget.textContent = this.temperatureSliderTarget.value
    this.tintValueTarget.textContent = this.tintSliderTarget.value
    this.highlightsValueTarget.textContent = this.highlightsSliderTarget.value + '%'
    this.shadowsValueTarget.textContent = this.shadowsSliderTarget.value + '%'
    this.whitesValueTarget.textContent = this.whitesSliderTarget.value + '%'
    this.blacksValueTarget.textContent = this.blacksSliderTarget.value + '%'
    this.exposureValueTarget.textContent = this.exposureSliderTarget.value

    // Detail section values
    this.sharpeningValueTarget.textContent = this.sharpeningSliderTarget.value
    const radiusValue = parseInt(this.radiusSliderTarget.value)
    let radiusPx
    if (radiusValue === 0) {
      radiusPx = 0.5
    } else if (radiusValue === 50) {
      radiusPx = 1.0
    } else if (radiusValue < 50) {
      radiusPx = 0.5 + (radiusValue / 50) * 0.5
    } else {
      radiusPx = 1.0 + ((radiusValue - 50) / 50) * 2.0
    }
    this.radiusValueTarget.textContent = radiusPx.toFixed(1)
    this.sharpeningDetailValueTarget.textContent = this.sharpeningDetailSliderTarget.value
    this.maskingValueTarget.textContent = this.maskingSliderTarget.value
    this.noiseReductionValueTarget.textContent = this.noiseReductionSliderTarget.value
    this.noiseDetailValueTarget.textContent = this.noiseDetailSliderTarget.value
    this.noiseContrastValueTarget.textContent = this.noiseContrastSliderTarget.value
    this.colorNoiseReductionValueTarget.textContent = this.colorNoiseReductionSliderTarget.value
    this.colorNoiseDetailValueTarget.textContent = this.colorNoiseDetailSliderTarget.value
    this.smoothnessValueTarget.textContent = this.smoothnessSliderTarget.value

    // Enable/disable child sliders based on parent values
    const sharpening = parseInt(this.sharpeningSliderTarget.value)
    const noiseReduction = parseInt(this.noiseReductionSliderTarget.value)
    const colorNoiseReduction = parseInt(this.colorNoiseReductionSliderTarget.value)

    // Sharpening children
    this.radiusSliderTarget.disabled = sharpening === 0
    this.sharpeningDetailSliderTarget.disabled = sharpening === 0
    this.maskingSliderTarget.disabled = sharpening === 0
    
    // Noise Reduction children
    this.noiseDetailSliderTarget.disabled = noiseReduction === 0
    this.noiseContrastSliderTarget.disabled = noiseReduction === 0
    
    // Color Noise Reduction children
    this.colorNoiseDetailSliderTarget.disabled = colorNoiseReduction === 0
    this.smoothnessSliderTarget.disabled = colorNoiseReduction === 0

    // Update opacity of disabled sliders
    const updateSliderOpacity = (slider) => {
      const item = slider.closest('.image-editor-slider-item')
      if (item) {
        const labels = item.querySelectorAll('.image-editor-slider-name, .image-editor-slider-value')
        labels.forEach(label => {
          label.style.opacity = slider.disabled ? '0.6' : '1'
        })
      }
    }

    updateSliderOpacity(this.radiusSliderTarget)
    updateSliderOpacity(this.sharpeningDetailSliderTarget)
    updateSliderOpacity(this.maskingSliderTarget)
    updateSliderOpacity(this.noiseDetailSliderTarget)
    updateSliderOpacity(this.noiseContrastSliderTarget)
    updateSliderOpacity(this.colorNoiseDetailSliderTarget)
    updateSliderOpacity(this.smoothnessSliderTarget)

    // Update all state from slider values
    this.advancedState.brightness = parseInt(this.brightnessSliderTarget.value)
    this.advancedState.contrast = parseInt(this.contrastSliderTarget.value)
    this.advancedState.saturation = parseInt(this.saturationSliderTarget.value)
    this.advancedState.hue = parseInt(this.hueSliderTarget.value)
    this.advancedState.vibrance = parseInt(this.vibranceSliderTarget.value)
    this.advancedState.blur = parseInt(this.blurSliderTarget.value)
    this.advancedState.sharpen = parseInt(this.sharpenSliderTarget.value)
    this.advancedState.vignette = parseInt(this.vignetteSliderTarget.value)
    this.advancedState.temperature = parseInt(this.temperatureSliderTarget.value)
    this.advancedState.tint = parseInt(this.tintSliderTarget.value)
    this.advancedState.highlights = parseInt(this.highlightsSliderTarget.value)
    this.advancedState.shadows = parseInt(this.shadowsSliderTarget.value)
    this.advancedState.whites = parseInt(this.whitesSliderTarget.value)
    this.advancedState.blacks = parseInt(this.blacksSliderTarget.value)
    this.advancedState.exposure = parseInt(this.exposureSliderTarget.value)
    this.advancedState.radius = radiusPx
    this.advancedState.sharpening = sharpening
    this.advancedState.sharpeningDetail = parseInt(this.sharpeningDetailSliderTarget.value)
    this.advancedState.masking = parseInt(this.maskingSliderTarget.value)
    this.advancedState.noiseReduction = noiseReduction
    this.advancedState.noiseDetail = parseInt(this.noiseDetailSliderTarget.value)
    this.advancedState.noiseContrast = parseInt(this.noiseContrastSliderTarget.value)
    this.advancedState.colorNoiseReduction = colorNoiseReduction
    this.advancedState.colorNoiseDetail = parseInt(this.colorNoiseDetailSliderTarget.value)
    this.advancedState.smoothness = parseInt(this.smoothnessSliderTarget.value)
    
    // Force immediate apply after update since this is a reset
    this.applyAdvancedFilters()
    
    // Save to history
    this.saveToHistory()
  }

  applyAdvanced() {
    // This method is now deprecated as we apply immediately
    // But keep it for the "Apply" button if we still need it
    this.saveToHistory()
  }

  // META TAB METHODS
  async loadMetadata() {
    if (!window.piexif) {
      console.error('piexif library not loaded')
      this.metaLoadingTarget.classList.add('hidden')
      this.metaEmptyTarget.classList.remove('hidden')
      return
    }
    
    try {
      this.metaLoadingTarget.classList.remove('hidden')
      this.metaEmptyTarget.classList.add('hidden')
      this.metaContentTarget.classList.add('hidden')
      
      // Strategy: prefer reading EXIF from the ORIGINAL image file, not the canvas
      // because canvas-generated data URLs strip EXIF. For same-origin URLs, fetch blob
      // and convert to data URL. If cross-origin (CORS not allowed), fall back to
      // showing no metadata.

      let exifObj
      const imageUrl = this.imageUrl
      let canAttemptFetch = false
      try {
        const u = new URL(imageUrl, window.location.origin)
        canAttemptFetch = (u.origin === window.location.origin)
      } catch (_) {
        canAttemptFetch = false
      }

      if (canAttemptFetch) {
        try {
          const resp = await fetch(imageUrl, { credentials: 'same-origin' })
          if (resp.ok) {
            const blob = await resp.blob()
            // Only JPEGs are expected to carry EXIF
            const isJpeg = /jpeg|jpg/i.test(blob.type)
            if (isJpeg) {
              const dataUrl = await new Promise(resolve => {
                const reader = new FileReader()
                reader.onload = () => resolve(reader.result)
                reader.readAsDataURL(blob)
              })
              try {
                exifObj = window.piexif.load(dataUrl)
              } catch (e) {
                exifObj = null
              }
            }
          }
        } catch (e) {
          // Ignore and fall through to no metadata
          exifObj = null
        }
      }

      // If we couldn't read EXIF from the original (or non-JPEG), consider last resort:
      // Attempt from canvas (likely stripped) – usually returns none.
      if (!exifObj) {
        try {
          const canvasDataUrl = this.virtualCanvasTarget.toDataURL('image/jpeg')
          exifObj = window.piexif.load(canvasDataUrl)
        } catch (e) {
          exifObj = null
        }
      }

      if (!exifObj) {
        this.metaLoadingTarget.classList.add('hidden')
        this.metaEmptyTarget.classList.remove('hidden')
        return
      }

      // Populate fields
      this.populateMetadataFields(exifObj)

      this.metaLoadingTarget.classList.add('hidden')
      this.metaContentTarget.classList.remove('hidden')
    } catch (error) {
      console.error('Error loading metadata:', error)
      this.metaLoadingTarget.classList.add('hidden')
      this.metaEmptyTarget.classList.remove('hidden')
    }
  }

  populateMetadataFields(exifObj) {
    const fields = this.metaContentTarget.querySelectorAll('[data-exif-field]')
    
    fields.forEach(field => {
      const exifField = field.dataset.exifField
      let value = ''
      
      // Check in different IFD sections
      if (exifObj['0th'] && exifObj['0th'][window.piexif.ImageIFD[exifField]]) {
        value = exifObj['0th'][window.piexif.ImageIFD[exifField]]
      } else if (exifObj['Exif'] && exifObj['Exif'][window.piexif.ExifIFD[exifField]]) {
        value = exifObj['Exif'][window.piexif.ExifIFD[exifField]]
      } else if (exifObj['GPS'] && exifObj['GPS'][window.piexif.GPSIFD[exifField]]) {
        value = exifObj['GPS'][window.piexif.GPSIFD[exifField]]
      }
      
      // Format value
      if (Array.isArray(value)) {
        value = value.join(', ')
      }
      
      field.value = value || ''
    })
    
    // Add change listeners to track modifications
    fields.forEach(field => {
      field.addEventListener('input', (e) => {
        this.metadataChanges[e.target.dataset.exifField] = e.target.value
      })
    })
  }

  clearAllMetadata() {
    const fields = this.metaContentTarget.querySelectorAll('[data-exif-field]')
    fields.forEach(field => {
      field.value = ''
      this.metadataChanges[field.dataset.exifField] = ''
    })
  }

  applyMetadataToImage(blob) {
    if (!window.piexif || Object.keys(this.metadataChanges).length === 0) {
      return Promise.resolve(blob)
    }
    
    return new Promise((resolve) => {
      const reader = new FileReader()
      reader.onload = () => {
        const dataUrl = reader.result
        
        try {
          // Load existing EXIF or create new
          let exifObj
          try {
            exifObj = window.piexif.load(dataUrl)
          } catch (e) {
            // Create empty EXIF object
            exifObj = {
              "0th": {},
              "Exif": {},
              "GPS": {},
              "Interop": {},
              "1st": {},
              "thumbnail": null
            }
          }
          
          // Apply changes
          Object.keys(this.metadataChanges).forEach(field => {
            const value = this.metadataChanges[field]
            
            if (window.piexif.ImageIFD[field] !== undefined) {
              if (value === '') {
                delete exifObj['0th'][window.piexif.ImageIFD[field]]
              } else {
                exifObj['0th'][window.piexif.ImageIFD[field]] = value
              }
            } else if (window.piexif.ExifIFD[field] !== undefined) {
              if (value === '') {
                delete exifObj['Exif'][window.piexif.ExifIFD[field]]
              } else {
                exifObj['Exif'][window.piexif.ExifIFD[field]] = value
              }
            } else if (window.piexif.GPSIFD[field] !== undefined) {
              if (value === '') {
                delete exifObj['GPS'][window.piexif.GPSIFD[field]]
              } else {
                exifObj['GPS'][window.piexif.GPSIFD[field]] = value
              }
            }
          })
          
          // Insert EXIF into image
          const exifBytes = window.piexif.dump(exifObj)
          const newDataUrl = window.piexif.insert(exifBytes, dataUrl)
          
          // Convert back to blob
          fetch(newDataUrl)
            .then(res => res.blob())
            .then(resolve)
        } catch (error) {
          console.error('Error applying metadata:', error)
          resolve(blob) // Return original blob if metadata fails
        }
      }
      reader.readAsDataURL(blob)
    })
  }

  // SAVE
  async saveEdits(event) {
    if (event) event.preventDefault()

    // Prevent double submissions
    if (this.isSaving) return
    this.isSaving = true
    const saveButton = event && event.currentTarget ? event.currentTarget : null
    if (saveButton) {
      saveButton.disabled = true
      try { saveButton.classList.add('opacity-50', 'cursor-not-allowed') } catch(_) {}
    }

    try {
      // Get final canvas
      const canvas = this.virtualCanvasTarget

      // Convert to blob
      let blob = await new Promise(resolve => {
        canvas.toBlob(resolve, 'image/jpeg', 0.95)
      })
      
      // Apply metadata changes
      blob = await this.applyMetadataToImage(blob)

      // Create FormData
      const formData = new FormData()
      formData.append('file', blob, 'edited-image.jpg')
      formData.append('original_upload_id', this.mediumId)

      // Upload
      const response = await fetch('/admin/media/upload', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })

      if (!response.ok) throw new Error('Upload failed')

      const data = await response.json()

      // Dispatch event to reload media library
      window.dispatchEvent(new CustomEvent('image-edited', {
        detail: { mediumId: data.medium_id }
      }))

      this.close()
      
      if (window.Swal) {
        Swal.fire({
          icon: 'success',
          title: 'Image saved successfully',
          showConfirmButton: false,
          timer: 2000,
          customClass: {
            popup: 'sweet-alert-popup',
            title: 'sweet-alert-title',
            content: 'sweet-alert-content',
            icon: 'sweet-alert-icon'
          },
          didOpen: () => {
            const popup = document.querySelector('.swal2-popup')
            if (popup) {
              popup.style.background = 'var(--admin-bg-primary)'
              popup.style.border = '1px solid var(--admin-border)'
              popup.style.color = 'var(--admin-text-primary)'
              popup.style.borderRadius = 'var(--admin-radius-lg)'
            }
          }
        })
      }
    } catch (error) {
      console.error('Save error:', error)
      alert('An error occurred while saving')
    } finally {
      // Re-enable button and reset guard only if we are still open (i.e., on error)
      this.isSaving = false
      if (saveButton) {
        saveButton.disabled = false
        try { saveButton.classList.remove('opacity-50', 'cursor-not-allowed') } catch(_) {}
      }
    }
  }

  async cancelEditing(event) {
    if (event) event.preventDefault()
    
    if (window.Swal) {
      const result = await Swal.fire({
        title: 'Discard Changes?',
        text: 'Are you sure you want to discard all changes to this image?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: 'var(--admin-error)',
        cancelButtonColor: 'var(--admin-border)',
        confirmButtonText: 'Yes, Discard',
        cancelButtonText: 'Cancel',
        allowOutsideClick: false,
        customClass: {
          popup: 'sweet-alert-popup',
          title: 'sweet-alert-title',
          content: 'sweet-alert-content',
          confirmButton: 'sweet-alert-confirm',
          cancelButton: 'sweet-alert-cancel',
          actions: 'sweet-alert-actions',
          icon: 'sweet-alert-icon'
        },
        // Apply theme colors from CSS variables
        didOpen: () => {
          const popup = document.querySelector('.swal2-popup')
          if (popup) {
            popup.style.background = 'var(--admin-bg-primary)'
            popup.style.border = '1px solid var(--admin-border)'
            popup.style.color = 'var(--admin-text-primary)'
            popup.style.borderRadius = 'var(--admin-radius-lg)'
          }
          // Set z-index to be above the image editor
          const container = document.querySelector('.swal2-container')
          if (container) {
            container.style.zIndex = '14000'
            container.style.pointerEvents = 'auto'
          }
        }
      })

      if (result.isConfirmed) {
        this.close()
      }
    } else {
      // Fallback to native confirm if SweetAlert not available
      if (confirm('Discard all changes?')) {
        this.close()
      }
    }
  }

  close() {
    this.destroyCropper()
    this.overlayTarget.classList.add('hidden')
    this.history = []
    this.historyIndex = -1
    this.mediumId = null
    this.originalImage = null
    this.virtualImage = null
    this.metadataChanges = {}
  }
}
