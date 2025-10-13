# frozen_string_literal: true

module Railspress
  # Plugin Blocks System - Similar to Shopify App Blocks
  # Allows plugins to inject custom UI blocks into admin pages (posts, pages, etc.)
  class PluginBlocks
    @blocks = {}

    class << self
      # Register a new block
      #
      # @param key [Symbol] Unique identifier for the block
      # @param options [Hash] Block configuration
      # @option options [String] :label Display name for the block
      # @option options [String] :description Block description
      # @option options [String] :icon SVG icon or icon class
      # @option options [Array<Symbol>] :locations Where the block can appear (:post, :page, :product, etc.)
      # @option options [String] :position Block position (:sidebar, :main, :footer, :header)
      # @option options [Integer] :order Display order (lower numbers appear first)
      # @option options [String] :partial Path to the partial to render
      # @option options [Proc] :render_proc Alternative to partial - a proc that renders the block
      # @option options [Hash] :settings Block settings schema
      # @option options [Proc] :can_render Optional proc to determine if block should render
      #
      # @example
      #   Railspress::PluginBlocks.register(:seo_analyzer, {
      #     label: 'SEO Analyzer',
      #     description: 'AI-powered SEO analysis and suggestions',
      #     icon: '<svg>...</svg>',
      #     locations: [:post, :page],
      #     position: :sidebar,
      #     order: 10,
      #     partial: 'plugins/ai_seo/analyzer_block',
      #     can_render: ->(context) { context[:user].admin? }
      #   })
      def register(key, options = {})
        validate_block_options!(key, options)
        @blocks[key] = {
          key: key,
          label: options[:label] || key.to_s.titleize,
          description: options[:description] || '',
          icon: options[:icon],
          locations: Array(options[:locations] || [:post, :page]),
          position: options[:position] || :sidebar,
          order: options[:order] || 100,
          partial: options[:partial],
          render_proc: options[:render_proc],
          settings: options[:settings] || {},
          can_render: options[:can_render],
          plugin_name: options[:plugin_name]
        }.freeze
      end

      # Unregister a block
      def unregister(key)
        @blocks.delete(key)
      end

      # Get all registered blocks
      def all
        @blocks.values
      end

      # Get blocks for a specific location and position
      #
      # @param location [Symbol] The location (e.g., :post, :page)
      # @param position [Symbol] The position (e.g., :sidebar, :main)
      # @param context [Hash] Context for rendering (user, record, etc.)
      # @return [Array<Hash>] Sorted array of block configurations
      def for_location(location, position: nil, context: {})
        blocks = @blocks.values.select do |block|
          next false unless block[:locations].include?(location)
          next false if position && block[:position] != position
          next false if block[:can_render] && !block[:can_render].call(context)
          true
        end

        blocks.sort_by { |b| b[:order] }
      end

      # Get a specific block by key
      def get(key)
        @blocks[key]
      end

      # Check if a block exists
      def exists?(key)
        @blocks.key?(key)
      end

      # Clear all blocks (useful for testing)
      def clear!
        @blocks = {}
      end

      # Render a block
      #
      # @param key [Symbol] The block key
      # @param context [Hash] Context for rendering
      # @param view_context [ActionView::Base] The view context
      # @return [String] Rendered HTML
      def render(key, context: {}, view_context:)
        block = get(key)
        return '' unless block
        
        # Ensure context is a hash
        unless context.is_a?(Hash)
          Rails.logger.warn("Plugin block context is not a hash for #{key}: #{context.class}")
          context = {}
        end
        
        return '' if block[:can_render] && !block[:can_render].call(context)

        if block[:render_proc]
          view_context.instance_exec(context, &block[:render_proc])
        elsif block[:partial]
          # Create a clean locals hash
          locals_hash = context.is_a?(Hash) ? context.dup : {}
          locals_hash[:block] = block
          
          view_context.render(
            partial: block[:partial],
            locals: locals_hash
          )
        else
          ''
        end
      rescue => e
        Rails.logger.error("Error rendering plugin block #{key}: #{e.message}")
        Rails.logger.error("Context class: #{context.class}")
        Rails.logger.error("Context value: #{context.inspect}")
        Rails.logger.error(e.backtrace.join("\n"))
        
        if Rails.env.development?
          view_context.content_tag(:div, class: 'p-4 bg-red-500/10 border border-red-500/20 rounded text-red-400 text-sm') do
            "Error rendering block #{key}: #{e.message}<br/>Context: #{context.class}".html_safe
          end
        else
          ''
        end
      end

      # Render all blocks for a location and position
      #
      # @param location [Symbol] The location
      # @param position [Symbol] The position
      # @param context [Hash] Context for rendering
      # @param view_context [ActionView::Base] The view context
      # @return [String] Rendered HTML
      def render_all(location, position: nil, context: {}, view_context:)
        blocks = for_location(location, position: position, context: context)
        blocks.map { |block| render(block[:key], context: context, view_context: view_context) }.join.html_safe
      end

      private

      def validate_block_options!(key, options)
        raise ArgumentError, "Block key must be a symbol" unless key.is_a?(Symbol)
        raise ArgumentError, "Block must have either :partial or :render_proc" unless options[:partial] || options[:render_proc]
        
        if options[:locations] && !options[:locations].is_a?(Array)
          raise ArgumentError, "Block locations must be an array"
        end
        
        if options[:position] && ![:sidebar, :main, :footer, :header, :toolbar].include?(options[:position])
          raise ArgumentError, "Invalid block position: #{options[:position]}"
        end
      end
    end
  end
end

