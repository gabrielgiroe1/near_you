import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "locationInput",
    "serviceDisplay",
    "locationDisplay"
  ]

  connect() {
    console.log("hero-search controller connected")

    // Listen for selection events from the modal
    document.addEventListener("modal:service-selected", this.handleServiceSelected.bind(this))
    document.addEventListener("modal:location-selected", this.handleLocationSelected.bind(this))
  }

  disconnect() {
    document.removeEventListener("modal:service-selected", this.handleServiceSelected.bind(this))
    document.removeEventListener("modal:location-selected", this.handleLocationSelected.bind(this))
  }

  openServiceModal() {
    this.openModal("service")
  }

  openLocationModal() {
    this.openModal("location")
  }

  openModal(context) {
    const modal = document.getElementById("search-modal")
    if (!modal) {
      console.error("Search modal not found")
      return
    }

    // Store context on the modal element
    modal.dataset.context = context

    // Show modal
    modal.classList.remove("hidden")

    // Force reflow
    modal.offsetHeight

    // Animate in
    requestAnimationFrame(() => {
      const backdrop = modal.querySelector('[data-role="backdrop"]')
      const panel = modal.querySelector('[data-role="panel"]')

      if (backdrop) {
        backdrop.classList.remove("opacity-0")
        backdrop.classList.add("opacity-100")
      }

      if (panel) {
        panel.classList.remove("scale-95", "opacity-0")
        panel.classList.add("scale-100", "opacity-100")

        // Only animate translate-y on mobile (slide up from bottom)
        if (window.innerWidth < 768) {
          panel.classList.remove("translate-y-full")
          panel.classList.add("translate-y-0")
        }
      }
    })

    // Update context UI
    this.updateModalContext(modal, context)

    // Prevent body scroll
    document.body.style.overflow = "hidden"
  }

  updateModalContext(modal, context) {
    const isService = context === "service"

    const serviceInput = modal.querySelector('[data-role="serviceInput"]')
    const locationInput = modal.querySelector('[data-role="locationInput"]')
    const serviceContext = modal.querySelector('[data-role="serviceContext"]')
    const locationContext = modal.querySelector('[data-role="locationContext"]')

    // Update input highlighting
    if (serviceInput) {
      serviceInput.classList.toggle("ring-2", isService)
      serviceInput.classList.toggle("ring-blue-500", isService)
      serviceInput.classList.toggle("border-transparent", isService)
    }

    if (locationInput) {
      locationInput.classList.toggle("ring-2", !isService)
      locationInput.classList.toggle("ring-blue-500", !isService)
      locationInput.classList.toggle("border-transparent", !isService)
    }

    // Show/hide context content
    if (serviceContext) {
      serviceContext.classList.toggle("hidden", !isService)
    }

    if (locationContext) {
      locationContext.classList.toggle("hidden", isService)
    }

    // Focus the appropriate input
    setTimeout(() => {
      if (isService && serviceInput) {
        serviceInput.focus()
      } else if (!isService && locationInput) {
        locationInput.focus()
      }
    }, 100)
  }

  handleServiceSelected(event) {
    const service = event.detail.service
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = service
    }
    if (this.hasServiceDisplayTarget) {
      this.serviceDisplayTarget.textContent = service
    }
  }

  handleLocationSelected(event) {
    const location = event.detail.location
    if (this.hasLocationInputTarget) {
      this.locationInputTarget.value = location
    }
    if (this.hasLocationDisplayTarget) {
      this.locationDisplayTarget.textContent = location
    }
  }
}
