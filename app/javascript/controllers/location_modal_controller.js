import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "panel", "input", "citiesList", "cityItem", "noResults", "geoButton", "geoText", "geoError"]

  // Romanian cities for filtering
  static cities = [
    "Bucuresti", "Cluj-Napoca", "Timisoara", "Iasi", "Constanta",
    "Craiova", "Brasov", "Galati", "Ploiesti", "Oradea",
    "Sibiu", "Bacau", "Arad", "Pitesti", "Buzau"
  ]

  connect() {
    console.log("location-modal controller connected")
    this.isOpen = false
    this.boundHandleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  open() {
    this.isOpen = true
    this.element.classList.remove("hidden")

    // Force reflow
    this.element.offsetHeight

    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")

      // Mobile: slide up, Desktop: fade/scale
      if (window.innerWidth < 768) {
        this.panelTarget.classList.remove("translate-y-full")
        this.panelTarget.classList.add("translate-y-0")
      } else {
        this.panelTarget.classList.remove("scale-95", "opacity-0")
        this.panelTarget.classList.add("scale-100", "opacity-100")
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

    if (window.innerWidth < 768) {
      this.panelTarget.classList.remove("translate-y-0")
      this.panelTarget.classList.add("translate-y-full")
    } else {
      this.panelTarget.classList.remove("scale-100", "opacity-100")
      this.panelTarget.classList.add("scale-95", "opacity-0")
    }

    // Hide after animation
    setTimeout(() => {
      this.element.classList.add("hidden")
      this.inputTarget.value = ""
      this.resetFilter()
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

  filterCities(event) {
    const query = event.target.value.trim().toLowerCase()

    if (!this.hasCityItemTarget) return

    let visibleCount = 0

    this.cityItemTargets.forEach(item => {
      const city = item.dataset.city.toLowerCase()
      const matches = query === "" || city.includes(query)

      if (matches) {
        item.classList.remove("hidden")
        visibleCount++
      } else {
        item.classList.add("hidden")
      }
    })

    // Show/hide no results message
    if (this.hasNoResultsTarget) {
      if (visibleCount === 0 && query !== "") {
        this.noResultsTarget.classList.remove("hidden")
      } else {
        this.noResultsTarget.classList.add("hidden")
      }
    }
  }

  resetFilter() {
    if (this.hasCityItemTarget) {
      this.cityItemTargets.forEach(item => {
        item.classList.remove("hidden")
      })
    }
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.add("hidden")
    }
    if (this.hasGeoErrorTarget) {
      this.geoErrorTarget.classList.add("hidden")
    }
  }

  selectCity(event) {
    const city = event.currentTarget.dataset.city

    // Dispatch custom event to parent controller
    const customEvent = new CustomEvent("location-selected", {
      detail: { location: city },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)

    this.close()
  }

  async useMyLocation() {
    if (!navigator.geolocation) {
      this.showGeoError("Geolocația nu este suportată de browser-ul tău.")
      return
    }

    // Update button state
    this.geoTextTarget.textContent = "Se detectează locația..."
    this.geoButtonTarget.disabled = true

    try {
      const position = await this.getCurrentPosition()
      const { latitude, longitude } = position.coords

      // Reverse geocode using OpenStreetMap Nominatim
      const city = await this.reverseGeocode(latitude, longitude)

      if (city) {
        // Dispatch custom event
        const customEvent = new CustomEvent("location-selected", {
          detail: { location: city },
          bubbles: true
        })
        this.element.dispatchEvent(customEvent)

        this.close()
      } else {
        this.showGeoError("Nu s-a putut determina orașul. Te rugăm să selectezi manual.")
      }
    } catch (error) {
      let message = "Eroare la detectarea locației."
      if (error.code === 1) {
        message = "Acces la locație refuzat. Te rugăm să permiți accesul în setările browser-ului."
      } else if (error.code === 2) {
        message = "Locația nu este disponibilă."
      } else if (error.code === 3) {
        message = "Timeout la detectarea locației."
      }
      this.showGeoError(message)
    } finally {
      // Reset button state
      this.geoTextTarget.textContent = "Folosește locația mea"
      this.geoButtonTarget.disabled = false
    }
  }

  getCurrentPosition() {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: false,
        timeout: 10000,
        maximumAge: 300000 // 5 minutes cache
      })
    })
  }

  async reverseGeocode(latitude, longitude) {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=10&addressdetails=1`,
        {
          headers: {
            "Accept-Language": "ro"
          }
        }
      )

      if (!response.ok) {
        throw new Error("Geocoding failed")
      }

      const data = await response.json()

      // Try to get city from various fields
      const city = data.address?.city ||
                   data.address?.town ||
                   data.address?.municipality ||
                   data.address?.county

      if (city) {
        // Check if the city matches one of our known cities
        const matchedCity = this.constructor.cities.find(
          c => c.toLowerCase() === city.toLowerCase() ||
               city.toLowerCase().includes(c.toLowerCase()) ||
               c.toLowerCase().includes(city.toLowerCase())
        )
        return matchedCity || city
      }

      return null
    } catch (error) {
      console.error("Reverse geocoding error:", error)
      return null
    }
  }

  showGeoError(message) {
    if (this.hasGeoErrorTarget) {
      this.geoErrorTarget.textContent = message
      this.geoErrorTarget.classList.remove("hidden")
    }
  }
}
