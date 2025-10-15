import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "testInput", "testResult", "testError", "testButton"]
  static values = { currentAgentId: String }
  
  connect() {
    this.currentAgentId = null
  }
  
  disconnect() {
    // Cleanup if needed
  }
  
  testAgent(event) {
    this.currentAgentId = event.target.dataset.agentId
    this.modalTarget.classList.remove('hidden')
    this.testInputTarget.value = ''
    this.testResultTarget.classList.add('hidden')
    this.testErrorTarget.classList.add('hidden')
  }
  
  closeTestModal() {
    this.modalTarget.classList.add('hidden')
    this.currentAgentId = null
  }
  
  async runTest() {
    const input = this.testInputTarget.value
    const testButton = this.testButtonTarget
    const resultDiv = this.testResultTarget
    const errorDiv = this.testErrorTarget
    
    if (!input.trim()) {
      alert('Please enter test input')
      return
    }
    
    testButton.disabled = true
    testButton.textContent = 'Testing...'
    
    try {
      const response = await fetch(`/admin/ai_agents/${this.currentAgentId}/test`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          user_input: input,
          context: {}
        })
      })
      
      const data = await response.json()
      
      if (data.success) {
        resultDiv.querySelector('div').textContent = data.result
        resultDiv.classList.remove('hidden')
        errorDiv.classList.add('hidden')
      } else {
        errorDiv.querySelector('div').textContent = data.error || 'Test failed'
        errorDiv.classList.remove('hidden')
        resultDiv.classList.add('hidden')
      }
    } catch (error) {
      errorDiv.querySelector('div').textContent = 'Network error: ' + error.message
      errorDiv.classList.remove('hidden')
      resultDiv.classList.add('hidden')
    } finally {
      testButton.disabled = false
      testButton.textContent = 'Run Test'
    }
  }
}


