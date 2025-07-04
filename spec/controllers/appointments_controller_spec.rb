require "rails_helper"

RSpec.describe AppointmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, :with_stripe_account) }
  let(:availability) { create(:availability, provider: provider, day_of_week: "Monday", start_time: "09:00", end_time: "17:00") }

  before do
    sign_in user
    setup_stripe_mocks
  end

  describe "GET #index" do
    let!(:upcoming_appointment) { create(:appointment, :confirmed, user: user, start_time: 1.day.from_now) }
    let!(:past_appointment) { create(:appointment, :confirmed, user: user, start_time: 1.day.ago, end_time: 1.day.ago + 1.hour) }

    it "loads upcoming and past appointments for customer" do
      get :index
      expect(assigns(:upcoming_appointments)).to include(upcoming_appointment)
      expect(assigns(:previous_appointments)).to include(past_appointment)
    end

    context "when user is a provider" do
      let(:provider_user) { create(:user, role: :provider) }
      let(:provider_account) { create(:provider, :with_stripe_account, user: provider_user) }
      let!(:provider_appointment) { create(:appointment, :confirmed, provider: provider_account, start_time: 1.day.from_now) }

      before { sign_in provider_user }

      it "loads appointments for the provider" do
        get :index
        expect(assigns(:upcoming_appointments)).to include(provider_appointment)
      end
    end
  end

  describe "POST #create" do
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

    before { availability }

    context "with valid parameters and Stripe account setup" do
      it "creates appointment and redirects to Stripe checkout" do
        expect {
          post :create, params: appointment_params
        }.to change(Appointment, :count).by(1)

        appointment = Appointment.last
        expect(appointment.user).to eq(user)
        expect(appointment.provider).to eq(provider)
        expect(appointment.status).to eq("pending")
        expect(appointment.stripe_session_id).to eq("cs_test_123")
        expect(appointment.stripe_payment_intent_id).to eq("pi_test_123")

        expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_test_123")
      end

      it "calls Stripe with correct parameters including application fee" do
        expect(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            payment_intent_data: hash_including(
              application_fee_amount: (provider.hourly_rate.to_i * 100 * 0.1).to_i,
              on_behalf_of: provider.stripe_account_id,
              transfer_data: { destination: provider.stripe_account_id },
              metadata: hash_including(
                provider_id: provider.id,
                user_id: user.id
              )
            )
          )
        )

        post :create, params: appointment_params
      end
    end

    context "when provider has no Stripe account" do
      let(:provider_without_stripe) { create(:provider) }

      it "redirects with alert when provider has no Stripe account" do
        post :create, params: appointment_params.merge(provider_id: provider_without_stripe.id)
        expect(response).to redirect_to(provider_path(provider_without_stripe))
        expect(flash[:alert]).to include("hasn't set up payments yet")
      end
    end

    context "when time slot is not available" do
      it "redirects with alert for unavailable time slot" do
        post :create, params: appointment_params.merge(
          appointment: appointment_params[:appointment].merge(start_time: "08:00")
        )
        expect(response).to redirect_to(provider_path(provider))
        expect(flash[:alert]).to include("not available")
      end
    end

    context "when appointment overlaps with existing booking" do
      let(:next_monday) { Date.tomorrow.beginning_of_week(:monday) + 1.week }
      let!(:existing_appointment) do
        create(:appointment, :confirmed,
               provider: provider,
               start_time: next_monday.in_time_zone.change(hour: 10, min: 0),
               end_time: next_monday.in_time_zone.change(hour: 11, min: 0))
      end
      let(:overlapping_params) do
        {
          provider_id: provider.id,
          appointment: {
            day_of_week: "Monday",
            start_time: "10:00",
            appointment_date: next_monday.strftime("%Y-%m-%d")
          }
        }
      end

      it "redirects with validation error" do
        post :create, params: overlapping_params
        expect(response).to redirect_to(provider_path(provider))
        expect(flash[:alert]).to include("Could not create appointment")
      end
    end
  end

  describe "GET #success" do
    let(:appointment) { create(:appointment, :with_stripe_session, user: user) }

    it "confirms the appointment" do
      expect {
        get :success, params: { id: appointment.id }
      }.to change { appointment.reload.status }.from("pending").to("confirmed")

      expect(response).to redirect_to(appointments_path)
      expect(flash[:notice]).to include("confirmed successfully")
    end
  end

  describe "GET #cancel" do
    context "with confirmed appointment that can be refunded" do
      let(:appointment) { create(:appointment, :confirmed, user: user) }

      it "processes refund and cancels appointment" do
        expect {
          get :cancel, params: { id: appointment.id }
        }.to change { appointment.reload.status }.from("confirmed").to("cancelled")

        expect(appointment.reload.refunded_at).to be_present
        expect(appointment.stripe_refund_id).to eq("re_test_123")
        expect(response).to redirect_to(appointments_path)
        expect(flash[:notice]).to include("refund processed")
      end

      it "calls Stripe refund with reverse transfer" do
        expect(Stripe::Refund).to receive(:create).with(
          hash_including(
            payment_intent: appointment.stripe_payment_intent_id,
            reverse_transfer: true
          )
        )

        get :cancel, params: { id: appointment.id }
      end
    end

    context "with already refunded appointment" do
      let(:appointment) { create(:appointment, :refunded, user: user) }

      it "cancels without processing refund again" do
        expect(Stripe::Refund).not_to receive(:create)

        get :cancel, params: { id: appointment.id }
        expect(response).to redirect_to(appointments_path)
        expect(flash[:notice]).to include("cancelled")
      end
    end

    context "when Stripe refund fails" do
      let(:appointment) { create(:appointment, :confirmed, user: user) }

      before do
        allow(Stripe::Refund).to receive(:create).and_raise(
          Stripe::StripeError.new("Refund failed")
        )
      end

      it "cancels appointment but shows refund failure alert" do
        expect {
          get :cancel, params: { id: appointment.id }
        }.to change { appointment.reload.status }.from("confirmed").to("cancelled")

        expect(appointment.reload.refunded_at).to be_nil
        expect(response).to redirect_to(appointments_path)
        expect(flash[:alert]).to include("refund failed")
      end
    end

    context "with pending appointment" do
      let(:appointment) { create(:appointment, user: user) }

      it "cancels without refund processing" do
        expect(Stripe::Refund).not_to receive(:create)

        get :cancel, params: { id: appointment.id }
        expect(appointment.reload.status).to eq("cancelled")
        expect(response).to redirect_to(appointments_path)
        expect(flash[:notice]).to include("cancelled")
      end
    end
  end
end
