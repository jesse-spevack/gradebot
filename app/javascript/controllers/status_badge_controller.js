import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="status-badge"
export default class extends Controller {
  static values = {
    status: String
  }

  connect() {
    console.log(`Status badge connected: ${this.statusValue}`)
  }

  statusValueChanged() {
    console.log(`Status changed to: ${this.statusValue}`)
  }
} 