class StripeConnectController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider, only: [:create]

  def create
    # Create a new Stripe Connect account if one doesn't exist
    create_stripe_account unless @provider.stripe_account_id

    # Refresh account status before creating onboarding link
    refresh_account_status

    redirect_url = ENV["BASE_URL"] || request.base_url
    # Generate the Stripe onboarding link
    account_link = Stripe::AccountLink.create({
      account: @provider.stripe_account_id,
      refresh_url: "#{redirect_url}/stripe_connect/refresh?provider_id=#{@provider.id}",
      return_url: "#{redirect_url}/providers/#{@provider.id}",
      type: "account_onboarding",
      collect: "currently_due"
    })

    # Redirect to the Stripe onboarding page
    redirect_to account_link.url, status: :see_other, allow_other_host: true
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error("Stripe Error: #{e.http_status} - #{e.code} - #{e.message}")
    flash[:alert] = "There was an error with Stripe: #{e.message}"
    redirect_to provider_path(@provider)
  end

  def refresh
    @provider = Provider.find(params[:provider_id])

    # Verify the user owns this provider
    unless current_user == @provider.user
      flash[:alert] = "Unauthorized access"
      redirect_to root_path
      return
    end

    redirect_url = ENV["BASE_URL"] || request.base_url

    # Create a new account link for the provider to continue onboarding
    account_link = Stripe::AccountLink.create({
      account: @provider.stripe_account_id,
      refresh_url: "#{redirect_url}/stripe_connect/refresh?provider_id=#{@provider.id}",
      return_url: "#{redirect_url}/providers/#{@provider.id}",
      type: "account_onboarding",
      collect: "currently_due"
    })

    redirect_to account_link.url, status: :see_other, allow_other_host: true
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error("Stripe Refresh Error: #{e.http_status} - #{e.code} - #{e.message}")
    flash[:alert] = "There was an error refreshing your Stripe setup: #{e.message}"
    redirect_to provider_path(@provider)
  end

  private

  def set_provider
    @provider = Provider.find(params[:provider_id])

    # Verify the user owns this provider
    unless current_user == @provider.user
      flash[:alert] = "Unauthorized access"
      redirect_to root_path
    end
  end

  def create_stripe_account
    account = Stripe::Account.create({
      type: "express",
      email: @provider.user.email,
      country: "RO",
      business_type: "individual",
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true }
      }
    })

    @provider.update!(
      stripe_account_id: account.id,
      stripe_status: "incomplete",
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      requirements_due: account.requirements.currently_due
    )
    Rails.logger.info("Stripe account created for Provider ID #{@provider.id}: #{account.id}")
  end

  def refresh_account_status
    return unless @provider.stripe_account_id

    account = Stripe::Account.retrieve(@provider.stripe_account_id)

    @provider.update!(
      stripe_status: (account.charges_enabled && account.payouts_enabled) ? "active" : "incomplete",
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      requirements_due: account.requirements.currently_due
    )

    Rails.logger.info("Refreshed account status for Provider #{@provider.id}")
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error("Failed to refresh account status: #{e.message}")
  end
end
