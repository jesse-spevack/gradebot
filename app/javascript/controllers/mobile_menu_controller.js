import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "backdrop"]

  connect() {
    // Prevent body scroll when menu is open
    this.originalOverflow = document.body.style.overflow

    // Close menu when pressing escape
    document.addEventListener("keydown", this.handleKeyDown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeyDown.bind(this))
    this.restoreBodyScroll()
  }

  handleKeyDown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.menuTarget.classList.remove("-translate-x-full")
    this.menuTarget.classList.add("translate-x-0")
    
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto")
    
    // Prevent body scroll
    document.body.style.overflow = "hidden"
    
    this.isOpen = true
  }

  close() {
    this.menuTarget.classList.remove("translate-x-0")
    this.menuTarget.classList.add("-translate-x-full")
    
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    
    this.restoreBodyScroll()
    
    this.isOpen = false
  }

  restoreBodyScroll() {
    document.body.style.overflow = this.originalOverflow
  }
}
