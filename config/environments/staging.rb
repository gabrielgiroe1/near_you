# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  # Staging overrides

  # Set host for mailer URLs
  config.action_mailer.default_url_options = { host: "staging.localhub.solutions", protocol: "https" }

  # Configure SMTP settings for Gmail
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "gmail.com",
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Raise delivery errors so we can see them in logs
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
end
