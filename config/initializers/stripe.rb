Rails.configuration.stripe = {
  publishable_key: Rails.application.credentials.dig(:stripe, :STRIPE_PUBLIC_KEY) || ENV["STRIPE_PUBLIC_KEY"],
  secret_key: Rails.application.credentials.dig(:stripe, :STRIPE_SECRET_KEY) || ENV["STRIPE_SECRET_KEY"],
  platform_fee_rate: ENV["STRIPE_PLATFORM_FEE_RATE"]&.to_f || 0.1 # Default 10% platform fee
}
Stripe.api_key = Rails.configuration.stripe[:secret_key]
