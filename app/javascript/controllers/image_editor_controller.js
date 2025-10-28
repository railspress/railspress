import { Controller } from "@hotwired/stimulus"
import { ImageFilters } from "image_filters"

export default class extends Controller {
  static targets = [
    "overlay", "virtualCanvas", "undoBtn", "redoBtn",
    "tabBtn", "filtersPanel", "cropPanel", "scalePanel", "rotationPanel", "advancedPanel",
    "filterGrid", "aspectRatio", "scaleWidth", "scaleHeight", "lockAspect",
    "brightnessSlider", "brightnessValue",
    "contrastSlider", "contrastValue",
    "saturationSlider", "saturationValue",
    "hueSlider", "hueValue",
    "blurSlider", "blurValue",
    "sharpenSlider", "sharpenValue"
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
    
    // Load Cropper.js dynamically
    this.loadCropperJS()
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
    }

    this.currentTab = tab
  }

  // FILTERS TAB
  generateFilterThumbnails() {
    const filterNames = ImageFilters.getFilterNames()
    const gridHTML = filterNames.map(filterName => {
      const filterData = ImageFilters.getFilterData(filterName)
      return `
        <div class="filter-thumbnail cursor-pointer hover:opacity-80 transition-opacity" data-filter="${filterName}">
          <canvas class="w-full aspect-square rounded mb-1" data-filter-canvas="${filterName}"></canvas>
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
        const filterName = thumb.dataset.filter
        this.applyFilter(filterName)
      })
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

  applyFilter(filterName) {
    this.selectedFilter = filterName
    const filterData = ImageFilters.getFilterData(filterName)

    // Always apply filter to original image, not the already-filtered virtual canvas
    const canvas = this.virtualCanvasTarget
    
    // Create temp canvas and apply filter to original image
    const tempCanvas = document.createElement('canvas')
    tempCanvas.width = this.originalImage.width
    tempCanvas.height = this.originalImage.height

    const tempCtx = tempCanvas.getContext('2d')
    tempCtx.filter = filterData.css
    tempCtx.drawImage(this.originalImage, 0, 0)

    // Update virtual canvas with filtered result
    const ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(tempCanvas, 0, 0)

    // Save to history
    this.saveToHistory()
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

  // ADVANCED TAB
  updateAdvanced(event) {
    this.brightnessValueTarget.textContent = this.brightnessSliderTarget.value
    this.contrastValueTarget.textContent = this.contrastSliderTarget.value
    this.saturationValueTarget.textContent = this.saturationSliderTarget.value
    this.hueValueTarget.textContent = this.hueSliderTarget.value
    this.blurValueTarget.textContent = this.blurSliderTarget.value
    this.sharpenValueTarget.textContent = this.sharpenSliderTarget.value
  }

  resetAdvanced() {
    this.brightnessSliderTarget.value = 100
    this.contrastSliderTarget.value = 100
    this.saturationSliderTarget.value = 100
    this.hueSliderTarget.value = 0
    this.blurSliderTarget.value = 0
    this.sharpenSliderTarget.value = 0
    this.updateAdvanced()
  }

  applyAdvanced() {
    const brightness = this.brightnessSliderTarget.value
    const contrast = this.contrastSliderTarget.value
    const saturation = this.saturationSliderTarget.value
    const hue = this.hueSliderTarget.value
    const blur = this.blurSliderTarget.value

    // Build filter string
    const filters = [
      `brightness(${brightness}%)`,
      `contrast(${contrast}%)`,
      `saturate(${saturation}%)`,
      `hue-rotate(${hue}deg)`,
      blur > 0 ? `blur(${blur}px)` : ''
    ].filter(f => f).join(' ')

    // Apply to virtual canvas
    const canvas = this.virtualCanvasTarget
    const tempCanvas = document.createElement('canvas')
    tempCanvas.width = canvas.width
    tempCanvas.height = canvas.height

    const tempCtx = tempCanvas.getContext('2d')
    tempCtx.filter = filters
    tempCtx.drawImage(canvas, 0, 0)

    // Update virtual canvas
    const ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(tempCanvas, 0, 0)

    this.saveToHistory()
  }

  // SAVE
  async saveEdits(event) {
    if (event) event.preventDefault()
    
    try {
      // Get final canvas
      const canvas = this.virtualCanvasTarget

      // Convert to blob
      const blob = await new Promise(resolve => {
        canvas.toBlob(resolve, 'image/jpeg', 0.95)
      })

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
          timer: 2000
        })
      }
    } catch (error) {
      console.error('Save error:', error)
      alert('An error occurred while saving')
    }
  }

  cancelEditing(event) {
    if (event) event.preventDefault()
    if (confirm('Discard all changes?')) {
      this.close()
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
  }
}
