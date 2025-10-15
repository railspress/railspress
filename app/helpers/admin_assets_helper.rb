module AdminAssetsHelper
  # Define CSS files needed for each admin page
  ADMIN_PAGE_ASSETS = {
    'theme_editor' => %w[admin/theme_editor theme_editor_tabs],
    'api_docs' => %w[admin/api_docs],
    'users' => %w[admin/shared tabulator_custom],
    'posts' => %w[admin/shared tabulator_custom],
    'pages' => %w[admin/shared tabulator_custom],
    'comments' => %w[admin/shared tabulator_custom],
    'media' => %w[admin/shared],
    'settings' => %w[admin/shared],
    'ai_agents' => %w[admin/shared],
    'plugins' => %w[admin/shared],
    'content_types' => %w[admin/shared tabulator_custom],
    'categories' => %w[admin/shared tabulator_custom],
    'tags' => %w[admin/shared tabulator_custom],
    'subscribers' => %w[admin/shared tabulator_custom],
    'analytics' => %w[admin/shared],
    'trash' => %w[admin/shared tabulator_custom],
    'cache' => %w[admin/shared],
    'logs' => %w[admin/shared],
    'integrations' => %w[admin/shared],
    'pixels' => %w[admin/shared],
    'pixel_preview' => %w[admin/pixel_preview],
    'template_customizer' => %w[admin/shared],
    'tools' => %w[admin/shared],
    'fonts' => %w[admin/shared],
    'terms' => %w[admin/shared tabulator_custom],
    'field_groups' => %w[admin/shared tabulator_custom],
    'shortcodes' => %w[admin/shared],
    'email_logs' => %w[admin/shared],
    'redirects' => %w[admin/shared tabulator_custom],
    'system' => %w[admin/shared],
    'dashboard' => %w[admin/shared]
  }.freeze

  # Define JavaScript files needed for each admin page
  ADMIN_PAGE_JAVASCRIPT = {
    'theme_editor' => %w[theme_editor_tabs_controller],
    'posts' => %w[keyboard_shortcuts_controller],
    'settings' => %w[appearance_preview_controller email_settings_controller post_by_email_controller],
    'ai_agents' => %w[ai_agents_controller ai_agent_chat_controller],
    'analytics' => %w[analytics_controller],
    'cache' => %w[cache_controller],
    'logs' => %w[log_viewer_controller],
    'tools' => %w[import_tools_controller],
    'users' => %w[tabulator_controller],
    'pages' => %w[tabulator_controller],
    'comments' => %w[tabulator_controller],
    'media' => %w[media_library_controller],
    'content_types' => %w[tabulator_controller],
    'categories' => %w[tabulator_controller],
    'tags' => %w[tabulator_controller],
    'subscribers' => %w[tabulator_controller],
    'trash' => %w[tabulator_controller],
    'terms' => %w[tabulator_controller],
    'field_groups' => %w[tabulator_controller],
    'redirects' => %w[tabulator_controller]
  }.freeze

  def admin_stylesheets_for_page(page_name)
    assets = ADMIN_PAGE_ASSETS[page_name.to_s] || %w[admin/shared]
    assets.map { |asset| stylesheet_link_tag(asset, "data-turbo-track": "reload") }.join("\n").html_safe
  end

  def admin_javascripts_for_page(page_name)
    assets = ADMIN_PAGE_JAVASCRIPT[page_name.to_s] || []
    # Stimulus controllers are automatically loaded, so we just need to ensure they're available
    # This method can be extended to load specific JS files if needed
    "".html_safe
  end

  def admin_page_assets(page_name)
    content_for :stylesheets, admin_stylesheets_for_page(page_name)
    content_for :javascripts, admin_javascripts_for_page(page_name)
  end
end
