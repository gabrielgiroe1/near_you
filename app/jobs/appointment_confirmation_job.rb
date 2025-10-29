class AppointmentConfirmationJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)

    AppointmentMailer.confirmation_email_user(appointment).deliver_later
    AppointmentMailer.confirmation_email_provider(appointment).deliver_later

    # Send notifications
    AppointmentConfirmationNotifier.with(appointment: appointment).deliver(appointment.user)
    AppointmentConfirmationNotifier.with(appointment: appointment).deliver(appointment.provider.user)
  end
end
