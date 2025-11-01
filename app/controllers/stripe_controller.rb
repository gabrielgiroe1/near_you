class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token # Webhooks don't include CSRF tokens
  skip_before_action :authenticate_user! # Webhooks are unauthenticated requests from Stripe

  def webhook
    # Handle both raw body (production) and params (test environment)
    payload = request.body.read
    payload = params.to_json if payload.blank? && params.present?

    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.configuration.stripe[:webhook_secret]

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
          handle_checkout_session_expired(event["data"]["object"])
        when "charge.refunded"
          handle_charge_refunded(event["data"]["object"])
        when "transfer.created"
          handle_transfer_created(event["data"]["object"])
        when "transfer.failed"
          handle_transfer_failed(event["data"]["object"])
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

    Rails.logger.info "Deleting expired pending appointment #{appointment.id} from Stripe session #{session["id"]}"
    appointment.destroy
  end

  def handle_charge_refunded(charge)
    # Log refund information
    payment_intent_id = charge["payment_intent"]
    appointment = Appointment.find_by(stripe_payment_intent_id: payment_intent_id)

    if appointment
      Rails.logger.info "Charge refunded for appointment #{appointment.id}"
      # Additional refund tracking logic if needed
    else
      Rails.logger.warn "Charge refunded for unknown payment intent: #{payment_intent_id}"
    end
  end

  def handle_transfer_created(transfer)
    # Log successful transfer to provider
    destination_account = transfer["destination"]
    amount = transfer["amount"]

    provider = Provider.find_by(stripe_account_id: destination_account)
    if provider
      Rails.logger.info "Transfer of #{amount} cents created to provider #{provider.id} (#{provider.name})"
    else
      Rails.logger.warn "Transfer created to unknown account: #{destination_account}"
    end
  end

  def handle_transfer_failed(transfer)
    # Log failed transfer to provider
    destination_account = transfer["destination"]
    failure_message = transfer["failure_message"]

    provider = Provider.find_by(stripe_account_id: destination_account)
    if provider
      Rails.logger.error "Transfer failed to provider #{provider.id}: #{failure_message}"
      # You might want to notify the provider or admin about this
    else
      Rails.logger.error "Transfer failed to unknown account #{destination_account}: #{failure_message}"
    end
  end
end
