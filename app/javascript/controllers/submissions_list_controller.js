import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submissions-list"
export default class extends Controller {
  connect() {
    console.log("Submissions list controller connected")
    this.setupRefresh()
  }

  disconnect() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  setupRefresh() {
    // Get the grading task ID from the URL
    const gradingTaskId = window.location.pathname.split('/').pop()
    
    // Only set up the refresh if we're on a grading task page
    if (gradingTaskId && !isNaN(gradingTaskId)) {
      // Refresh every 5 seconds
      this.refreshInterval = setInterval(() => {
        this.refreshSubmissions(gradingTaskId)
      }, 5000)
    }
  }

  refreshSubmissions(gradingTaskId) {
    // Fetch updated data using Turbo
    const url = `/grading_tasks/${gradingTaskId}`
    
    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error("Network response was not ok")
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Error refreshing submissions:", error)
    })
  }
} 