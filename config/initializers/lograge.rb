# Lograge configuration for better structured logging

Rails.application.configure do
  config.lograge.enabled = true
  
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time,
      user_id: event.payload[:user_id],
      params: event.payload[:params].except('controller', 'action')
    }
  end
  
  config.lograge.formatter = Lograge::Formatters::Json.new
end





