require "ostruct"

module StripeHelpers
  def setup_stripe_mocks
    # Mock job queuing to avoid Solid Queue dependency in tests
    allow(AppointmentConfirmationJob).to receive(:perform_now)
    allow(AppointmentReminderJob).to receive_message_chain(:set, :perform_later)
    # Mock successful checkout session creation

    # Mock successful account creation

    # Mock account retrieval (for refresh_account_status)
    allow(Stripe::Account).to receive_messages(create: OpenStruct.new(
        id: "acct_test_123",
        charges_enabled: false,
        payouts_enabled: false,
        requirements: OpenStruct.new(currently_due: [])
      ), retrieve: OpenStruct.new(
        id: "acct_test_123",
        charges_enabled: false,
        payouts_enabled: false,
        requirements: OpenStruct.new(currently_due: [])
      ))

    # Mock successful account link creation
    allow(Stripe::AccountLink).to receive(:create).and_return(
      OpenStruct.new(url: "https://connect.stripe.com/setup/onboarding/123")
    )

    # Mock successful refund creation
    allow(Stripe::Refund).to receive(:create).and_return(
      OpenStruct.new(id: "re_test_123", status: "succeeded")
    )

    # Mock checkout session retrieval
    allow(Stripe::Checkout::Session).to receive_messages(create: OpenStruct.new(
        id: "cs_test_123",
        url: "https://checkout.stripe.com/pay/cs_test_123",
        payment_intent: "pi_test_123"
      ), retrieve: OpenStruct.new(
        id: "cs_test_123",
        payment_intent: "pi_test_123"
      ))

    # Mock payment intent retrieval
    allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(
      OpenStruct.new(id: "pi_test_123")
    )
  end

  def stripe_webhook_event(type, data = {})
    {
      "id" => "evt_test_123",
      "type" => type,
      "data" => {
        "object" => data
      }
    }
  end

  def mock_stripe_signature
    "t=1234567890,v1=test_signature"
  end

  def stripe_payment_intent_data(appointment_id = 1)
    {
      "id" => "pi_test_123",
      "metadata" => {
        "appointment_id" => appointment_id.to_s
      }
    }
  end

  def stripe_account_data(account_id = "acct_test_123")
    {
      "id" => account_id,
      "charges_enabled" => true,
      "payouts_enabled" => true,
      "requirements" => {
        "currently_due" => []
      }
    }
  end

  def post_webhook(url, payload, headers = {})
    # For Rails request specs, we need to simulate the webhook properly
    # by sending the JSON as raw body content
    post url,
      params: payload.to_json,
      headers: headers.merge("CONTENT_TYPE" => "application/json"),
      as: :json
  end

  def post_raw_webhook(url, payload, headers = {})
    # Alternative method that sends raw body data
    post url,
      params: {},
      headers: headers.merge("CONTENT_TYPE" => "application/json"),
      env: { "RAW_POST_DATA" => payload.to_json }
  end
end
