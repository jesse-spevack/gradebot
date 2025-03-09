import { Controller } from "@hotwired/stimulus"

/**
 * Sidebar controller that handles opening and closing the mobile sidebar
 * @class SidebarController
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["backdrop", "panel"]
  
  /**
   * Connect the controller to initialize event handlers and bind methods
   */
  connect() {
    // Ensure all methods that are used as event handlers are properly bound to this
    this.handleKeydown = this.handleKeydown.bind(this);
    this.close = this.close.bind(this);
    this.handlePanelClick = this.handlePanelClick.bind(this);
    this.open = this.open.bind(this);
  }
  
  /**
   * Clean up event listeners when disconnecting
   */
  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
  }
  
  /**
   * Opens the sidebar
   */
  open() {
    // Show the backdrop
    this.backdropTarget.classList.remove("opacity-0");
    this.backdropTarget.classList.add("opacity-100");
    
    // Show the panel
    this.panelTarget.classList.remove("-translate-x-full");
    this.panelTarget.classList.add("translate-x-0");
    
    // Add a delay before enabling pointer events on the backdrop
    // This prevents accidental clicks from immediately closing the sidebar
    setTimeout(() => {
      // Only enable pointer events if the sidebar is still open
      if (this.panelTarget.classList.contains("translate-x-0")) {
        this.backdropTarget.classList.remove("pointer-events-none");
        this.backdropTarget.classList.add("pointer-events-auto");
      }
    }, 300); // Match transition duration
    
    // Setup event listener for ESC key to close the sidebar
    document.addEventListener("keydown", this.handleKeydown);
  }
  
  /**
   * Closes the sidebar
   */
  close() {
    // Hide the backdrop and disable pointer events
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none");
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto");
    
    // Hide the panel
    this.panelTarget.classList.add("-translate-x-full");
    this.panelTarget.classList.remove("translate-x-0");
    
    // Remove event listener for ESC key
    document.removeEventListener("keydown", this.handleKeydown);
  }
  
  /**
   * Handle keyboard events for accessibility
   * @param {KeyboardEvent} event 
   */
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }

  /**
   * Handle clicks on the panel to prevent accidental closing
   * @param {Event} event - The click event
   */
  handlePanelClick(event) {
    // Don't do anything special for links and buttons - let them work normally
    const isClickableElement = event.target.closest('a, button');
    if (isClickableElement) {
      return;
    }
    
    // For clicks on the empty panel area, prevent propagation
    // so the backdrop's close action doesn't trigger
    event.stopPropagation();
  }
} 