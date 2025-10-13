# frozen_string_literal: true

module PluginBlocksHelper
  # Render plugin blocks for a specific location and position
  #
  # @param location [Symbol] The location (e.g., :post, :page)
  # @param position [Symbol] The position (e.g., :sidebar, :main)
  # @param context [Hash] Context to pass to blocks
  # @return [String] Rendered HTML
  def render_plugin_blocks(location, position: :sidebar, **context)
    # Ensure we always have a hash to work with
    context = {} unless context.is_a?(Hash)
    
    full_context = context.merge(
      current_user: current_user,
      controller: controller,
      action_name: action_name
    )

    result = Railspress::PluginBlocks.render_all(
      location,
      position: position,
      context: full_context,
      view_context: self
    )
    
    # Ensure we return a safe string
    result.is_a?(String) ? result.html_safe : ''
  rescue => e
    Rails.logger.error("Error rendering plugin blocks: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    if Rails.env.development?
      content_tag(:div, class: 'p-4 bg-red-500/10 border border-red-500/20 rounded text-red-400 text-sm') do
        "Error rendering plugin blocks: #{e.message}"
      end
    else
      ''
    end
  end

  # Check if there are any blocks for a location/position
  #
  # @param location [Symbol] The location
  # @param position [Symbol] The position
  # @param context [Hash] Context for can_render checks
  # @return [Boolean] True if blocks exist
  def plugin_blocks_present?(location, position: :sidebar, **context)
    full_context = context.merge(
      current_user: current_user,
      controller: controller,
      action_name: action_name
    )

    Railspress::PluginBlocks.for_location(
      location,
      position: position,
      context: full_context
    ).any?
  end

  # Render a single plugin block
  #
  # @param key [Symbol] The block key
  # @param context [Hash] Context to pass to the block
  # @return [String] Rendered HTML
  def render_plugin_block(key, **context)
    full_context = context.merge(
      current_user: current_user,
      controller: controller,
      action_name: action_name
    )

    Railspress::PluginBlocks.render(
      key,
      context: full_context,
      view_context: self
    )
  end
end

