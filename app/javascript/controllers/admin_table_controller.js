import { Controller } from "@hotwired/stimulus"
import { TabulatorFull as Tabulator } from "tabulator-tables"

// Connects to data-controller="admin-table"
export default class extends Controller {
  static targets = ["table", "search", "bulkAction", "applyButton", "statusFilter"]

  connect() {
    this.loadSettings()
    this.initializeTable()
    this.setupEventListeners()
  }

  loadSettings() {
    const settingsElement = document.getElementById('admin-table-settings')
    if (settingsElement) {
      const allSettings = JSON.parse(settingsElement.textContent)
      this.settings = allSettings.adminTable || {}
    } else {
      console.error('Admin table settings not found')
      this.settings = {}
    }
  }

  disconnect() {
    if (this.table && typeof this.table.destroy === 'function') {
      this.table.destroy()
    }
  }

  async initializeTable() {
    // Load Tabulator if not already loaded
    if (typeof window.Tabulator === 'undefined') {
      try {
        const { TabulatorFull } = await import("tabulator-tables")
        window.Tabulator = TabulatorFull
      } catch (error) {
        console.error('Failed to load Tabulator:', error)
        return
      }
    }
    
    console.log('Initializing table with data:', this.settings.data)
    console.log('Initializing table with columns:', this.settings.columns)
    
    this.table = new window.Tabulator(this.tableTarget, {
      data: this.settings.data || [],
      columns: this.settings.columns || [],
      layout: "fitColumns",
      responsiveLayout: "hide",
      pagination: true,
      paginationSize: 25,
      paginationSizeSelector: [10, 25, 50, 100],
      movableColumns: true,
      resizableRows: false,
      selectable: true,
      selectableRangeMode: "click",
      tooltips: true,
      rowFormatter: this.rowFormatter.bind(this),
      cellClick: this.cellClick.bind(this),
      rowSelectionChanged: this.rowSelectionChanged.bind(this)
    })
  }

  rowFormatter(row) {
    const data = row.getData()
    const element = row.getElement()
    
    // Add status-specific styling using raw status
    if (data.status_raw) {
      element.classList.add(`status-${data.status_raw.toLowerCase()}`)
    }
    
    // Add row-specific classes
    if (data.trashed) {
      element.classList.add('trashed')
    }
  }

  cellClick(e, cell) {
    const data = cell.getRow().getData()
    
    // Handle title clicks for navigation
    if (cell.getColumn().getField() === 'title') {
      // For webhooks, use show_url, for others use edit_url
      const url = this.settings.tableType === 'webhooks' ? data.show_url : (data.edit_url || data.show_url)
      if (url) {
        window.location.href = url
      }
    }
  }

  rowSelectionChanged(data, rows) {
    this.selectedRows = rows
    this.updateBulkActions()
  }

  updateBulkActions() {
    const hasSelection = this.selectedRows && this.selectedRows.length > 0
    this.bulkActionTarget.disabled = !hasSelection
    this.applyButtonTarget.disabled = !hasSelection
    
    if (hasSelection) {
      this.bulkActionTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.applyButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    } else {
      this.bulkActionTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.applyButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  setupEventListeners() {
    // Search functionality
    if (this.hasSearchTarget) {
      this.searchTarget.addEventListener('input', this.debounce((e) => {
        // Search by title for most tables, but by name for webhooks
        const searchField = this.settings.tableType === 'webhooks' ? 'name' : 'title'
        this.table.setFilter(searchField, "like", e.target.value)
      }, 300))
    }

    // Status filter
    if (this.hasStatusFilterTarget) {
      this.statusFilterTarget.addEventListener('change', (e) => {
        if (e.target.value === '') {
          this.table.removeFilter("status")
        } else {
          this.table.setFilter("status", "=", e.target.value)
        }
      })
    }

    // Bulk actions
    if (this.hasApplyButtonTarget) {
      this.applyButtonTarget.addEventListener('click', this.handleBulkAction.bind(this))
    }
  }

  handleBulkAction() {
    const action = this.bulkActionTarget.value
    if (!action || !this.selectedRows || this.selectedRows.length === 0) return

    const selectedIds = this.selectedRows.map(row => row.getData().id)
    
    // Show confirmation for destructive actions
    if (['trash', 'delete'].includes(action)) {
      if (!confirm(`Are you sure you want to ${action} ${selectedIds.length} item(s)?`)) {
        return
      }
    }

    this.performBulkAction(action, selectedIds)
  }

  async performBulkAction(action, ids) {
    try {
      const response = await fetch(this.bulkActionUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({
          action_type: action,
          ids: ids
        })
      })

      if (response.ok) {
        this.showSuccessToast(`Successfully ${action}ed ${ids.length} item(s)`)
        this.table.replaceData()
        this.table.deselectRow()
        this.bulkActionTarget.value = ''
      } else {
        throw new Error('Bulk action failed')
      }
    } catch (error) {
      console.error('Error:', error)
      this.showErrorToast('An error occurred. Please try again.')
    }
  }

  // Utility methods
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  showSuccessToast(message) {
    // Use SweetAlert2 if available, otherwise fallback to alert
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'success',
        title: 'Success',
        text: message,
        timer: 3000,
        showConfirmButton: false,
        toast: true,
        position: 'top-end'
      })
    } else {
      alert(message)
    }
  }

  showErrorToast(message) {
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: message,
        timer: 5000,
        showConfirmButton: false,
        toast: true,
        position: 'top-end'
      })
    } else {
      alert(message)
    }
  }

  // Getters
  get bulkActionUrl() {
    return this.settings.url.replace('/index', '/bulk_action')
  }
}
