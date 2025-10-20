import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Realtime page controller connected")
    
    // Dynamically import and initialize the ActionCable channel
    this.loadActionCableChannel()
  }

  disconnect() {
    console.log("Realtime page controller disconnected")
  }

  async loadActionCableChannel() {
    try {
      // Dynamically import the ActionCable channel only on this page
      const { default: channelModule } = await import("../channels/realtime_analytics_channel")
      console.log("✅ ActionCable channel loaded successfully")
    } catch (error) {
      console.error("❌ Failed to load ActionCable channel:", error)
    }
  }
}
