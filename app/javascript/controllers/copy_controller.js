import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button" ]

  copy() {
    console.log("Copy button clicked")
    const providerUrl = window.location.href // Copies the current URL
    navigator.clipboard.writeText(providerUrl)
  }
}