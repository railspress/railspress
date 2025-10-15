import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    contentType: String,
    contentId: String,
    provider: String,
    model: String
  }
  
  connect() {
    // Controller is ready
  }
  
  disconnect() {
    // Cleanup if needed
  }
  
  generateSeo() {
    const statusEl = document.getElementById('ai-seo-status')
    const statusText = statusEl.querySelector('p')
    
    // Show loading
    statusEl.classList.remove('hidden')
    statusEl.querySelector('div').className = 'p-3 rounded-lg bg-blue-500/20 border border-blue-500/30'
    statusText.textContent = '🔄 Generating SEO with AI... This may take a moment.'
    
    // Call API
    fetch('/api/v1/ai_seo/generate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        content_type: this.contentTypeValue,
        content_id: this.contentIdValue
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Success
        statusEl.querySelector('div').className = 'p-3 rounded-lg bg-green-500/20 border border-green-500/30'
        statusText.textContent = '✅ SEO generated successfully! Refresh the page to see updates.'
        
        // Auto-reload after 2 seconds
        setTimeout(() => {
          window.location.reload()
        }, 2000)
      } else {
        // Error
        statusEl.querySelector('div').className = 'p-3 rounded-lg bg-red-500/20 border border-red-500/30'
        statusText.textContent = '❌ ' + (data.message || 'Failed to generate SEO')
      }
    })
    .catch(error => {
      statusEl.querySelector('div').className = 'p-3 rounded-lg bg-red-500/20 border border-red-500/30'
      statusText.textContent = '❌ Network error: ' + error.message
    })
  }
  
  showInfo() {
    const provider = this.providerValue || 'OpenAI'
    const model = this.modelValue || 'gpt-3.5-turbo'
    
    if (typeof Swal !== 'undefined') {
      Swal.fire({
        title: 'AI SEO Assistant',
        html: `
          <div class="text-left space-y-3">
            <p class="text-sm text-gray-600 dark:text-gray-400">
              This feature uses AI to automatically generate optimized SEO meta tags for your content.
            </p>
            
            <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
              <p class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">Configuration:</p>
              <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                <li><strong>Provider:</strong> ${provider}</li>
                <li><strong>Model:</strong> ${model}</li>
                <li><strong>Auto-generate:</strong> On save & publish</li>
              </ul>
            </div>
            
            <p class="text-xs text-gray-500 dark:text-gray-500">
              Configure settings in <a href="/admin/plugins" class="text-blue-600 hover:underline">Plugins → AI SEO → Settings</a>
            </p>
          </div>
        `,
        icon: 'info',
        confirmButtonColor: '#8B5CF6'
      })
    }
  }
}


