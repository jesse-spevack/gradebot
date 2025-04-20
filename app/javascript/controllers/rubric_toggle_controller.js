import { Controller } from "@hotwired/stimulus"

/**
 * Rubric Builder Controller
 * 
 * Controls the functionality of the AI-generated rubric checkbox
 * When checked, it disables the rubric textarea and indicates
 * that an AI-generated rubric will be created
 */
export default class extends Controller {
  static targets = ["checkbox", "textarea"]

  connect() {
    // Set initial state
    this.updateTextareaState()
  }

  /**
   * Toggle the disabled state of the textarea based on the checkbox
   */
  toggle() {
    this.updateTextareaState()
  }

  /**
   * Update the textarea state (disabled/enabled) based on checkbox
   */
  updateTextareaState() {
    if (this.hasCheckboxTarget && this.hasTextareaTarget) {
      const isChecked = this.checkboxTarget.checked
      
      // Disable/enable the textarea
      this.textareaTarget.disabled = isChecked
      
      // Add/remove the styling for disabled state
      if (isChecked) {
        this.textareaTarget.classList.add('bg-gray-100', 'text-gray-500')
        this.textareaTarget.placeholder = "GradeBot will generate an AI rubric based on your assignment details."
      } else {
        this.textareaTarget.classList.remove('bg-gray-100', 'text-gray-500')
        this.textareaTarget.placeholder = "Paste your existing rubric here or check the box above to generate a rubric with AI."
      }
    }
  }
}
