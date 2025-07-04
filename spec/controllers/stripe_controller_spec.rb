require "rails_helper"

RSpec.describe StripeController, type: :controller do
  include StripeHelpers
  let(:controller_instance) { described_class.new }

  describe "Webhook handlers" do
    context "when handling payment_intent.succeeded" do
      let(:appointment) { create(:appointment, :with_stripe_session) }
      let(:payment_intent_data) do
        {
          "id" => appointment.stripe_payment_intent_id,
          "metadata" => {
            "appointment_id" => appointment.id.to_s
          }
        }
      end

      it "confirms the appointment" do
        expect {
          controller_instance.send(:handle_payment_intent_succeeded, payment_intent_data)
        }.to change { appointment.reload.status }.from("pending").to("confirmed")
      end

      it "is idempotent - doesn't process already confirmed appointment" do
        appointment.update!(status: :confirmed)

        expect {
          controller_instance.send(:handle_payment_intent_succeeded, payment_intent_data)
        }.not_to change { appointment.reload.updated_at }
      end

      it "logs error when appointment not found" do
        payment_intent_data["id"] = "pi_nonexistent_123"
        expect(Rails.logger).to receive(:error).with(/No appointment found/)

        controller_instance.send(:handle_payment_intent_succeeded, payment_intent_data)
      end
    end

    context "when handling payment_intent.payment_failed" do
      let(:appointment) { create(:appointment, :with_stripe_session) }
      let(:payment_intent_data) { { "id" => appointment.stripe_payment_intent_id } }

      it "cancels the appointment" do
        expect {
          controller_instance.send(:handle_payment_intent_failed, payment_intent_data)
        }.to change { appointment.reload.status }.from("pending").to("cancelled")
      end

      it "logs error when appointment not found" do
        payment_intent_data["id"] = "pi_nonexistent_123"
        expect(Rails.logger).to receive(:error).with(/Payment failed for unknown payment intent/)

        controller_instance.send(:handle_payment_intent_failed, payment_intent_data)
      end
    end

    context "when handling account.updated" do
      let(:provider) { create(:provider, stripe_account_id: "acct_test_123") }
      let(:account_data) do
        {
          "id" => provider.stripe_account_id,
          "charges_enabled" => true,
          "payouts_enabled" => true,
          "requirements" => {
            "currently_due" => []
          }
        }
      end

      it "updates provider Stripe status to active" do
        expect {
          controller_instance.send(:handle_account_updated, account_data)
        }.to change { provider.reload.stripe_status }.to("active")

        expect(provider.reload.charges_enabled).to be true
        expect(provider.reload.payouts_enabled).to be true
      end

      it "updates provider Stripe status to incomplete when not fully enabled" do
        account_data["charges_enabled"] = false

        expect {
          controller_instance.send(:handle_account_updated, account_data)
        }.to change { provider.reload.stripe_status }.to("incomplete")

        expect(provider.reload.charges_enabled).to be false
      end

      it "logs error when provider not found" do
        account_data["id"] = "nonexistent_account"
        expect(Rails.logger).to receive(:error).with(/No provider found/)

        controller_instance.send(:handle_account_updated, account_data)
      end
    end

    # Note: HTTP-level webhook testing (signature verification, JSON parsing)
    # is better handled through integration tests or by testing against
    # actual Stripe webhook endpoints in a staging environment

    context "when handling checkout.session.expired" do
      let!(:appointment) { create(:appointment, status: :pending) }

      let(:expired_session_data) do
        {
          "id" => "cs_test_expired",
          "metadata" => {
            "appointment_id" => appointment.id
          }
        }
      end

      it "destroys the pending appointment" do
        expect {
          controller_instance.send(:handle_checkout_session_expired, expired_session_data)
        }.to change(Appointment, :count).by(-1)
      end

      it "does nothing if appointment is not found" do
        expired_session_data["metadata"]["appointment_id"] = "nonexistent_id"
        expect {
          controller_instance.send(:handle_checkout_session_expired, expired_session_data)
        }.not_to change(Appointment, :count)
      end

      it "does nothing if appointment is not pending" do
        appointment.update!(status: :confirmed)
        expect {
          controller_instance.send(:handle_checkout_session_expired, expired_session_data)
        }.not_to change(Appointment, :count)
      end
    end
  end
end
