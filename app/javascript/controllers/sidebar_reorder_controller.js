import { Controller } from "@hotwired/stimulus"
import { Sortable, Plugins } from "@shopify/draggable"

export default class extends Controller {
  static targets = ["container", "section"]
  static values = { 
    userId: String,
    currentOrder: Array
  }

  connect() {
    console.log("Sidebar reorder controller connected")
    console.log("userIdValue:", this.userIdValue)
    this.initializeSortable()
  }

  disconnect() {
    if (this.sortableInstance) {
      this.sortableInstance.destroy()
      this.sortableInstance = null
    }
  }

  async initializeSortable() {
    try {
      // Wait for Shopify Draggable to be available
      if (typeof Sortable === 'undefined') {
        console.error('Shopify Draggable not available')
        return
      }

      console.log('Initializing sidebar reorder with Shopify Draggable')
      
      this.sortableInstance = new Sortable(this.containerTarget, {
        draggable: '.sidebar-section',
        handle: '.drag-handle',
        mirror: { 
          constrainDimensions: true,
          xAxis: false,
          yAxis: true
        },
        plugins: [
          Plugins.ResizeMirror,
          Plugins.SwapAnimation,
          Plugins.Snappable
        ]
      })

      // Add event listeners
      this.sortableInstance.on('sortable:start', (evt) => {
        console.log('Sidebar drag started')
        if (evt.data.source) {
          evt.data.source.classList.add('dragging')
        }
      })

      this.sortableInstance.on('sortable:stop', (evt) => {
        console.log('Sidebar drag ended')
        if (evt.data.source) {
          evt.data.source.classList.remove('dragging')
        }
      })

      this.sortableInstance.on('sortable:sorted', (evt) => {
        console.log('Sidebar sorted - DOM is clean')
        const newOrder = this.getCurrentOrder()
        console.log('Saving order:', newOrder)
        this.saveUserPreferences(newOrder)
      })

    } catch (error) {
      console.error('Failed to initialize sidebar reorder:', error)
    }
  }

  getCurrentOrder() {
    const sections = this.containerTarget.querySelectorAll('.sidebar-section')
    return Array.from(sections).map(section => section.dataset.sectionType)
  }


  saveUserPreferences(order) {
    const key = `sidebar-order-${this.userIdValue}`
    localStorage.setItem(key, JSON.stringify(order))
    
    // Also save to server for persistence across devices
    this.saveToServer(order)
  }

  async saveToServer(order) {
    try {
      const response = await fetch('/admin/user_preferences', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          sidebar_order: order
        })
      })

      if (!response.ok) {
        console.error('Failed to save sidebar order to server')
      }
    } catch (error) {
      console.error('Error saving sidebar order to server:', error)
    }
  }

  // Removed resetToDefault() - not needed
}
