import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "panel", "input", "results", "resultsList", "defaultContent"]

  connect() {
    console.log("search-modal controller connected")
    this.isOpen = false
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  open() {
    this.isOpen = true
    this.element.classList.remove("hidden")

    // Force reflow before adding animation classes
    this.element.offsetHeight

    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")

      // Animate opacity and scale for all screen sizes
      this.panelTarget.classList.remove("scale-95", "opacity-0")
      this.panelTarget.classList.add("scale-100", "opacity-100")

      // Only animate translate-y on mobile
      if (window.innerWidth < 768) {
        this.panelTarget.classList.remove("translate-y-full")
        this.panelTarget.classList.add("translate-y-0")
      }
    })

    // Focus input after animation
    setTimeout(() => {
      this.inputTarget.focus()
    }, 300)

    // Add keyboard listener
    document.addEventListener("keydown", this.boundHandleKeydown)

    // Prevent body scroll
    document.body.style.overflow = "hidden"
  }

  close() {
    this.isOpen = false

    // Animate out
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")

    // Animate opacity and scale for all screen sizes
    this.panelTarget.classList.remove("scale-100", "opacity-100")
    this.panelTarget.classList.add("scale-95", "opacity-0")

    // Only animate translate-y on mobile
    if (window.innerWidth < 768) {
      this.panelTarget.classList.remove("translate-y-0")
      this.panelTarget.classList.add("translate-y-full")
    }

    // Hide after animation
    setTimeout(() => {
      this.element.classList.add("hidden")
      this.inputTarget.value = ""
      this.showDefaultContent()
    }, 300)

    // Remove keyboard listener
    document.removeEventListener("keydown", this.boundHandleKeydown)

    // Restore body scroll
    document.body.style.overflow = ""
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  onInput(event) {
    const query = event.target.value.trim()

    // Clear any pending debounce
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    if (query.length < 2) {
      this.showDefaultContent()
      return
    }

    // Debounce the search
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`/providers/search_suggestions?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.showResults()
        // Parse and render the turbo stream response
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Search error:", error)
    }
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
    }
    if (this.hasDefaultContentTarget) {
      this.defaultContentTarget.classList.add("hidden")
    }
  }

  showDefaultContent() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
    }
    if (this.hasDefaultContentTarget) {
      this.defaultContentTarget.classList.remove("hidden")
    }
  }

  selectService(event) {
    const service = event.currentTarget.dataset.service

    // Dispatch custom event to parent controller
    const customEvent = new CustomEvent("service-selected", {
      detail: { service },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)

    this.close()
  }
}
