class AppointmentMailer < ApplicationMailer
  default from: "gabriel.giroe@localhub.solutions"

  def confirmation_email_user(appointment)
    @appointment = appointment
    @user = appointment.user
    @provider = appointment.provider

    mail(
      to: @user.email,
      subject: "Your appointment has been confirmed!"
    )
  end

  def confirmation_email_provider(appointment)
    @appointment = appointment
    @user = appointment.user
    @provider = appointment.provider

    mail(
      to: @provider.user.email,
      subject: "New appointment confirmed!"
    )
  end

  def reminder_email_user(appointment)
    @appointment = appointment
    @user = appointment.user
    @provider = appointment.provider

    mail(
      to: @user.email,
      subject: "Reminder: Upcoming appointment in 1 hour"
    )
  end

  def reminder_email_provider(appointment)
    @appointment = appointment
    @user = appointment.user
    @provider = appointment.provider

    mail(
      to: @provider.user.email,
      subject: "Reminder: Upcoming appointment in 1 hour"
    )
  end
end
