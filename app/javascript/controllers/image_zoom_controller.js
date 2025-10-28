import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zoomPercentage", "zoomDropdown", "canvasWrapper"]

  connect() {
    console.log('[Image Zoom] Controller connected')
    this.currentZoom = 1.0
    this.panOffset = { x: 0, y: 0 }
    this.isPanning = false
    this.lastMousePos = { x: 0, y: 0 }
    this.zoomLevels = [0.25, 0.5, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 16.0]
    
    // Bind event listeners
    this.boundHandleWheel = this.handleWheel.bind(this)
    this.boundStartPan = this.startPan.bind(this)
    this.boundDoPan = this.doPan.bind(this)
    this.boundEndPan = this.endPan.bind(this)
    
    // Add wheel listener to canvas wrapper
    if (this.hasCanvasWrapperTarget) {
      this.canvasWrapperTarget.addEventListener('wheel', this.boundHandleWheel, { passive: false })
      this.canvasWrapperTarget.addEventListener('mousedown', this.boundStartPan)
    }
    
    // Add global mouse move/up listeners
    document.addEventListener('mousemove', this.boundDoPan)
    document.addEventListener('mouseup', this.boundEndPan)
    
    // Update initial zoom display
    this.updateZoomDisplay()
  }

  disconnect() {
    // Cleanup
    if (this.hasCanvasWrapperTarget) {
      this.canvasWrapperTarget.removeEventListener('wheel', this.boundHandleWheel)
      this.canvasWrapperTarget.removeEventListener('mousedown', this.boundStartPan)
    }
    document.removeEventListener('mousemove', this.boundDoPan)
    document.removeEventListener('mouseup', this.boundEndPan)
  }

  zoomIn() {
    console.log('[Image Zoom] zoomIn called')
    const currentIndex = this.zoomLevels.indexOf(this.currentZoom)
    const nextIndex = Math.min(currentIndex + 1, this.zoomLevels.length - 1)
    this.setZoom(this.zoomLevels[nextIndex])
  }

  zoomOut() {
    const currentIndex = this.zoomLevels.indexOf(this.currentZoom)
    const prevIndex = Math.max(currentIndex - 1, 0)
    this.setZoom(this.zoomLevels[prevIndex])
  }

  setZoom(level) {
    console.log('[Image Zoom] setZoom called with:', level)
    this.currentZoom = level
    // Always reset pan when zoom changes to keep centered
    this.panOffset = { x: 0, y: 0 }
    this.applyZoomAndPan()
    this.updateZoomDisplay()
    this.updateActiveOption()
  }

  toggleZoomDropdown() {
    this.zoomDropdownTarget.classList.toggle('hidden')
  }

  selectZoomLevel(event) {
    const zoom = parseFloat(event.currentTarget.dataset.zoom) / 100
    this.setZoom(zoom)
    this.zoomDropdownTarget.classList.add('hidden')
  }

  handleWheel(event) {
    event.preventDefault()
    
    const delta = event.deltaY * -0.001
    const newZoom = Math.max(0.25, Math.min(16.0, this.currentZoom + delta * 0.5))
    
    // Keep centered when zooming
    this.currentZoom = newZoom
    this.panOffset = { x: 0, y: 0 }
    this.applyZoomAndPan()
    this.updateZoomDisplay()
    this.updateActiveOption()
  }

  startPan(event) {
    if (this.currentZoom <= 1.0) {
      return // Only pan when zoomed in
    }
    
    this.isPanning = true
    this.lastMousePos = { x: event.clientX, y: event.clientY }
    event.preventDefault()
  }

  doPan(event) {
    if (!this.isPanning || !this.hasCanvasWrapperTarget) {
      return
    }
    
    const deltaX = event.clientX - this.lastMousePos.x
    const deltaY = event.clientY - this.lastMousePos.y
    
    this.panOffset.x += deltaX / this.currentZoom
    this.panOffset.y += deltaY / this.currentZoom
    
    // Constrain panning to keep image within bounds
    const wrapper = this.canvasWrapperTarget
    const maxPan = {
      x: Math.max(0, (wrapper.scrollWidth * this.currentZoom - wrapper.parentElement.clientWidth) / (2 * this.currentZoom)),
      y: Math.max(0, (wrapper.scrollHeight * this.currentZoom - wrapper.parentElement.clientHeight) / (2 * this.currentZoom))
    }
    
    this.panOffset.x = Math.max(-maxPan.x, Math.min(maxPan.x, this.panOffset.x))
    this.panOffset.y = Math.max(-maxPan.y, Math.min(maxPan.y, this.panOffset.y))
    
    this.lastMousePos = { x: event.clientX, y: event.clientY }
    this.applyZoomAndPan()
  }

  endPan(event) {
    this.isPanning = false
  }

  applyZoomAndPan() {
    if (!this.hasCanvasWrapperTarget) {
      console.log('[Image Zoom] No canvas wrapper target found!')
      return
    }
    
    const wrapper = this.canvasWrapperTarget
    const transform = `scale(${this.currentZoom}) translate(${this.panOffset.x}px, ${this.panOffset.y}px)`
    console.log('[Image Zoom] Applying transform:', transform)
    wrapper.style.transform = transform
  }

  updateZoomDisplay() {
    if (this.hasZoomPercentageTarget) {
      this.zoomPercentageTarget.textContent = `${Math.round(this.currentZoom * 100)}%`
    }
  }

  updateActiveOption() {
    const options = this.zoomDropdownTarget.querySelectorAll('.zoom-option')
    const zoomPercent = Math.round(this.currentZoom * 100)
    
    options.forEach(option => {
      const optionZoom = parseInt(option.dataset.zoom)
      if (optionZoom === zoomPercent) {
        option.classList.add('active')
      } else {
        option.classList.remove('active')
      }
    })
  }

  reset() {
    this.setZoom(1.0)
    this.panOffset = { x: 0, y: 0 }
    this.isPanning = false
  }
}

