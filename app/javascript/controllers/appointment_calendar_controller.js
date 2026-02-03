import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "timeSlot", "confirmationModal"]

  connect() {
    console.log("Appointment Calendar Controller connected!!!!")
  }

  show() {
    this.modalTarget.classList.remove("hidden")
  }

  hide() {
    this.modalTarget.classList.add("hidden")
  }

  selectDate(event) {
    const date = event.target.value
    const providerId = this.element.dataset.appointmentCalendarProviderIdValue;
    
    fetch(`/providers/${providerId}/available_slots?date=${date}`)
      .then(response => response.json())
      .then(data => {
        this.timeSlotTarget.innerHTML = data.slots.map(slot =>
          `<button data-time="${slot}" 
            data-action="click->appointment-calendar#showConfirmation"
            class="slot-btn bg-gray-200 hover:bg-gray-400 text-black font-bold py-1 px-2 m-1 rounded">
            ${slot}
          </button>`
        ).join("")
      })
      .catch(error => console.error('Error:', error));
  }

  showConfirmation(event) {
    const selectedTime = event.target.dataset.time
    const date = document.getElementById('appointment-date').value
    this.selectedDateTime = `${date} ${selectedTime}`
    this.confirmationModalTarget.classList.remove("hidden")
  }

  hideConfirmation() {
    this.confirmationModalTarget.classList.add("hidden")
  }

  confirmAppointment() {
    const providerId = this.element.dataset.appointmentCalendarProviderIdValue;
    const [date, time] = this.selectedDateTime.split(' ')
    
    // Create form and submit
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/providers/${providerId}/appointments`
    
    // Add CSRF token from meta tag
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)
    
    // Parse the date to get the day of week
    const appointmentDate = new Date(date)
    const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    const dayOfWeek = daysOfWeek[appointmentDate.getDay()]
    
    // Add appointment details
    const appointmentParams = {
      'appointment[start_time]': time,
      'appointment[day_of_week]': dayOfWeek,
      'appointment[appointment_date]': date
    }
    
    Object.entries(appointmentParams).forEach(([name, value]) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = name
      input.value = value
      form.appendChild(input)
    })
    
    document.body.appendChild(form)
    form.submit()
  }
}