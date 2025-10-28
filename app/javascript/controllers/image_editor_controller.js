import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "overlay", "image", "imageContainer",
    "cropBtn", "scaleBtn", "effectsBtn", "rotationBtn", "rotationMenu",
    "cropPanel", "scalePanel", "effectsPanel",
    "aspectWidth", "aspectHeight", "selectionWidth", "selectionHeight", "cropX", "cropY",
    "scaleWidth", "scaleHeight", "originalDimensions",
    "brightnessSlider", "brightnessValue", "contrastSlider", "contrastValue",
    "saturationSlider", "saturationValue", "hueSlider", "hueValue",
    "sharpenSlider", "sharpenValue",
    "undoBtn", "redoBtn", "saveBtn"
  ]
  
  connect() {
    this.uploadId = null
    this.cropper = null
    this.currentTool = 'crop'
    this.originalWidth = 0
    this.originalHeight = 0
    this.history = []
    this.historyIndex = -1
    this.currentFilters = {
      brightness: 100,
      contrast: 100,
      saturation: 100,
      hue: 0,
      sharpen: 0,
      grayscale: 0,
      sepia: 0,
      invert: 0,
      blur: 0
    }
    this.loadCropperJS()
  }
  
  loadCropperJS() {
    if (window.Cropper) return
    
    // Load Cropper.js CSS
    const css = document.createElement('link')
    css.rel = 'stylesheet'
    css.href = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.css'
    document.head.appendChild(css)
    
    // Load Cropper.js
    const script = document.createElement('script')
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.js'
    script.onload = () => {
      console.log('Cropper.js loaded')
    }
    document.head.appendChild(script)
  }
  
  openEditor(uploadId, imageUrl) {
    this.uploadId = uploadId
    this.imageTarget.src = imageUrl
    this.overlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    
    // Wait for image to load
    this.imageTarget.onload = () => {
      this.originalWidth = this.imageTarget.naturalWidth
      this.originalHeight = this.imageTarget.naturalHeight
      this.originalDimensionsTarget.textContent = `${this.originalWidth} × ${this.originalHeight}`
      this.scaleWidthTarget.value = this.originalWidth
      this.scaleHeightTarget.value = this.originalHeight
      
      // Wait for Cropper.js to be available
      const initCropper = () => {
        if (window.Cropper) {
          this.initCropper()
          this.activateCrop()
        } else {
          setTimeout(initCropper, 100)
        }
      }
      initCropper()
    }
  }
  
  initCropper() {
    if (this.cropper) {
      this.cropper.destroy()
    }
    
    this.imageTarget.style.display = 'block'
    
    this.cropper = new window.Cropper(this.imageTarget, {
      viewMode: 1,
      dragMode: 'move',
      autoCropArea: 1,
      restore: false,
      guides: true,
      center: true,
      highlight: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      crop: (event) => {
        this.updateCropInfo(event.detail)
      }
    })
  }
  
  updateCropInfo(detail) {
    this.selectionWidthTarget.value = Math.round(detail.width)
    this.selectionHeightTarget.value = Math.round(detail.height)
    this.cropXTarget.value = Math.round(detail.x)
    this.cropYTarget.value = Math.round(detail.y)
  }
  
  activateCrop(event) {
    if (event) event.preventDefault()
    this.currentTool = 'crop'
    this.cropBtnTarget.style.background = 'var(--admin-primary)'
    this.cropBtnTarget.style.color = 'white'
    this.scaleBtnTarget.style.background = 'transparent'
    this.scaleBtnTarget.style.color = 'var(--admin-text-primary)'
    this.effectsBtnTarget.style.background = 'transparent'
    this.effectsBtnTarget.style.color = 'var(--admin-text-primary)'
    this.cropPanelTarget.classList.remove('hidden')
    this.scalePanelTarget.classList.add('hidden')
    this.effectsPanelTarget.classList.add('hidden')
    
    if (this.cropper) {
      this.cropper.setDragMode('crop')
    }
  }
  
  activateScale(event) {
    if (event) event.preventDefault()
    this.currentTool = 'scale'
    this.scaleBtnTarget.style.background = 'var(--admin-primary)'
    this.scaleBtnTarget.style.color = 'white'
    this.cropBtnTarget.style.background = 'transparent'
    this.cropBtnTarget.style.color = 'var(--admin-text-primary)'
    this.effectsBtnTarget.style.background = 'transparent'
    this.effectsBtnTarget.style.color = 'var(--admin-text-primary)'
    this.scalePanelTarget.classList.remove('hidden')
    this.cropPanelTarget.classList.add('hidden')
    this.effectsPanelTarget.classList.add('hidden')
  }
  
  toggleRotationMenu(event) {
    event.preventDefault()
    this.rotationMenuTarget.classList.toggle('hidden')
  }
  
  rotate(event) {
    event.preventDefault()
    const degrees = parseFloat(event.currentTarget.dataset.degrees)
    if (this.cropper) {
      this.cropper.rotate(degrees)
    }
    this.rotationMenuTarget.classList.add('hidden')
    this.addToHistory()
  }
  
  flip(event) {
    event.preventDefault()
    const direction = event.currentTarget.dataset.direction
    if (this.cropper) {
      if (direction === 'horizontal') {
        this.cropper.scaleX(-(this.cropper.getData().scaleX || 1))
      } else {
        this.cropper.scaleY(-(this.cropper.getData().scaleY || 1))
      }
    }
    this.rotationMenuTarget.classList.add('hidden')
    this.addToHistory()
  }
  
  setAspectRatio(event) {
    const width = parseFloat(this.aspectWidthTarget.value)
    const height = parseFloat(this.aspectHeightTarget.value)
    
    if (width && height && this.cropper) {
      this.cropper.setAspectRatio(width / height)
    } else if (this.cropper) {
      this.cropper.setAspectRatio(NaN) // Free aspect
    }
  }
  
  updateScaleHeight(event) {
    const width = parseFloat(this.scaleWidthTarget.value)
    if (width && this.originalWidth && this.originalHeight) {
      const ratio = this.originalHeight / this.originalWidth
      this.scaleHeightTarget.value = Math.round(width * ratio)
    }
  }
  
  updateScaleWidth(event) {
    const height = parseFloat(this.scaleHeightTarget.value)
    if (height && this.originalWidth && this.originalHeight) {
      const ratio = this.originalWidth / this.originalHeight
      this.scaleWidthTarget.value = Math.round(height * ratio)
    }
  }
  
  applyScale(event) {
    event.preventDefault()
    // Scale is applied during save by using canvas dimensions
    this.addToHistory()
  }
  
  applyCrop(event) {
    event.preventDefault()
    if (this.cropper) {
      this.cropper.crop()
      this.addToHistory()
    }
  }
  
  clearCrop(event) {
    event.preventDefault()
    if (this.cropper) {
      this.cropper.clear()
      this.aspectWidthTarget.value = ''
      this.aspectHeightTarget.value = ''
    }
  }
  
  addToHistory() {
    // Simple history tracking (could be expanded)
    if (this.cropper) {
      this.history.push(this.cropper.getData())
      this.historyIndex = this.history.length - 1
      this.undoBtnTarget.disabled = false
      this.redoBtnTarget.disabled = true
    }
  }
  
  undo(event) {
    event.preventDefault()
    if (this.historyIndex > 0 && this.cropper) {
      this.historyIndex--
      this.cropper.setData(this.history[this.historyIndex])
      this.redoBtnTarget.disabled = false
    }
    if (this.historyIndex === 0) {
      this.undoBtnTarget.disabled = true
    }
  }
  
  redo(event) {
    event.preventDefault()
    if (this.historyIndex < this.history.length - 1 && this.cropper) {
      this.historyIndex++
      this.cropper.setData(this.history[this.historyIndex])
      this.undoBtnTarget.disabled = false
    }
    if (this.historyIndex === this.history.length - 1) {
      this.redoBtnTarget.disabled = true
    }
  }
  
  cancelEditing(event) {
    event.preventDefault()
    if (confirm('Discard all changes?')) {
      this.close()
    }
  }
  
  async saveEdits(event) {
    event.preventDefault()
    this.saveBtnTarget.disabled = true
    this.saveBtnTarget.textContent = 'Saving...'
    
    try {
      if (!this.cropper) {
        throw new Error('Cropper not initialized')
      }
      
      // Get cropped/transformed canvas
      const width = parseFloat(this.scaleWidthTarget.value) || this.originalWidth
      const height = parseFloat(this.scaleHeightTarget.value) || this.originalHeight
      
      let canvas = null
      
      try {
        // Try to get cropped canvas from Cropper
        canvas = this.cropper.getCroppedCanvas({
          width: width,
          height: height,
          imageSmoothingEnabled: true,
          imageSmoothingQuality: 'high'
        })
      } catch (e) {
        console.error('Error getting cropped canvas:', e)
        throw new Error('Failed to get image data')
      }
      
      if (!canvas) {
        throw new Error('Canvas is null')
      }
      
      // Apply filters to the canvas if any effects are active
      const hasFilters = Object.values(this.currentFilters).some((val, idx) => {
        const keys = Object.keys(this.currentFilters)
        if (keys[idx] === 'brightness' && val !== 100) return true
        if (keys[idx] === 'contrast' && val !== 100) return true
        if (keys[idx] === 'saturation' && val !== 100) return true
        if (keys[idx] === 'hue' && val !== 0) return true
        if (keys[idx] === 'sharpen' && val !== 0) return true
        if (keys[idx] === 'grayscale' && val !== 0) return true
        if (keys[idx] === 'sepia' && val !== 0) return true
        if (keys[idx] === 'invert' && val !== 0) return true
        if (keys[idx] === 'blur' && val !== 0) return true
        return false
      })
      
      if (hasFilters) {
        // Create a new canvas to apply filters
        const filteredCanvas = document.createElement('canvas')
        filteredCanvas.width = canvas.width
        filteredCanvas.height = canvas.height
        const ctx = filteredCanvas.getContext('2d')
        
        // Build filter string
        const filters = []
        if (this.currentFilters.brightness !== 100) {
          filters.push(`brightness(${this.currentFilters.brightness}%)`)
        }
        if (this.currentFilters.contrast !== 100) {
          filters.push(`contrast(${this.currentFilters.contrast}%)`)
        }
        if (this.currentFilters.saturation !== 100) {
          filters.push(`saturate(${this.currentFilters.saturation}%)`)
        }
        if (this.currentFilters.hue !== 0) {
          filters.push(`hue-rotate(${this.currentFilters.hue}deg)`)
        }
        if (this.currentFilters.sharpen > 0) {
          const sharpContrast = 100 + (this.currentFilters.sharpen * 0.5)
          filters.push(`contrast(${sharpContrast}%)`)
        }
        if (this.currentFilters.grayscale > 0) {
          filters.push(`grayscale(${this.currentFilters.grayscale}%)`)
        }
        if (this.currentFilters.sepia > 0) {
          filters.push(`sepia(${this.currentFilters.sepia}%)`)
        }
        if (this.currentFilters.invert > 0) {
          filters.push(`invert(${this.currentFilters.invert}%)`)
        }
        if (this.currentFilters.blur > 0) {
          filters.push(`blur(${this.currentFilters.blur}px)`)
        }
        
        ctx.filter = filters.join(' ')
        ctx.drawImage(canvas, 0, 0)
        
        // Use the filtered canvas
        canvas = filteredCanvas
      }
      
      // Convert to blob
      const blob = await new Promise((resolve, reject) => {
        try {
          canvas.toBlob((blob) => {
            if (blob) {
              resolve(blob)
            } else {
              reject(new Error('Failed to create blob from canvas'))
            }
          }, 'image/jpeg', 0.95)
        } catch (e) {
          reject(e)
        }
      })
      
      if (!blob) {
        throw new Error('Failed to create blob')
      }
      
      // Create FormData and upload
      const formData = new FormData()
      formData.append('file', blob, 'edited-image.jpg')
      
      const response = await fetch('/admin/media/upload', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })
      
      const data = await response.json()
      
      if (data.success === 1) {
        // Dispatch event to reload media library
        this.element.dispatchEvent(new CustomEvent('image-edited', {
          bubbles: true,
          detail: { uploadId: data.medium_id || this.uploadId }
        }))
        
        this.close()
      } else {
        alert('Failed to save edited image: ' + (data.message || 'Unknown error'))
        this.saveBtnTarget.disabled = false
        this.saveBtnTarget.textContent = 'Save Edits'
      }
    } catch (error) {
      console.error('Save error:', error)
      alert('An error occurred while saving: ' + error.message)
      this.saveBtnTarget.disabled = false
      this.saveBtnTarget.textContent = 'Save Edits'
    }
  }
  
  activateEffects(event) {
    if (event) event.preventDefault()
    this.currentTool = 'effects'
    this.effectsBtnTarget.style.background = 'var(--admin-primary)'
    this.effectsBtnTarget.style.color = 'white'
    this.cropBtnTarget.style.background = 'transparent'
    this.cropBtnTarget.style.color = 'var(--admin-text-primary)'
    this.scaleBtnTarget.style.background = 'transparent'
    this.scaleBtnTarget.style.color = 'var(--admin-text-primary)'
    this.effectsPanelTarget.classList.remove('hidden')
    this.cropPanelTarget.classList.add('hidden')
    this.scalePanelTarget.classList.add('hidden')
  }
  
  applyEffect(event) {
    event.preventDefault()
    const effect = event.currentTarget.dataset.effect
    
    switch(effect) {
      case 'grayscale':
        this.currentFilters.grayscale = 100
        this.currentFilters.sepia = 0
        this.currentFilters.invert = 0
        this.currentFilters.blur = 0
        break
      case 'sepia':
        this.currentFilters.sepia = 100
        this.currentFilters.grayscale = 0
        this.currentFilters.invert = 0
        this.currentFilters.blur = 0
        break
      case 'invert':
        this.currentFilters.invert = 100
        this.currentFilters.grayscale = 0
        this.currentFilters.sepia = 0
        this.currentFilters.blur = 0
        break
      case 'blur':
        this.currentFilters.blur = 5
        this.currentFilters.grayscale = 0
        this.currentFilters.sepia = 0
        this.currentFilters.invert = 0
        break
      case 'vintage':
        this.currentFilters.brightness = 105
        this.currentFilters.contrast = 110
        this.currentFilters.saturation = 85
        this.currentFilters.sepia = 20
        this.brightnessSliderTarget.value = 105
        this.brightnessValueTarget.textContent = 105
        this.contrastSliderTarget.value = 110
        this.contrastValueTarget.textContent = 110
        this.saturationSliderTarget.value = 85
        this.saturationValueTarget.textContent = 85
        break
      case 'vivid':
        this.currentFilters.brightness = 105
        this.currentFilters.contrast = 120
        this.currentFilters.saturation = 130
        this.brightnessSliderTarget.value = 105
        this.brightnessValueTarget.textContent = 105
        this.contrastSliderTarget.value = 120
        this.contrastValueTarget.textContent = 120
        this.saturationSliderTarget.value = 130
        this.saturationValueTarget.textContent = 130
        break
    }
    
    this.applyFilters()
  }
  
  updateBrightness(event) {
    const value = event.target.value
    this.currentFilters.brightness = value
    this.brightnessValueTarget.textContent = value
    this.applyFilters()
  }
  
  updateContrast(event) {
    const value = event.target.value
    this.currentFilters.contrast = value
    this.contrastValueTarget.textContent = value
    this.applyFilters()
  }
  
  updateSaturation(event) {
    const value = event.target.value
    this.currentFilters.saturation = value
    this.saturationValueTarget.textContent = value
    this.applyFilters()
  }
  
  updateHue(event) {
    const value = event.target.value
    this.currentFilters.hue = value
    this.hueValueTarget.textContent = value
    this.applyFilters()
  }
  
  updateSharpen(event) {
    const value = event.target.value
    this.currentFilters.sharpen = value
    this.sharpenValueTarget.textContent = value
    this.applyFilters()
  }
  
  applyFilters() {
    const filters = []
    
    if (this.currentFilters.brightness !== 100) {
      filters.push(`brightness(${this.currentFilters.brightness}%)`)
    }
    if (this.currentFilters.contrast !== 100) {
      filters.push(`contrast(${this.currentFilters.contrast}%)`)
    }
    if (this.currentFilters.saturation !== 100) {
      filters.push(`saturate(${this.currentFilters.saturation}%)`)
    }
    if (this.currentFilters.hue !== 0) {
      filters.push(`hue-rotate(${this.currentFilters.hue}deg)`)
    }
    if (this.currentFilters.grayscale > 0) {
      filters.push(`grayscale(${this.currentFilters.grayscale}%)`)
    }
    if (this.currentFilters.sepia > 0) {
      filters.push(`sepia(${this.currentFilters.sepia}%)`)
    }
    if (this.currentFilters.invert > 0) {
      filters.push(`invert(${this.currentFilters.invert}%)`)
    }
    if (this.currentFilters.blur > 0) {
      filters.push(`blur(${this.currentFilters.blur}px)`)
    }
    
    let filterString = filters.join(' ')
    
    // Add sharpen as contrast
    if (this.currentFilters.sharpen > 0) {
      const sharpContrast = 100 + (this.currentFilters.sharpen * 0.5)
      filterString = filterString ? filterString + ` contrast(${sharpContrast}%)` : `contrast(${sharpContrast}%)`
    }
    
    // Apply filter to both the original image and the cropper canvas
    const imagesToFilter = []
    
    // Find the actual displayed image element (Cropper creates its own)
    if (this.cropper) {
      const cropperElement = this.imageContainerTarget.querySelector('.cropper-container')
      if (cropperElement) {
        const cropperImg = cropperElement.querySelector('img')
        if (cropperImg) {
          imagesToFilter.push(cropperImg)
        }
      }
    }
    
    // Also apply to original image for compatibility
    if (this.imageTarget) {
      imagesToFilter.push(this.imageTarget)
    }
    
    // Apply filter to all found images
    imagesToFilter.forEach(img => {
      img.style.filter = filterString
    })
  }
  
  resetEffects(event) {
    event.preventDefault()
    this.currentFilters = {
      brightness: 100,
      contrast: 100,
      saturation: 100,
      hue: 0,
      sharpen: 0,
      grayscale: 0,
      sepia: 0,
      invert: 0,
      blur: 0
    }
    
    this.brightnessSliderTarget.value = 100
    this.brightnessValueTarget.textContent = 100
    this.contrastSliderTarget.value = 100
    this.contrastValueTarget.textContent = 100
    this.saturationSliderTarget.value = 100
    this.saturationValueTarget.textContent = 100
    this.hueSliderTarget.value = 0
    this.hueValueTarget.textContent = 0
    this.sharpenSliderTarget.value = 0
    this.sharpenValueTarget.textContent = 0
    
    // Clear filter from all images
    const imagesToFilter = []
    
    if (this.cropper) {
      const cropperElement = this.imageContainerTarget.querySelector('.cropper-container')
      if (cropperElement) {
        const cropperImg = cropperElement.querySelector('img')
        if (cropperImg) {
          imagesToFilter.push(cropperImg)
        }
      }
    }
    
    if (this.imageTarget) {
      imagesToFilter.push(this.imageTarget)
    }
    
    imagesToFilter.forEach(img => {
      img.style.filter = ''
    })
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
    
    this.overlayTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.uploadId = null
    this.history = []
    this.historyIndex = -1
    this.undoBtnTarget.disabled = true
    this.redoBtnTarget.disabled = true
  }
}

