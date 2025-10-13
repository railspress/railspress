import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabulator"
export default class extends Controller {
  static values = {
    url: String,
    tableId: String
  }
  
  static targets = ["table"]

  async connect() {
    // Wait for TabulatorFull to be available
    await this.waitForTabulator()
    this.initTable()
  }

  disconnect() {
    if (this.table) {
      try {
        this.table.destroy()
      } catch (e) {
        console.error('Error destroying table:', e)
      }
    }
  }
  
  async waitForTabulator() {
    // Wait for the Tabulator library to load from CDN
    let attempts = 0
    while (typeof window.TabulatorFull === 'undefined' && attempts < 50) {
      await new Promise(resolve => setTimeout(resolve, 100))
      attempts++
    }
    
    if (typeof window.TabulatorFull === 'undefined') {
      console.error('Tabulator failed to load')
      return false
    }
    return true
  }

  initTable() {
    if (typeof window.TabulatorFull === 'undefined') {
      console.error('Tabulator is not loaded')
      return
    }
    
    // Use the custom initialization function if available
    if (window.initCustomTable && this.tableIdValue) {
      this.table = window.initCustomTable(this.tableIdValue, this.urlValue)
    }
  }

  setupBulkActions() {
    const bulkActionSelect = document.getElementById('bulk-action')
    const applyBulkButton = document.getElementById('apply-bulk')
    
    if (!bulkActionSelect || !applyBulkButton) return

    applyBulkButton.addEventListener('click', async () => {
      const action = bulkActionSelect.value
      if (!action) {
        if (window.showWarningToast) {
          window.showWarningToast('Please select an action')
        } else {
          alert('Please select an action')
        }
        return
      }

      const selectedRows = this.table.getSelectedData()
      if (selectedRows.length === 0) {
        if (window.showWarningToast) {
          window.showWarningToast('Please select at least one item')
        } else {
          alert('Please select at least one item')
        }
        return
      }

      if (action === 'delete' || action === 'permanent_delete') {
        const confirmResult = window.showDeleteConfirm ? 
          await window.showDeleteConfirm(`${selectedRows.length} item(s)`) :
          confirm(`Are you sure you want to ${action === 'permanent_delete' ? 'permanently delete' : 'move to trash'} ${selectedRows.length} items?`)
        
        if (!confirmResult && !confirmResult.isConfirmed) {
          return
        }
      }

      const ids = selectedRows.map(row => row.id)
      
      // Get the current path to determine the resource type
      const path = window.location.pathname
      let bulkActionUrl = ''
      
      if (path.includes('/posts')) {
        bulkActionUrl = '/admin/posts/bulk_action'
      } else if (path.includes('/pages')) {
        bulkActionUrl = '/admin/pages/bulk_action'
      } else if (path.includes('/redirects')) {
        bulkActionUrl = '/admin/redirects/bulk_action'
      } else if (path.includes('/pixels')) {
        bulkActionUrl = '/admin/pixels/bulk_action'
      } else if (path.includes('/subscribers')) {
        bulkActionUrl = '/admin/subscribers/bulk_action'
      }

      if (!bulkActionUrl) return

      fetch(bulkActionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ action: action, ids: ids })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.table.replaceData()
          bulkActionSelect.value = ''
          if (window.showSuccessToast) {
            window.showSuccessToast(data.message || 'Action completed successfully')
          } else {
            alert(data.message || 'Action completed successfully')
          }
        } else {
          if (window.showErrorToast) {
            window.showErrorToast(data.error || 'Action failed')
          } else {
            alert(data.error || 'Action failed')
          }
        }
      })
      .catch(error => {
        console.error('Error:', error)
        if (window.showErrorToast) {
          window.showErrorToast('An error occurred. Please try again.')
        } else {
          alert('An error occurred')
        }
      })
    })
  }

  setupFilters() {
    const searchInput = document.getElementById('search-input')
    const statusFilter = document.getElementById('status-filter')
    const typeFilter = document.getElementById('type-filter')

    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        this.table.setFilter([
          { field: "title", type: "like", value: e.target.value },
          { field: "name", type: "like", value: e.target.value },
          { field: "email", type: "like", value: e.target.value }
        ])
      })
    }

    if (statusFilter) {
      statusFilter.addEventListener('change', (e) => {
        if (e.target.value) {
          this.table.setFilter("status", "=", e.target.value)
        } else {
          this.table.clearFilter()
        }
      })
    }

    if (typeFilter) {
      typeFilter.addEventListener('change', (e) => {
        if (e.target.value) {
          this.table.setFilter("type", "=", e.target.value)
        } else {
          this.table.clearFilter()
        }
      })
    }
  }

  getDefaultColumns() {
    return [
      {
        formatter: "rowSelection",
        titleFormatter: "rowSelection",
        hozAlign: "center",
        headerSort: false,
        width: 40,
        responsive: 0
      },
      {
        title: "Title",
        field: "title",
        sorter: "string",
        headerFilter: "input",
        responsive: 0
      },
      {
        title: "Status",
        field: "status",
        sorter: "string",
        width: 120,
        responsive: 1
      },
      {
        title: "Created",
        field: "created_at",
        sorter: "string",
        width: 150,
        responsive: 2
      },
      {
        title: "Actions",
        field: "actions",
        headerSort: false,
        width: 150,
        responsive: 0
      }
    ]
  }

  refresh() {
    if (this.table) {
      this.table.replaceData()
    }
  }
}

