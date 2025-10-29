# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  # Staging overrides

  # Set host for mailer URLs
  config.action_mailer.default_url_options = { host: "staging.localhub.solutions", protocol: "https" }

  # Raise delivery errors so we can see them in logs
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
end
