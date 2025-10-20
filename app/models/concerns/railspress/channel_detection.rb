module Railspress
  module ChannelDetection
    extend ActiveSupport::Concern

    # Device detection patterns based on user agent strings
    DEVICE_PATTERNS = {
      mobile: [
        /iPhone/i, /Android/i, /Mobile/i, /BlackBerry/i, /Windows Phone/i,
        /Opera Mini/i, /IEMobile/i, /webOS/i, /Palm/i, /Nokia/i
      ],
      tablet: [
        /iPad/i, /Android.*Tablet/i, /Kindle/i, /Silk/i, /PlayBook/i,
        /BB10/i, /Tablet/i, /Nexus 7/i, /Nexus 10/i
      ],
      smart_tv: [
        /SmartTV/i, /TV/i, /Roku/i, /AppleTV/i, /AndroidTV/i, /WebOS/i,
        /Tizen/i, /NetCast/i, /BRAVIA/i, /Samsung/i, /LG/i
      ],
      desktop: [
        /Windows/i, /Macintosh/i, /Linux/i, /X11/i, /Win64/i, /WOW64/i
      ]
    }.freeze

    # Email client detection patterns
    EMAIL_CLIENT_PATTERNS = [
      /Outlook/i, /Gmail/i, /Apple Mail/i, /Thunderbird/i, /Mail/i,
      /Yahoo Mail/i, /Hotmail/i, /AOL/i, /Zimbra/i
    ].freeze

    class_methods do
      # Detect device type from user agent string
      def detect_device_type(user_agent)
        return :email if email_client?(user_agent)
        
        DEVICE_PATTERNS.each do |device_type, patterns|
          patterns.each do |pattern|
            return device_type if user_agent.match?(pattern)
          end
        end
        
        :desktop # Default fallback
      end

      # Check if user agent is an email client
      def email_client?(user_agent)
        EMAIL_CLIENT_PATTERNS.any? { |pattern| user_agent.match?(pattern) }
      end

      # Get appropriate channel for device type
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

      # Auto-detect and return appropriate channel
      def auto_detect_channel(user_agent)
        device_type = detect_device_type(user_agent)
        channel_for_device(device_type)
      end

      # Get channel-specific settings for rendering
      def channel_settings_for_device(device_type)
        channel = channel_for_device(device_type)
        return {} unless channel
        
        channel.settings.merge(
          'device_type' => device_type,
          'channel_slug' => channel.slug,
          'channel_name' => channel.name
        )
      end
    end

    # Instance methods for applying channel settings
    def apply_channel_settings(data, user_agent = nil)
      return data unless user_agent
      
      device_type = self.class.detect_device_type(user_agent)
      channel = self.class.channel_for_device(device_type)
      
      return data unless channel
      
      # Apply channel-specific overrides
      if respond_to?(:apply_overrides_to_data)
        overridden_data, provenance = apply_overrides_to_data(
          data, 
          self.class.name, 
          id, 
          true
        )
        
        # Add channel context
        overridden_data.merge!(
          'channel_context' => channel.slug,
          'device_type' => device_type,
          'provenance' => provenance
        )
      else
        data.merge!(
          'channel_context' => channel.slug,
          'device_type' => device_type
        )
      end
      
      overridden_data || data
    end

    # Get optimized content for specific device
    def content_for_device(device_type)
      channel = self.class.channel_for_device(device_type)
      return content unless channel
      
      # Apply device-specific optimizations
      optimized_content = content.dup
      
      case device_type
      when :mobile, :tablet
        # Mobile optimizations
        optimized_content = optimize_for_mobile(optimized_content)
      when :smart_tv
        # TV optimizations
        optimized_content = optimize_for_tv(optimized_content)
      when :email
        # Email optimizations
        optimized_content = optimize_for_email(optimized_content)
      end
      
      optimized_content
    end

    private

    def optimize_for_mobile(content)
      # Remove heavy elements, optimize images, etc.
      content.gsub(/<iframe[^>]*>/i, '') # Remove iframes
             .gsub(/width="\d+"/i, '') # Remove width attributes
             .gsub(/height="\d+"/i, '') # Remove height attributes
    end

    def optimize_for_tv(content)
      # Optimize for large screens and remote navigation
      content.gsub(/<img([^>]*)>/i, '<img\1 style="max-width: 100%; height: auto;">')
             .gsub(/font-size:\s*\d+px/i, 'font-size: 24px') # Larger text
    end

    def optimize_for_email(content)
      # Email client compatibility
      content.gsub(/style="[^"]*"/i, '') # Remove inline styles
             .gsub(/<div([^>]*)>/i, '<table><tr><td\1>') # Convert divs to tables
             .gsub(/<\/div>/i, '</td></tr></table>')
    end
  end
end
