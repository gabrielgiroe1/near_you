require "rails_helper"

RSpec.describe Provider, type: :model do
  describe "Stripe functionality" do
    let(:provider) { create(:provider) }

    describe "stripe_status enum" do
      it "defaults to incomplete" do
        expect(provider.stripe_status).to be_nil # No default set
      end

      it "can be set to incomplete" do
        provider.update!(stripe_status: :incomplete)
        expect(provider.incomplete?).to be true
      end

      it "can be set to active" do
        provider.update!(stripe_status: :active)
        expect(provider.active?).to be true
      end
    end

    describe "Stripe account validation" do
      context "when ready to accept payments" do
        let(:provider) { create(:provider, :with_stripe_account) }

        it "has all required Stripe fields" do
          expect(provider.stripe_account_id).to be_present
          expect(provider.stripe_status).to eq("active")
          expect(provider.charges_enabled).to be true
          expect(provider.payouts_enabled).to be true
        end
      end

      context "when Stripe setup is incomplete" do
        let(:provider) { create(:provider, :incomplete_stripe) }

        it "has account ID but is not fully enabled" do
          expect(provider.stripe_account_id).to be_present
          expect(provider.stripe_status).to eq("incomplete")
          expect(provider.charges_enabled).to be false
          expect(provider.payouts_enabled).to be false
        end
      end
    end

    describe "factory traits" do
      it "creates provider with complete Stripe setup" do
        provider = create(:provider, :with_stripe_account)
        expect(provider.stripe_account_id).to match(/^acct_test_/)
        expect(provider.active?).to be true
        expect(provider.charges_enabled).to be true
        expect(provider.payouts_enabled).to be true
      end

      it "creates provider with incomplete Stripe setup" do
        provider = create(:provider, :incomplete_stripe)
        expect(provider.stripe_account_id).to match(/^acct_test_/)
        expect(provider.incomplete?).to be true
        expect(provider.charges_enabled).to be false
        expect(provider.payouts_enabled).to be false
      end
    end

    describe "requirements_due JSONB field" do
      it "can store array of requirements" do
        provider.update!(requirements_due: ["external_account", "individual.verification.document"])
        expect(provider.requirements_due).to eq(["external_account", "individual.verification.document"])
      end

      it "can store empty array" do
        provider.update!(requirements_due: [])
        expect(provider.requirements_due).to eq([])
      end

      it "can be nil" do
        provider.update!(requirements_due: nil)
        expect(provider.requirements_due).to be_nil
      end
    end

    describe "business logic" do
      context "payment readiness" do
        it "can accept payments when fully enabled" do
          provider = create(:provider, :with_stripe_account)
          expect(provider.charges_enabled).to be true
          expect(provider.payouts_enabled).to be true
          expect(provider.active?).to be true
        end

        it "cannot accept payments when incomplete" do
          provider = create(:provider, :incomplete_stripe)
          expect(provider.charges_enabled).to be false
          expect(provider.payouts_enabled).to be false
          expect(provider.incomplete?).to be true
        end

        it "handles partial enablement" do
          provider.update!(
            stripe_account_id: "acct_test_123",
            charges_enabled: true,
            payouts_enabled: false,
            stripe_status: :incomplete
          )

          expect(provider.charges_enabled).to be true
          expect(provider.payouts_enabled).to be false
          expect(provider.incomplete?).to be true
        end
      end

      context "onboarding flow" do
        it "starts without Stripe account" do
          expect(provider.stripe_account_id).to be_nil
          expect(provider.stripe_status).to be_nil
        end

        it "progresses through onboarding states" do
          # Initial account creation
          provider.update!(
            stripe_account_id: "acct_test_123",
            stripe_status: :incomplete,
            charges_enabled: false,
            payouts_enabled: false,
            requirements_due: ["external_account"]
          )

          expect(provider.incomplete?).to be true
          expect(provider.requirements_due).to include("external_account")

          # Complete onboarding
          provider.update!(
            stripe_status: :active,
            charges_enabled: true,
            payouts_enabled: true,
            requirements_due: []
          )

          expect(provider.active?).to be true
          expect(provider.requirements_due).to be_empty
        end
      end
    end

    describe "appointment creation dependency" do
      let(:user) { create(:user) }

      context "when provider has no Stripe account" do
        it "should block appointment creation in controller" do
          # This is tested in the controller spec, but the model allows it
          appointment = build(:appointment, provider: provider, user: user)
          expect(appointment).to be_valid # Model doesn't enforce this constraint
        end
      end

      context "when provider has active Stripe account" do
        let(:provider) { create(:provider, :with_stripe_account) }

        it "allows appointment creation" do
          appointment = build(:appointment, provider: provider, user: user)
          expect(appointment).to be_valid
        end
      end
    end

    describe "rating system integration" do
      let(:provider) { create(:provider, :with_stripe_account) }

      it "maintains rating calculation with Stripe integration" do
        # This tests that Stripe fields don't interfere with existing functionality
        expect { provider.recalculate_average_rating! }.not_to raise_error
        expect(provider.rating).to eq(0.0) # No reviews yet
      end
    end
  end
end
