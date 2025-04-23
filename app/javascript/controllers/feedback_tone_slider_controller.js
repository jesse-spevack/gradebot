import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "label"]

  connect() {
    this.updateLabel()
  }

  updateLabel() {
    const value = this.sliderTarget.value
    let label = ""
    switch (value) {
      case "0":
        label = "Encouraging"
        break
      case "1":
        label = "Objective / Neutral"
        break
      case "2":
        label = "Critical"
        break
    }
    this.labelTarget.textContent = label
  }

  onInput() {
    this.updateLabel()
  }
}
