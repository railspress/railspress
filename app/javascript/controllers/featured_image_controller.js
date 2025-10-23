import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    this.initializeEvents()
  }

  initializeEvents() {
    const uploadPlaceholder = this.previewTarget.querySelector('[data-action="upload"]')
    if (uploadPlaceholder) {
      uploadPlaceholder.addEventListener('click', () => this.openFileDialog())
    }

    const replaceBtn = this.previewTarget.querySelector('[data-action="replace"]')
    if (replaceBtn) {
      replaceBtn.addEventListener('click', () => this.openFileDialog())
    }

    const removeBtn = this.previewTarget.querySelector('[data-action="remove"]')
    if (removeBtn) {
      removeBtn.addEventListener('click', () => this.removeImage())
    }
  }

  openFileDialog() {
    this.inputTarget.click()
  }

  preview(event) {
    const input = event.target
    if (input.files && input.files[0]) {
      console.log('Featured image selected:', input.files[0].name, input.files[0].size)
      
      const file = input.files[0]
      
      // Upload immediately
      const formData = new FormData()
      formData.append('image', file)
      
      fetch('/admin/media/upload', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success === 1) {
          // Update hidden field with medium ID
          const hiddenField = document.querySelector('input[name*="featured_medium_id"]')
          if (hiddenField) {
            hiddenField.value = data.medium_id
            hiddenField.dispatchEvent(new Event('change', { bubbles: true }))
          }
          
          // Update preview
          const reader = new FileReader()
          reader.onload = (e) => {
            this.previewTarget.innerHTML = `
              <img src="${e.target.result}" class="w-full h-full object-cover" />
              <div class="featured-image-overlay">
                <button type="button" class="featured-image-btn featured-image-btn-replace" data-action="replace">Replace</button>
                <button type="button" class="featured-image-btn featured-image-btn-remove" data-action="remove">Remove</button>
              </div>
            `
            this.initializeEvents()
          }
          reader.readAsDataURL(file)
        } else {
          console.error('Upload failed:', data.message)
          alert('Failed to upload image: ' + data.message)
        }
      })
      .catch(error => {
        console.error('Upload error:', error)
        alert('Failed to upload image')
      })
    }
  }

  removeImage() {
    this.previewTarget.innerHTML = `
      <div class="featured-image-upload-placeholder" data-action="upload">
        Click to upload featured image
      </div>
    `
    
    if (this.inputTarget) {
      this.inputTarget.value = ''
      this.inputTarget.dispatchEvent(new Event('change'))
    }
    
    this.initializeEvents()
  }
}

