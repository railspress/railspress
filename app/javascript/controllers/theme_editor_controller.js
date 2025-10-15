import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["themeSelector"]
  
  connect() {
    console.log('Theme Editor Controller connected')
    this.initializeMonaco()
  }
  
  disconnect() {
    if (this.editor) {
      this.editor.dispose()
    }
  }
  
  initializeMonaco() {
    console.log('Initializing Monaco Editor...')
    if (typeof monaco === 'undefined') {
      console.error('Monaco Editor not loaded')
      return
    }
    console.log('Monaco Editor is available')
    
    // Find the Monaco container within this controller's element
    const container = this.element.querySelector('#monaco-container')
    if (!container) {
      console.error('Monaco container not found')
      console.log('Available elements:', this.element.querySelectorAll('*'))
      return
    }
    console.log('Monaco container found:', container)
    
    // Monaco theme mapping
    const monacoThemes = {
      'auto': 'vs',
      'dark': 'vs-dark',
      'light': 'vs',
      'blue': 'vs-dark-blue'
    }
    
    // Get current user's preferred theme or default to auto
    const currentTheme = this.data.get('current-theme-value') || 'auto'
    
    // Language mapping
    const languageMap = {
      '.html': 'html',
      '.erb': 'html',
      '.liquid': 'html',
      '.css': 'css',
      '.scss': 'scss',
      '.sass': 'scss',
      '.js': 'javascript',
      '.json': 'json',
      '.yml': 'yaml',
      '.yaml': 'yaml',
      '.md': 'markdown',
      '.rb': 'ruby',
      '.txt': 'plaintext'
    }
    
    const fileExt = this.data.get('file-extension-value') || ''
    const language = languageMap[fileExt] || 'plaintext'
    
    // Create editor with proper tab support and styling
    console.log('Creating Monaco Editor with options:', {
      value: this.data.get('current-content-value') || '',
      language: language,
      theme: monacoThemes[currentTheme] || 'vs'
    })
    
    this.editor = monaco.editor.create(container, {
      value: this.data.get('current-content-value') || '',
      language: language,
      theme: monacoThemes[currentTheme] || 'vs',
      automaticLayout: true,
      fontSize: 16,
      fontFamily: 'Monaco, Menlo, "Ubuntu Mono", monospace',
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
      // Enable proper tab support
      tabIndex: 0,
      accessibilitySupport: 'auto',
      // Better styling
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
      // Enable editor tabs
      tabFocusMode: false,
      // Better visual styling
      renderLineHighlight: 'line',
      selectOnLineNumbers: true,
      roundedSelection: false,
      readOnly: false,
      // Enable multiple editor tabs (this is key for tab support)
      enableSplitViewResizing: true
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
    
    // Set the dropdown to current theme
    if (this.hasThemeSelectorTarget) {
      this.themeSelectorTarget.value = currentTheme
    }
    
    console.log('Monaco Editor created successfully!')
    
    // Listen for content changes
    this.editor.onDidChangeModelContent(() => {
      this.markAsDirty()
    })
    
    // Keyboard shortcuts
    this.editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => {
      this.saveFile()
    })
    
    this.editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyF, () => {
      this.editor.getAction('actions.find').run()
    })
    
    // Ensure editor resizes properly
    window.addEventListener('resize', () => {
      if (this.editor) {
        this.editor.layout()
      }
    })
  }
  
  changeTheme(event) {
    const themePreference = event.target.value
    const monacoThemes = {
      'auto': 'vs',
      'dark': 'vs-dark',
      'light': 'vs',
      'blue': 'vs-dark-blue'
    }
    
    const monacoTheme = monacoThemes[themePreference] || 'vs'
    
    if (this.editor) {
      monaco.editor.setTheme(monacoTheme)
    }
    
    // Save user preference
    this.saveThemePreference(themePreference)
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
  
  saveFile() {
    if (!this.editor) {
      this.showError('Editor not initialized')
      return
    }
    
    const content = this.editor.getValue()
    const filePath = this.data.get('current-file-value')
    
    if (!filePath) {
      this.showError('No file selected')
      return
    }
    
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
        this.markAsClean()
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
  
  markAsDirty() {
    // Mark current file as having unsaved changes
    this.data.set('dirty', 'true')
    // You can add visual indicators here
  }
  
  markAsClean() {
    // Mark current file as clean
    this.data.set('dirty', 'false')
    // Remove visual indicators here
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
