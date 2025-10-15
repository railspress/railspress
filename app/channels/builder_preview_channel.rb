class BuilderPreviewChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to a specific builder theme's preview updates
    stream_from "builder_preview_#{params[:theme_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    # Handle incoming data from the client
    case data['type']
    when 'preview_ready'
      # Client is ready to receive updates
      transmit({ type: 'ack', message: 'Preview ready' })
    when 'request_update'
      # Client is requesting a fresh update
      broadcast_update(data['theme_id'])
    end
  end

  private

  def broadcast_update(theme_id)
    # Send current theme state to the preview
    builder_theme = BuilderTheme.find(theme_id)
    
    ActionCable.server.broadcast(
      "builder_preview_#{theme_id}",
      {
        type: 'theme_update',
        theme_id: theme_id,
        sections: builder_theme.sections_data,
        settings: builder_theme.settings_data,
        timestamp: Time.current.to_i
      }
    )
  end
end

