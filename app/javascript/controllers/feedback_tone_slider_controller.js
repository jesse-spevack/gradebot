import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slider", "feedbackTone" ]
  static values = { tones: Array } // Expect an array of strings

  connect() {
    // Set initial hidden field value on load
    this.updateToneValue()
  }

  updateTone() {
    // Called when the slider value changes
    this.updateToneValue()
  }

  updateToneValue() {
    // Reads slider value, finds corresponding tone, updates hidden field
    const index = parseInt(this.sliderTarget.value, 10);
    if (this.hasTonesValue && index >= 0 && index < this.tonesValue.length) {
      const selectedTone = this.tonesValue[index];
      this.feedbackToneTarget.value = selectedTone;
    } else {
      console.error("Invalid slider index or tones not provided:", index, this.tonesValue);
      // Optionally set a default or handle the error
      this.feedbackToneTarget.value = '';
    }
  }
}
