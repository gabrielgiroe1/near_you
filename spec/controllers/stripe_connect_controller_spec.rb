require "rails_helper"

RSpec.describe StripeConnectController, type: :request do
  include StripeHelpers
  let(:user) { create(:user) }
  let(:provider) { create(:provider, user: user) }

  before do
    sign_in user
    setup_stripe_mocks
  end

  describe "POST #create" do
    context "when provider doesn't have a Stripe account" do
      it "creates a new Stripe account and redirects to onboarding" do
        expect(Stripe::Account).to receive(:create).with(
          hash_including(
            type: "express",
            email: user.email,
            country: "RO",
            business_type: "individual",
            capabilities: {
              card_payments: { requested: true },
              transfers: { requested: true }
            }
          )
        ).and_return(
          OpenStruct.new(
            id: "acct_test_new_123",
            charges_enabled: false,
            payouts_enabled: false,
            requirements: OpenStruct.new(currently_due: ["external_account"])
          )
        )

        expect(Stripe::AccountLink).to receive(:create).with(
          hash_including(
            account: "acct_test_new_123",
            type: "account_onboarding",
            collect: "eventually_due"
          )
        )

        post "/stripe_connect", params: { provider_id: provider.id }

        expect(provider.reload.stripe_account_id).to eq("acct_test_new_123")
        expect(provider.stripe_status).to eq("incomplete")
        expect(provider.charges_enabled).to be false
        expect(provider.payouts_enabled).to be false
        expect(response).to redirect_to("https://connect.stripe.com/setup/onboarding/123")
      end
    end

    context "when provider already has a Stripe account" do
      let(:provider_with_stripe) { create(:provider, :incomplete_stripe, user: user) }

      it "uses existing account and redirects to onboarding" do
        expect(Stripe::Account).not_to receive(:create)

        expect(Stripe::AccountLink).to receive(:create).with(
          hash_including(
            account: provider_with_stripe.stripe_account_id,
            type: "account_onboarding"
          )
        )

        post "/stripe_connect", params: { provider_id: provider_with_stripe.id }
        expect(response).to redirect_to("https://connect.stripe.com/setup/onboarding/123")
      end
    end

    context "when using development environment" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BASE_URL").and_return(nil)
        host! "www.example.com"
      end

      it "uses request.base_url for redirect URLs" do
        expect(Stripe::AccountLink).to receive(:create).with(
          hash_including(
            refresh_url: "http://www.example.com/stripe/refresh",
            return_url: "http://www.example.com/providers/#{provider.id}"
          )
        )

        post "/stripe_connect", params: { provider_id: provider.id }
      end
    end

    context "when BASE_URL environment variable is set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("BASE_URL").and_return("https://myapp.com")
      end

      it "uses BASE_URL for redirect URLs" do
        expect(Stripe::AccountLink).to receive(:create).with(
          hash_including(
            refresh_url: "https://myapp.com/stripe/refresh",
            return_url: "https://myapp.com/providers/#{provider.id}"
          )
        )

        post "/stripe_connect", params: { provider_id: provider.id }
      end
    end

    context "when Stripe returns an error" do
      before do
        allow(Stripe::Account).to receive(:create).and_raise(
          Stripe::InvalidRequestError.new("Account creation failed", "account_error", http_status: 400)
        )
      end

      it "handles the error and redirects with alert" do
        post "/stripe_connect", params: { provider_id: provider.id }

        expect(response).to redirect_to(providers_path)
        expect(flash[:alert]).to include("Account creation failed")
      end

      it "logs the error details" do
        expect(Rails.logger).to receive(:error).with(/Stripe Error: 400 -  - Account creation failed/)

        post "/stripe_connect", params: { provider_id: provider.id }
      end
    end

    context "when provider is not found" do
      it "returns 404 not found" do
        post "/stripe_connect", params: { provider_id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        post "/stripe_connect", params: { provider_id: provider.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user tries to access another user's provider" do
      let(:other_user) { create(:user) }
      let(:other_provider) { create(:provider, user: other_user) }

      it "allows access (since set_provider finds by ID)" do
        # Note: This test reveals a potential security issue
        # The controller should probably check if current_user owns the provider
        expect {
          post "/stripe_connect", params: { provider_id: other_provider.id }
        }.not_to raise_error
      end
    end
  end

  describe "logging" do
    it "logs successful account creation" do
      # Create a provider without Stripe account
      provider_without_stripe = create(:provider, user: user, stripe_account_id: nil)

      allow(Rails.logger).to receive(:info).and_call_original

      # Mock Stripe account creation to return a specific response
      expect(Stripe::Account).to receive(:create).and_return(
        OpenStruct.new(
          id: "acct_test_logging_123",
          charges_enabled: false,
          payouts_enabled: false,
          requirements: OpenStruct.new(currently_due: [])
        )
      )

      expect(Rails.logger).to receive(:info).with(/Stripe account create for Provider ID \d+/)

      post "/stripe_connect", params: { provider_id: provider_without_stripe.id }
    end
  end
end
