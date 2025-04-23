import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Shows/hides the rubric textarea based on rubric_option
  toggleRubric(event) {
    const rubricTextarea = document.getElementById("rubric-textarea")
    if (event.target.value === "paste") {
      rubricTextarea.classList.remove("hidden")
    } else {
      rubricTextarea.classList.add("hidden")
    }
  }
}
