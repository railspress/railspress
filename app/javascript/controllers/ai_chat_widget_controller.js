import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "send", "header", "menu", "settingsOverlay", "settingAgent", "settingTone", "settingLength", "settingTemperature", "settingMaxTokens", "advancedFields", "modeToggleText", "temperatureValue", "contentOverlay", "contentTextarea", "attachModal", "attachInput", "attachedFilesList", "attachmentChips"]
  static values = {
    agentSlug: String,
    targetSelector: String,
    insertCallback: String,
    recallConversation: Boolean,
    showGreeting: Boolean,
    showSettings: Boolean,
    addContent: Boolean,
    allowAttachments: Boolean,
    allowAgentSwitch: Boolean,
    showCloseButton: Boolean,
    closeButtonCallback: String,
    backgroundColor: String,
    userBubbleColor: String,
    agentBubbleColor: String,
    accentColor: String,
    displayHtmlRaw: Boolean,
    userAvatarUrl: String,
    botAvatarUrl: String,
    userName: String,
    userId: String,
    userEmail: String,
    userRole: String,
    headerColor: String,
    textbarColor: String
  }

  async connect() {
    this.conversationHistory = []
    this.sessionUuid = null
    this.currentEventId = null
    this.eventSource = null
    this.settings = this.loadSettings()
    this.content = ''
    this.editorContent = ''  // Hidden field for auto-captured editor content
    this.attachedFiles = []
    this.setupColors()
    
    // Listen for scroll requests
    this.boundHandleScrollRequest = this.handleScrollRequest.bind(this)
    this.element.addEventListener('scroll-chat-widget', this.boundHandleScrollRequest)
    
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
    
    // Setup content if enabled
    if (this.addContentValue) {
      this.setupContent()
    }
    
    // Auto-capture editor content as context (hidden, doesn't affect manual content)
    this.captureEditorContent().then(editorContent => {
      if (editorContent) {
        this.editorContent = editorContent
      }
    })
    
    // Close menu when clicking outside
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }

  disconnect() {
    this.closeStream()
    if (this.boundHandleScrollRequest) {
      this.element.removeEventListener('scroll-chat-widget', this.boundHandleScrollRequest)
    }
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
    
    // Header color override
    if (this.hasHeaderColorValue && this.headerColorValue) {
      const header = this.headerTarget
      if (header) {
        header.style.backgroundColor = this.headerColorValue
      }
    }
    
    // Textbar color override
    if (this.hasTextbarColorValue && this.textbarColorValue) {
      const inputArea = root.querySelector('.ai-chat-input-area')
      if (inputArea) {
        inputArea.style.backgroundColor = this.textbarColorValue
      }
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
    
    // Use custom avatar if provided, otherwise use initials
    if (role === 'user' && this.hasUserAvatarUrlValue && this.userAvatarUrlValue) {
      avatar.innerHTML = `<img src="${this.userAvatarUrlValue}" alt="User" />`
    } else if (role === 'agent' && this.hasBotAvatarUrlValue && this.botAvatarUrlValue) {
      avatar.innerHTML = `<img src="${this.botAvatarUrlValue}" alt="AI" />`
    } else {
      avatar.textContent = role === 'user' ? 'U' : 'AI'
    }
    
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
    
    // Use custom bot avatar if provided, otherwise use 'AI' text
    if (this.hasBotAvatarUrlValue && this.botAvatarUrlValue) {
      avatar.innerHTML = `<img src="${this.botAvatarUrlValue}" alt="AI" />`
    } else {
      avatar.textContent = 'AI'
    }
    
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
    copyBtn.type = 'button'
    copyBtn.className = 'ai-chat-action-icon'
    copyBtn.title = 'Copy'
    copyBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>'
    copyBtn.addEventListener('click', (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.copyMessage(bubble, eventId)
    })
    
    // Insert button
    const insertBtn = document.createElement('button')
    insertBtn.type = 'button'
    insertBtn.className = 'ai-chat-action-icon'
    insertBtn.title = 'Insert to editor'
    insertBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>'
    insertBtn.addEventListener('click', (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.insertMessage(bubble, eventId)
    })
    
    // Like button
    const likeBtn = document.createElement('button')
    likeBtn.type = 'button'
    likeBtn.className = 'ai-chat-action-icon'
    likeBtn.title = 'Like'
    likeBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" /></svg>'
    likeBtn.addEventListener('click', (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.likeMessage(bubble, eventId)
    })
    
    // Unlike button
    const unlikeBtn = document.createElement('button')
    unlikeBtn.type = 'button'
    unlikeBtn.className = 'ai-chat-action-icon'
    unlikeBtn.title = 'Dislike'
    unlikeBtn.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2m5-10h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5" /></svg>'
    unlikeBtn.addEventListener('click', (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.unlikeMessage(bubble, eventId)
    })
    
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
    
    // Include user info if available
    const userInfo = {}
    if (this.hasUserNameValue && this.userNameValue) {
      userInfo.name = this.userNameValue
    }
    if (this.hasUserIdValue && this.userIdValue) {
      userInfo.id = this.userIdValue
    }
    if (this.hasUserEmailValue && this.userEmailValue) {
      userInfo.email = this.userEmailValue
    }
    if (this.hasUserRoleValue && this.userRoleValue) {
      userInfo.role = this.userRoleValue
    }
    if (Object.keys(userInfo).length > 0) {
      formData.append('user_info', JSON.stringify(userInfo))
    }
    
    // Include settings if available
    if (this.settings) {
      formData.append('settings', JSON.stringify(this.getSettingsContext()))
    }
    
    // Include content if available
    if (this.addContentValue && this.content) {
      formData.append('content', JSON.stringify(this.getContentContext()))
    }
    
    // Include attachments if available
    if (this.allowAttachmentsValue && this.attachedFiles.length > 0) {
      formData.append('attachments', JSON.stringify(this.attachedFiles))
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
            
            // Clear attachments after sending
            this.attachedFiles = []
            if (this.allowAttachmentsValue) {
              this.renderAttachedFiles()
            }
            
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
    console.log('Scrolling to bottom')
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  handleScrollRequest(event) {
    // Scroll to bottom when requested
    requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  handleKeyDown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage()
    }
  }

  closeWidget() {
    // If callback is provided, call it instead of removing the element
    if (this.closeButtonCallbackValue) {
      try {
        const callbackFunc = new Function('return ' + this.closeButtonCallbackValue)()
        if (typeof callbackFunc === 'function') {
          callbackFunc()
        }
      } catch (e) {
        console.error('Error executing close button callback:', e)
        // Fallback to default behavior
        this.element.remove()
      }
    } else {
      this.element.remove()
    }
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
    
    // Clear content
    this.content = ''
    if (this.addContentValue) {
      this.clearContentFromStorage()
      this.applyContent('')
    }
    
    // Re-capture current editor content for new chat
    this.captureEditorContent().then(editorContent => {
      if (editorContent) {
        this.editorContent = editorContent
      }
    })
    
    // Clear attachments
    this.attachedFiles = []
    if (this.allowAttachmentsValue) {
      this.renderAttachedFiles()
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
      showToast('Message copied to clipboard')
      this.sendFeedback(eventId, 'copy')
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }

   async insertMessage(bubble, eventId) {

    const contentDiv = bubble.querySelector('.ai-chat-bubble-content')
    if (!contentDiv) return

    const generatedContent = this.displayHtmlRawValue ? contentDiv.innerHTML : contentDiv.textContent
    
    // Extract heading and populate title if empty
    const { heading, remainingContent, originalContent } = this.extractFirstHeading(generatedContent)
    const titleWasPopulated = this.populateTitleIfEmpty(heading)
    
    // Use remainingContent (without heading) if title was populated, otherwise use original
    const contentToInsert = titleWasPopulated ? remainingContent : originalContent
    
    if (this.insertCallbackValue) {
      try {
        const callback = new Function('return ' + this.insertCallbackValue)()
        if (typeof callback === 'function') {
          callback(contentToInsert)
        }
      } catch (e) {
        console.error('Failed to execute insert callback:', e)
      }
      this.sendFeedback(eventId, 'insert')
      return
    }

    // Detect editor type from the wrapper
    const editorWrapper = document.querySelector('[data-editor-type]');
    const editorType = editorWrapper ? editorWrapper.dataset.editorType : null;
    
    // Try different insertion methods based on editor type
    if (editorType === 'editorjs') {
      // Find EditorJS controller
      const editorjsElement = document.querySelector('[data-controller*="editorjs"]');
      if (editorjsElement) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(editorjsElement, 'editorjs');
        if (controller && controller.editor) {
          try {
            // Import HTML to EditorJS converter
            const { htmlToEditorJS } = await import('editorjs_converter');
            
            // Convert HTML to EditorJS JSON
            const editorJSData = htmlToEditorJS(contentToInsert);
            console.log('Converted HTML to EditorJS:', editorJSData);
            
            // Insert into EditorJS
            await controller.editor.render(editorJSData);
            
            // Trigger saveContent to populate content_json field
            if (controller.saveContent) {
              await controller.saveContent();
            }
            
      this.sendFeedback(eventId, 'insert')
            return;
          } catch (error) {
            console.error('EditorJS insertion failed:', error);
            alert('Failed to insert content: ' + error.message);
          }
        }
      }
    } else if (editorType === 'trix') {
      // Find Trix editor
      const trixEditor = document.querySelector('trix-editor');
      if (trixEditor) {
        trixEditor.editor.loadHTML(contentToInsert);
        this.sendFeedback(eventId, 'insert')
        return;
      }
    } else if (editorType === 'ckeditor5') {
      // Find CKEditor instance
      const ckElement = document.querySelector('[data-controller*="ckeditor5"]');
      if (ckElement) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(ckElement, 'ckeditor5');
        if (controller && controller.editor) {
          controller.editor.setData(contentToInsert);
          this.sendFeedback(eventId, 'insert')
          return;
        }
      }
    }
    
  }
  
  extractFirstHeading(htmlContent) {
    const parser = new DOMParser()
    const doc = parser.parseFromString(htmlContent, 'text/html')
    
    // Find first h1 or h2
    const heading = doc.querySelector('h1, h2')
    
    if (!heading) {
      return { heading: null, remainingContent: htmlContent, originalContent: htmlContent }
    }
    
    // Get plain text from heading
    const headingText = heading.textContent.trim()
    
    // Clone document for remaining content (with heading removed)
    const docWithoutHeading = doc.cloneNode(true)
    const headingToRemove = docWithoutHeading.querySelector('h1, h2')
    if (headingToRemove) {
      headingToRemove.remove()
    }
    const remainingContent = docWithoutHeading.body.innerHTML
    
    // Return both versions: with and without heading
    return { 
      heading: headingText, 
      remainingContent: remainingContent,
      originalContent: htmlContent
    }
  }
  
  populateTitleIfEmpty(headingText) {
    if (!headingText) return false
    
    const titleField = document.querySelector('textarea[name*="title"]')
    if (!titleField) return false
    
    const currentTitle = titleField.value.trim()
    if (currentTitle && currentTitle !== 'Untitled') return false
    
    titleField.value = headingText
    titleField.dispatchEvent(new Event('input', { bubbles: true }))
    
    // Auto-resize title field
    titleField.style.height = 'auto'
    titleField.style.height = titleField.scrollHeight + 'px'
    
    return true
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
    const postUuid = this.getPostUuid()
    return `ai_chat_session_${this.agentSlugValue}_${postUuid}`
  }

  getPostUuid() {
    // Try to get from post form data attribute
    const form = document.querySelector('form[data-post-id]')
    if (form && form.dataset.postId && form.dataset.postId !== 'new') {
      return form.dataset.postId
    }
    
    // Try to get from any form element with data-post-id
    const anyForm = document.querySelector('[data-post-id]')
    if (anyForm && anyForm.dataset.postId && anyForm.dataset.postId !== 'new') {
      return anyForm.dataset.postId
    }
    
    // Try to get from URL
    const urlMatch = window.location.pathname.match(/\/posts\/(\d+)/)
    if (urlMatch) {
      return urlMatch[1]
    }
    
    // Fallback for new posts
    return 'new'
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
      
      // Load content for this session
      if (this.addContentValue) {
        const loadedContent = this.loadContent()
        if (loadedContent && loadedContent.sessionUuid === this.sessionUuid) {
          this.content = loadedContent.content
          this.applyContent(this.content)
        } else {
          // Session doesn't match, clear content
          this.content = ''
          this.clearContentFromStorage()
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
  async setupSettings() {
    if (!this.showSettingsValue) return
    
    // Load agent list if agent switching is enabled
    if (this.allowAgentSwitchValue && this.hasSettingAgentTarget) {
      await this.loadAgents()
      
      // Setup agent change listener
      this.settingAgentTarget.addEventListener('change', (e) => {
        this.switchAgent(e.target.value)
      })
    }
    
    // Load settings from localStorage
    this.applySettings(this.settings)
    
    // Setup temperature slider display
    if (this.hasSettingTemperatureTarget) {
      this.settingTemperatureTarget.addEventListener('input', (e) => {
        this.temperatureValueTarget.textContent = e.target.value
      })
    }
  }
  
  async loadAgents() {
    try {
      const response = await fetch('/admin/ai_agents.json')
      if (!response.ok) throw new Error('Failed to load agents')
      
      const agents = await response.json()
      const select = this.settingAgentTarget
      
      // Clear existing options
      select.innerHTML = ''
      
      // Add options
      agents.forEach(agent => {
        const option = document.createElement('option')
        option.value = agent.slug
        option.textContent = agent.name
        if (agent.slug === this.agentSlugValue) {
          option.selected = true
        }
        select.appendChild(option)
      })
    } catch (error) {
      console.error('Failed to load agents:', error)
    }
  }
  
  async switchAgent(newAgentSlug) {
    // Don't switch if it's the same agent
    if (newAgentSlug === this.agentSlugValue) return
    
    // Close current session if it exists
    if (this.sessionUuid) {
      await this.closeSession()
    }
    
    // Clear conversation history
    this.conversationHistory = []
    this.sessionUuid = null
    this.currentEventId = null
    
    // Clear messages
    this.messagesTarget.innerHTML = ''
    
    // Clear attachments if enabled
    this.attachedFiles = []
    if (this.allowAttachmentsValue) {
      this.renderAttachedFiles()
    }
    
    // Clear content if enabled
    this.content = ''
    if (this.addContentValue) {
      this.applyContent('')
    }
    
    // Update agent slug
    this.agentSlugValue = newAgentSlug
    
    // Clear localStorage for this agent
    if (this.recallConversationValue) {
      this.clearSessionFromStorage()
    }
    
    // Load agent info and update title
    try {
      const response = await fetch(`/admin/ai_chat/agent_info?agent_slug=${newAgentSlug}`)
      if (response.ok) {
        const agentInfo = await response.json()
        const title = this.headerTarget.querySelector('.ai-chat-title')
        if (title && agentInfo.name) {
          title.textContent = agentInfo.name
        }
      }
    } catch (error) {
      console.error('Failed to load agent info:', error)
    }
    
    // Request greeting for new agent
    if (this.showGreetingValue !== false) {
      this.requestGreeting()
    }
    
    // Close settings overlay
    this.closeSettings()
  }

  toggleSettings() {
    if (!this.hasSettingsOverlayTarget) return
    
    const overlay = this.settingsOverlayTarget
    const isOpening = overlay.style.display === 'none'
    
    // Close content overlay if opening settings
    if (isOpening && this.hasContentOverlayTarget) {
      this.contentOverlayTarget.style.display = 'none'
    }
    
    overlay.style.display = isOpening ? 'block' : 'none'
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
      length: this.settingLengthTarget.value
    }
    
    // Only include advanced settings if targets exist
    if (this.hasSettingTemperatureTarget) {
      settings.temperature = parseFloat(this.settingTemperatureTarget.value)
    }
    if (this.hasSettingMaxTokensTarget) {
      settings.maxTokens = parseInt(this.settingMaxTokensTarget.value)
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
    const context = {
      tone: this.settings.tone,
      length: this.settings.length
    }
    
    // Only include advanced settings if present
    if (this.settings.temperature !== undefined) {
      context.temperature = this.settings.temperature
    }
    if (this.settings.maxTokens !== undefined) {
      context.max_tokens = this.settings.maxTokens
    }
    
    return context
  }
  
  // Content Management
  setupContent() {
    if (!this.addContentValue) return
    this.applyContent(this.content)
  }
  
  toggleContent() {
    if (!this.hasContentOverlayTarget) return
    
    const overlay = this.contentOverlayTarget
    const isOpening = overlay.style.display === 'none'
    
    // Close settings overlay if opening content
    if (isOpening && this.hasSettingsOverlayTarget) {
      this.settingsOverlayTarget.style.display = 'none'
    }
    
    overlay.style.display = isOpening ? 'block' : 'none'
  }
  
  closeContent() {
    if (this.hasContentOverlayTarget) {
      this.contentOverlayTarget.style.display = 'none'
    }
  }
  
  saveContent() {
    const content = this.contentTextareaTarget.value
    
    this.content = content
    this.saveContentToStorage(content)
    this.closeContent()
  }
  
  loadContent() {
    const key = `ai_chat_content_${this.agentSlugValue}`
    const stored = localStorage.getItem(key)
    
    if (stored) {
      try {
        return JSON.parse(stored)
      } catch (e) {
        console.error('Failed to parse content:', e)
      }
    }
    
    return null
  }
  
  saveContentToStorage(content) {
    const key = `ai_chat_content_${this.agentSlugValue}`
    const data = {
      content: content,
      sessionUuid: this.sessionUuid
    }
    localStorage.setItem(key, JSON.stringify(data))
  }
  
  clearContentFromStorage() {
    const key = `ai_chat_content_${this.agentSlugValue}`
    localStorage.removeItem(key)
  }
  
  applyContent(content) {
    if (!this.addContentValue || !this.hasContentTextareaTarget) return
    this.contentTextareaTarget.value = content || ''
  }
  
  getContentContext() {
    const context = {}
    
    // Include manual content if provided
    if (this.content) {
      context.manual_content = this.content
    }
    
    // Include auto-captured editor content if available
    if (this.editorContent) {
      context.editor_content = this.editorContent
    }
    
    return context
  }
  
  captureEditorContent() {
    const editorWrapper = document.querySelector('[data-editor-type]')
    const editorType = editorWrapper ? editorWrapper.dataset.editorType : null
    
    if (!editorType) return Promise.resolve('')
    
    try {
      if (editorType === 'editorjs') {
        const editorjsElement = document.querySelector('[data-controller*="editorjs"]')
        if (editorjsElement) {
          const controller = window.Stimulus.getControllerForElementAndIdentifier(editorjsElement, 'editorjs')
          if (controller && controller.editor) {
            return controller.editor.save().then(outputData => {
              return this.convertEditorJSToText(outputData)
            })
          }
        }
      } else if (editorType === 'trix') {
        const trixEditor = document.querySelector('trix-editor')
        if (trixEditor && trixEditor.editor) {
          return Promise.resolve(trixEditor.editor.getDocument().toString())
        }
      } else if (editorType === 'ckeditor5') {
        const ckElement = document.querySelector('[data-controller*="ckeditor5"]')
        if (ckElement) {
          const controller = window.Stimulus.getControllerForElementAndIdentifier(ckElement, 'ckeditor5')
          if (controller && controller.editor) {
            return Promise.resolve(controller.editor.getData())
          }
        }
      }
    } catch (error) {
      console.error('Failed to capture editor content:', error)
    }
    
    return Promise.resolve('')
  }
  
  convertEditorJSToText(editorData) {
    if (!editorData || !editorData.blocks) return ''
    
    return editorData.blocks.map(block => {
      switch (block.type) {
        case 'header':
          return block.data.text
        case 'paragraph':
          return block.data.text
        case 'list':
          return block.data.items.join('\n')
        case 'quote':
          return `"${block.data.text}" - ${block.data.caption || ''}`
        case 'code':
          return block.data.code
        default:
          return block.data.text || ''
      }
    }).filter(text => text.trim()).join('\n\n')
  }
  
  // Attachment Management
  openAttachmentModal() {
    if (!this.hasAttachModalTarget) return
    this.attachModalTarget.style.display = 'block'
  }
  
  closeAttachmentModal() {
    if (this.hasAttachModalTarget) {
      this.attachModalTarget.style.display = 'none'
    }
  }
  
  async handleFileSelect(event) {
    const files = Array.from(event.target.files)
    
    for (const file of files) {
      // Validate file size (5MB max)
      if (file.size > 5 * 1024 * 1024) {
        alert(`File ${file.name} is too large. Maximum size is 5MB.`)
        continue
      }
      
      // Upload file
      const fileData = await this.uploadFile(file)
      if (fileData) {
        this.addAttachedFile(fileData)
      }
    }
    
    // Reset input
    if (this.hasAttachInputTarget) {
      this.attachInputTarget.value = ''
    }
  }
  
  async uploadFile(file) {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('agent_slug', this.agentSlugValue)
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    try {
      const response = await fetch('/admin/ai_chat/upload_attachment', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': csrfToken
        }
      })
      
      if (!response.ok) {
        throw new Error('Upload failed')
      }
      
      return await response.json()
    } catch (error) {
      console.error('File upload error:', error)
      alert('Failed to upload file. Please try again.')
      return null
    }
  }
  
  addAttachedFile(fileData) {
    this.attachedFiles.push(fileData)
    this.renderAttachedFiles()
    this.closeAttachmentModal()
  }
  
  removeAttachedFile(fileId) {
    this.attachedFiles = this.attachedFiles.filter(f => f.id !== fileId)
    this.renderAttachedFiles()
  }
  
  renderAttachedFiles() {
    if (!this.hasAttachmentChipsTarget) return
    
    const container = this.attachmentChipsTarget
    
    if (this.attachedFiles.length === 0) {
      container.style.display = 'none'
      return
    }
    
    container.style.display = 'block'
    container.innerHTML = ''
    
    this.attachedFiles.forEach(file => {
      const chip = document.createElement('div')
      chip.className = 'ai-chat-attachment-chip'
      
      const icon = this.getFileIcon(file.type)
      const name = document.createElement('span')
      name.textContent = file.name
      
      const removeBtn = document.createElement('button')
      removeBtn.className = 'ai-chat-attachment-remove'
      removeBtn.innerHTML = '×'
      removeBtn.addEventListener('click', () => this.removeAttachedFile(file.id))
      
      chip.innerHTML = icon
      chip.appendChild(name)
      chip.appendChild(removeBtn)
      
      container.appendChild(chip)
    })
  }
  
  getFileIcon(type) {
    if (type?.startsWith('image/')) {
      return '<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/></svg>'
    } else if (type === 'application/pdf') {
      return '<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M20 2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-9.5 7.5c0 .83-.67 1.5-1.5 1.5H9v2H7.5V7H10c.83 0 1.5.67 1.5 1.5v1zm5 2c0 .83-.67 1.5-1.5 1.5h-2.5V7H15c.83 0 1.5.67 1.5 1.5v3zm4-3H19v1h1.5V11H19v2h-1.5V7h3v1.5zM9 9.5h1v-1H9v1zm5 2h1v-1h-1v1zm6-2h1v-1h-1v1z"/></svg>'
    } else {
      return '<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/></svg>'
    }
  }
}

