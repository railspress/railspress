# [Plugin Name] Plugin for RailsPress
# [Brief description of what this plugin does]
#
# Features:
# - Feature 1
# - Feature 2
# - Feature 3
#
# Settings:
# - setting_name (type): Description
#
# Hooks Registered:
# - action_name: Description
# - filter_name: Description

class PluginTemplate < Railspress::PluginBase
  # Plugin Metadata (required)
  plugin_name 'Plugin Template'
  plugin_version '1.0.0'
  plugin_description 'A template for creating RailsPress plugins'
  plugin_author 'Your Name'
  plugin_url 'https://github.com/yourname/plugin-name' # optional
  plugin_license 'MIT' # optional
  
  # Plugin configuration (optional)
  def self.default_settings
    {
      'enabled' => true,
      'setting_1' => 'default_value',
      'setting_2' => 10
    }
  end
  
  # Activation hook (required)
  def activate
    super # Always call super first
    
    Rails.logger.info "#{plugin_name} v#{plugin_version} activated"
    
    # Initialize plugin
    register_hooks
    register_filters
    register_shortcodes if respond_to?(:register_shortcodes, true)
    inject_helpers if respond_to?(:inject_helpers, true)
    
    # Run one-time setup tasks
    perform_activation_tasks
  end
  
  # Deactivation hook (required)
  def deactivate
    super # Always call super first
    
    Rails.logger.info "#{plugin_name} deactivated"
    
    # Cleanup
    cleanup_hooks
    cleanup_shortcodes if respond_to?(:cleanup_shortcodes, true)
  end
  
  private
  
  # Register action hooks
  def register_hooks
    # Examples:
    # add_action('post_created', :on_post_created)
    # add_action('page_published', :on_page_published)
    # add_action('comment_approved', :on_comment_approved)
  end
  
  # Register filters
  def register_filters
    # Examples:
    # add_filter('post_content', :modify_post_content)
    # add_filter('page_title', :modify_page_title)
  end
  
  # Register shortcodes (optional)
  def register_shortcodes
    # Example:
    # register_shortcode('my_shortcode') do |attrs, content|
    #   "<div>#{content}</div>"
    # end
  end
  
  # Inject helper methods (optional)
  def inject_helpers
    # Example:
    # ApplicationController.helper(PluginTemplateHelper)
  end
  
  # Perform one-time activation tasks
  def perform_activation_tasks
    # Examples:
    # - Create database records
    # - Generate files
    # - Set default settings
  end
  
  # Cleanup on deactivation
  def cleanup_hooks
    # Remove registered hooks/filters
    # This is usually handled by PluginBase
  end
  
  # Hook callback examples
  def on_post_created(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    
    Rails.logger.info "New post created: #{post.title}"
    # Add your logic here
  end
  
  def on_page_published(page_id)
    page = Page.find_by(id: page_id)
    return unless page
    
    Rails.logger.info "Page published: #{page.title}"
    # Add your logic here
  end
  
  # Filter callback examples
  def modify_post_content(content)
    # Modify and return content
    content
  end
  
  def modify_page_title(title)
    # Modify and return title
    title
  end
  
  # Public API methods (can be called from anywhere)
  def self.do_something(param)
    # Your public plugin method
  end
  
  # Settings helpers (inherited from PluginBase)
  # get_setting(key, default)
  # set_setting(key, value)
  # setting_enabled?(key)
end

# Helper module (optional)
module PluginTemplateHelper
  def plugin_template_method
    # Your helper method
  end
end

# Initialize the plugin
PluginTemplate.new





