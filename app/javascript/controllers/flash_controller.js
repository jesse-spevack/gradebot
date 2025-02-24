import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.boundHandleError = this.handleError.bind(this)
    window.addEventListener("flash:error", this.boundHandleError)
    this.hideTimeout = null
  }

  disconnect() {
    window.removeEventListener("flash:error", this.boundHandleError)
    if (this.hideTimeout) clearTimeout(this.hideTimeout)
  }

  handleError(event) {
    const { message } = event.detail
    this.showMessage(message)
  }

  showMessage(message) {
    // Clear any existing timeout
    if (this.hideTimeout) clearTimeout(this.hideTimeout)

    // Find the text container and update message
    const textContainer = this.messageTarget.querySelector('.text-sm.font-medium')
    textContainer.textContent = message
    
    // Enable pointer events for the close button
    this.messageTarget.parentElement.classList.remove('pointer-events-none')
    this.messageTarget.parentElement.classList.add('pointer-events-auto')
    
    // Show the message with animation
    this.messageTarget.classList.remove('hidden')
    // Trigger reflow
    this.messageTarget.offsetHeight
    this.messageTarget.classList.remove('-translate-y-full', 'opacity-0')
    
    // Set timeout to hide
    this.hideTimeout = setTimeout(() => this.hide(), 5000)
  }

  hide() {
    // Add animation classes
    this.messageTarget.classList.add('-translate-y-full', 'opacity-0')
    
    // Wait for animation to complete before hiding
    setTimeout(() => {
      this.messageTarget.classList.add('hidden')
      this.messageTarget.parentElement.classList.remove('pointer-events-auto')
      this.messageTarget.parentElement.classList.add('pointer-events-none')
    }, 300)
  }
}
