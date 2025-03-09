import { Controller } from "@hotwired/stimulus"

/**
 * Hamburger menu controller that opens the sidebar
 * @class HamburgerController
 * @extends Controller
 */
export default class extends Controller {
  /**
   * Open the sidebar when the hamburger button is clicked
   */
  openSidebar(event) {
    // Stop propagation to prevent any parent elements from receiving this event
    event.stopPropagation()
    
    // Find the sidebar element
    const sidebar = document.getElementById("mobile-sidebar")
    if (sidebar) {
      // Check if the sidebar has a controller
      const sidebarController = this.application.getControllerForElementAndIdentifier(sidebar, "sidebar")
      
      if (sidebarController) {
        sidebarController.open()
      } else {
        console.warn("Sidebar controller not found")
      }
    } else {
      console.warn("Sidebar element not found")
    }
  }
} 