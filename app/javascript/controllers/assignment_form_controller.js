import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "error", "rubric", "rubricError"]

  validatePrompt() {
    const prompt = this.promptTarget.value
    const errorElement = this.errorTarget

    if (prompt.length < 10) {
      errorElement.textContent = "Assignment prompt must be at least 10 characters"
      errorElement.classList.remove("hidden")
    } else if (prompt.length > 2000) {
      errorElement.textContent = "Assignment prompt cannot exceed 2000 characters"
      errorElement.classList.remove("hidden")
    } else {
      errorElement.classList.add("hidden")
    }
  }

  validateRubric() {
    const rubric = this.rubricTarget.value
    const errorElement = this.rubricErrorTarget

    if (rubric.length < 10) {
      errorElement.textContent = "Grading rubric must be at least 10 characters"
      errorElement.classList.remove("hidden")
    } else if (rubric.length > 3000) {
      errorElement.textContent = "Grading rubric cannot exceed 3000 characters"
      errorElement.classList.remove("hidden")
    } else {
      errorElement.classList.add("hidden")
    }
  }
}
