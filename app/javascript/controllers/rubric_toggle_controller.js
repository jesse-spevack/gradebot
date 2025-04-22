import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rubric-toggle"
export default class extends Controller {
  static targets = ["textarea", "switch", "knob", "generateLabel", "pasteLabel"]

  // CSS classes for the switch and knob states
  static values = {
    onBgClass: { type: String, default: 'bg-blue-600' },
    offBgClass: { type: String, default: 'bg-gray-200' },
    knobOnTranslateClass: { type: String, default: 'translate-x-5' },
    knobOffTranslateClass: { type: String, default: 'translate-x-0' },
    textareaDisabledClass: { type: String, default: 'bg-gray-100' },
    textareaDisabledTextClass: { type: String, default: 'text-gray-500' },
    generatePlaceholder: { type: String, default: 'GradeBot will generate an AI rubric based on your assignment details.' },
    pastePlaceholder: { type: String, default: "Paste your rubric here, don't worry about formatting." }
  }

  connect() {
    // Get the hidden field that stores the actual value ('generate' or 'paste')
    this.optionField = document.getElementById('rubric_option_field');

    if (!this.optionField) {
      console.error("Rubric option field (#rubric_option_field) not found!");
      return;
    }

    // Set initial state based on the field's value in the HTML
    this.setState(this.optionField.value);
  }

  toggle() {
    if (!this.optionField) return; // Guard clause

    // Determine the new state and update the hidden field
    const newState = this.optionField.value === 'generate' ? 'paste' : 'generate';
    this.optionField.value = newState;

    // Update the UI
    this.setState(newState);
  }

  setState(state) {
    // Ensure all required targets are present before proceeding
    if (!this.hasTextareaTarget || !this.hasSwitchTarget || !this.hasKnobTarget) {
       console.warn("Rubric toggle controller is missing required targets (textarea, switch, knob). State cannot be set.");
       // Attempt to find targets again after a microtask, in case they load late
       queueMicrotask(() => {
         if (this.hasTextareaTarget && this.hasSwitchTarget && this.hasKnobTarget) {
           this._applyStateChanges(state);
         } else {
            console.error("Rubric toggle targets still missing after delay.");
         }
       });
       return;
    }
    this._applyStateChanges(state);
  }

  _applyStateChanges(state) {
      const isGenerate = state === 'generate';

      // --- Toggle Label Visibility --- 
      if (this.hasGenerateLabelTarget && this.hasPasteLabelTarget) {
        this.generateLabelTarget.classList.toggle('hidden', !isGenerate);
        this.pasteLabelTarget.classList.toggle('hidden', isGenerate);
      }

      // --- Update Textarea ---
      this.textareaTarget.disabled = isGenerate;
      this.textareaTarget.placeholder = isGenerate ? this.generatePlaceholderValue : this.pastePlaceholderValue;

      if (isGenerate) {
        this.textareaTarget.classList.add(this.textareaDisabledClassValue, this.textareaDisabledTextClassValue);
        this.textareaTarget.value = ''; // Clear any pasted content
      } else {
        this.textareaTarget.classList.remove(this.textareaDisabledClassValue, this.textareaDisabledTextClassValue);
      }

      // --- Update Switch Visuals ---
      this.switchTarget.setAttribute('aria-checked', isGenerate.toString());

      // Toggle background class on the switch
      this.switchTarget.classList.toggle(this.onBgClassValue, isGenerate);
      this.switchTarget.classList.toggle(this.offBgClassValue, !isGenerate);

      // Toggle translation class on the knob
      this.knobTarget.classList.toggle(this.knobOnTranslateClassValue, isGenerate);
      this.knobTarget.classList.toggle(this.knobOffTranslateClassValue, !isGenerate);
  }

  disconnect() {
    // Optional: Clean up references if needed, though Stimulus handles most of it
    this.optionField = null;
  }
}