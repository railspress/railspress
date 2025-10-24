import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "send", "header", "menu", "settingsOverlay", "settingTone", "settingLength", "settingTemperature", "settingMaxTokens", "advancedFields", "modeToggleText", "temperatureValue"]
  static values = {
    agentSlug: String,
    targetSelector: String,
    insertCallback: String,
    recallConversation: Boolean,
    showGreeting: Boolean,
    showSettings: Boolean,
    backgroundColor: String,
    userBubbleColor: String,
    agentBubbleColor: String,
    accentColor: String,
    displayHtmlRaw: Boolean
  }

  async connect() {
    this.conversationHistory = []
    this.sessionUuid = null
    this.currentEventId = null
    this.eventSource = null
    this.settings = this.loadSettings()
    this.setupColors()
    
    // Try to recall session from localStorage
    if (this.recallConversationValue) {
      const hasRecalled = await this.recallSession()
      // If no session was recalled and greeting is enabled, request greeting from server
      if (!hasRecalled && this.showGreetingValue !== false) {
        this.requestGreeting()
      }
    } else if (this.showGreetingValue !== false) {
      this.requestGreeting()
    }
    
    // Setup settings if enabled
    if (this.showSettingsValue) {
      this.setupSettings()
    }
    
    // Close menu when clicking outside
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }

  disconnect() {
    this.closeStream()
  }

  requestGreeting() {
    // Stream greeting from server with empty message
    this.startStreaming('', true) // Second param indicates greeting request
  }

  setupColors() {
    const root = this.element
    if (this.backgroundColorValue) {
      root.style.setProperty('--chat-bg', this.backgroundColorValue)
    }
    if (this.userBubbleColorValue) {
      root.style.setProperty('--chat-user-bubble', this.userBubbleColorValue)
    }
    if (this.agentBubbleColorValue) {
      root.style.setProperty('--chat-agent-bubble', this.agentBubbleColorValue)
    }
    if (this.accentColorValue) {
      root.style.setProperty('--chat-accent', this.accentColorValue)
    }
  }

  async sendMessage() {
    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to UI
    this.addMessage('user', message)
    
    // Clear input
    this.inputTarget.value = ''
    
    // Add to history
    this.conversationHistory.push({ role: 'user', content: message })
    
    // Start streaming
    this.startStreaming(message)
  }

  addMessage(role, content) {
    const messageDiv = document.createElement('div')
    messageDiv.className = `ai-chat-message ${role}`
    
    const avatar = document.createElement('div')
    avatar.className = 'ai-chat-avatar'
    avatar.textContent = role === 'user' ? 'U' : 'AI'
    
    const bubble = document.createElement('div')
    bubble.className = 'ai-chat-bubble'
    
    // Handle HTML content based on displayHtmlRaw setting
    if (role === 'user') {
      bubble.textContent = content
    } else if (this.displayHtmlRawValue) {
      bubble.innerHTML = content
    } else {
      bubble.textContent = content
    }
    
    messageDiv.appendChild(avatar)
    messageDiv.appendChild(bubble)
    
    this.messagesTarget.appendChild(messageDiv)
    this.scrollToBottom()
  }

  addAgentMessage() {
    const messageDiv = document.createElement('div')
    messageDiv.className = 'ai-chat-message agent typing'
    
    const avatar = document.createElement('div')
    avatar.className = 'ai-chat-avatar'
    avatar.textContent = 'AI'
    
    const bubble = document.createElement('div')
    bubble.className = 'ai-chat-bubble'
    
    const contentDiv = document.createElement('div')
    contentDiv.className = 'ai-chat-bubble-content'
    
    bubble.appendChild(contentDiv)
    
    messageDiv.appendChild(avatar)
    messageDiv.appendChild(bubble)
    
    this.messagesTarget.appendChild(messageDiv)
    this.scrollToBottom()
    
    return { messageDiv, bubble, contentDiv }
  }
  
  addActionButtons(bubble, eventId) {
    // Check if actions already exist
    if (bubble.querySelector('.ai-chat-bubble-actions')) return
    
    const actionsDiv = document.createElement('div')
    actionsDiv.className = 'ai-chat-bubble-actions'
    
    // Copy button
    const copyBtn = document.createElement('button')
    copyBtn.className = 'ai-chat-action-icon'
    copyBtn.title = 'Copy'
    copyBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>'
    copyBtn.addEventListener('click', () => this.copyMessage(bubble, eventId))
    
    // Insert button
    const insertBtn = document.createElement('button')
    insertBtn.className = 'ai-chat-action-icon'
    insertBtn.title = 'Insert to editor'
    insertBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>'
    insertBtn.addEventListener('click', () => this.insertMessage(bubble, eventId))
    
    // Like button
    const likeBtn = document.createElement('button')
    likeBtn.className = 'ai-chat-action-icon'
    likeBtn.title = 'Like'
    likeBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" /></svg>'
    likeBtn.addEventListener('click', () => this.likeMessage(bubble, eventId))
    
    // Unlike button
    const unlikeBtn = document.createElement('button')
    unlikeBtn.className = 'ai-chat-action-icon'
    unlikeBtn.title = 'Dislike'
    unlikeBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2m5-10h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5" /></svg>'
    unlikeBtn.addEventListener('click', () => this.unlikeMessage(bubble, eventId))
    
    actionsDiv.appendChild(copyBtn)
    actionsDiv.appendChild(insertBtn)
    actionsDiv.appendChild(likeBtn)
    actionsDiv.appendChild(unlikeBtn)
    
    bubble.appendChild(actionsDiv)
  }

  startStreaming(message, isGreetingRequest = false) {
    this.sendTarget.disabled = true
    
    // Create agent message bubble
    const { messageDiv, bubble, contentDiv } = this.addAgentMessage()
    
    // Build request body
    const formData = new FormData()
    formData.append('agent_slug', this.agentSlugValue)
    formData.append('message', message)
    formData.append('conversation_history', JSON.stringify(this.conversationHistory))
    formData.append('show_greeting', isGreetingRequest ? 'true' : 'false')
    
    // Include settings if available
    if (this.settings) {
      formData.append('settings', JSON.stringify(this.getSettingsContext()))
    }
    
    if (this.sessionUuid) {
      formData.append('session_uuid', this.sessionUuid)
    }
    
    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    // Use Fetch API with streaming
    fetch('/admin/ai_chat/stream', {
      method: 'POST',
      body: formData,
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': csrfToken
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Streaming failed')
      }
      
      const reader = response.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''
      let accumulatedContent = ''
      
      const readChunk = () => {
        reader.read().then(({ done, value }) => {
          if (done) {
            // Remove typing class when done
            messageDiv.classList.remove('typing')
            this.sendTarget.disabled = false
            // Add action buttons (will be updated when data.done is received)
            this.addActionButtons(bubble)
            // Add agent message to conversation history after streaming completes
            this.conversationHistory.push({ role: 'assistant', content: accumulatedContent })
            return
          }
          
          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split('\n')
          buffer = lines.pop() || ''
          
          lines.forEach(line => {
            if (line.startsWith('data: ')) {
              try {
                const data = JSON.parse(line.slice(6))
                if (data.error) {
                  contentDiv.innerHTML = `Error: ${data.error}`
                  messageDiv.classList.remove('typing')
                } else if (data.agent_info) {
                  // Update agent name from server response
                  const title = this.headerTarget.querySelector('.ai-chat-title')
                  if (title) {
                    title.textContent = data.agent_info.name || 'AI Assistant'
                  }
                } else if (data.chunk) {
                  // Accumulate content
                  accumulatedContent += data.chunk
                  
                  // Update display based on displayHtmlRaw setting
                  if (this.displayHtmlRawValue) {
                    contentDiv.innerHTML = accumulatedContent
                  } else {
                    contentDiv.textContent = accumulatedContent
                  }
                  this.scrollToBottom()
                } else if (data.done) {
                  // Store session info
                  this.sessionUuid = data.session_uuid
                  this.currentEventId = data.event_id
                  
                  // Save session to localStorage
                  this.saveSessionToStorage()
                  
                  // Remove typing class when done
                  messageDiv.classList.remove('typing')
                  this.sendTarget.disabled = false
                  // Add action buttons with event ID
                  this.addActionButtons(bubble, data.event_id)
                }
              } catch (e) {
                console.error('Failed to parse SSE data:', e)
              }
            }
          })
          
          readChunk()
        })
      }
      
      readChunk()
    })
    .catch(error => {
      console.error('Streaming error:', error)
      contentDiv.textContent = `Error: ${error.message}`
      messageDiv.classList.remove('typing')
      this.sendTarget.disabled = false
    })
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  handleKeyDown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage()
    }
  }

  closeWidget() {
    this.element.remove()
  }

  insertToTarget() {
    if (!this.targetSelectorValue) return
    
    const target = document.querySelector(this.targetSelectorValue)
    if (!target) return
    
    const lastAgentMessage = this.messagesTarget.querySelector('.ai-chat-message.agent:last-child .ai-chat-bubble')
    if (lastAgentMessage) {
      const content = this.displayHtmlRawValue ? lastAgentMessage.innerHTML : lastAgentMessage.textContent
      target.value = content
      target.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  closeStream() {
    if (this.eventSource) {
      this.eventSource.close()
      this.eventSource = null
    }
  }
  
  toggleMenu() {
    const menu = this.menuTarget
    if (menu.style.display === 'none') {
      menu.style.display = 'block'
    } else {
      menu.style.display = 'none'
    }
  }
  
  async newChat() {
    // Close existing session if it exists
    if (this.sessionUuid) {
      await this.closeSession()
    }
    
    // Clear conversation history
    this.conversationHistory = []
    
    // Clear session UUID
    this.sessionUuid = null
    this.currentEventId = null
    
    // Clear localStorage
    this.clearSessionFromStorage()
    
    // Reset settings to defaults
    this.settings = {
      tone: 'balanced',
      length: 'medium',
      temperature: 0.7,
      maxTokens: 1000
    }
    if (this.showSettingsValue) {
      this.saveSettingsToStorage(this.settings)
      this.applySettings(this.settings)
    }
    
    // Clear all messages
    this.messagesTarget.innerHTML = ''
    
    // Hide menu
    this.menuTarget.style.display = 'none'
    
    // Request greeting for new session
    if (this.showGreetingValue !== false) {
      this.requestGreeting()
    }
  }

  async closeSession() {
    if (!this.sessionUuid) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    try {
      const response = await fetch('/admin/ai_chat/close_session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          agent_slug: this.agentSlugValue,
          session_uuid: this.sessionUuid
        })
      })
      
      if (!response.ok) throw new Error('Failed to close session')
      console.log('Session closed')
    } catch (error) {
      console.error('Failed to close session:', error)
    }
  }
  
  downloadTranscript() {
    // Collect all messages
    const messages = this.messagesTarget.querySelectorAll('.ai-chat-message')
    let transcript = ''
    
    messages.forEach(msg => {
      const role = msg.classList.contains('user') ? 'User' : 'AI'
      const content = msg.querySelector('.ai-chat-bubble').textContent
      transcript += `${role}: ${content}\n\n`
    })
    
    // Create download link
    const blob = new Blob([transcript], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `chat-transcript-${Date.now()}.txt`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    
    // Hide menu
    this.menuTarget.style.display = 'none'
  }
  
  handleClickOutside(event) {
    if (this.menuTarget && this.menuTarget.style.display === 'block') {
      if (!this.element.contains(event.target)) {
        this.menuTarget.style.display = 'none'
      }
    }
  }
  
  async sendFeedback(eventId, feedbackType, category = null, reasonText = null) {
    if (!eventId) return
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    try {
      const response = await fetch('/admin/ai_chat/feedback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          agent_slug: this.agentSlugValue,
          session_uuid: this.sessionUuid,
          event_id: eventId,
          feedback_type: feedbackType,
          category: category,
          reason_text: reasonText
        })
      })
      
      if (!response.ok) throw new Error('Feedback failed')
      console.log(`Feedback ${feedbackType} recorded`)
    } catch (error) {
      console.error('Feedback error:', error)
    }
  }

  copyMessage(bubble, eventId) {
    const contentDiv = bubble.querySelector('.ai-chat-bubble-content')
    if (!contentDiv) return
    
    const content = this.displayHtmlRawValue ? contentDiv.innerHTML : contentDiv.textContent
    navigator.clipboard.writeText(content).then(() => {
      // Could show a toast notification here
      console.log('Message copied to clipboard')
      this.sendFeedback(eventId, 'copy')
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }
  
  insertMessage(bubble, eventId) {
    const contentDiv = bubble.querySelector('.ai-chat-bubble-content')
    if (!contentDiv) return
    
    const content = this.displayHtmlRawValue ? contentDiv.innerHTML : contentDiv.textContent
    
    // Use callback if provided
    if (this.insertCallbackValue) {
      try {
        const callback = new Function('return ' + this.insertCallbackValue)()
        if (typeof callback === 'function') {
          callback(content)
        }
      } catch (e) {
        console.error('Failed to execute insert callback:', e)
      }
      this.sendFeedback(eventId, 'insert')
      return
    }
    
    // Fallback to target selector
    if (!this.targetSelectorValue) return
    
    const target = document.querySelector(this.targetSelectorValue)
    if (!target) return
    
    target.value = content
    target.dispatchEvent(new Event('input', { bubbles: true }))
    this.sendFeedback(eventId, 'insert')
  }
  
  likeMessage(bubble, eventId) {
    console.log('Message liked')
    this.sendFeedback(eventId, 'like')
  }
  
  unlikeMessage(bubble, eventId) {
    console.log('Message unliked')
    this.sendFeedback(eventId, 'unlike', 'incorrect', 'User marked as incorrect')
  }

  // localStorage methods
  getStorageKey() {
    return `chat_session_${this.agentSlugValue}`
  }

  saveSessionToStorage() {
    if (this.sessionUuid) {
      localStorage.setItem(this.getStorageKey(), this.sessionUuid)
    }
  }

  getSessionFromStorage() {
    return localStorage.getItem(this.getStorageKey())
  }

  clearSessionFromStorage() {
    localStorage.removeItem(this.getStorageKey())
  }

  async recallSession() {
    const storedUuid = this.getSessionFromStorage()
    if (!storedUuid) return false

    try {
      const response = await fetch(`/admin/ai_chat/session?agent_slug=${this.agentSlugValue}&session_uuid=${storedUuid}`)
      if (!response.ok) {
        this.clearSessionFromStorage()
        return false
      }

      const data = await response.json()
      this.sessionUuid = data.session_uuid
      this.conversationHistory = data.conversation_history || []

      // Update agent name from session data
      if (data.agent_info && data.agent_info.name) {
        const title = this.headerTarget.querySelector('.ai-chat-title')
        if (title) {
          title.textContent = data.agent_info.name
        }
      }

      // Render recalled messages
      this.conversationHistory.forEach((msg, index) => {
        if (msg.role === 'user') {
          this.addMessage('user', msg.content)
        } else {
          const { bubble } = this.addAgentMessage()
          if (this.displayHtmlRawValue) {
            bubble.querySelector('.ai-chat-bubble-content').innerHTML = msg.content
          } else {
            bubble.querySelector('.ai-chat-bubble-content').textContent = msg.content
          }
          
          // Add action buttons for recalled bot messages with real event ID
          const eventId = msg.event_id || `recalled_${index}`
          this.addActionButtons(bubble, eventId)
        }
      })
      
      // Scroll to bottom after rendering recalled messages
      this.scrollToBottom()
      
      return true
    } catch (error) {
      console.error('Failed to recall session:', error)
      this.clearSessionFromStorage()
      return false
    }
  }

  // Settings Management
  setupSettings() {
    if (!this.showSettingsValue) return
    
    // Load settings from localStorage
    this.applySettings(this.settings)
    
    // Setup temperature slider display
    if (this.hasSettingTemperatureTarget) {
      this.settingTemperatureTarget.addEventListener('input', (e) => {
        this.temperatureValueTarget.textContent = e.target.value
      })
    }
  }

  toggleSettings() {
    if (!this.hasSettingsOverlayTarget) return
    
    const overlay = this.settingsOverlayTarget
    overlay.style.display = overlay.style.display === 'none' ? 'block' : 'none'
  }

  closeSettings() {
    if (this.hasSettingsOverlayTarget) {
      this.settingsOverlayTarget.style.display = 'none'
    }
  }

  toggleAdvanced() {
    if (!this.hasAdvancedFieldsTarget || !this.hasModeToggleTextTarget) return
    
    const fields = this.advancedFieldsTarget
    const toggleText = this.modeToggleTextTarget
    
    const isVisible = fields.style.display !== 'none'
    fields.style.display = isVisible ? 'none' : 'block'
    toggleText.textContent = isVisible ? 'Show Advanced' : 'Hide Advanced'
  }

  saveSettings() {
    const settings = {
      tone: this.settingToneTarget.value,
      length: this.settingLengthTarget.value,
      temperature: parseFloat(this.settingTemperatureTarget.value),
      maxTokens: parseInt(this.settingMaxTokensTarget.value)
    }
    
    this.settings = settings
    this.saveSettingsToStorage(settings)
    this.closeSettings()
  }

  loadSettings() {
    const key = `ai_chat_settings_${this.agentSlugValue}`
    const stored = localStorage.getItem(key)
    
    if (stored) {
      try {
        return JSON.parse(stored)
      } catch (e) {
        console.error('Failed to parse settings:', e)
      }
    }
    
    // Default settings
    return {
      tone: 'balanced',
      length: 'medium',
      temperature: 0.7,
      maxTokens: 1000
    }
  }

  saveSettingsToStorage(settings) {
    const key = `ai_chat_settings_${this.agentSlugValue}`
    localStorage.setItem(key, JSON.stringify(settings))
  }

  applySettings(settings) {
    if (!this.showSettingsValue) return
    
    if (this.hasSettingToneTarget) {
      this.settingToneTarget.value = settings.tone || 'balanced'
    }
    if (this.hasSettingLengthTarget) {
      this.settingLengthTarget.value = settings.length || 'medium'
    }
    if (this.hasSettingTemperatureTarget) {
      this.settingTemperatureTarget.value = settings.temperature || 0.7
      if (this.hasTemperatureValueTarget) {
        this.temperatureValueTarget.textContent = settings.temperature || 0.7
      }
    }
    if (this.hasSettingMaxTokensTarget) {
      this.settingMaxTokensTarget.value = settings.maxTokens || 1000
    }
  }

  getSettingsContext() {
    return {
      tone: this.settings.tone,
      length: this.settings.length,
      temperature: this.settings.temperature,
      max_tokens: this.settings.maxTokens
    }
  }
}

