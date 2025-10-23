class UppyEditorTool {
  static get toolbox() {
    return {
      title: 'Uppy Upload',
      icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10 1L3 7h4v8h6V7h4l-7-6zm8 17H2v2h16v-2z" fill="currentColor"/></svg>'
    };
  }
  
  constructor({data, config, api}) {
    this.api = api;
    this.data = data || {};
    this.data.files = this.data.files || [];
    this.config = config || {};
    this.wrapper = null;
    this.uppy = null;
    this.uppyContainer = null;
  }
  
  render() {
    this.wrapper = document.createElement('div');
    this.wrapper.classList.add('uppy-editor-block');
    
    // Store tool reference for removal function
    this.wrapper._uppyTool = this;
    
    // Create Uppy container
    this.uppyContainer = document.createElement('div');
    this.uppyContainer.id = `uppy-${Date.now()}`;
    this.wrapper.appendChild(this.uppyContainer);
    
    // Initialize Uppy
    this.initializeUppy();
    
    // Show uploaded files if any
    if (this.data.files && this.data.files.length > 0) {
      this.renderUploadedFiles();
    }
    
    return this.wrapper;
  }
  
  initializeUppy() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    
    // Wait for Uppy to be available
    if (!window.Uppy || !window.UppyDashboard || !window.UppyXHR) {
      console.error('Uppy not loaded');
      return;
    }
    
    // Determine theme from localStorage
    const savedTheme = localStorage.getItem('theme');
    const currentTheme = savedTheme || 'dark'; // default to dark
    const uppyTheme = currentTheme === 'auto' ? 'light' : currentTheme; // Uppy doesn't support 'auto'
    
    console.log('Uppy theme determined:', { savedTheme, currentTheme, uppyTheme });
    
    this.uppy = new window.Uppy({
      id: this.uppyContainer.id,
      autoProceed: this.config.autoProceed || false,
      restrictions: {
        maxFileSize: this.config.maxFileSize,
        maxNumberOfFiles: this.config.maxNumberOfFiles
      }
    });
    
    this.uppy.use(window.UppyDashboard, {
      target: this.uppyContainer,
      inline: true,
      height: 350,
      proudlyDisplayPoweredByUppy: false,
      showProgressDetails: true,
      theme: uppyTheme
    });
    
    // Configure XHR Upload
    this.uppy.use(window.UppyXHR, {
      endpoint: this.config.endpoint,
      formData: true,
      fieldName: 'file',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      }
    });
    
    // Handle upload success (alternative to complete)
    this.uppy.on('upload-success', (file, response) => {
      console.log('Upload success event:', file, response);
      
      try {
        let responseData = response?.body || response?.response || response;
        
        // Parse JSON if it's a string
        if (typeof responseData === 'string') {
          try {
            responseData = JSON.parse(responseData);
          } catch (e) {
            console.error('Failed to parse success response:', e);
            return;
          }
        }
        
        console.log('Success response data:', responseData);
        if (responseData && responseData.success === 1) {
          // Ensure data object exists
          if (!this.data) {
            this.data = {};
          }
          // Ensure files array exists
          if (!this.data.files) {
            this.data.files = [];
          }
          
          // Check if file already exists to prevent duplicates
          const fileExists = this.data.files.some(existingFile => existingFile.id === responseData.file.id);
          if (!fileExists) {
            this.data.files.push({
              url: responseData.file.url,
              name: responseData.file.name,
              id: responseData.file.id,
              type: file.type
            });
            console.log('File added via success handler:', this.data.files);
            
            // Hide Uppy Dashboard after successful upload
            this.hideUppyDashboard();
            
            this.renderUploadedFiles();
            if (this.api && this.api.blocks && typeof this.api.blocks.dispatchChange === 'function') {
              this.api.blocks.dispatchChange();
            }
          } else {
            console.log('File already exists, skipping duplicate:', responseData.file.id);
          }
        }
      } catch (error) {
        console.error('Error in upload-success handler:', error);
      }
    });
    
    // Handle upload complete - just for logging, files already added in upload-success
    this.uppy.on('complete', (result) => {
      console.log('Uppy complete result:', result);
      // Files are already added via upload-success handler
      // Just ensure UI is updated
      this.renderUploadedFiles();
      if (this.api && this.api.blocks && typeof this.api.blocks.dispatchChange === 'function') {
        this.api.blocks.dispatchChange();
      }
    });
    
    // Handle upload errors
    this.uppy.on('upload-error', (file, error) => {
      console.error('Upload failed:', error);
    });
    
    // Listen for theme changes and update Uppy theme
    this.setupThemeListener();
  }
  
  setupThemeListener() {
    // Listen for storage changes (theme updates)
    window.addEventListener('storage', (e) => {
      if (e.key === 'theme' && this.uppy) {
        const newTheme = e.newValue || 'dark';
        const uppyTheme = newTheme === 'auto' ? 'light' : newTheme;
        console.log('Theme changed, updating Uppy theme:', { newTheme, uppyTheme });
        
        // Update Uppy theme by recreating the dashboard
        if (this.uppy.getPlugin('Dashboard')) {
          this.uppy.getPlugin('Dashboard').setOptions({ theme: uppyTheme });
        }
      }
    });
    
    // Also listen for theme toggle events (in case localStorage isn't used)
    document.addEventListener('theme-changed', (e) => {
      if (this.uppy && e.detail) {
        const uppyTheme = e.detail.theme === 'auto' ? 'light' : e.detail.theme;
        console.log('Theme changed via event, updating Uppy theme:', uppyTheme);
        
        if (this.uppy.getPlugin('Dashboard')) {
          this.uppy.getPlugin('Dashboard').setOptions({ theme: uppyTheme });
        }
      }
    });
  }
  
  renderUploadedFiles() {
    if (!this.data.files || this.data.files.length === 0) {
      const existingFilesDiv = this.wrapper.querySelector('.uppy-uploaded-files');
      if (existingFilesDiv) {
        existingFilesDiv.remove();
      }
      return;
    }
    
    let filesHtml = '<div class="uppy-uploaded-files mt-6">';
    
    this.data.files.forEach((file, index) => {
      const isImage = file.type && file.type.startsWith('image/');
      
      if (isImage) {
        // Render image like EditorJS image tool - full width with editable caption
        const caption = file.caption || file.name;
        filesHtml += `<figure class="group relative mb-6">
          <div class="relative w-full">
            <img src="${file.url}" alt="${file.name}" class="w-full h-auto rounded-lg">
            <div class="absolute top-4 right-4 bg-black bg-opacity-50 backdrop-blur-sm rounded-lg p-2 opacity-0 group-hover:opacity-100 transition-opacity">
              <button onclick="window.removeUppyFile(${index}, '${this.uppyContainer.id}')" class="text-white hover:text-red-400 text-sm font-medium">
                Remove
              </button>
            </div>
          </div>
          <figcaption class="text-sm text-gray-400 dark:text-gray-500 mt-2 px-2">
            <input 
              type="text" 
              value="${this.escapeHtml(caption)}" 
              placeholder="Enter caption..."
              class="w-full bg-transparent border-none outline-none focus:text-gray-300 dark:focus:text-gray-200"
              onblur="window.updateUppyCaption(${index}, '${this.uppyContainer.id}', this.value)"
            >
          </figcaption>
        </figure>`;
      } else {
        // Render non-image files as download links
        filesHtml += `<div class="group relative mb-4 p-4 border border-gray-600 dark:border-gray-700 rounded-lg hover:border-gray-500 dark:hover:border-gray-600 transition-all">
          <div class="flex items-center gap-3">
            <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <div class="flex-1">
              <p class="text-sm text-gray-300 dark:text-gray-200">${file.name}</p>
              <a href="${file.url}" download="${file.name}" class="text-xs text-blue-400 hover:text-blue-300">Download</a>
            </div>
            <button onclick="window.removeUppyFile(${index}, '${this.uppyContainer.id}')" class="text-red-400 hover:text-red-300 text-sm opacity-0 group-hover:opacity-100 transition-opacity">
              Remove
            </button>
          </div>
        </div>`;
      }
    });
    
    filesHtml += '</div>';
    
    const existingFilesDiv = this.wrapper.querySelector('.uppy-uploaded-files');
    if (existingFilesDiv) {
      existingFilesDiv.outerHTML = filesHtml;
    } else {
      this.wrapper.insertAdjacentHTML('beforeend', filesHtml);
    }
  }
  
  save(blockContent) {
    return {
      files: this.data.files
    };
  }
  
  destroy() {
    if (this.uppy) {
      this.uppy.close();
    }
  }
  
  hideUppyDashboard() {
    if (this.uppyContainer) {
      this.uppyContainer.style.display = 'none';
    }
  }
  
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Global function to remove files
window.removeUppyFile = function(index, containerId) {
  const container = document.getElementById(containerId);
  if (container) {
    const block = container.closest('.uppy-editor-block');
    if (block) {
      const tool = block._uppyTool;
      if (tool && tool.data.files) {
        tool.data.files.splice(index, 1);
        tool.renderUploadedFiles();
        if (tool.api && tool.api.blocks) {
          // EditorJS API method to notify of changes
          if (typeof tool.api.blocks.dispatchChange === 'function') {
            tool.api.blocks.dispatchChange();
          } else {
            console.warn('EditorJS dispatchChange method not found');
          }
        }
      }
    }
  }
};

// Global function to update caption
window.updateUppyCaption = function(index, containerId, caption) {
  const container = document.getElementById(containerId);
  if (container) {
    const block = container.closest('.uppy-editor-block');
    if (block) {
      const tool = block._uppyTool;
      if (tool && tool.data.files && tool.data.files[index]) {
        tool.data.files[index].caption = caption;
        if (tool.api && tool.api.blocks) {
          // EditorJS API method to notify of changes
          if (typeof tool.api.blocks.dispatchChange === 'function') {
            tool.api.blocks.dispatchChange();
          }
        }
      }
    }
  }
};

