import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="slug-generator"
export default class extends Controller {
  static targets = ["title", "slug"]
  static values = { 
    debounce: { type: Number, default: 300 }, // 300ms debounce
    persisted: { type: Boolean, default: false }, // Is this an existing post?
    status: { type: String, default: 'auto_draft' } // Post status
  }

  connect() {
    console.log("Slug generator controller connected", { persisted: this.persistedValue })
    this.debounceTimeout = null
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  generateSlug() {
    // ALWAYS auto-generate for auto-drafts (even if persisted)
    // Only skip for published/pending posts
    if (this.persistedValue && this.statusValue !== 'auto_draft') {
      console.log("Post is persisted and not auto-draft, skipping slug auto-generation")
      return
    }

    // Clear previous timeout
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    // Debounce the slug generation
    this.debounceTimeout = setTimeout(() => {
      this.updateSlug()
    }, this.debounceValue)
  }

  updateSlug() {
    if (!this.hasTitleTarget || !this.hasSlugTarget) return

    const title = this.titleTarget.value.trim()
    
    if (title === '') {
      this.slugTarget.value = ''
      return
    }

    const slug = this.parameterize(title)
    this.slugTarget.value = slug
    
    console.log("Slug updated to:", slug)
  }

  parameterize(string) {
    if (!string) return ''
    
    return string
      .toLowerCase()                    // Convert to lowercase
      .trim()                           // Remove leading/trailing whitespace
      .replace(/[^\w\s-]/g, '')        // Remove special characters except word chars, spaces, hyphens
      .replace(/[\s_-]+/g, '-')        // Replace spaces, underscores, and multiple hyphens with single hyphen
      .replace(/^-+|-+$/g, '')         // Remove leading and trailing hyphens
  }
}
