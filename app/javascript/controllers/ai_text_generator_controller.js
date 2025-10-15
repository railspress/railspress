import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "prompt", "tone", "submitBtn", "submitText", "loadingSpinner", "successToast", "errorToast", "errorMessage"]
  static values = { 
    agentId: String,
    targetSelector: String,
    popupId: String
  }

  connect() {
    // Close popup when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
    
    // Close popup with Escape key
    document.addEventListener('keydown', this.handleEscapeKey.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
    document.removeEventListener('keydown', this.handleEscapeKey.bind(this))
  }

  openPopup() {
    this.popupTarget.classList.remove('hidden')
    this.popupTarget.classList.add('flex')
    
    // Focus on the textarea
    setTimeout(() => {
      this.promptTarget.focus()
    }, 100)
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
  }

  closePopup() {
    this.popupTarget.classList.add('hidden')
    this.popupTarget.classList.remove('flex')
    
    // Clear form
    this.promptTarget.value = ''
    this.toneTarget.value = ''
    
    // Restore body scroll
    document.body.style.overflow = ''
  }

  async generateText(event) {
    event.preventDefault()
    
    const prompt = this.promptTarget.value.trim()
    if (!prompt) {
      this.showError('Please enter a prompt')
      return
    }

    // Show loading state
    this.setLoadingState(true)

    try {
      // Get the current user's API key
      const apiKey = this.getApiKey()
      if (!apiKey) {
        throw new Error('API key not found. Please refresh the page and try again.')
      }

      // Prepare the request
      const requestBody = {
        model: this.agentIdValue,
        messages: [
          {
            role: "user",
            content: this.buildPrompt(prompt)
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      }

      // Make API request
      const response = await fetch('/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(requestBody)
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error?.message || `HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      
      if (!data.choices || !data.choices[0] || !data.choices[0].message) {
        throw new Error('Invalid response from AI service')
      }

      const generatedText = data.choices[0].message.content.trim()
      
      // Insert the generated text into the target element
      this.insertTextIntoTarget(generatedText)
      
      // Close popup and show success
      this.closePopup()
      this.showSuccess()

    } catch (error) {
      console.error('AI Text Generation Error:', error)
      this.showError(error.message)
    } finally {
      this.setLoadingState(false)
    }
  }

  buildPrompt(userPrompt) {
    const tone = this.toneTarget.value
    
    if (tone) {
      const toneInstructions = {
        professional: "Write in a professional, business-appropriate tone.",
        casual: "Write in a casual, conversational tone.",
        friendly: "Write in a warm, friendly tone.",
        formal: "Write in a formal, academic tone.",
        creative: "Write in a creative, engaging tone.",
        concise: "Be concise and to the point.",
        detailed: "Provide detailed, comprehensive information."
      }
      
      return `${userPrompt}\n\n${toneInstructions[tone]}`
    }
    
    return userPrompt
  }

  insertTextIntoTarget(text) {
    const targetElement = document.querySelector(this.targetSelectorValue)
    
    if (!targetElement) {
      console.error('Target element not found:', this.targetSelectorValue)
      this.showError('Target element not found')
      return
    }

    // Handle different types of elements
    if (targetElement.tagName === 'TEXTAREA' || targetElement.tagName === 'INPUT') {
      // For form inputs, insert at cursor position or append
      const currentValue = targetElement.value || ''
      const cursorPos = targetElement.selectionStart || currentValue.length
      
      const newValue = currentValue.slice(0, cursorPos) + text + currentValue.slice(cursorPos)
      targetElement.value = newValue
      
      // Trigger input event for any listeners
      targetElement.dispatchEvent(new Event('input', { bubbles: true }))
      
      // Set cursor position after inserted text
      const newCursorPos = cursorPos + text.length
      targetElement.setSelectionRange(newCursorPos, newCursorPos)
      
    } else if (targetElement.contentEditable === 'true') {
      // For contenteditable elements
      const selection = window.getSelection()
      if (selection.rangeCount > 0) {
        const range = selection.getRangeAt(0)
        range.deleteContents()
        range.insertNode(document.createTextNode(text))
        range.collapse(false)
        selection.removeAllRanges()
        selection.addRange(range)
      } else {
        targetElement.textContent = (targetElement.textContent || '') + text
      }
      
    } else {
      // For other elements, append text
      targetElement.textContent = (targetElement.textContent || '') + text
    }

    // Focus back on the target element
    targetElement.focus()
  }

  getApiKey() {
    // Try to get API key from meta tag
    const metaTag = document.querySelector('meta[name="api-key"]')
    if (metaTag) {
      return metaTag.getAttribute('content')
    }

    // Try to get from window object (set by admin layout)
    if (window.currentUserApiKey) {
      return window.currentUserApiKey
    }

    // Try to get from localStorage (if set by user)
    return localStorage.getItem('rails_api_key')
  }

  setLoadingState(isLoading) {
    this.submitBtnTarget.disabled = isLoading
    
    if (isLoading) {
      this.submitTextTarget.textContent = 'Generating...'
      this.loadingSpinnerTarget.classList.remove('hidden')
    } else {
      this.submitTextTarget.textContent = 'Generate'
      this.loadingSpinnerTarget.classList.add('hidden')
    }
  }

  showSuccess() {
    this.successToastTarget.classList.remove('hidden')
    this.successToastTarget.classList.add('transform', 'translate-x-0')
    
    setTimeout(() => {
      this.successToastTarget.classList.add('hidden')
      this.successToastTarget.classList.remove('transform', 'translate-x-0')
    }, 3000)
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorToastTarget.classList.remove('hidden')
    this.errorToastTarget.classList.add('transform', 'translate-x-0')
    
    setTimeout(() => {
      this.errorToastTarget.classList.add('hidden')
      this.errorToastTarget.classList.remove('transform', 'translate-x-0')
    }, 5000)
  }

  handleOutsideClick(event) {
    if (this.popupTarget.classList.contains('flex') && 
        !this.popupTarget.contains(event.target) && 
        !this.element.contains(event.target)) {
      this.closePopup()
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape' && this.popupTarget.classList.contains('flex')) {
      this.closePopup()
    }
  }
}

