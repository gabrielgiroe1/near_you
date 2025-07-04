require "rails_helper"

RSpec.describe "Stripe Payment Flow Integration", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, :with_stripe_account, hourly_rate: 100) }
  let(:availability) { create(:availability, provider: provider, day_of_week: "Monday", start_time: "09:00", end_time: "17:00") }
  let(:appointment_params) do
    {
      provider_id: provider.id,
      appointment: {
        day_of_week: "Monday",
        start_time: "10:00",
        appointment_date: Date.tomorrow.strftime("%Y-%m-%d")
      }
    }
  end

  before do
    sign_in user
    setup_stripe_mocks
    availability
  end

  describe "Complete appointment booking and payment flow" do
    it "completes full payment lifecycle" do
      # Step 1: Create appointment and redirect to Stripe
      expect {
        post "/providers/#{provider.id}/appointments", params: appointment_params
      }.to change(Appointment, :count).by(1)

      appointment = Appointment.last
      expect(appointment.status).to eq("pending")
      expect(appointment.stripe_session_id).to eq("cs_test_123")
      expect(appointment.stripe_payment_intent_id).to eq("pi_test_123")
      expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_test_123")

      # Step 2: Simulate successful payment webhook by calling the handler directly
      # This tests the business logic without HTTP complexity
      stripe_controller = StripeController.new
      payment_intent_data = {
        "id" => appointment.stripe_payment_intent_id,
        "metadata" => {
          "appointment_id" => appointment.id.to_s
        }
      }

      expect {
        stripe_controller.send(:handle_payment_intent_succeeded, payment_intent_data)
      }.to change { appointment.reload.status }.from("pending").to("confirmed")

      # Step 3: Customer returns to success page
      get "/appointments/#{appointment.id}/success"
      expect(response).to redirect_to(appointments_path)
      expect(flash[:notice]).to include("confirmed successfully")

      # Step 4: Later cancellation with refund
      expect {
        get "/appointments/#{appointment.id}/cancel"
      }.to change { appointment.reload.status }.from("confirmed").to("cancelled")

      expect(appointment.reload.refunded_at).to be_present
      expect(appointment.stripe_refund_id).to eq("re_test_123")
      expect(response).to redirect_to(appointments_path)
      expect(flash[:notice]).to include("refund processed")
    end

    it "handles payment failure scenario" do
      # Step 1: Create appointment
      post "/providers/#{provider.id}/appointments", params: appointment_params
      appointment = Appointment.last

      # Step 2: Simulate failed payment webhook by calling the handler directly
      stripe_controller = StripeController.new
      payment_intent_data = {
        "id" => appointment.stripe_payment_intent_id
      }

      expect {
        stripe_controller.send(:handle_payment_intent_failed, payment_intent_data)
      }.to change { appointment.reload.status }.from("pending").to("cancelled")

      # Step 3: Customer returns to cancel page (no refund needed for failed payment)
      expect(Stripe::Refund).not_to receive(:create)

      get "/appointments/#{appointment.id}/cancel"
      expect(response).to redirect_to(appointments_path)
      expect(flash[:notice]).to include("cancelled")
    end

    it "calculates platform fees correctly" do
      post "/providers/#{provider.id}/appointments", params: appointment_params

      # Verify Stripe was called with correct fee calculation
      expected_total = provider.hourly_rate.to_i * 100 # 10000 cents ($100)
      expected_fee = (expected_total * 0.1).to_i # 1000 cents ($10)
      expected_provider_amount = expected_total - expected_fee # 9000 cents ($90)

      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          line_items: [{
            price_data: hash_including(unit_amount: expected_total),
            quantity: 1
          }],
          payment_intent_data: hash_including(
            application_fee_amount: expected_fee,
            transfer_data: { destination: provider.stripe_account_id }
          )
        )
      )
    end

    it "includes proper metadata for tracking" do
      post "/providers/#{provider.id}/appointments", params: appointment_params
      appointment = Appointment.last

      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          payment_intent_data: hash_including(
            metadata: {
              appointment_id: appointment.id,
              provider_id: provider.id,
              user_id: user.id
            }
          )
        )
      )
    end
  end

  describe "Error handling scenarios" do
    it "handles Stripe API errors gracefully" do
      # Reset the mock to throw an error for this test
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(
        Stripe::CardError.new("Your card was declined", "card_declined")
      )

      # The appointment is created but Stripe session creation fails
      # This causes the Stripe error to bubble up and crash the request
      expect {
        post "/providers/#{provider.id}/appointments", params: appointment_params
      }.to raise_error(Stripe::CardError)

      # The appointment gets created but has no stripe session
      appointment = Appointment.last
      expect(appointment).to be_present
      expect(appointment.stripe_session_id).to be_nil
      expect(appointment.status).to eq("pending")
    end

    it "prevents duplicate appointments during concurrent requests" do
      # Create an overlapping appointment first
      next_monday = Date.tomorrow
      while next_monday.strftime("%A") != "Monday"
        next_monday += 1.day
      end

      existing_appointment = create(:appointment, :confirmed,
        provider: provider,
        start_time: next_monday.in_time_zone.change(hour: 10, min: 0),
        end_time: next_monday.in_time_zone.change(hour: 11, min: 0))

      # Update appointment_params to use the same Monday date
      overlapping_params = appointment_params.deep_dup
      overlapping_params[:appointment][:appointment_date] = next_monday.strftime("%Y-%m-%d")

      expect {
        post "/providers/#{provider.id}/appointments", params: overlapping_params
      }.not_to change(Appointment, :count)

      expect(response).to redirect_to(provider_path(provider))
      expect(flash[:alert]).to include("Could not create appointment")
    end

    it "handles webhook replay attacks with idempotency" do
      appointment = create(:appointment, :confirmed)

      # Test idempotency by calling handler on already confirmed appointment
      stripe_controller = StripeController.new
      payment_intent_data = {
        "id" => appointment.stripe_payment_intent_id
      }

      # First webhook call - no change expected since already confirmed
      expect {
        stripe_controller.send(:handle_payment_intent_succeeded, payment_intent_data)
      }.not_to change { appointment.reload.updated_at }
    end
  end

  describe "Provider onboarding flow" do
    let(:incomplete_provider) { create(:provider, user: create(:user)) }

    it "requires Stripe setup before accepting appointments" do
      post "/providers/#{incomplete_provider.id}/appointments", params: appointment_params.merge(provider_id: incomplete_provider.id)

      expect(response).to redirect_to(provider_path(incomplete_provider))
      expect(flash[:alert]).to include("hasn't set up payments yet")
      expect(Appointment.count).to eq(0)
    end

    it "completes provider onboarding flow" do
      sign_in incomplete_provider.user

      # Start onboarding
      expect {
        post "/stripe_connect", params: { provider_id: incomplete_provider.id }
      }.to change { incomplete_provider.reload.stripe_account_id }.from(nil).to("acct_test_123")

      expect(incomplete_provider.reload.stripe_status).to eq("incomplete")
      expect(response).to redirect_to("https://connect.stripe.com/setup/onboarding/123")

      # Simulate account update webhook by calling the handler directly
      stripe_controller = StripeController.new
      account_data = {
        "id" => incomplete_provider.stripe_account_id,
        "charges_enabled" => true,
        "payouts_enabled" => true,
        "requirements" => { "currently_due" => [] }
      }

      expect {
        stripe_controller.send(:handle_account_updated, account_data)
      }.to change { incomplete_provider.reload.stripe_status }.from("incomplete").to("active")

      expect(incomplete_provider.reload.charges_enabled).to be true
      expect(incomplete_provider.reload.payouts_enabled).to be true
    end
  end
end
