class DevelopmentPluginWatcher
  def self.start_watching
    return unless Rails.env.development?
    
    # Create a thread to watch for plugin changes
    Thread.new do
      watch_plugin_changes
    end
  end
  
  private
  
  def self.watch_plugin_changes
    trigger_file = Rails.root.join('tmp', 'plugin_reload_trigger')
    
    loop do
      if File.exist?(trigger_file)
        begin
          data = JSON.parse(File.read(trigger_file))
          plugin_name = data['plugin_name']
          action = data['action']
          
          Rails.logger.info "🔄 Detected plugin #{action}: #{plugin_name}"
          
          # Remove the trigger file
          File.delete(trigger_file)
          
          # Trigger a graceful restart
          trigger_graceful_restart(plugin_name, action)
          
        rescue => e
          Rails.logger.error "Error processing plugin reload trigger: #{e.message}"
          File.delete(trigger_file) if File.exist?(trigger_file)
        end
      end
      
      sleep 1
    end
  end
  
  def self.trigger_graceful_restart(plugin_name, action)
    Rails.logger.info "🔄 Gracefully restarting server for plugin #{action}: #{plugin_name}"
    
    # Send a signal to restart the server
    # This is a development-only feature
    if defined?(Puma)
      # Puma restart
      Process.kill('USR1', Process.pid)
    elsif defined?(Unicorn)
      # Unicorn restart
      Process.kill('USR2', Process.pid)
    else
      # Fallback: create a restart file
      restart_file = Rails.root.join('tmp', 'restart.txt')
      FileUtils.touch(restart_file)
      Rails.logger.info "📝 Created restart file. Please restart the server manually."
    end
  end
end


