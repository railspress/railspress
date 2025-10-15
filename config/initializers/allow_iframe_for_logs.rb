class AllowIframeForLogs
    def initialize(app)
      @app = app
    end
  
    def call(env)
      status, headers, body = @app.call(env)
      
      if env['PATH_INFO'].start_with?('/admin/logster')
        headers.delete('X-Frame-Options') # Remove restrictive header
        headers['Content-Security-Policy'] = 
          [headers['Content-Security-Policy'],
           "frame-ancestors 'self'"].compact.join('; ')
      end
      
      [status, headers, body]
    end
  end
  