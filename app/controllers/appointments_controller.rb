class AppointmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.provider?
      # For providers: filter confirmed appointments into upcoming and previous
      @upcoming_appointments = current_user.provider.appointments
        .where(status: :confirmed)
        .where("start_time >= ?", Time.now)
      @previous_appointments = current_user.provider.appointments
        .where(status: :confirmed)
        .where("end_time < ?", Time.now)
    else
      # For regular users: filter confirmed appointments into upcoming and previous
      @upcoming_appointments = current_user.appointments
        .where(status: :confirmed)
        .where("start_time >= ?", Time.now)
      @previous_appointments = current_user.appointments
        .where(status: :confirmed)
        .where("end_time < ?", Time.now)
    end
  end

  def new
    @provider = Provider.find(params[:provider_id])
    @availabilities = @provider.availabilities.where("available = ?", true)
    @appointment = Appointment.new
  end

  def create
    @provider = Provider.find(params[:provider_id])

    unless @provider.stripe_account_id.present?
      redirect_to provider_path(@provider), alert: "This provider hasn't set up payments yet"
      return
    end

    # Get the day of week and time from params
    day_of_week = params[:appointment][:day_of_week]
    start_time = Time.parse(params[:appointment][:start_time])
    appointment_date = Date.parse(params[:appointment][:appointment_date])

    # Combine date and time
    datetime = DateTime.new(
      appointment_date.year,
      appointment_date.month,
      appointment_date.day,
      start_time.hour,
      start_time.min
    )

    # Find availability for the given day
    availability = @provider.availabilities.find_by(day_of_week: day_of_week)

    # Check if the time slot is within the availability window
    if availability&.available? &&
        start_time.strftime("%H:%M") >= availability.start_time.strftime("%H:%M") &&
        start_time.strftime("%H:%M") < availability.end_time.strftime("%H:%M")

      @appointment = Appointment.new(
        user: current_user,
        provider: @provider,
        start_time: datetime,
        status: :pending
      )

      if @appointment.save
        # Schedule cleanup job for this appointment
        CleanupPendingAppointmentsJob.set(wait: 30.minutes).perform_later

        session = Stripe::Checkout::Session.create(
          payment_method_types: ["card"],
          line_items: [{
            price_data: {
              currency: "ron",
              product_data: {
                name: "Appointment with #{@provider.name}"
              },
              unit_amount: @provider.hourly_rate.to_i * 100
            },
            quantity: 1
          }],
          mode: "payment",
          success_url: success_appointment_url(@appointment),
          cancel_url: cancel_appointment_url(@appointment),
          expires_at: Time.now.to_i + (30 * 60) # Expire after 30 minutes
        )

        @appointment.update(stripe_session_id: session.id)
        redirect_to session.url, allow_other_host: true
      else
        redirect_to provider_path(@provider),
          alert: "Could not create appointment: #{@appointment.errors.full_messages.join(', ')}"
      end
    else
      redirect_to provider_path(@provider), alert: "This time slot is not available."
    end
  end

  def success
    @appointment = Appointment.find(params[:id])
    @appointment.update(status: :confirmed)

    # Schedule confirmation emails
    AppointmentConfirmationJob.perform_now(@appointment.id)

    # Schedule reminder emails for 1 hour before the appointment
    reminder_time = @appointment.start_time - 1.hour
    AppointmentReminderJob.set(wait_until: reminder_time).perform_later(@appointment.id)

    redirect_to appointments_path, notice: "Appointment confirmed successfully!"
  end

  def cancel
    @appointment = Appointment.find(params[:id])
    @appointment.update(status: :cancelled)
    redirect_to appointments_path, alert: "Appointment cancelled."
  end
end
