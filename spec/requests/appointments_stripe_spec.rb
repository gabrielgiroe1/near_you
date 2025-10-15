require "rails_helper"

RSpec.describe "Appointments with Stripe Integration", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, :with_stripe_account, hourly_rate: 100) }
  let(:availability) { create(:availability, provider: provider, day_of_week: "Monday", start_time: "09:00", end_time: "17:00") }

  before do
    sign_in user
    setup_stripe_mocks
    availability
  end

  describe "POST /providers/:provider_id/appointments" do
    let(:appointment_params) do
      {
        appointment: {
          day_of_week: "Monday",
          start_time: "10:00",
          appointment_date: Date.tomorrow.strftime("%Y-%m-%d")
        }
      }
    end

    context "with valid parameters and Stripe account setup" do
      it "creates appointment and redirects to Stripe checkout" do
        expect {
          post "/providers/#{provider.id}/appointments", params: appointment_params
        }.to change(Appointment, :count).by(1)

        appointment = Appointment.last
        expect(appointment.user).to eq(user)
        expect(appointment.provider).to eq(provider)
        expect(appointment.status).to eq("pending")
        expect(appointment.stripe_session_id).to eq("cs_test_123")
        expect(appointment.stripe_payment_intent_id).to eq("pi_test_123")

        expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_test_123")
      end

      it "calls Stripe with correct application fee" do
        post "/providers/#{provider.id}/appointments", params: appointment_params

        expected_total = provider.hourly_rate.to_i * 100 # 10000 cents
        expected_fee = (expected_total * 0.1).to_i # 1000 cents

        expect(Stripe::Checkout::Session).to have_received(:create).with(
          hash_including(
            payment_intent_data: hash_including(
              application_fee_amount: expected_fee,
              on_behalf_of: provider.stripe_account_id,
              transfer_data: { destination: provider.stripe_account_id }
            )
          )
        )
      end
    end

    context "when provider has no Stripe account" do
      let(:provider_without_stripe) { create(:provider) }

      it "redirects with alert" do
        post "/providers/#{provider_without_stripe.id}/appointments", params: appointment_params

        expect(response).to redirect_to("/providers/#{provider_without_stripe.id}")
        expect(flash[:alert]).to include("needs to complete their payment setup before accepting bookings")
      end
    end
  end

  describe "GET /appointments/:id/success" do
    let(:appointment) { create(:appointment, :with_stripe_session, user: user) }

    it "confirms the appointment" do
      expect {
        get "/appointments/#{appointment.id}/success"
      }.to change { appointment.reload.status }.from("pending").to("confirmed")

      expect(response).to redirect_to("/appointments")
    end
  end

  describe "GET /appointments/:id/cancel" do
    context "with confirmed appointment" do
      let(:appointment) { create(:appointment, :confirmed, user: user) }

      it "processes refund and cancels appointment" do
        expect {
          get "/appointments/#{appointment.id}/cancel"
        }.to change { appointment.reload.status }.from("confirmed").to("cancelled")

        expect(appointment.reload.refunded_at).to be_present
        expect(appointment.stripe_refund_id).to eq("re_test_123")
        expect(response).to redirect_to("/appointments")
      end

      it "calls Stripe refund with correct parameters" do
        get "/appointments/#{appointment.id}/cancel"

        expect(Stripe::Refund).to have_received(:create).with(
          hash_including(
            payment_intent: appointment.stripe_payment_intent_id,
            reverse_transfer: true
          )
        )
      end
    end

    context "when already refunded" do
      let(:appointment) { create(:appointment, :refunded, user: user) }

      it "doesn't process refund again" do
        expect(Stripe::Refund).not_to receive(:create)

        get "/appointments/#{appointment.id}/cancel"
        expect(response).to redirect_to("/appointments")
      end
    end

    context "when Stripe refund fails" do
      let(:appointment) { create(:appointment, :confirmed, user: user) }

      before do
        allow(Stripe::Refund).to receive(:create).and_raise(
          Stripe::StripeError.new("Refund failed")
        )
      end

      it "cancels appointment but shows error" do
        expect {
          get "/appointments/#{appointment.id}/cancel"
        }.to change { appointment.reload.status }.from("confirmed").to("cancelled")

        expect(appointment.reload.refunded_at).to be_nil
        expect(response).to redirect_to("/appointments")
      end
    end
  end
end
