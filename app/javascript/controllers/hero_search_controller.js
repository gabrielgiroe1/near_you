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
  }

  openServiceModal() {
    // Dispatch a global event that the search-modal controller will listen for
    window.dispatchEvent(new CustomEvent("open-search-modal"))
  }

  openLocationModal() {
    // Dispatch a global event that the location-modal controller will listen for
    window.dispatchEvent(new CustomEvent("open-location-modal"))
  }

  // Called when a service is selected from the modal
  selectService(event) {
    const service = event.detail.service
    this.searchInputTarget.value = service
    this.serviceDisplayTarget.textContent = service
  }

  // Called when a location is selected from the modal
  selectLocation(event) {
    const location = event.detail.location
    this.locationInputTarget.value = location
    this.locationDisplayTarget.textContent = location
  }
}
