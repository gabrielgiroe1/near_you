require "rails_helper"

RSpec.describe "Simple Appointment Test", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, :with_stripe_account, hourly_rate: 100) }
  let(:availability) { create(:availability, provider: provider, day_of_week: "Monday", start_time: "09:00", end_time: "17:00") }

  before do
    sign_in user
    setup_stripe_mocks
    availability
  end

  describe "Basic appointment creation" do
    it "can create an appointment with valid params" do
      appointment_params = {
        appointment: {
          day_of_week: "Monday",
          start_time: "10:00",
          appointment_date: Date.tomorrow.strftime("%Y-%m-%d")
        }
      }

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
  end
end
