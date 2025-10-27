import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "hiddenField"]
  static values = { dialogId: String }

  connect() {
    // Register global callback for media selector
    window.handleFeaturedImageSelected = this.handleMediaSelected.bind(this)
  }

  disconnect() {
    window.handleFeaturedImageSelected = null
  }

  openMediaSelector(event) {
    if (event) event.preventDefault()
    
    // Find the media selector dialog element
    const dialog = document.getElementById(this.dialogIdValue)
    if (!dialog) return

    // Get the media-selector controller 
    let controller = this.application.getControllerForElementAndIdentifier(dialog, "media-selector")
    
    if (controller) {
      try {
        controller.openDialog()
      } catch (error) {
        console.error('Error calling openDialog:', error)
        // Fallback: just show the dialog
        dialog.classList.remove("hidden")
      }
    } else {
      // Fallback: just show the dialog
      dialog.classList.remove("hidden")
    }
  }

  handleMediaSelected(mediaData) {
    
    // Update hidden field
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = mediaData.id
      this.hiddenFieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }

    // Update preview
    if (mediaData.thumbnail_url) {
      this.previewTarget.innerHTML = `
        <img src="${mediaData.thumbnail_url}" class="w-full h-full object-cover" />
        <div class="featured-image-overlay">
          <button type="button" class="featured-image-btn featured-image-btn-replace" data-action="click->featured-image#openMediaSelector">Replace</button>
          <button type="button" class="featured-image-btn featured-image-btn-remove" data-action="click->featured-image#removeImage">Remove</button>
        </div>
      `
    } else if (mediaData.url) {
      this.previewTarget.innerHTML = `
        <img src="${mediaData.url}" class="w-full h-full object-cover" />
        <div class="featured-image-overlay">
          <button type="button" class="featured-image-btn featured-image-btn-replace" data-action="click->featured-image#openMediaSelector">Replace</button>
          <button type="button" class="featured-image-btn featured-image-btn-remove" data-action="click->featured-image#removeImage">Remove</button>
        </div>
      `
    }
  }

  removeImage() {
    this.previewTarget.innerHTML = `
      <div class="featured-image-upload-placeholder" data-action="click->featured-image#openMediaSelector">
        Click to upload featured image
      </div>
    `
    
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = ''
      this.hiddenFieldTarget.dispatchEvent(new Event('change'))
    }
  }
}

