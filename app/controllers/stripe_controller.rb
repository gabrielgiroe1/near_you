class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token # Webhooks don't include CSRF tokens

  def webhook
    payload = request.body.read
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
    # Logic for successful payment
    appointment = Appointment.find_by(stripe_session_id: payment_intent["id"])
    appointment&.update!(status: :confirmed)
    Rails.logger.info "Payment succeeded for appointment ID: #{appointment&.id}"
  end

  def handle_payment_intent_failed(payment_intent)
    # Logic for failed payment
    Rails.logger.error "Payment failed: #{payment_intent["id"]}"
  end
end
