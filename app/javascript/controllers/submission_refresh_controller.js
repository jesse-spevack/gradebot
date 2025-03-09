import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submission-refresh"
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 3000 },
    gradeTaskId: Number
  }
  
  static targets = ["submission"]
  
  connect() {
    console.log("Submission refresh controller connected")
    if (this.hasGradeTaskIdValue) {
      this.startRefreshing()
    }
  }
  
  disconnect() {
    this.stopRefreshing()
  }
  
  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      // Only continue refreshing if there are submissions in pending or processing state
      if (this.hasActiveSubmissions()) {
        this.refreshSubmissions()
      } else {
        this.stopRefreshing()
      }
    }, this.intervalValue)
  }
  
  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
  
  hasActiveSubmissions() {
    // Check if any submission is still in pending or processing state
    const pendingElements = document.querySelectorAll('.bg-yellow-100.text-yellow-800')
    const processingElements = document.querySelectorAll('.bg-blue-100.text-blue-800')
    return pendingElements.length > 0 || processingElements.length > 0
  }
  
  refreshSubmissions() {
    const url = `/grading_tasks/${this.gradeTaskIdValue}`
    
    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Error refreshing submissions:", error)
    })
  }
} 