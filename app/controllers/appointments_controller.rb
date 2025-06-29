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

        platform_fee_rate = Rails.configuration.stripe[:platform_fee_rate]
        total_amount = @provider.hourly_rate.to_i * 100
        application_fee = (total_amount * platform_fee_rate).to_i

        session = Stripe::Checkout::Session.create(
          payment_method_types: ["card"],
          line_items: [{
            price_data: {
              currency: "ron",
              product_data: {
                name: "Appointment with #{@provider.name}"
              },
              unit_amount: total_amount
            },
            quantity: 1
          }],
          mode: "payment",
          success_url: success_appointment_url(@appointment),
          cancel_url: cancel_appointment_url(@appointment),
          expires_at: Time.now.to_i + (30 * 60), # Expire after 30 minutes
          payment_intent_data: {
            application_fee_amount: application_fee,
            on_behalf_of: @provider.stripe_account_id,
            transfer_data: {
              destination: @provider.stripe_account_id
            },
            metadata: {
              appointment_id: @appointment.id,
              provider_id: @provider.id,
              user_id: current_user.id
            }
          }
        )

        @appointment.update!(
          stripe_session_id: session.id,
          stripe_payment_intent_id: session.payment_intent
        )
        redirect_to session.url, allow_other_host: true
      else
        redirect_to provider_path(@provider),
          alert: "Could not create appointment: #{@appointment.errors.full_messages.join(",")}"
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

    # Process refund if payment was successful and not already refunded
    if @appointment.stripe_payment_intent_id.present? && @appointment.confirmed? && @appointment.refunded_at.nil?
      begin
        # Create refund using stored payment intent ID
        refund = Stripe::Refund.create({
          payment_intent: @appointment.stripe_payment_intent_id,
          reverse_transfer: true # This reverses the transfer to the provider
        })

        Rails.logger.info "Refund created for appointment #{@appointment.id}: #{refund.id}"
        @appointment.update!(
          status: :cancelled,
          refunded_at: Time.current,
          stripe_refund_id: refund.id
        )
        redirect_to appointments_path, notice: "Appointment cancelled and refund processed."
      rescue Stripe::StripeError => e
        Rails.logger.error "Refund failed for appointment #{@appointment.id}: #{e.message}"
        @appointment.update!(status: :cancelled)
        redirect_to appointments_path, alert: "Appointment cancelled but refund failed. Please contact support."
      end
    else
      @appointment.update(status: :cancelled)
      redirect_to appointments_path, notice: "Appointment cancelled."
    end
  end
end
