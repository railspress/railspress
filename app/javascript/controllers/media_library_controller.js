import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uploadArea", "fileInput", "searchInput", "mediaGrid", "mediaItem"]

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
    // Create FormData for file upload
    const formData = new FormData()
    
    Array.from(files).forEach((file, index) => {
      formData.append(`media[${index}][file]`, file)
      formData.append(`media[${index}][title]`, file.name)
    })

    // Show loading state
    this.showUploadProgress()

    // Upload files via fetch
    fetch('/admin/media/bulk_upload', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.hideUploadProgress()
        this.closeUploadArea()
        this.refreshMediaGrid()
        this.showSuccessMessage(`Successfully uploaded ${files.length} file(s)`)
      } else {
        this.hideUploadProgress()
        this.showErrorMessage(data.message || 'Upload failed')
      }
    })
    .catch(error => {
      console.error('Upload error:', error)
      this.hideUploadProgress()
      this.showErrorMessage('Upload failed. Please try again.')
    })
  }

  showUploadProgress() {
    // You can implement a progress indicator here
    console.log("Upload in progress...")
  }

  hideUploadProgress() {
    // Hide progress indicator
    console.log("Upload completed")
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
    this.uploadAreaTarget.classList.add("border-indigo-500", "bg-indigo-500/10")
  }

  dragLeave(event) {
    event.preventDefault()
    this.uploadAreaTarget.classList.remove("border-indigo-500", "bg-indigo-500/10")
  }

  drop(event) {
    event.preventDefault()
    this.uploadAreaTarget.classList.remove("border-indigo-500", "bg-indigo-500/10")
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }
}


