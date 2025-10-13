# Shortcode System Initializer

require Rails.root.join('lib', 'railspress', 'shortcode_processor')

Rails.application.config.after_initialize do
  # Initialize shortcode processor
  Railspress::ShortcodeProcessor.initialize_processor
  
  # Add helper method to controllers
  ActiveSupport.on_load(:action_controller) do
    helper_method :process_shortcodes
  end
  
  Rails.logger.info "Shortcode system initialized. Registered shortcodes: #{Railspress::ShortcodeProcessor.all.join(', ')}"
end

# Helper method for processing shortcodes
module ShortcodeHelper
  def process_shortcodes(content, context = {})
    return content if content.blank?
    
    # Add view context to shortcode processing
    context[:view_context] = self if context[:view_context].nil?
    
    Railspress::ShortcodeProcessor.process(content.to_s, context)
  end
  
  def shortcode_help
    Railspress::ShortcodeProcessor.all.map do |name|
      { name: name, usage: "[#{name}]" }
    end
  end
end

# Include helper in ApplicationController
if defined?(ApplicationController)
  ApplicationController.helper(ShortcodeHelper)
end





