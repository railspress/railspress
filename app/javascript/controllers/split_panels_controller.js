import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["leftPanel", "middlePanel", "rightPanel"]
  static values = { 
    leftCollapsed: Boolean,
    rightCollapsed: Boolean
  }

  connect() {
    this.leftCollapsedValue = true; // Both start collapsed
    this.rightCollapsedValue = true;
    
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

    try {
      this.splitInstance = Split([leftPanel, middlePanel, rightPanel], {
        sizes: initialSizes,
        minSize: [0, 400, 0], // Allow collapsing to 0
        gutterSize: 2,
        cursor: 'col-resize',
        direction: 'horizontal',
        onDrag: () => {
          // Update panel visibility during drag
          this.updatePanelVisibilities();
        },
        onDragEnd: () => {
          // Save sizes to localStorage
          const sizes = this.splitInstance.getSizes();
          localStorage.setItem('post-editor-panel-sizes', JSON.stringify(sizes));
        }
      });

      // Restore saved sizes if sidebars are visible
      this.restoreSavedSizes();

      console.log('Split.js initialized successfully');
    } catch (error) {
      console.error('Split.js initialization failed:', error);
    }
  }

  getInitialSizes() {
    // Calculate sizes based on collapsed state
    if (this.leftCollapsedValue && this.rightCollapsedValue) {
      return [0, 100, 0]; // Both collapsed, middle full width
    } else if (this.leftCollapsedValue) {
      return [0, 75, 25]; // Only right visible, symmetric
    } else if (this.rightCollapsedValue) {
      return [25, 75, 0]; // Only left visible, symmetric
    } else {
      return [25, 50, 25]; // Both visible, symmetric
    }
  }

  restoreSavedSizes() {
    const savedSizes = localStorage.getItem('post-editor-panel-sizes');
    if (savedSizes && this.splitInstance) {
      try {
        const sizes = JSON.parse(savedSizes);
        // Only restore if both sidebars are visible
        if (!this.leftCollapsedValue && !this.rightCollapsedValue) {
          this.splitInstance.setSizes(sizes);
        }
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
    this.updateSplitSizes();
  }

  toggleRightPanel(event) {
    const collapsed = event.detail.collapsed;
    console.log('Toggle right panel:', collapsed);
    this.rightCollapsedValue = collapsed;
    this.updateSplitSizes();
  }

  updateSplitSizes() {
    if (!this.splitInstance) return;

    const newSizes = this.getInitialSizes();
    this.splitInstance.setSizes(newSizes);
    
    // Ensure panels are properly hidden/visible
    const leftPanel = this.leftPanelTarget;
    const rightPanel = this.rightPanelTarget;
    
    if (this.leftCollapsedValue && leftPanel) {
      leftPanel.style.overflow = 'hidden';
    } else if (leftPanel) {
      leftPanel.style.overflow = 'visible';
    }
    
    if (this.rightCollapsedValue && rightPanel) {
      rightPanel.style.overflow = 'hidden';
    } else if (rightPanel) {
      rightPanel.style.overflow = 'hidden'; // Container doesn't scroll, content inside does
    }
    
    // Save to localStorage
    if (!this.leftCollapsedValue && !this.rightCollapsedValue) {
      localStorage.setItem('post-editor-panel-sizes', JSON.stringify(newSizes));
    }
  }

  disconnect() {
    if (this.splitInstance) {
      this.splitInstance.destroy();
    }
  }
}

