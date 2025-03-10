import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "quickRange", "form"]

  connect() {
    console.log("Date range controller connected")
  }
  
  updateDates() {
    const range = parseInt(this.quickRangeTarget.value)
    if (isNaN(range)) return
    
    const endDate = new Date()
    const startDate = new Date()
    startDate.setDate(endDate.getDate() - range)
    
    // Format dates as YYYY-MM-DD for the date inputs
    this.endDateTarget.value = this.formatDate(endDate)
    this.startDateTarget.value = this.formatDate(startDate)
    
    // Auto-submit the form when selecting a quick range
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }
  
  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
} 