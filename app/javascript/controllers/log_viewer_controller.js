import { Controller } from "@hotwired/stimulus"

// Real-time log viewer with Server-Sent Events
export default class extends Controller {
  static targets = ["output", "status", "search"]
  static values = {
    url: String,
    file: String
  }

  connect() {
    this.autoScroll = true
    this.isPaused = false
    this.lines = []
    this.maxLines = 1000
    this.eventSource = null
    
    this.startStreaming()
  }

  disconnect() {
    this.stopStreaming()
  }

  startStreaming() {
    if (this.eventSource) {
      this.eventSource.close()
    }

    const url = this.urlValue || `/admin/logs/stream?file=${this.fileValue}`
    this.eventSource = new EventSource(url)

    this.eventSource.onopen = () => {
      this.updateStatus('Connected', 'success')
    }

    this.eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        
        if (Array.isArray(data)) {
          // Initial batch of lines
          data.forEach(line => this.addLine(line))
        } else {
          // Single new line
          this.addLine(data)
        }
      } catch (e) {
        console.error('Failed to parse log line:', e)
      }
    }

    this.eventSource.onerror = (error) => {
      console.error('EventSource error:', error)
      this.updateStatus('Disconnected', 'error')
      
      // Try to reconnect after 3 seconds
      setTimeout(() => {
        if (!this.isPaused) {
          this.startStreaming()
        }
      }, 3000)
    }
  }

  stopStreaming() {
    if (this.eventSource) {
      this.eventSource.close()
      this.eventSource = null
    }
    this.updateStatus('Stopped', 'warning')
  }

  addLine(line) {
    if (this.isPaused) return

    this.lines.push(line)
    
    // Keep only last N lines
    if (this.lines.length > this.maxLines) {
      this.lines.shift()
    }

    // Append to output
    const lineElement = this.createLineElement(line)
    this.outputTarget.appendChild(lineElement)

    // Remove old lines from DOM
    while (this.outputTarget.children.length > this.maxLines) {
      this.outputTarget.removeChild(this.outputTarget.firstChild)
    }

    // Auto-scroll to bottom
    if (this.autoScroll) {
      this.scrollToBottom()
    }
  }

  createLineElement(line) {
    const div = document.createElement('div')
    div.className = 'log-line font-mono text-sm py-1 px-2 hover:bg-gray-800'
    
    // Syntax highlighting for log levels
    const text = this.highlightLogLevel(line)
    div.innerHTML = text
    
    return div
  }

  highlightLogLevel(line) {
    // Escape HTML
    let escaped = line
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
    
    // Highlight log levels
    escaped = escaped.replace(/\b(DEBUG)\b/g, '<span class="text-gray-400">$1</span>')
    escaped = escaped.replace(/\b(INFO)\b/g, '<span class="text-blue-400">$1</span>')
    escaped = escaped.replace(/\b(WARN|WARNING)\b/g, '<span class="text-yellow-400">$1</span>')
    escaped = escaped.replace(/\b(ERROR)\b/g, '<span class="text-red-400 font-bold">$1</span>')
    escaped = escaped.replace(/\b(FATAL)\b/g, '<span class="text-red-600 font-bold">$1</span>')
    
    // Highlight timestamps
    escaped = escaped.replace(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+/g, '<span class="text-purple-400">$&</span>')
    
    // Highlight file paths
    escaped = escaped.replace(/([a-z_\/]+\.rb:\d+)/gi, '<span class="text-cyan-400">$&</span>')
    
    return escaped
  }

  togglePause() {
    this.isPaused = !this.isPaused
    
    const button = event.currentTarget
    if (this.isPaused) {
      button.textContent = '▶ Resume'
      button.classList.remove('bg-yellow-600')
      button.classList.add('bg-green-600')
      this.updateStatus('Paused', 'warning')
    } else {
      button.textContent = '⏸ Pause'
      button.classList.remove('bg-green-600')
      button.classList.add('bg-yellow-600')
      this.updateStatus('Streaming', 'success')
    }
  }

  toggleAutoScroll() {
    this.autoScroll = !this.autoScroll
    
    const button = event.currentTarget
    if (this.autoScroll) {
      button.classList.add('bg-indigo-600')
      button.classList.remove('bg-gray-600')
      this.scrollToBottom()
    } else {
      button.classList.remove('bg-indigo-600')
      button.classList.add('bg-gray-600')
    }
  }

  clear() {
    this.lines = []
    this.outputTarget.innerHTML = ''
  }

  scrollToBottom() {
    this.outputTarget.scrollTop = this.outputTarget.scrollHeight
  }

  scrollToTop() {
    this.outputTarget.scrollTop = 0
  }

  search() {
    if (!this.hasSearchTarget) return
    
    const query = this.searchTarget.value.trim()
    if (!query) {
      this.clearHighlights()
      return
    }

    // Highlight matching lines
    const lines = this.outputTarget.querySelectorAll('.log-line')
    let matchCount = 0
    
    lines.forEach(line => {
      const text = line.textContent
      if (text.toLowerCase().includes(query.toLowerCase())) {
        line.classList.add('bg-yellow-900', 'border-l-4', 'border-yellow-500')
        matchCount++
      } else {
        line.classList.remove('bg-yellow-900', 'border-l-4', 'border-yellow-500')
      }
    })

    this.updateStatus(`Found ${matchCount} matches`, 'info')
  }

  clearHighlights() {
    const lines = this.outputTarget.querySelectorAll('.log-line')
    lines.forEach(line => {
      line.classList.remove('bg-yellow-900', 'border-l-4', 'border-yellow-500')
    })
  }

  updateStatus(message, type = 'info') {
    if (!this.hasStatusTarget) return

    const colors = {
      success: 'text-green-400',
      error: 'text-red-400',
      warning: 'text-yellow-400',
      info: 'text-blue-400'
    }

    this.statusTarget.textContent = message
    this.statusTarget.className = `text-sm font-medium ${colors[type] || colors.info}`
  }

  copyToClipboard() {
    const text = this.lines.join('\n')
    navigator.clipboard.writeText(text).then(() => {
      this.updateStatus('Copied to clipboard!', 'success')
      setTimeout(() => this.updateStatus('Streaming', 'success'), 2000)
    })
  }
}








