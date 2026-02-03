import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("search-modal controller connected")
    this.selectedService = null
    this.selectedLocation = null
    this.debounceTimer = null

    // Add keyboard listener
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close()
    }
  }

  close() {
    const backdrop = this.element.querySelector('[data-role="backdrop"]')
    const panel = this.element.querySelector('[data-role="panel"]')

    if (backdrop) {
      backdrop.classList.remove("opacity-100")
      backdrop.classList.add("opacity-0")
    }

    if (panel) {
      panel.classList.remove("scale-100", "opacity-100")
      panel.classList.add("scale-95", "opacity-0")

      // Only animate translate-y on mobile (slide down to bottom)
      if (window.innerWidth < 768) {
        panel.classList.remove("translate-y-0")
        panel.classList.add("translate-y-full")
      }
    }

    setTimeout(() => {
      this.element.classList.add("hidden")

      const serviceInput = this.element.querySelector('[data-role="serviceInput"]')
      const locationInput = this.element.querySelector('[data-role="locationInput"]')
      if (serviceInput) serviceInput.value = ""
      if (locationInput) locationInput.value = ""

      this.showDefaultContent()
      this.showAllCities()
      this.selectedService = null
      this.selectedLocation = null
    }, 300)

    document.body.style.overflow = ""
  }

  switchToService() {
    this.element.dataset.context = "service"
    this.updateContext()
  }

  switchToLocation() {
    this.element.dataset.context = "location"
    this.updateContext()
  }

  updateContext() {
    const isService = this.element.dataset.context === "service"

    const serviceInput = this.element.querySelector('[data-role="serviceInput"]')
    const locationInput = this.element.querySelector('[data-role="locationInput"]')
    const serviceContext = this.element.querySelector('[data-role="serviceContext"]')
    const locationContext = this.element.querySelector('[data-role="locationContext"]')

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

    if (serviceContext) {
      serviceContext.classList.toggle("hidden", !isService)
    }

    if (locationContext) {
      locationContext.classList.toggle("hidden", isService)
    }

    setTimeout(() => {
      if (isService && serviceInput) {
        serviceInput.focus()
      } else if (!isService && locationInput) {
        locationInput.focus()
      }
    }, 100)
  }

  onServiceInput(event) {
    const query = event.target.value.trim()

    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    if (query.length < 2) {
      this.showDefaultContent()
      return
    }

    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  onLocationInput(event) {
    const query = event.target.value.trim().toLowerCase()
    const cityItems = this.element.querySelectorAll('[data-role="cityItem"]')

    if (!cityItems.length) return

    let hasVisibleCities = false

    cityItems.forEach(cityButton => {
      const cityName = cityButton.dataset.city.toLowerCase()
      const matches = cityName.includes(query)
      cityButton.classList.toggle("hidden", !matches)
      if (matches) hasVisibleCities = true
    })

    const noResults = this.element.querySelector('[data-role="noLocationResults"]')
    if (noResults) {
      noResults.classList.toggle("hidden", hasVisibleCities)
    }
  }

  showAllCities() {
    const cityItems = this.element.querySelectorAll('[data-role="cityItem"]')
    cityItems.forEach(cityButton => {
      cityButton.classList.remove("hidden")
    })

    const noResults = this.element.querySelector('[data-role="noLocationResults"]')
    if (noResults) {
      noResults.classList.add("hidden")
    }
  }

  useMyLocation() {
    if (!navigator.geolocation) {
      console.log("Geolocation not supported")
      return
    }

    const geoText = this.element.querySelector('[data-role="geoText"]')
    if (geoText) {
      geoText.textContent = "Se detectează..."
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.selectedLocation = "Locația ta"

        // Dispatch event
        document.dispatchEvent(new CustomEvent("modal:location-selected", {
          detail: {
            location: "Locația ta",
            coordinates: {
              lat: position.coords.latitude,
              lng: position.coords.longitude
            }
          }
        }))

        if (geoText) {
          geoText.textContent = "Locația ta"
        }

        const locationInput = this.element.querySelector('[data-role="locationInput"]')
        if (locationInput) {
          locationInput.value = "Locația ta"
        }

        if (!this.selectedService) {
          this.element.dataset.context = "service"
          this.updateContext()
        } else {
          this.close()
        }
      },
      (error) => {
        console.error("Geolocation error:", error)
        if (geoText) {
          geoText.textContent = "Locația ta"
        }
      }
    )
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
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Search error:", error)
    }
  }

  showResults() {
    const results = this.element.querySelector('[data-role="results"]')
    const defaultContent = this.element.querySelector('[data-role="defaultContent"]')

    if (results) {
      results.classList.remove("hidden")
    }
    if (defaultContent) {
      defaultContent.classList.add("hidden")
    }
  }

  showDefaultContent() {
    const results = this.element.querySelector('[data-role="results"]')
    const defaultContent = this.element.querySelector('[data-role="defaultContent"]')

    if (results) {
      results.classList.add("hidden")
    }
    if (defaultContent) {
      defaultContent.classList.remove("hidden")
    }
  }

  selectService(event) {
    const service = event.currentTarget.dataset.service
    this.selectedService = service

    const serviceInput = this.element.querySelector('[data-role="serviceInput"]')
    if (serviceInput) {
      serviceInput.value = service
    }

    // Dispatch event
    document.dispatchEvent(new CustomEvent("modal:service-selected", {
      detail: { service }
    }))

    if (!this.selectedLocation) {
      this.element.dataset.context = "location"
      this.updateContext()
    } else {
      this.close()
    }
  }

  selectLocation(event) {
    const location = event.currentTarget.dataset.city
    this.selectedLocation = location

    const locationInput = this.element.querySelector('[data-role="locationInput"]')
    if (locationInput) {
      locationInput.value = location
    }

    // Dispatch event
    document.dispatchEvent(new CustomEvent("modal:location-selected", {
      detail: { location }
    }))

    if (!this.selectedService) {
      this.element.dataset.context = "service"
      this.updateContext()
    } else {
      this.close()
    }
  }
}
