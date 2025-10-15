import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { config: Object }
  
  connect() {
    this.table = null
    this.initializeTable()
  }
  
  disconnect() {
    this.destroyTable()
  }
  
  initializeTable() {
    this.destroyTable()
    
    try {
      const config = this.configValue
      this.table = new Tabulator(this.element, config)
    } catch (error) {
      console.error('Error initializing Tabulator table:', error)
    }
  }
  
  destroyTable() {
    if (this.table) {
      try {
        this.table.destroy()
      } catch (error) {
        console.error('Error destroying Tabulator table:', error)
      }
      this.table = null
    }
  }
  
  // Method to refresh table data
  refresh() {
    if (this.table) {
      this.table.redraw(true)
    }
  }
  
  // Method to set new data
  setData(data) {
    if (this.table) {
      this.table.setData(data)
    }
  }
}