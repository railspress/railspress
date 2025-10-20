if Rails.env.development?
  # Reduce ActionCable log verbosity in development to avoid noise/perf impact
  ActionCable.server.config.logger = ActiveSupport::Logger.new($stdout, level: :warn)
  ActionCable.server.config.log_tags = []
end


