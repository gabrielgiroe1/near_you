require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "Stripe-related functionality" do
    let(:appointment) { create(:appointment) }

    describe "#refunded?" do
      it "returns false when refunded_at is nil" do
        expect(appointment.refunded?).to be false
      end

      it "returns true when refunded_at is present" do
        appointment.update!(refunded_at: 1.hour.ago)
        expect(appointment.refunded?).to be true
      end
    end

    describe "#refundable?" do
      context "when appointment is confirmed and not refunded" do
        let(:appointment) { create(:appointment, :confirmed) }

        it "returns true" do
          expect(appointment.refundable?).to be true
        end
      end

      context "when appointment is confirmed but already refunded" do
        let(:appointment) { create(:appointment, :refunded) }

        it "returns false" do
          expect(appointment.refundable?).to be false
        end
      end

      context "when appointment is not confirmed" do
        let(:appointment) { create(:appointment, status: :pending) }

        it "returns false" do
          expect(appointment.refundable?).to be false
        end
      end

      context "when appointment is cancelled" do
        let(:appointment) { create(:appointment, status: :cancelled) }

        it "returns false" do
          expect(appointment.refundable?).to be false
        end
      end
    end

    describe "Stripe fields validation" do
      it "allows nil Stripe fields" do
        appointment.stripe_session_id = nil
        appointment.stripe_payment_intent_id = nil
        appointment.stripe_refund_id = nil
        expect(appointment).to be_valid
      end

      it "allows valid Stripe session ID format" do
        appointment.stripe_session_id = "cs_test_123456789"
        expect(appointment).to be_valid
      end

      it "allows valid payment intent ID format" do
        appointment.stripe_payment_intent_id = "pi_test_123456789"
        expect(appointment).to be_valid
      end

      it "allows valid refund ID format" do
        appointment.stripe_refund_id = "re_test_123456789"
        expect(appointment).to be_valid
      end
    end

    describe "database constraints" do
      it "has stripe_payment_intent_id index for fast lookups" do
        expect(ActiveRecord::Base.connection.index_exists?(:appointments, :stripe_payment_intent_id)).to be true
      end
    end

    describe "factory traits" do
      it "creates appointment with Stripe session" do
        appointment = create(:appointment, :with_stripe_session)
        expect(appointment.stripe_session_id).to be_present
        expect(appointment.stripe_payment_intent_id).to be_present
      end

      it "creates confirmed appointment with Stripe data" do
        appointment = create(:appointment, :confirmed)
        expect(appointment.status).to eq("confirmed")
        expect(appointment.stripe_session_id).to be_present
        expect(appointment.stripe_payment_intent_id).to be_present
      end

      it "creates refunded appointment with all data" do
        appointment = create(:appointment, :refunded)
        expect(appointment.status).to eq("cancelled")
        expect(appointment.stripe_refund_id).to be_present
        expect(appointment.refunded_at).to be_present
        expect(appointment.refunded?).to be true
      end
    end
  end

  describe "edge cases and business logic" do
    context "appointment lifecycle with Stripe" do
      let(:appointment) { create(:appointment, :with_stripe_session) }

      it "transitions from pending to confirmed" do
        expect {
          appointment.update!(status: :confirmed)
        }.to change(appointment, :status).from("pending").to("confirmed")

        expect(appointment.refundable?).to be true
      end

      it "can be refunded after confirmation" do
        appointment.update!(status: :confirmed)

        expect {
          appointment.update!(
            status: :cancelled,
            refunded_at: Time.current,
            stripe_refund_id: "re_test_123"
          )
        }.to change(appointment, :refundable?).from(true).to(false)
      end
    end

    context "overlapping appointments validation" do
      let(:provider) { create(:provider) }
      let(:existing_appointment) do
        create(:appointment, :confirmed,
          provider: provider,
          start_time: 1.day.from_now.change(hour: 10),
          end_time: 1.day.from_now.change(hour: 11))
      end

      it "prevents overlapping bookings" do
        existing_appointment # Create the existing appointment

        overlapping_appointment = build(:appointment,
          provider: provider,
          start_time: 1.day.from_now.change(hour: 10, min: 30),
          end_time: 1.day.from_now.change(hour: 11, min: 30))

        expect(overlapping_appointment).not_to be_valid
        expect(overlapping_appointment.errors[:start_time]).to include("is already booked")
      end

      it "allows non-overlapping appointments" do
        existing_appointment # Create the existing appointment

        non_overlapping_appointment = build(:appointment,
          provider: provider,
          start_time: 1.day.from_now.change(hour: 12),
          end_time: 1.day.from_now.change(hour: 13))

        expect(non_overlapping_appointment).to be_valid
      end

      it "ignores cancelled appointments when checking overlaps" do
        cancelled_appointment = create(:appointment,
          provider: provider,
          status: :cancelled,
          start_time: 1.day.from_now.change(hour: 10),
          end_time: 1.day.from_now.change(hour: 11))

        new_appointment = build(:appointment,
          provider: provider,
          start_time: 1.day.from_now.change(hour: 10, min: 30),
          end_time: 1.day.from_now.change(hour: 11, min: 30))

        expect(new_appointment).to be_valid
      end
    end
  end
end
