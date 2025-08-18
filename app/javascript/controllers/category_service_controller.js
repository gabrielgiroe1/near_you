// app/javascript/controllers/category_service_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["categorySelect", "serviceSelect"]

  connect() {
    // Initialize service types on page load if category is already selected
    const categorySelect = this.categorySelectTarget;
    if (categorySelect && categorySelect.value) {
      // Don't fetch again, the server should have already populated @service_types
    }
  }

  toggle(event) {
    const dropdown = this.element.querySelector("#filter-dropdown");
    if (dropdown) {
      dropdown.classList.toggle("hidden");
    } else {
      console.error("Dropdown not found!");
    }
  }

  fetchServiceTypes(event) {
    const category = event.target.value;
    const frameId = this.element.dataset.categoryServiceFrameIdValue;

    if (category) {
      const url = `/providers/service_types?category=${encodeURIComponent(category)}&frame_id=${frameId}`;

      fetch(url, {
        method: "GET",
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })
        .then(response => {
          return response.text();
        })
        .then(html => {
          Turbo.renderStreamMessage(html);
        })
        .catch(error => console.error("Error fetching service types:", error));
    } else {
      console.warn("No category selected, resetting dropdown.");
      const serviceTypeFrame = document.getElementById(frameId);
      if (serviceTypeFrame) {
        serviceTypeFrame.innerHTML = `
          <div>
            <label for="service_type" class="block text-sm font-medium text-gray-700 mt-4">Service Type</label>
            <select name="service_type" id="service_type" class="mt-1 block w-full rounded-md border-gray-300 shadow-xs" onchange="this.form.submit();">
              <option value="">Select a Service Type</option>
            </select>
          </div>
        `;
      }
    }
  }
}