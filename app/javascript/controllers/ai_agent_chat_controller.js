import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendButton"]

  connect() {
    console.log("AI Agent Chat controller connected")
    this.scrollToBottom()
  }

  sendMessage(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    const userInput = formData.get('user_input')
    const context = formData.get('context') || ''
    
    if (!userInput.trim()) return
    
    // Disable send button
    this.sendButtonTarget.disabled = true
    this.sendButtonTarget.textContent = 'Sending...'
    
    // Add user message to chat
    this.addMessage('user', userInput)
    
    // Clear input
    this.inputTarget.value = ''
    
    // Send request to server
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.addMessage('agent', data.result)
      } else {
        this.addMessage('error', data.error || 'An error occurred')
      }
    })
    .catch(error => {
      console.error('Chat error:', error)
      this.addMessage('error', 'Failed to send message. Please try again.')
    })
    .finally(() => {
      // Re-enable send button
      this.sendButtonTarget.disabled = false
      this.sendButtonTarget.innerHTML = `
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
        </svg>
        Send
      `
    })
  }

  addMessage(type, content) {
    const messagesContainer = this.messagesTarget
    const messageDiv = document.createElement('div')
    messageDiv.className = 'flex items-start space-x-3'
    
    if (type === 'user') {
      messageDiv.innerHTML = `
        <div class="flex-1"></div>
        <div class="bg-indigo-600 rounded-lg p-3 max-w-md ml-auto">
          <p class="text-white text-sm">${this.escapeHtml(content)}</p>
        </div>
      `
    } else if (type === 'agent') {
      messageDiv.innerHTML = `
        <div class="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center flex-shrink-0">
          <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
          </svg>
        </div>
        <div class="bg-gray-800 rounded-lg p-3 max-w-md">
          <p class="text-white text-sm">${this.escapeHtml(content)}</p>
        </div>
      `
    } else if (type === 'error') {
      messageDiv.innerHTML = `
        <div class="w-8 h-8 bg-red-500 rounded-full flex items-center justify-center flex-shrink-0">
          <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 18.5c-.77.833.192 2.5 1.732 2.5z"/>
          </svg>
        </div>
        <div class="bg-red-900/50 border border-red-500/50 rounded-lg p-3 max-w-md">
          <p class="text-red-200 text-sm">${this.escapeHtml(content)}</p>
        </div>
      `
    }
    
    messagesContainer.appendChild(messageDiv)
    this.scrollToBottom()
  }

  copyUrl(event) {
    event.preventDefault()
    
    const urlInput = event.target.parentElement.querySelector('input')
    urlInput.select()
    urlInput.setSelectionRange(0, 99999) // For mobile devices
    
    try {
      document.execCommand('copy')
      
      // Show success feedback
      const button = event.target
      const originalText = button.textContent
      button.textContent = 'Copied!'
      button.classList.add('bg-green-600', 'hover:bg-green-700')
      button.classList.remove('bg-indigo-600', 'hover:bg-indigo-700')
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove('bg-green-600', 'hover:bg-green-700')
        button.classList.add('bg-indigo-600', 'hover:bg-indigo-700')
      }, 2000)
    } catch (err) {
      console.error('Failed to copy URL:', err)
      alert('Failed to copy URL to clipboard')
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}




