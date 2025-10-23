class UppyEditor < Railspress::PluginBase
  plugin_name 'Uppy Editor'
  plugin_version '1.0.0'
  plugin_description 'Uppy file uploader integration for EditorJS'
  plugin_author 'RailsPress Team'
  
  settings_schema do
    section 'Upload Settings' do
      checkbox 'enable_dashboard', 'Enable Full Dashboard',
        description: 'Use full Uppy Dashboard UI',
        default: true
      
      checkbox 'enable_webcam', 'Enable Webcam',
        default: false
      
      checkbox 'enable_screen_capture', 'Enable Screen Capture',
        default: false
      
      checkbox 'enable_url_import', 'Enable URL Import',
        default: false
      
      number 'max_file_size', 'Max File Size (MB)',
        default: 10, min: 1, max: 100
      
      number 'max_files', 'Max Files Per Upload',
        default: 10, min: 1, max: 50
    end
  end
  
  def activate
    super
    register_hooks
  end
  
  # ========================================
  # HANDLER METHODS (called by proxy)
  # ========================================
  
  def handle_upload(request, params, current_user)
    file = params[:file]
    
    Rails.logger.info "Uppy upload started - file: #{file&.original_filename}, type: #{file&.content_type}"
    
    # Security checks
    security = UploadSecurity.current
    unless security.file_allowed?(file)
      Rails.logger.error "Upload rejected: File type not allowed"
      return { success: 0, error: 'File type not allowed' }
    end
    
    if security.file_suspicious?(file)
      Rails.logger.error "Upload rejected: Suspicious file detected"
      return { success: 0, error: 'Suspicious file detected' }
    end
    
    # Create Upload
    upload = Upload.new(title: file.original_filename)
    upload.file.attach(file)
    upload.user = current_user
    upload.storage_provider = StorageProvider.active.first
    
    if upload.save
      Rails.logger.info "Upload successful: #{upload.id}"
      {
        success: 1,
        file: {
          url: upload.url,
          id: upload.id,
          name: file.original_filename,
          type: file.content_type
        }
      }
    else
      Rails.logger.error "Upload failed: #{upload.errors.full_messages.join(', ')}"
      { success: 0, error: upload.errors.full_messages.join(', ') }
    end
  rescue => e
    Rails.logger.error "Uppy upload failed: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    { success: 0, error: 'Upload failed' }
  end
  
  def handle_asset(request, params, current_user)
    # Path comes as array from route *path
    path = params[:path] || []
    path = [path] if path.is_a?(String)
    
    Rails.logger.debug "Uppy asset request - path: #{path.inspect}"
    
    # Add .js extension if missing
    if path.last && !path.last.end_with?('.js') && !path.last.end_with?('.css')
      path = path.dup
      path[-1] = "#{path.last}.js"
    end
    
    file_path = plugin_path.join('assets', *path)
    
    Rails.logger.debug "Uppy asset - file_path: #{file_path}"
    
    # Security check
    assets_dir = plugin_path.join('assets')
    unless file_path.to_s.start_with?(assets_dir.to_s)
      Rails.logger.error "Uppy asset forbidden: #{file_path}"
      return [403, {}, ['Forbidden']]
    end
    
    unless File.exist?(file_path) && File.file?(file_path)
      Rails.logger.error "Asset not found: #{file_path}"
      return [404, {}, ['Not Found']]
    end
    
    # Determine content type
    ext = File.extname(file_path)[1..-1]
    content_type = Mime::Type.lookup_by_extension(ext) || 'application/octet-stream'
    
    # Return [status, headers, body]
    [
      200,
      {
        'Content-Type' => content_type.to_s,
        'Cache-Control' => 'public, max-age=31536000'
      },
      [File.read(file_path)]
    ]
  end
  
  # ========================================
  # RENDERING METHODS  
  # ========================================
  
  def enabled?
    true
  end
  
  private
  
  def register_hooks
    # Inject Uppy assets into EditorJS pages
    add_action('editor_js_head_assets') do
      render_uppy_assets
    end
    
    # Inject Uppy tool configuration
    add_action('editor_js_tools') do
      render_uppy_tool_config
    end
  end
  
  def render_uppy_assets
    return '' unless enabled?
    
    <<~HTML
      <!-- Uppy Core CSS -->
      <link href="https://releases.transloadit.com/uppy/v5.1.7/uppy.min.css" rel="stylesheet">
      
      <!-- Uppy Core + Dashboard + XHR -->
      <script type="module">
        import { Uppy, Dashboard, XHRUpload } from "https://releases.transloadit.com/uppy/v5.1.7/uppy.min.mjs";
        window.Uppy = Uppy;
        window.UppyDashboard = Dashboard;
        window.UppyXHR = XHRUpload;
      </script>
      
      <!-- Uppy EditorJS Tool -->
      <script src="/admin/plugins/#{plugin_identifier}/assets/javascripts/uppy_editorjs_tool.js?v=#{Time.current.to_i}"></script>
    HTML
  end
  
  def render_uppy_tool_config
    settings = get_all_settings
    
    <<~JS
      window.pluginEditorJsTools = window.pluginEditorJsTools || {};
      window.pluginEditorJsTools.uppy = {
        class: UppyEditorTool,
        config: {
          endpoint: '/admin/plugins/#{plugin_identifier}/upload',
          maxFileSize: #{settings['max_file_size'] || 10} * 1024 * 1024,
          maxNumberOfFiles: #{settings['max_files'] || 10},
          enableWebcam: #{settings['enable_webcam'] || false},
          enableScreenCapture: #{settings['enable_screen_capture'] || false},
          enableUrl: #{settings['enable_url_import'] || false},
          autoProceed: false,
          theme: 'auto' // Will be dynamically determined from localStorage
        }
      };
    JS
  end
end

# Auto-initialize if active
if Plugin.exists?(name: 'Uppy Editor', active: true)
  UppyEditor.new
end

