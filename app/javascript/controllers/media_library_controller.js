import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uploadArea", "fileInput", "searchInput", "mediaGrid", "mediaItem", "uploadProgress", "progressBar", "progressText"]

  connect() {
    console.log("Media library controller connected")
  }

  openUploadArea() {
    this.uploadAreaTarget.classList.remove("hidden")
    this.uploadAreaTarget.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  closeUploadArea() {
    this.uploadAreaTarget.classList.add("hidden")
  }

  selectFiles() {
    this.fileInputTarget.click()
  }

  handleFileSelect(event) {
    const files = event.target.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }

  uploadFiles(files) {
    // Validate files
    const maxSize = 100 * 1024 * 1024 // 100MB
    const allowedTypes = ['image/', 'video/', 'application/', 'text/']
    
    for (let file of files) {
      if (file.size > maxSize) {
        this.showErrorMessage(`File "${file.name}" is too large. Maximum size is 100MB.`)
        return
      }
      
      if (!allowedTypes.some(type => file.type.startsWith(type))) {
        this.showErrorMessage(`File "${file.name}" is not a supported format.`)
        return
      }
    }

    // Create FormData for file upload
    const formData = new FormData()
    
    Array.from(files).forEach((file, index) => {
      formData.append(`media[${index}][file]`, file)
      formData.append(`media[${index}][title]`, file.name)
    })

    // Show loading state
    this.showUploadProgress()

    // Upload files via fetch with progress tracking
    const xhr = new XMLHttpRequest()
    
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percentComplete = (e.loaded / e.total) * 100
        this.updateProgress(percentComplete)
      }
    })
    
    xhr.addEventListener('load', () => {
      if (xhr.status === 200) {
        try {
          const data = JSON.parse(xhr.responseText)
          if (data.success) {
            this.hideUploadProgress()
            this.closeUploadArea()
            this.refreshMediaGrid()
            this.showSuccessMessage(`Successfully uploaded ${files.length} file(s)`)
          } else {
            this.hideUploadProgress()
            this.showErrorMessage(data.message || 'Upload failed')
          }
        } catch (error) {
          this.hideUploadProgress()
          this.showErrorMessage('Upload completed but response was invalid')
        }
      } else {
        this.hideUploadProgress()
        this.showErrorMessage('Upload failed. Please try again.')
      }
    })
    
    xhr.addEventListener('error', () => {
      this.hideUploadProgress()
      this.showErrorMessage('Upload failed. Please check your connection and try again.')
    })
    
    xhr.open('POST', '/admin/media/bulk_upload')
    xhr.setRequestHeader('X-CSRF-Token', document.querySelector('meta[name="csrf-token"]').content)
    xhr.send(formData)
  }

  showUploadProgress() {
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.remove("hidden")
    }
  }

  hideUploadProgress() {
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.add("hidden")
      this.updateProgress(0)
    }
  }

  updateProgress(percent) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `Uploading... ${Math.round(percent)}%`
    }
  }

  refreshMediaGrid() {
    // Reload the page to show new media
    window.location.reload()
  }

  showSuccessMessage(message) {
    // Use SweetAlert2 for success message
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'success',
        title: 'Success',
        text: message,
        timer: 3000,
        showConfirmButton: false
      })
    }
  }

  showErrorMessage(message) {
    // Use SweetAlert2 for error message
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: message
      })
    }
  }

  setGridView() {
    // Switch to grid view
    this.mediaGridTarget.className = "grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-4"
    
    // Update button states
    this.element.querySelector('[data-action*="setGridView"]').className = "p-2 rounded text-white bg-indigo-600"
    this.element.querySelector('[data-action*="setListView"]').className = "p-2 rounded text-gray-400 hover:text-white"
  }

  setListView() {
    // Switch to list view
    this.mediaGridTarget.className = "grid grid-cols-1 gap-2"
    
    // Update button states
    this.element.querySelector('[data-action*="setGridView"]').className = "p-2 rounded text-gray-400 hover:text-white"
    this.element.querySelector('[data-action*="setListView"]').className = "p-2 rounded text-white bg-indigo-600"
  }

  search() {
    const query = this.searchInputTarget.value.toLowerCase()
    const mediaItems = this.mediaItemTargets

    mediaItems.forEach(item => {
      const title = item.querySelector('.text-xs').textContent.toLowerCase()
      const isVisible = title.includes(query)
      
      item.style.display = isVisible ? 'block' : 'none'
    })
  }

  // Drag and drop functionality
  dragOver(event) {
    event.preventDefault()
    this.uploadAreaTarget.classList.add("border-indigo-500", "bg-indigo-500/20", "scale-105")
    this.uploadAreaTarget.classList.remove("border-gray-600", "bg-gray-800/50")
  }

  dragLeave(event) {
    event.preventDefault()
    this.uploadAreaTarget.classList.remove("border-indigo-500", "bg-indigo-500/20", "scale-105")
    this.uploadAreaTarget.classList.add("border-gray-600", "bg-gray-800/50")
  }

  drop(event) {
    event.preventDefault()
    this.uploadAreaTarget.classList.remove("border-indigo-500", "bg-indigo-500/20", "scale-105")
    this.uploadAreaTarget.classList.add("border-gray-600", "bg-gray-800/50")
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }
}




