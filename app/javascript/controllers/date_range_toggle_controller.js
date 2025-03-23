import { Controller } from "@hotwired/stimulus"

/**
 * Handles toggling visibility between specific dates and range preset sections
 * and clears fields that aren't applicable to the current selection.
 */
export default class extends Controller {
  static targets = [
    "specificDatesSection", 
    "rangePresetSection", 
    "startDateField", 
    "endDateField", 
    "rangePresetField"
  ]

  connect() {
    console.log("Date range toggle controller connected")
    this.updateVisibility()
  }
  
  /**
   * Show specific dates section and hide range preset section
   * Also clears the range preset field since it won't be used
   */
  showSpecificDates() {
    this.toggleSectionVisibility(true)
    this.clearRangePresetField()
  }
  
  /**
   * Show range preset section and hide specific dates section
   * Also clears the date fields since they won't be used
   */
  showRangePreset() {
    this.toggleSectionVisibility(false)
    this.clearDateFields()
  }
  
  /**
   * Update visibility based on currently selected radio button
   */
  updateVisibility() {
    const selectedOption = document.querySelector('input[name="filter_type"]:checked')
    if (!selectedOption) return
    
    if (selectedOption.value === 'specific_dates') {
      this.showSpecificDates()
    } else if (selectedOption.value === 'range_preset') {
      this.showRangePreset()
    }
  }
  
  /**
   * Helper method to toggle visibility of sections
   * @param {boolean} showSpecificDates - Whether to show specific dates section
   */
  toggleSectionVisibility(showSpecificDates) {
    if (showSpecificDates) {
      this.specificDatesSectionTarget.classList.remove('hidden')
      this.rangePresetSectionTarget.classList.add('hidden')
    } else {
      this.specificDatesSectionTarget.classList.add('hidden')
      this.rangePresetSectionTarget.classList.remove('hidden')
    }
  }
  
  /**
   * Clear the range preset field
   */
  clearRangePresetField() {
    this.rangePresetFieldTarget.value = ''
  }
  
  /**
   * Clear the date fields
   */
  clearDateFields() {
    this.startDateFieldTarget.value = ''
    this.endDateFieldTarget.value = ''
  }
}
