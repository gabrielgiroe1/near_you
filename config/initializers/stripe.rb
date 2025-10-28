# Determine webhook secret based on environment
webhook_secret = if Rails.env.production?
  Rails.application.credentials.dig(:stripe, :STRIPE_WEBHOOK_SECRET_PRODUCTION) || ENV["STRIPE_WEBHOOK_SECRET_PRODUCTION"]
elsif Rails.env.staging?
  Rails.application.credentials.dig(:stripe, :STRIPE_WEBHOOK_SECRET_STAGING) || ENV["STRIPE_WEBHOOK_SECRET_STAGING"]
else # development, test
  Rails.application.credentials.dig(:stripe, :STRIPE_WEBHOOK_SECRET_DEVELOPMENT) || ENV["STRIPE_WEBHOOK_SECRET_DEVELOPMENT"]
end

Rails.configuration.stripe = {
  publishable_key: Rails.application.credentials.dig(:stripe, :STRIPE_PUBLIC_KEY) || ENV["STRIPE_PUBLIC_KEY"],
  secret_key: Rails.application.credentials.dig(:stripe, :STRIPE_SECRET_KEY) || ENV["STRIPE_SECRET_KEY"],
  webhook_secret: webhook_secret,
  platform_fee_rate: ENV["STRIPE_PLATFORM_FEE_RATE"]&.to_f || 0.1 # Default 10% platform fee
}
Stripe.api_key = Rails.configuration.stripe[:secret_key]
