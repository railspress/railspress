import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["redisStats"]
  static values = { statsUrl: String }
  
  connect() {
    if (this.hasRedisStatsTarget && this.hasStatsUrlValue) {
      this.loadRedisStats()
    }
  }
  
  async loadRedisStats() {
    try {
      const response = await fetch(this.statsUrlValue)
      const data = await response.json()
      
      if (data.connected) {
        this.renderRedisStats(data)
      } else {
        this.showRedisError()
      }
    } catch (error) {
      console.error('Failed to load Redis stats:', error)
      this.showRedisError()
    }
  }
  
  renderRedisStats(data) {
    this.redisStatsTarget.innerHTML = `
      <div class="grid grid-cols-2 gap-4">
        <div class="bg-[#0a0a0a] rounded-lg p-4">
          <p class="text-gray-400 text-sm mb-1">Redis Version</p>
          <p class="text-white font-semibold">${data.version}</p>
        </div>
        <div class="bg-[#0a0a0a] rounded-lg p-4">
          <p class="text-gray-400 text-sm mb-1">Memory Used</p>
          <p class="text-white font-semibold">${data.used_memory}</p>
        </div>
        <div class="bg-[#0a0a0a] rounded-lg p-4">
          <p class="text-gray-400 text-sm mb-1">Connected Clients</p>
          <p class="text-white font-semibold">${data.connected_clients}</p>
        </div>
        <div class="bg-[#0a0a0a] rounded-lg p-4">
          <p class="text-gray-400 text-sm mb-1">Total Commands</p>
          <p class="text-white font-semibold">${data.total_commands}</p>
        </div>
      </div>
    `
  }
  
  showRedisError() {
    this.redisStatsTarget.innerHTML = `
      <div class="text-center py-4">
        <p class="text-red-400">Failed to load Redis statistics</p>
      </div>
    `
  }
}

