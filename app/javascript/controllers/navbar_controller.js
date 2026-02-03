import { Controller } from "@hotwired/stimulus"

/**
 * Navbar Controller
 * Handles scroll-based blur/shadow effect for the top navbar
 */
export default class extends Controller {
  static targets = ["nav"]
  static values = {
    scrollThreshold: { type: Number, default: 10 }
  }

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.handleScroll() // Initial check
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const isScrolled = window.scrollY > this.scrollThresholdValue

    if (this.hasNavTarget) {
      if (isScrolled) {
        this.navTarget.classList.add("navbar-scrolled")
      } else {
        this.navTarget.classList.remove("navbar-scrolled")
      }
    }
  }
}
