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
    this.initializeSortable()
    this.loadUserPreferences()
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
        evt.data.source.classList.add('dragging')
      })

      this.sortableInstance.on('sortable:stop', (evt) => {
        console.log('Sidebar drag ended')
        evt.data.source.classList.remove('dragging')
        
        // Get new order and save to user preferences
        const newOrder = this.getCurrentOrder()
        this.saveUserPreferences(newOrder)
      })

    } catch (error) {
      console.error('Failed to initialize sidebar reorder:', error)
    }
  }

  getCurrentOrder() {
    const sections = this.containerTarget.querySelectorAll('.sidebar-section')
    return Array.from(sections).map(section => {
      return section.dataset.sectionType
    })
  }

  async loadUserPreferences() {
    try {
      // Try to load from server first
      const response = await fetch('/admin/user_preferences')
      if (response.ok) {
        const data = await response.json()
        if (data.sidebar_order) {
          this.applyOrder(data.sidebar_order)
          return
        }
      }
    } catch (error) {
      console.log('Could not load preferences from server, using localStorage')
    }
    
    // Fallback to localStorage
    const savedOrder = localStorage.getItem(`sidebar-order-${this.userIdValue}`)
    
    if (savedOrder) {
      try {
        const order = JSON.parse(savedOrder)
        this.applyOrder(order)
      } catch (error) {
        console.error('Error parsing saved sidebar order:', error)
        this.applyDefaultOrder()
      }
    } else {
      this.applyDefaultOrder()
    }
  }
  
  applyDefaultOrder() {
    const defaultOrder = ['publish', 'featured-image', 'categories-tags', 'excerpt', 'seo']
    this.applyOrder(defaultOrder)
  }

  applyOrder(order) {
    const sections = this.containerTarget.querySelectorAll('.sidebar-section')
    const sectionMap = {}
    
    // Create a map of sections by type
    sections.forEach(section => {
      const type = section.dataset.sectionType
      sectionMap[type] = section
    })

    // Clear container
    this.containerTarget.innerHTML = ''

    // Add sections in the specified order
    order.forEach(sectionType => {
      if (sectionMap[sectionType]) {
        this.containerTarget.appendChild(sectionMap[sectionType])
      }
    })

    // Add any remaining sections that weren't in the order
    Object.keys(sectionMap).forEach(sectionType => {
      if (!order.includes(sectionType)) {
        this.containerTarget.appendChild(sectionMap[sectionType])
      }
    })
  }

  saveUserPreferences(order) {
    // Save to localStorage
    localStorage.setItem(`sidebar-order-${this.userIdValue}`, JSON.stringify(order))
    
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

  resetToDefault() {
    const defaultOrder = ['publish', 'featured-image', 'categories-tags', 'excerpt', 'seo']
    this.applyOrder(defaultOrder)
    this.saveUserPreferences(defaultOrder)
  }
}
