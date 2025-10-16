module MonacoHelper
  # Monaco Editor theme mappings based on admin themes
  ADMIN_THEME_MONACO_MAPPINGS = {
    'onyx' => 'vs-dark',
    'vallarta' => 'vs-dark-blue', 
    'amanecer' => 'vs',
    'default' => 'vs'
  }.freeze

  # Get the appropriate Monaco theme based on user preference and admin theme
  def monaco_theme_for_user(user = current_user, admin_theme = 'default')
    return 'vs' if user.nil?
    
    case user.preferred_monaco_theme
    when 'auto'
      # Auto-detect based on admin theme
      ADMIN_THEME_MONACO_MAPPINGS[admin_theme.downcase] || 'vs'
    when 'dark'
      'vs-dark'
    when 'light'
      'vs'
    when 'blue'
      'vs-dark-blue'
    else
      'vs'
    end
  end

  # Get Monaco theme options for dropdown
  def monaco_theme_options
    [
      ['Auto (Follow Admin Theme)', 'auto'],
      ['Dark', 'dark'],
      ['Light', 'light'],
      ['Blue', 'blue']
    ]
  end

  # Get current admin theme (this would need to be implemented based on your admin theme system)
  def current_admin_theme
    # This should return the current admin theme name
    # For now, we'll use a default or get it from session/cookie
    session[:admin_theme] || 'default'
  end

  # Generate Monaco Editor configuration
  def monaco_editor_config(options = {})
    theme = monaco_theme_for_user(current_user, current_admin_theme)
    
    default_config = {
      theme: theme,
      automaticLayout: true,
      fontSize: 14,
      lineNumbers: 'on',
      minimap: { enabled: true },
      scrollBeyondLastLine: false,
      wordWrap: 'on',
      tabSize: 2,
      insertSpaces: true,
      formatOnPaste: true,
      formatOnType: true,
      fixedOverflowWidgets: true,
      renderLineHighlight: 'line',
      cursorStyle: 'line',
      cursorBlinking: 'blink'
    }
    
    default_config.merge(options)
  end
end




