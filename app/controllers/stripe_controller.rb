class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token # Webhooks don't include CSRF tokens

  def webhook
    # Handle both raw body (production) and params (test environment)
    payload = request.body.read
    payload = params.to_json if payload.blank? && params.present?

    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)

      # Handle the event
      case event["type"]
        when "account.updated"
          handle_account_updated(event["data"]["object"])
        when "payment_intent.succeeded"
          handle_payment_intent_succeeded(event["data"]["object"])
        when "payment_intent.payment_failed"
          handle_payment_intent_failed(event["data"]["object"])
        when "checkout.session.expired"
          handle_checkout_session_expired(event.data.object)
          # Add more event types as needed
        else
          Rails.logger.info "Unhandled event type: #{event["type"]}"
      end

      render json: { message: "Success" }, status: 200
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: 400
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: 400
    end
  end

  private

  def handle_account_updated(account)
    provider = Provider.find_by(stripe_account_id: account["id"])
    if provider
      provider.update!(
        stripe_status: (account["charges_enabled"] && account["payouts_enabled"]) ? "active" : "incomplete",
        charges_enabled: account["charges_enabled"],
        payouts_enabled: account["payouts_enabled"],
        requirements_due: account["requirements"]["currently_due"] # This stores any incomplete requirements
      )
      Rails.logger.info "Updated Provider #{provider.id} with Stripe account status"
    else
      Rails.logger.error "No provider found for Stripe account ID #{account["id"]}"
    end
  end

  def handle_payment_intent_succeeded(payment_intent)
    # Find appointment by payment intent ID (more efficient than session lookup)
    appointment = Appointment.find_by(stripe_payment_intent_id: payment_intent["id"])

    if appointment
      # Idempotency check - don't process if already confirmed
      return if appointment.confirmed?

      appointment.update!(status: :confirmed)
      Rails.logger.info "Payment succeeded for appointment ID: #{appointment.id}"

      # The transfer happens automatically due to transfer_data in payment intent
      # But we can add additional logic here if needed for tracking
    else
      Rails.logger.error "No appointment found for payment intent: #{payment_intent["id"]}"
    end
  end

  def handle_payment_intent_failed(payment_intent)
    # Find appointment by payment intent ID and mark as failed
    appointment = Appointment.find_by(stripe_payment_intent_id: payment_intent["id"])

    if appointment
      appointment.update!(status: :cancelled)
      Rails.logger.info "Payment failed for appointment ID: #{appointment.id}, marked as cancelled"
    else
      Rails.logger.error "Payment failed for unknown payment intent: #{payment_intent["id"]}"
    end
  end

  def handle_checkout_session_expired(session)
    appointment_id = session.dig("metadata", "appointment_id")
    return unless appointment_id

    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment&.pending?

    Rails.logger.info "Deleting expired pending appointment #{appointment.id} from Stripe session #{session.id}"
    appointment.destroy
  end
end
