// EditorJS Media Tool
// Allows users to insert media from the media library into EditorJS blocks

export default class MediaTool {
  static get toolbox() {
    return {
      title: 'Media',
      icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 3H17C17.5304 3 18.0391 3.21071 18.4142 3.58579C18.7893 3.96086 19 4.46957 19 5V15C19 15.5304 18.7893 16.0391 18.4142 16.4142C18.0391 16.7893 17.5304 17 17 17H3C2.46957 17 1.96086 16.7893 1.58579 16.4142C1.21071 16.0391 1 15.5304 1 15V5C1 4.46957 1.21071 3.96086 1.58579 3.58579C1.96086 3.21071 2.46957 3 3 3Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M8.5 11.5L10.5 9.5L13.5 12.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M7 11H13" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>'
    };
  }

  static get isReadOnlySupported() {
    return true;
  }

  constructor({ data, api, config, readOnly }) {
    this.api = api;
    this.readOnly = readOnly;
    
    // Handle data structure - could be { media: {...} } or just {...}
    if (data && typeof data === 'object') {
      this.mediaData = data.media || data;
      this.data = data;
    } else {
      this.mediaData = null;
      this.data = {};
    }
    
    this.config = config || {};
    this.wrapper = null;
    this.captionInput = null;
    
    // Bind methods to preserve context
    this.openMediaSelector = this.openMediaSelector.bind(this);
    this.changeMedia = this.changeMedia.bind(this);
    this.removeMedia = this.removeMedia.bind(this);
    this.handleCaptionChange = this.handleCaptionChange.bind(this);
  }

  render() {
    // Don't recreate wrapper if it already exists
    if (this.wrapper) {
      this.wrapper.innerHTML = '';
    } else {
      this.wrapper = document.createElement('div');
      this.wrapper.className = 'media-tool-wrapper';
    }
    
    if (!this.mediaData) {
      this.renderEmptyState();
    } else {
      this.renderMedia();
    }
    
    return this.wrapper;
  }

  renderEmptyState() {
    this.wrapper.innerHTML = '';
    
    const container = document.createElement('div');
    container.className = 'media-tool-empty';
    container.style.cssText = `
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 3rem;
      border: 2px dashed var(--admin-border, #e5e7eb);
      border-radius: 8px;
      text-align: center;
      cursor: pointer;
      transition: all 0.2s ease;
    `;
    container.onmouseenter = (e) => {
      e.target.style.borderColor = 'var(--admin-primary, #3b82f6)';
      e.target.style.backgroundColor = 'var(--admin-primary-light, rgba(59, 130, 246, 0.05))';
    };
    container.onmouseleave = (e) => {
      e.target.style.borderColor = 'var(--admin-border, #e5e7eb)';
      e.target.style.backgroundColor = 'transparent';
    };
    container.onclick = this.openMediaSelector;
    
    container.innerHTML = `
      <svg width="48" height="48" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-bottom: 1rem; opacity: 0.5;">
        <path d="M3 3H17C17.5304 3 18.0391 3.21071 18.4142 3.58579C18.7893 3.96086 19 4.46957 19 5V15C19 15.5304 18.7893 16.0391 18.4142 16.4142C18.0391 16.7893 17.5304 17 17 17H3C2.46957 17 1.96086 16.7893 1.58579 16.4142C1.21071 16.0391 1 15.5304 1 15V5C1 4.46957 1.21071 3.96086 1.58579 3.58579C1.96086 3.21071 2.46957 3 3 3Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M8.5 11.5L10.5 9.5L13.5 12.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
      <p style="margin: 0; font-weight: 500; color: var(--admin-text-primary, #1f2937);">Click to select media</p>
      <p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--admin-text-muted, #6b7280);">Insert image, video, or file</p>
    `;
    
    this.wrapper.appendChild(container);
  }

  renderMedia() {
    this.wrapper.innerHTML = '';
    
    const container = document.createElement('div');
    container.className = 'media-tool-content';
    container.style.cssText = `
      border: 1px solid var(--ce-border, #e5e7eb);
      border-radius: 8px;
      overflow: hidden;
      position: relative;
    `;
    
    // Make the whole block clickable to change media
    if (!this.readOnly) {
      container.style.cursor = 'pointer';
      container.onclick = () => this.changeMedia();
    }
    
    // Check media type - could be in type, file_type, or check if URL ends with image extension
    const mediaType = this.mediaData.type || this.mediaData.file_type;
    
    // Also check if URL looks like an image
    const urlIsImage = this.mediaData.url && (
      this.mediaData.url.match(/\.(jpg|jpeg|png|gif|webp|svg)$/i) ||
      this.mediaData.thumbnail_url
    );
    
    const isImage = (mediaType && mediaType.startsWith('image/')) || urlIsImage;
    const isVideo = mediaType && mediaType.startsWith('video/');
    
    console.log('Rendering media:', { 
      type: this.mediaData.type,
      file_type: this.mediaData.file_type, 
      mediaType, 
      isImage, 
      isVideo, 
      url: this.mediaData.url,
      thumbnail_url: this.mediaData.thumbnail_url,
      mediaData: this.mediaData 
    });
    
    if (isImage) {
      this.renderImage(container);
    } else if (isVideo) {
      this.renderVideo(container);
    } else {
      this.renderFile(container);
    }
    
    this.wrapper.appendChild(container);
  }

  renderImage(container) {
    const mediaUrl = this.mediaData.thumbnail_url || this.mediaData.url;
    
    container.innerHTML = `
      <img src="${mediaUrl}" alt="${this.mediaData.alt_text || this.mediaData.title || ''}" 
           style="width: 100%; height: auto; display: block;">
    `;
  }

  renderVideo(container) {
    const mediaUrl = this.mediaData.url;
    
    container.innerHTML = `
      <video src="${mediaUrl}" controls style="width: 100%; display: block;"></video>
    `;
  }

  renderFile(container) {
    const fileSize = this.mediaData.file_size ? this.formatFileSize(this.mediaData.file_size) : '';
    
    container.innerHTML = `
      <div style="padding: 2rem; background: var(--ce-focus, #f3f4f6); display: flex; align-items: center; gap: 1rem; border-radius: 8px;">
        <svg width="48" height="48" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" style="color: var(--ce-muted, #6b7280);">
          <path d="M5 2H13L17 6V16C17 16.5304 16.7893 17.0391 16.4142 17.4142C16.0391 17.7893 15.5304 18 15 18H5C4.46957 18 3.96086 17.7893 3.58579 17.4142C3.21071 17.0391 3 16.5304 3 16V4C3 3.46957 3.21071 2.96086 3.58579 2.58579C3.96086 2.21071 4.46957 2 5 2Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M13 2V6H17" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <div style="flex: 1; color: var(--ce-text, #1f2937);">
          <div style="font-weight: 500; margin-bottom: 0.25rem;">
            ${this.escapeHTML(this.mediaData.title || 'Untitled')}${fileSize ? ` <span style="color: var(--ce-muted, #6b7280); font-size: 0.875rem;">(${fileSize})</span>` : ''}
          </div>
          <div style="font-size: 0.875rem; color: var(--ce-muted, #6b7280);">
            ${this.mediaData.type || 'File'}
          </div>
        </div>
      </div>
    `;
  }

  createCaptionInput() {
    return `
      <input type="text" class="media-tool-caption" placeholder="Add caption (optional)" 
             value="${this.mediaData.caption || ''}"
             style="width: 100%; padding: 0.5rem; border: 1px solid var(--admin-border, #e5e7eb); border-radius: 4px; font-size: 0.875rem;">
    `;
  }

  openMediaSelector() {
    // Store reference to this tool instance for callback
    window._currentMediaToolInstance = this;
    
    // Find and open the media selector dialog
    const dialog = document.getElementById('editorjs-media-selector');
    if (!dialog) {
      console.error('Media selector dialog not found');
      return;
    }

    // Get the media-selector controller and open it
    const controller = window.Stimulus?.getControllerForElementAndIdentifier?.(dialog, "media-selector");
    if (controller) {
      controller.openDialog();
    } else {
      // Fallback: just show the dialog
      dialog.classList.remove("hidden");
    }
  }

  changeMedia() {
    this.openMediaSelector();
  }

  removeMedia() {
    this.mediaData = null;
    this.renderEmptyState();
    this.notifyChange();
  }

  handleCaptionChange(event) {
    if (this.mediaData) {
      this.mediaData.caption = event.target.value;
      this.notifyChange();
    }
  }

  notifyChange() {
    // Just trigger the EditorJS onChange event
    if (this.api && this.api.listeners && typeof this.api.listeners.trigger === 'function') {
      this.api.listeners.trigger('change');
    }
  }

  save(blockContent) {
    if (!this.mediaData || !this.mediaData.id) {
      return {};
    }
    return {
      media: this.mediaData
    };
  }

  validate(savedData) {
    return savedData.media && savedData.media.id;
  }
  
  static get sanitize() {
    return {
      media: {}
    };
  }

  // Helper methods
  escapeHTML(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  formatFileSize(bytes) {
    if (!bytes) return '';
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  }

  static get pasteConfig() {
    return {
      tags: ['figure', 'img', 'video', 'a']
    };
  }

  onPaste(event) {
    // Handle paste events if needed
    return false;
  }
}

// Global handler for when media is selected
window.handleEditorJSMediaSelected = function(mediaData) {
  console.log('handleEditorJSMediaSelected called with:', mediaData);
  
  const toolInstance = window._currentMediaToolInstance;
  if (toolInstance) {
    // Handle array of media (multi-select) or single media
    const isArray = Array.isArray(mediaData);
    const mediaItems = isArray ? mediaData : [mediaData];
    
    if (isArray && mediaItems.length > 1) {
      // Multiple items selected - insert each as a separate block
      const editor = toolInstance.api;
      mediaItems.forEach(mediaItem => {
        editor.blocks.insert('media', {
          media: mediaItem
        });
      });
    } else {
      // Single item selected - update current block
      toolInstance.mediaData = mediaItems[0];
      console.log('Updated toolInstance.mediaData:', toolInstance.mediaData);
      
      // Re-render the block with the new media - clear and rebuild
      if (toolInstance.wrapper) {
        toolInstance.wrapper.innerHTML = '';
      }
      
      if (!toolInstance.mediaData) {
        console.log('No media data, rendering empty state');
        toolInstance.renderEmptyState();
      } else {
        console.log('Has media data, rendering media');
        toolInstance.renderMedia();
      }
      
      // Notify EditorJS that the block data has changed
      toolInstance.notifyChange();
    }
    
    window._currentMediaToolInstance = null;
  } else {
    console.warn('No current media tool instance found');
  }
  
  // Close the dialog
  const dialog = document.getElementById('editorjs-media-selector');
  if (dialog) {
    const controller = window.Stimulus?.getControllerForElementAndIdentifier?.(dialog, "media-selector");
    if (controller) {
      controller.closeDialog();
    } else {
      dialog.classList.add("hidden");
    }
  }
};

