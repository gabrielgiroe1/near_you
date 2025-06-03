Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn = Rails.application.credentials.sentry&.fetch(:dsn, nil)
  config.traces_sample_rate = 1.0
  config.enabled_environments = %w[production staging]
end
