class AllowIframeForLogs
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only intercept logster paths, let everything else pass through
    if env['PATH_INFO'].start_with?('/admin/logster')
      status, headers, body = @app.call(env)
      headers.delete('X-Frame-Options')
      headers['Content-Security-Policy'] = 
        [headers['Content-Security-Policy'],
         "frame-ancestors 'self'"].compact.join('; ')
      [status, headers, body]
    else
      # Pass through all other requests without unpacking
      # This preserves streaming responses like ActiveStorage files
      @app.call(env)
    end
  end
end
