import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "icon", "text", "progress"]
  static values = { 
    pluginName: String, 
    action: String,
    autoClose: { type: Number, default: 3000 }
  }

  connect() {
    console.log("🔥 Hot Reload Dialog Controller connected")
  }

  show(pluginName, action) {
    this.pluginNameValue = pluginName
    this.actionValue = action
    
    // Update the dialog content
    this.updateDialogContent()
    
    // Show the dialog with animation
    this.dialogTarget.classList.remove('hidden')
    this.dialogTarget.classList.add('flex')
    
    // Start the animation sequence
    this.startAnimation()
    
    // Auto close after delay
    setTimeout(() => {
      this.hide()
    }, this.autoCloseValue)
  }

  hide() {
    this.dialogTarget.classList.add('hidden')
    this.dialogTarget.classList.remove('flex')
  }

  updateDialogContent() {
    const actionText = this.actionValue === 'activation' ? 'Activating' : 'Deactivating'
    const actionIcon = this.actionValue === 'activation' ? 'activate' : 'deactivate'
    
    this.textTarget.innerHTML = `
      <div class="text-center">
        <div class="text-lg font-semibold text-white mb-2">
          ${actionText} Plugin
        </div>
        <div class="text-sm text-gray-300 mb-4">
          <span class="font-mono bg-gray-800 px-2 py-1 rounded">${this.pluginNameValue}</span>
        </div>
        <div class="text-xs text-gray-400">
          Hot reloading in progress...
        </div>
      </div>
    `
  }

  startAnimation() {
    // Reset animation
    this.iconTarget.style.animation = 'none'
    this.progressTarget.style.animation = 'none'
    
    // Force reflow
    this.iconTarget.offsetHeight
    this.progressTarget.offsetHeight
    
    // Start animations
    this.iconTarget.style.animation = 'spin 1s linear infinite, pulse 2s ease-in-out infinite'
    this.progressTarget.style.animation = 'progressBar 3s ease-in-out'
  }

  // Manual trigger for testing
  test() {
    this.show('Hello Tupac!', 'activation')
  }
}
