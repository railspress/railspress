module Railspress
  module AiAgentIntegration
    # AI Agent integration for channels and content optimization
    module Channels
      extend ActiveSupport::Concern

      # Generate channel-specific content using AI
      def self.generate_content_for_channel(content, channel_slug, ai_agent_name = nil)
        channel = Railspress::PluginApi::Channels.find_channel(channel_slug)
        return content unless channel

        # Get AI agent for content generation
        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'content_improver')
        return content unless agent&.active?

        # Get channel-specific settings
        settings = Railspress::PluginApi::Channels.channel_settings(channel_slug)
        
        # Create channel-aware prompt
        prompt = build_channel_prompt(content, channel, settings, agent)
        
        # Generate optimized content
        begin
          response = agent.generate_response(prompt)
          response.present? ? response : content
        rescue => e
          Rails.logger.error "AI content generation failed: #{e.message}"
          content
        end
      end

      # Optimize content for multiple channels
      def self.optimize_content_for_all_channels(content, ai_agent_name = nil)
        optimized_content = {}
        
        Channel.active.each do |channel|
          optimized_content[channel.slug] = generate_content_for_channel(content, channel.slug, ai_agent_name)
        end
        
        optimized_content
      end

      # Generate channel-specific meta descriptions
      def self.generate_meta_description(content, channel_slug, ai_agent_name = nil)
        channel = Railspress::PluginApi::Channels.find_channel(channel_slug)
        return nil unless channel

        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'seo_analyzer')
        return nil unless agent&.active?

        settings = Railspress::PluginApi::Channels.channel_settings(channel_slug)
        
        prompt = "Generate a compelling meta description for #{channel.name} channel (max 160 characters):\n\nContent: #{content}\n\nChannel settings: #{settings.to_json}\n\nMeta description:"
        
        begin
          agent.generate_response(prompt)
        rescue => e
          Rails.logger.error "AI meta description generation failed: #{e.message}"
          nil
        end
      end

      # Generate channel-specific titles
      def self.generate_title(content, channel_slug, ai_agent_name = nil)
        channel = Railspress::PluginApi::Channels.find_channel(channel_slug)
        return nil unless channel

        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'post_writer')
        return nil unless agent&.active?

        settings = Railspress::PluginApi::Channels.channel_settings(channel_slug)
        
        prompt = "Generate an engaging title for #{channel.name} channel:\n\nContent: #{content}\n\nChannel settings: #{settings.to_json}\n\nTitle:"
        
        begin
          agent.generate_response(prompt)
        rescue => e
          Rails.logger.error "AI title generation failed: #{e.message}"
          nil
        end
      end

      # Analyze content performance across channels
      def self.analyze_channel_performance(resource_type, resource_id, ai_agent_name = nil)
        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'comments_analyzer')
        return {} unless agent&.active?

        analysis = {}
        
        Channel.active.each do |channel|
          overrides = Railspress::PluginApi::Channels.resource_overrides(resource_type, resource_id, channel.slug)
          settings = Railspress::PluginApi::Channels.channel_settings(channel.slug)
          
          prompt = "Analyze content performance for #{channel.name} channel:\n\nResource: #{resource_type} ##{resource_id}\nOverrides: #{overrides.count}\nSettings: #{settings.to_json}\n\nAnalysis:"
          
          begin
            analysis[channel.slug] = agent.generate_response(prompt)
          rescue => e
            Rails.logger.error "AI channel analysis failed for #{channel.slug}: #{e.message}"
            analysis[channel.slug] = "Analysis failed"
          end
        end
        
        analysis
      end

      # Generate channel-specific recommendations
      def self.generate_recommendations(resource_type, resource_id, ai_agent_name = nil)
        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'seo_analyzer')
        return {} unless agent&.active?

        recommendations = {}
        
        Channel.active.each do |channel|
          overrides = Railspress::PluginApi::Channels.resource_overrides(resource_type, resource_id, channel.slug)
          settings = Railspress::PluginApi::Channels.channel_settings(channel.slug)
          
          prompt = "Generate optimization recommendations for #{channel.name} channel:\n\nResource: #{resource_type} ##{resource_id}\nCurrent overrides: #{overrides.count}\nChannel settings: #{settings.to_json}\n\nRecommendations:"
          
          begin
            recommendations[channel.slug] = agent.generate_response(prompt)
          rescue => e
            Rails.logger.error "AI recommendations failed for #{channel.slug}: #{e.message}"
            recommendations[channel.slug] = "Recommendations unavailable"
          end
        end
        
        recommendations
      end

      # Auto-create channel overrides based on AI analysis
      def self.auto_create_overrides(resource_type, resource_id, ai_agent_name = nil)
        agent = ai_agent_name ? AiAgent.find_by(name: ai_agent_name) : AiAgent.find_by(slug: 'content_improver')
        return [] unless agent&.active?

        created_overrides = []
        
        Channel.active.each do |channel|
          settings = Railspress::PluginApi::Channels.channel_settings(channel.slug)
          
          prompt = "Suggest channel-specific overrides for #{channel.name}:\n\nResource: #{resource_type} ##{resource_id}\nChannel settings: #{settings.to_json}\n\nSuggest specific overrides in JSON format: {\"path\": \"setting.key\", \"data\": \"value\", \"kind\": \"override\"}"
          
          begin
            response = agent.generate_response(prompt)
            overrides_data = JSON.parse(response) rescue []
            
            overrides_data.each do |override_data|
              override = Railspress::PluginApi::Channels.create_override(
                channel.slug,
                resource_type,
                resource_id,
                override_data['path'],
                override_data['data'],
                override_data['kind'] || 'override'
              )
              created_overrides << override if override
            end
          rescue => e
            Rails.logger.error "AI override creation failed for #{channel.slug}: #{e.message}"
          end
        end
        
        created_overrides
      end

      private

      def self.build_channel_prompt(content, channel, settings, agent)
        base_prompt = agent.prompt || "Optimize content for the specified channel."
        
        "#{base_prompt}\n\n" \
        "Channel: #{channel.name} (#{channel.slug})\n" \
        "Target Audience: #{channel.metadata['target_audience']}\n" \
        "Device Type: #{channel.metadata['device_type']}\n" \
        "Screen Resolution: #{channel.metadata['screen_resolution']}\n" \
        "Input Method: #{channel.metadata['input_method']}\n" \
        "Channel Settings: #{settings.to_json}\n\n" \
        "Original Content:\n#{content}\n\n" \
        "Optimized Content:"
      end
    end
  end
end

