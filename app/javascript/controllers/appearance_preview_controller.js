import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewBox", "primaryColorInput", "secondaryColorInput", "headingFontSelect", "paragraphFontSelect", "bodyFontSelect"]
  
  connect() {
    this.setupEventListeners()
  }
  
  disconnect() {
    // Event listeners will be automatically cleaned up
  }
  
  setupEventListeners() {
    // Primary color inputs
    if (this.hasPrimaryColorInputTarget) {
      this.primaryColorInputTarget.addEventListener('input', this.updatePrimaryColor.bind(this))
    }
    
    // Secondary color inputs
    if (this.hasSecondaryColorInputTarget) {
      this.secondaryColorInputTarget.addEventListener('input', this.updateSecondaryColor.bind(this))
    }
    
    // Font selects
    if (this.hasHeadingFontSelectTarget) {
      this.headingFontSelectTarget.addEventListener('change', this.updateHeadingFont.bind(this))
    }
    
    if (this.hasParagraphFontSelectTarget) {
      this.paragraphFontSelectTarget.addEventListener('change', this.updateParagraphFont.bind(this))
    }
    
    if (this.hasBodyFontSelectTarget) {
      this.bodyFontSelectTarget.addEventListener('change', this.updateBodyFont.bind(this))
    }
  }
  
  setPrimaryColor(event) {
    const color = event.target.dataset.color
    if (color && this.hasPrimaryColorInputTarget) {
      this.primaryColorInputTarget.value = color
      // Also update the text input if it exists
      const textInput = this.element.querySelector('input[name="settings[primary_color_text]"]')
      if (textInput) textInput.value = color
    }
    this.updatePrimaryColor()
  }
  
  setSecondaryColor(color) {
    if (this.hasSecondaryColorInputTarget) {
      this.secondaryColorInputTarget.value = color
    }
    this.updateSecondaryColor()
  }
  
  updatePrimaryColor() {
    const color = this.primaryColorInputTarget?.value
    if (color && this.hasPreviewBoxTarget) {
      const heading = this.previewBoxTarget.querySelector('h1')
      const primaryButton = this.previewBoxTarget.querySelector('button:first-of-type')
      
      if (heading) heading.style.color = color
      if (primaryButton) primaryButton.style.backgroundColor = color
    }
  }
  
  updateSecondaryColor() {
    const color = this.secondaryColorInputTarget?.value
    if (color && this.hasPreviewBoxTarget) {
      const secondaryButton = this.previewBoxTarget.querySelector('button:last-of-type')
      if (secondaryButton) secondaryButton.style.backgroundColor = color
    }
  }
  
  updateHeadingFont(event) {
    const font = event.target.value
    if (this.hasPreviewBoxTarget) {
      const heading = this.previewBoxTarget.querySelector('h1')
      if (heading) heading.style.fontFamily = font
    }
  }
  
  updateParagraphFont(event) {
    const font = event.target.value
    if (this.hasPreviewBoxTarget) {
      const paragraph = this.previewBoxTarget.querySelector('p')
      if (paragraph) paragraph.style.fontFamily = font
    }
  }
  
  updateBodyFont(event) {
    const font = event.target.value
    if (this.hasPreviewBoxTarget) {
      const buttons = this.previewBoxTarget.querySelectorAll('button')
      buttons.forEach(btn => btn.style.fontFamily = font)
    }
  }
}
