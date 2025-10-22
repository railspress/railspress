// Shared utilities for editor controllers
export class EditorBase {
  constructor(controller) {
    this.controller = controller
    this.debug = window.__EDITOR_DEBUG__ || false
    this.loadPromises = new Map() // Cache for asset loading promises
  }

  log(message, ...args) {
    if (this.debug) {
      console.debug(`[${this.controller.identifier}] ${message}`, ...args)
    }
  }

  logTime(label) {
    if (this.debug) {
      console.time(`[${this.controller.identifier}] ${label}`)
    }
  }

  logTimeEnd(label) {
    if (this.debug) {
      console.timeEnd(`[${this.controller.identifier}] ${label}`)
    }
  }

  emitState(event, data = {}) {
    if (this.debug) {
      window.dispatchEvent(new CustomEvent('editor:state', {
        detail: { editor: this.controller.identifier, event, ...data }
      }))
    }
  }

  // Lazy load assets (scripts/styles) with Promise caching
  async loadAssets(assets) {
    const promises = assets.map(asset => this.loadAsset(asset))
    return Promise.all(promises)
  }

  async loadAsset(asset) {
    const { url, type = 'script', integrity, crossorigin = 'anonymous' } = asset
    const cacheKey = `${type}:${url}`

    if (this.loadPromises.has(cacheKey)) {
      return this.loadPromises.get(cacheKey)
    }

    this.log(`Loading ${type}: ${url}`)
    this.logTime(`asset:loading:${url}`)

    const promise = new Promise((resolve, reject) => {
      if (type === 'script') {
        const script = document.createElement('script')
        script.src = url
        script.crossOrigin = crossorigin
        if (integrity) script.integrity = integrity
        script.onload = () => {
          this.logTimeEnd(`asset:loading:${url}`)
          this.log(`Loaded script: ${url}`)
          resolve()
        }
        script.onerror = () => {
          this.logTimeEnd(`asset:loading:${url}`)
          this.log(`Failed to load script: ${url}`)
          reject(new Error(`Failed to load script: ${url}`))
        }
        document.head.appendChild(script)
      } else if (type === 'style') {
        const link = document.createElement('link')
        link.rel = 'stylesheet'
        link.href = url
        link.crossOrigin = crossorigin
        if (integrity) link.integrity = integrity
        link.onload = () => {
          this.logTimeEnd(`asset:loading:${url}`)
          this.log(`Loaded style: ${url}`)
          resolve()
        }
        link.onerror = () => {
          this.logTimeEnd(`asset:loading:${url}`)
          this.log(`Failed to load style: ${url}`)
          reject(new Error(`Failed to load style: ${url}`))
        }
        document.head.appendChild(link)
      }
    })

    this.loadPromises.set(cacheKey, promise)
    return promise
  }

  // Notify autosave controller of changes
  notifyAutosave() {
    // Dispatch the event that autosave controller listens for
    const event = new CustomEvent('editor:content-changed', {
      detail: { 
        editor: this.controller.identifier,
        content: this.getPlainTextContent()
      }
    })
    document.dispatchEvent(event)
    this.log('Dispatched editor:content-changed event')
  }

  // Setup theme change listener
  setupThemeListener() {
    this.themeHandler = () => {
      this.log('Theme changed')
      this.emitState('theme:changed')
    }
    document.addEventListener('theme:changed', this.themeHandler)
  }

  // Cleanup theme listener
  cleanupThemeListener() {
    if (this.themeHandler) {
      document.removeEventListener('theme:changed', this.themeHandler)
      this.themeHandler = null
    }
  }

  // Get editor content as plain text (for debugging)
  getPlainTextContent() {
    const input = this.controller.element.querySelector('[data-editor-target="input"]')
    if (input) {
      return input.value
    }
    return ''
  }

  // Performance summary
  logPerformanceSummary() {
    if (this.debug && performance.getEntriesByType) {
      const entries = performance.getEntriesByType('measure')
      const editorEntries = entries.filter(entry => 
        entry.name.includes(this.controller.identifier)
      )
      
      if (editorEntries.length > 0) {
        console.table(editorEntries.map(entry => ({
          name: entry.name,
          duration: `${entry.duration.toFixed(2)}ms`,
          startTime: `${entry.startTime.toFixed(2)}ms`
        })))
      }
    }
  }
}
