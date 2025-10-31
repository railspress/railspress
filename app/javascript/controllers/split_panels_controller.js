import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["leftPanel", "middlePanel", "rightPanel"]
  static values = { 
    leftCollapsed: Boolean,
    rightCollapsed: Boolean,
    editorType: String // "page" or "post"
  }

  connect() {
    // Detect if this is a page editor
    const isPageEditor = document.querySelector('[data-controller*="railspress-context-page"]') !== null
    
    // For page editors, prefer saved state; fallback to defaults (left open, right closed)
    if (isPageEditor) {
      const savedLeftState = localStorage.getItem('page-editor-left-collapsed')
      const savedRightState = localStorage.getItem('page-editor-right-collapsed')
      if (!this.hasLeftCollapsedValue) {
        this.leftCollapsedValue = savedLeftState !== null ? savedLeftState === 'true' : false
      }
      if (!this.hasRightCollapsedValue) {
        this.rightCollapsedValue = savedRightState !== null ? savedRightState === 'true' : true
      }
    } else {
      // For post editors, use localStorage or defaults
      const savedLeftState = localStorage.getItem('editor-ai-sidebar-collapsed')
      const savedRightState = localStorage.getItem('editor-right-sidebar-collapsed')
      
      if (!this.hasLeftCollapsedValue) {
        this.leftCollapsedValue = savedLeftState !== null ? savedLeftState === 'true' : true
      }
      if (!this.hasRightCollapsedValue) {
        this.rightCollapsedValue = savedRightState !== null ? savedRightState === 'true' : true
      }
    }
    
    // Wait for DOM to be ready
    setTimeout(() => {
      this.initializeSplit();
    }, 100);
  }

  initializeSplit() {
    if (typeof Split === 'undefined') {
      console.warn('Split.js not loaded');
      return;
    }

    const leftPanel = this.leftPanelTarget;
    const middlePanel = this.middlePanelTarget;
    const rightPanel = this.rightPanelTarget;

    console.log('Split panels found:', {
      left: !!leftPanel,
      middle: !!middlePanel,
      right: !!rightPanel
    });

    if (!leftPanel || !middlePanel || !rightPanel) {
      console.error('Could not find all panels');
      return;
    }

    // Initial sizes based on collapsed state
    const initialSizes = this.getInitialSizes();

    const isPageEditor = this.element.closest('[data-controller*="railspress-context-page"]') !== null
    const minSizes = isPageEditor ? [200, 400, 200] : [0, 400, 0] // Page editor: allow right sidebar, Post: allow collapse
    
    try {
      this.splitInstance = Split([leftPanel, middlePanel, rightPanel], {
        sizes: initialSizes,
        minSize: minSizes,
        gutterSize: 2,
        cursor: 'col-resize',
        direction: 'horizontal',
        onDrag: () => {
          // Update panel visibility during drag
          this.updatePanelVisibilities();
        },
        onDragEnd: () => {
          // Save sizes to localStorage with editor-specific key
          const sizes = this.splitInstance.getSizes();
          const storageKey = isPageEditor ? 'page-editor-panel-sizes' : 'post-editor-panel-sizes'
          localStorage.setItem(storageKey, JSON.stringify(sizes));
        }
      });

      // Apply display styles based on collapsed state
      this.updateSplitSizes();

      // Restore saved sizes if any
      this.restoreSavedSizes(isPageEditor)

      console.log('Split.js initialized successfully');
    } catch (error) {
      console.error('Split.js initialization failed:', error);
    }
  }

  getInitialSizes() {
    const isPageEditor = this.element.closest('[data-controller*="railspress-context-page"]') !== null
    
    // Calculate sizes based on collapsed state
    if (this.leftCollapsedValue && this.rightCollapsedValue) {
      return [0, 100, 0]; // Both collapsed, middle full width
    } else if (this.leftCollapsedValue) {
      return [0, 75, 25]; // Only right visible, symmetric
    } else if (this.rightCollapsedValue) {
      // Right hidden, left visible. For page editor we want 50/50/0 default
      return isPageEditor ? [50, 50, 0] : [25, 75, 0];
    } else {
      // Different defaults for page vs post editor
      if (isPageEditor) {
        return [50, 50, 0]; // Page editor: AI/Content 50/50, no right sidebar
      } else {
        return [25, 50, 25]; // Post editor: Both visible, symmetric
      }
    }
  }

  restoreSavedSizes(isPageEditor = false) {
    const storageKey = isPageEditor ? 'page-editor-panel-sizes' : 'post-editor-panel-sizes'
    const savedSizes = localStorage.getItem(storageKey);
    if (savedSizes && this.splitInstance) {
      try {
        const sizes = JSON.parse(savedSizes);
        // Always restore whatever was saved for this editor type
        this.splitInstance.setSizes(sizes);
      } catch (e) {
        console.warn('Could not restore panel sizes:', e);
      }
    }
  }

  updatePanelVisibilities() {
    const sizes = this.splitInstance.getSizes();
    
    // Update collapsed states based on current sizes
    this.leftCollapsedValue = sizes[0] < 1;
    this.rightCollapsedValue = sizes[2] < 1;
  }

  toggleLeftPanel(event) {
    const collapsed = event.detail.collapsed;
    console.log('Toggle left panel:', collapsed);
    this.leftCollapsedValue = collapsed;
    // Save state to localStorage (editor-specific key)
    const isPageEditor = this.element.closest('[data-controller*="railspress-context-page"]') !== null
    const key = isPageEditor ? 'page-editor-left-collapsed' : 'editor-ai-sidebar-collapsed'
    localStorage.setItem(key, collapsed);
    this.updateSplitSizes();
  }

  toggleRightPanel(event) {
    const collapsed = event.detail.collapsed;
    console.log('Toggle right panel:', collapsed);
    this.rightCollapsedValue = collapsed;
    // Save state to localStorage (editor-specific key)
    const isPageEditor = this.element.closest('[data-controller*="railspress-context-page"]') !== null
    const key = isPageEditor ? 'page-editor-right-collapsed' : 'editor-right-sidebar-collapsed'
    localStorage.setItem(key, collapsed);
    this.updateSplitSizes();
  }

  updateSplitSizes() {
    if (!this.splitInstance) return;

    const newSizes = this.getInitialSizes();
    
    // First, apply display styles to hide/show panels
    const leftPanel = this.leftPanelTarget;
    const rightPanel = this.rightPanelTarget;
    
    if (this.leftCollapsedValue && leftPanel) {
      leftPanel.style.display = 'none';
    } else if (leftPanel) {
      leftPanel.style.display = 'flex';
    }
    
    if (this.rightCollapsedValue && rightPanel) {
      rightPanel.style.display = 'none';
    } else if (rightPanel) {
      rightPanel.style.display = 'flex';
    }
    
    // Then set the sizes (Split.js handles the remaining panels)
    this.splitInstance.setSizes(newSizes);
    
    // Save to localStorage with editor-specific key
    const isPageEditor = this.element.closest('[data-controller*="railspress-context-page"]') !== null
    const storageKey = isPageEditor ? 'page-editor-panel-sizes' : 'post-editor-panel-sizes'
    localStorage.setItem(storageKey, JSON.stringify(newSizes));
  }

  disconnect() {
    if (this.splitInstance) {
      this.splitInstance.destroy();
    }
  }
}

