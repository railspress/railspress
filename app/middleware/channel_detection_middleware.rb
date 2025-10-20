module Railspress
  class ChannelDetectionMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      
      # Only apply channel detection to API requests
      if api_request?(request)
        user_agent = request.user_agent || ''
        device_type = detect_device_type(user_agent)
        channel = channel_for_device(device_type)
        
        # Add channel context to request parameters
        if channel
          request.params[:auto_channel] = channel.slug
          request.params[:device_type] = device_type.to_s
          request.params[:channel_context] = channel.slug
        end
      end
      
      @app.call(env)
    end

    private

    def api_request?(request)
      request.path.start_with?('/api/')
    end

    def detect_device_type(user_agent)
      return :email if email_client?(user_agent)
      
      # Mobile detection
      if user_agent.match?(/iPhone|Android|Mobile|BlackBerry|Windows Phone|Opera Mini|IEMobile|webOS|Palm|Nokia/i)
        return :mobile
      end
      
      # Tablet detection
      if user_agent.match?(/iPad|Android.*Tablet|Kindle|Silk|PlayBook|BB10|Tablet|Nexus 7|Nexus 10/i)
        return :tablet
      end
      
      # Smart TV detection
      if user_agent.match?(/SmartTV|TV|Roku|AppleTV|AndroidTV|WebOS|Tizen|NetCast|BRAVIA|Samsung|LG/i)
        return :smart_tv
      end
      
      # Default to desktop
      :desktop
    end

    def email_client?(user_agent)
      user_agent.match?(/Outlook|Gmail|Apple Mail|Thunderbird|Mail|Yahoo Mail|Hotmail|AOL|Zimbra/i)
    end

    def channel_for_device(device_type)
      case device_type
      when :mobile, :tablet
        Channel.find_by(slug: 'mobile')
      when :smart_tv
        Channel.find_by(slug: 'smarttv')
      when :email
        Channel.find_by(slug: 'newsletter')
      else
        Channel.find_by(slug: 'web')
      end
    end
  end
end

