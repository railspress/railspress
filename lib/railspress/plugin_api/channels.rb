module Railspress
  module PluginApi
    # Plugin API for accessing channels and overrides
    module Channels
      extend ActiveSupport::Concern

      # Get all available channels
      def self.all_channels
        Channel.all
      end

      # Get active channels only
      def self.active_channels
        Channel.active
      end

      # Find channel by slug
      def self.find_channel(slug)
        Channel.find_by(slug: slug)
      end

      # Get channel for specific device type
      def self.channel_for_device(device_type)
        case device_type.to_s
        when 'mobile', 'tablet'
          Channel.find_by(slug: 'mobile')
        when 'smart_tv', 'tv'
          Channel.find_by(slug: 'smarttv')
        when 'email'
          Channel.find_by(slug: 'newsletter')
        else
          Channel.find_by(slug: 'web')
        end
      end

      # Auto-detect channel from user agent
      def self.auto_detect_channel(user_agent)
        device_type = detect_device_type(user_agent)
        channel_for_device(device_type)
      end

      # Get content with channel overrides applied
      def self.content_with_overrides(content, channel_slug, resource_type, resource_id)
        channel = find_channel(channel_slug)
        return content unless channel

        if content.respond_to?(:apply_channel_settings)
          content.apply_channel_settings(content, user_agent)
        else
          # Apply basic channel overrides
          channel.apply_overrides_to_data(content, resource_type, resource_id)
        end
      end

      # Get channel-specific settings
      def self.channel_settings(channel_slug)
        channel = find_channel(channel_slug)
        return {} unless channel

        channel.settings.merge(
          'channel_name' => channel.name,
          'channel_slug' => channel.slug,
          'domain' => channel.domain,
          'locale' => channel.locale
        )
      end

      # Check if content is excluded from channel
      def self.is_excluded?(resource_type, resource_id, channel_slug)
        channel = find_channel(channel_slug)
        return false unless channel

        channel.excluded?(resource_type, resource_id)
      end

      # Get all overrides for a channel
      def self.channel_overrides(channel_slug)
        channel = find_channel(channel_slug)
        return [] unless channel

        channel.channel_overrides.includes(:resource)
      end

      # Get overrides for specific resource
      def self.resource_overrides(resource_type, resource_id, channel_slug)
        channel = find_channel(channel_slug)
        return [] unless channel

        channel.overrides_for(resource_type, resource_id)
      end

      # Create a new channel override
      def self.create_override(channel_slug, resource_type, resource_id, path, data, kind = 'override')
        channel = find_channel(channel_slug)
        return nil unless channel

        channel.channel_overrides.create!(
          resource_type: resource_type,
          resource_id: resource_id,
          path: path,
          data: data,
          kind: kind,
          enabled: true
        )
      end

      # Update channel settings
      def self.update_channel_settings(channel_slug, settings)
        channel = find_channel(channel_slug)
        return false unless channel

        channel.update!(settings: channel.settings.merge(settings))
      end

      private

      def self.detect_device_type(user_agent)
        return :email if user_agent.match?(/Outlook|Gmail|Apple Mail|Thunderbird|Mail|Yahoo Mail|Hotmail|AOL|Zimbra/i)
        return :mobile if user_agent.match?(/iPhone|Android|Mobile|BlackBerry|Windows Phone|Opera Mini|IEMobile|webOS|Palm|Nokia/i)
        return :tablet if user_agent.match?(/iPad|Android.*Tablet|Kindle|Silk|PlayBook|BB10|Tablet|Nexus 7|Nexus 10/i)
        return :smart_tv if user_agent.match?(/SmartTV|TV|Roku|AppleTV|AndroidTV|WebOS|Tizen|NetCast|BRAVIA|Samsung|LG/i)
        
        :desktop
      end
    end
  end
end

