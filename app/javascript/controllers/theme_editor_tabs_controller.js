import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabContainer", "editorContainer"]
  static values = { 
    currentFile: String,
    currentContent: String,
    currentTheme: String
  }

  connect() {
    this.openTabs = []
    this.activeTabId = null
    this.tabCounter = 0
    this.editor = null
    
    // Initialize with current file if available
    if (this.currentFileValue) {
      this.addTab(this.currentFileValue, this.currentContentValue || '', true)
    }
    
    // Initialize Monaco Editor
    this.initializeMonaco()
  }

  disconnect() {
    if (this.editor) {
      this.editor.dispose()
    }
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  initializeMonaco() {
    if (typeof monaco === 'undefined') {
      console.error('Monaco Editor not loaded')
      return
    }

    // Create Monaco Editor
    this.editor = monaco.editor.create(this.editorContainerTarget, {
      value: '',
      language: 'plaintext',
      theme: this.getMonacoTheme(),
      automaticLayout: true,
      fontSize: 14,
      fontFamily: 'Monaco, Menlo, "Ubuntu Mono", "Fira Code", monospace',
      lineNumbers: 'on',
      minimap: { enabled: true },
      scrollBeyondLastLine: false,
      wordWrap: 'on',
      tabSize: 2,
      insertSpaces: false,
      useTabStops: true,
      tabCompletion: 'off',
      detectIndentation: false,
      formatOnPaste: true,
      formatOnType: true,
      fixedOverflowWidgets: true,
      padding: { top: 20, bottom: 20, left: 20, right: 20 },
      bracketPairColorization: { enabled: true },
      guides: {
        bracketPairs: true,
        indentation: true,
        highlightActiveIndentation: true
      },
      renderWhitespace: 'selection',
      cursorBlinking: 'blink',
      cursorSmoothCaretAnimation: 'on',
      smoothScrolling: true,
      contextmenu: true,
      mouseWheelZoom: true,
      renderLineHighlight: 'line',
      selectOnLineNumbers: true,
      roundedSelection: false,
      readOnly: false
    })

    // Configure tab behavior
    monaco.editor.setTabFocusMode(false)
    this.editor.updateOptions({
      detectIndentation: false,
      insertSpaces: false,
      tabSize: 2,
      useTabStops: true,
      tabCompletion: 'off'
    })

    // Custom tab handling
    this.editor.addCommand(monaco.KeyCode.Tab, () => {
      this.editor.trigger('keyboard', 'type', { text: '\t' })
    })

    this.editor.addCommand(monaco.KeyMod.Shift | monaco.KeyCode.Tab, () => {
      this.editor.trigger('keyboard', 'outdent', {})
    })

    // Keyboard shortcuts
    this.editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => {
      this.saveFile()
    })

    this.editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyF, () => {
      this.editor.getAction('actions.find').run()
    })

    // Listen for content changes
    this.editor.onDidChangeModelContent(() => {
      this.markCurrentTabDirty()
    })

    // Ensure editor resizes properly
    const resizeObserver = new ResizeObserver(() => {
      if (this.editor) {
        this.editor.layout()
      }
    })
    resizeObserver.observe(this.editorContainerTarget)

    window.addEventListener('resize', () => {
      if (this.editor) {
        this.editor.layout()
      }
    })

    // Store resize observer for cleanup
    this.resizeObserver = resizeObserver
  }

  addTab(filePath, content, isActive = false) {
    const tabId = `tab-${++this.tabCounter}`
    const fileName = filePath.split('/').pop()
    const fileExt = fileName.split('.').pop() || ''
    
    // Check if tab already exists
    const existingTab = this.openTabs.find(tab => tab.filePath === filePath)
    if (existingTab) {
      this.switchToTab(existingTab.id)
      return existingTab.id
    }
    
    const tab = {
      id: tabId,
      filePath: filePath,
      content: content,
      dirty: false,
      language: this.getLanguageFromExtension(fileExt)
    }
    
    this.openTabs.push(tab)
    
    // Create tab element
    const tabElement = document.createElement('div')
    tabElement.className = `tab ${isActive ? 'active' : ''}`
    tabElement.id = tabId
    tabElement.innerHTML = `
      <span class="tab-filename">${fileName}</span>
      <span class="tab-close" data-action="click->theme-editor-tabs#closeTab" data-tab-id="${tabId}">×</span>
    `
    
    // Add click handler
    tabElement.addEventListener('click', (e) => {
      if (!e.target.classList.contains('tab-close')) {
        this.switchToTab(tabId)
      }
    })
    
    // Add to container
    this.tabContainerTarget.appendChild(tabElement)
    
    if (isActive) {
      this.activeTabId = tabId
      this.updateEditorContent(content, tab.language)
    }
    
    return tabId
  }

  switchToTab(tabId) {
    const tab = this.openTabs.find(t => t.id === tabId)
    if (!tab) return
    
    // Update active tab
    this.tabContainerTarget.querySelectorAll('.tab').forEach(t => t.classList.remove('active'))
    document.getElementById(tabId).classList.add('active')
    this.activeTabId = tabId
    
    // Update editor content
    this.updateEditorContent(tab.content, tab.language)
  }

  closeTab(event) {
    const tabId = event.target.dataset.tabId
    const tabIndex = this.openTabs.findIndex(t => t.id === tabId)
    if (tabIndex === -1) return
    
    const tab = this.openTabs[tabIndex]
    
    // Check if tab has unsaved changes
    if (tab.dirty) {
      const fileName = tab.filePath.split('/').pop()
      if (!confirm(`Save changes to ${fileName}?`)) {
        return
      }
      this.saveFile()
    }
    
    // Remove tab
    this.openTabs.splice(tabIndex, 1)
    document.getElementById(tabId).remove()
    
    // Switch to another tab if this was active
    if (this.activeTabId === tabId) {
      if (this.openTabs.length > 0) {
        const newActiveTab = this.openTabs[Math.max(0, tabIndex - 1)]
        this.switchToTab(newActiveTab.id)
      } else {
        // No tabs left, show empty state
        this.activeTabId = null
        this.updateEditorContent('', 'plaintext')
      }
    }
  }

  updateEditorContent(content, language) {
    if (this.editor) {
      this.editor.setValue(content || '')
      monaco.editor.setModelLanguage(this.editor.getModel(), language)
    }
  }

  markCurrentTabDirty() {
    if (this.activeTabId) {
      const tab = this.openTabs.find(t => t.id === this.activeTabId)
      if (tab) {
        tab.dirty = true
        document.getElementById(this.activeTabId).classList.add('dirty')
        // Update content in tab
        tab.content = this.editor.getValue()
      }
    }
  }

  markCurrentTabClean() {
    if (this.activeTabId) {
      const tab = this.openTabs.find(t => t.id === this.activeTabId)
      if (tab) {
        tab.dirty = false
        document.getElementById(this.activeTabId).classList.remove('dirty')
      }
    }
  }

  openFile(event) {
    const filePath = event.target.closest('[data-file-path]').dataset.filePath
    this.loadFileContent(filePath)
  }

  async loadFileContent(filePath) {
    try {
      const response = await fetch(`/admin/theme_editor/${encodeURIComponent(filePath)}`)
      if (response.ok) {
        const data = await response.json()
        this.addTab(filePath, data.content, true)
      } else {
        this.showError('Failed to load file content')
      }
    } catch (error) {
      this.showError('Error loading file: ' + error.message)
      console.error('Error loading file:', error)
    }
  }

  saveFile() {
    if (!this.editor || !this.activeTabId) {
      this.showError('No active tab to save')
      return
    }
    
    const content = this.editor.getValue()
    const tab = this.openTabs.find(t => t.id === this.activeTabId)
    
    if (!tab) {
      this.showError('No active tab found')
      return
    }
    
    const filePath = tab.filePath
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    fetch(`/admin/theme_editor/${encodeURIComponent(filePath)}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        file: {
          content: content
        }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update tab content and mark as clean
        tab.content = content
        this.markCurrentTabClean()
        this.showSuccess('File saved successfully!')
      } else {
        this.showError(data.errors.join(', '))
      }
    })
    .catch(error => {
      this.showError('Failed to save file')
      console.error(error)
    })
  }

  formatCode() {
    if (this.editor) {
      this.editor.getAction('editor.action.formatDocument').run()
    }
  }

  openFindReplace() {
    if (this.editor) {
      this.editor.getAction('actions.find').run()
    }
  }

  changeTheme(event) {
    const themePreference = event.target.value
    const monacoTheme = this.getMonacoTheme(themePreference)
    
    if (this.editor) {
      monaco.editor.setTheme(monacoTheme)
    }
    
    // Save user preference
    this.saveThemePreference(themePreference)
  }

  getMonacoTheme(themePreference = this.currentThemeValue) {
    const monacoThemes = {
      'auto': 'vs',
      'dark': 'vs-dark',
      'light': 'vs',
      'blue': 'vs-dark-blue'
    }
    
    return monacoThemes[themePreference] || 'vs'
  }

  getLanguageFromExtension(ext) {
    const languageMap = {
      'html': 'html',
      'erb': 'html',
      'liquid': 'html',
      'css': 'css',
      'scss': 'scss',
      'sass': 'scss',
      'js': 'javascript',
      'json': 'json',
      'yml': 'yaml',
      'yaml': 'yaml',
      'md': 'markdown',
      'rb': 'ruby',
      'txt': 'plaintext'
    }
    
    return languageMap[ext.toLowerCase()] || 'plaintext'
  }

  saveThemePreference(themePreference) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    fetch('/admin/users/update_monaco_theme', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        monaco_theme: themePreference
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        console.log('Monaco theme preference saved:', data.theme)
      } else {
        console.error('Failed to save Monaco theme preference:', data.errors)
      }
    })
    .catch(error => {
      console.error('Error saving Monaco theme preference:', error)
    })
  }

  showSuccess(message) {
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'success',
        title: 'Success!',
        text: message,
        toast: true,
        position: 'top-end',
        timer: 3000,
        showConfirmButton: false
      })
    }
  }

  showError(message) {
    if (typeof Swal !== 'undefined') {
      Swal.fire('Error', message, 'error')
    } else {
      alert(message)
    }
  }
}
