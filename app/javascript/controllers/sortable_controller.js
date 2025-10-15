import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.Sortable) {
      this.sortable = new Sortable(this.element, {
        animation: 150,
        ghostClass: 'opacity-50',
        chosenClass: 'bg-blue-50',
        dragClass: 'bg-blue-100',
        onEnd: (evt) => {
          this.dispatch('sorted', {
            detail: {
              oldIndex: evt.oldIndex,
              newIndex: evt.newIndex,
              item: evt.item
            }
          })
        }
      })
    }
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
}

