import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pixel-form"
export default class extends Controller {
  static targets = ["pixelType", "pixelId", "customCode", "pixelIdField", "customCodeField", "pixelIdHint"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const pixelType = this.pixelTypeTarget.value
    const isCustom = pixelType === 'custom'

    if (isCustom) {
      // Show custom code, hide pixel ID
      this.customCodeFieldTarget.style.display = 'block'
      this.pixelIdFieldTarget.style.display = 'none'
      this.customCodeTarget.required = true
      this.pixelIdTarget.required = false
    } else {
      // Show pixel ID, hide custom code
      this.customCodeFieldTarget.style.display = 'none'
      this.pixelIdFieldTarget.style.display = 'block'
      this.customCodeTarget.required = false
      this.pixelIdTarget.required = true
      
      // Update hint text based on provider
      this.updatePixelIdHint(pixelType)
    }
  }

  updatePixelIdHint(pixelType) {
    const hints = {
      'google_analytics': 'Enter your Measurement ID (e.g., G-XXXXXXXXXX)',
      'google_tag_manager': 'Enter your GTM Container ID (e.g., GTM-XXXXXXX)',
      'facebook_pixel': 'Enter your Facebook Pixel ID (e.g., 1234567890123456)',
      'tiktok_pixel': 'Enter your TikTok Pixel ID',
      'linkedin_insight': 'Enter your LinkedIn Partner ID',
      'twitter_pixel': 'Enter your Twitter Pixel ID',
      'pinterest_tag': 'Enter your Pinterest Tag ID',
      'snapchat_pixel': 'Enter your Snapchat Pixel ID',
      'reddit_pixel': 'Enter your Reddit Pixel ID',
      'hotjar': 'Enter your Hotjar Site ID',
      'clarity': 'Enter your Microsoft Clarity Project ID',
      'mixpanel': 'Enter your Mixpanel Project Token',
      'segment': 'Enter your Segment Write Key',
      'heap': 'Enter your Heap App ID'
    }

    if (this.hasPixelIdHintTarget) {
      this.pixelIdHintTarget.textContent = hints[pixelType] || 'Enter your tracking ID'
    }
  }
}






