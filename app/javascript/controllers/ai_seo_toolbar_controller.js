import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ai-seo-toolbar"
export default class extends Controller {
  connect() {
    console.log("AI SEO Toolbar connected")
  }

  async generateSeo(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.innerHTML

    try {
      // Disable button and show loading
      button.disabled = true
      button.innerHTML = `
        <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
        </svg>
        <span>Generating...</span>
      `

      // Get the post/page ID from the form
      const contentId = this.getContentId()
      const contentType = this.getContentType()

      // Call API to generate SEO
      const response = await fetch(`/api/v1/ai_seo/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          content_type: contentType,
          content_id: contentId
        })
      })

      const data = await response.json()

      if (data.success) {
        // Update form fields with generated SEO
        this.updateFormFields(data)
        alert("SEO generated successfully!")
      } else {
        alert(`Error: ${data.error || "Failed to generate SEO"}`)
      }
    } catch (error) {
      console.error("Error generating SEO:", error)
      alert("An error occurred while generating SEO")
    } finally {
      button.disabled = false
      button.innerHTML = originalText
    }
  }

  getContentId() {
    // Try to get ID from URL
    const match = window.location.pathname.match(/\/(\d+)\/edit/)
    return match ? match[1] : null
  }

  getContentType() {
    // Determine content type from URL
    if (window.location.pathname.includes('/posts/')) {
      return 'Post'
    } else if (window.location.pathname.includes('/pages/')) {
      return 'Page'
    }
    return 'Post'
  }

  updateFormFields(data) {
    // Update form fields with AI-generated data
    const fields = {
      'meta_title': data.meta_title,
      'meta_description': data.meta_description,
      'meta_keywords': data.meta_keywords,
      'focus_keyphrase': data.focus_keyphrase
    }

    Object.entries(fields).forEach(([field, value]) => {
      if (value) {
        const input = document.querySelector(`[name*="[${field}]"]`)
        if (input) {
          input.value = value
          // Trigger change event
          input.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }
    })
  }
}








