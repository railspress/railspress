import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]
  
  connect() {
    this.tables = new Map()
    this.setupGlobalHandlers()
  }
  
  disconnect() {
    this.cleanupAllTables()
  }
  
  setupGlobalHandlers() {
    // Cleanup before caching
    document.addEventListener('turbo:before-cache', () => {
      this.cleanupAllTables()
    })
    
    // Cleanup before render (when navigating away)
    document.addEventListener('turbo:before-render', () => {
      this.cleanupAllTables()
    })
  }
  
  cleanupAllTables() {
    this.tables.forEach((table, elementId) => {
      try {
        table.destroy()
      } catch (error) {
        console.error(`Error destroying table ${elementId}:`, error)
      }
    })
    this.tables.clear()
  }
  
  // Global method to initialize tables (for backward compatibility)
  initTable(elementId, config) {
    const element = document.getElementById(elementId)
    if (!element) return null
    
    // Destroy existing table if present
    if (this.tables.has(elementId)) {
      this.tables.get(elementId).destroy()
      this.tables.delete(elementId)
    }
    
    // Create new table
    try {
      const table = new Tabulator(`#${elementId}`, config)
      this.tables.set(elementId, table)
      return table
    } catch (error) {
      console.error(`Error initializing Tabulator table ${elementId}:`, error)
      return null
    }
  }
}

