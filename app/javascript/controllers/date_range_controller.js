import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "rangePreset", "form"]

  connect() {
    console.log("Date range controller connected")
  }
  
  /**
   * Generic method to update a hidden field based on a data attribute
   * Uses data-field-type to determine which target to update
   */
  updateField(event) {
    const fieldType = event.currentTarget.dataset.fieldType
    if (!fieldType) return
    
    const targetName = `${fieldType}Target`
    if (this[targetName]) {
      this[targetName].value = event.currentTarget.value
    }
  }
  
  /**
   * Calculates start and end dates based on a selected range preset
   * and updates the hidden fields accordingly
   */
  calculateDatesFromRange(event) {
    const range = parseInt(event.currentTarget.value)
    if (isNaN(range)) return
    
    // Update the hidden range preset field
    this.rangePresetTarget.value = range
    
    // Calculate start and end dates based on the range
    const endDate = new Date()
    const startDate = new Date()
    startDate.setDate(endDate.getDate() - range)
    
    // Format dates and set values in hidden fields
    this.endDateTarget.value = this.formatDate(endDate)
    this.startDateTarget.value = this.formatDate(startDate)
    
    // Auto-submit the form
    this.formTarget.requestSubmit()
  }
  
  /**
   * Formats a Date object as YYYY-MM-DD string
   */
  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}