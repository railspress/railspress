class PluginTaskWorkerJob < ApplicationJob
  queue_as :default
  
  def perform(plugin_identifier, task_name)
    plugin = Railspress::PluginSystem.get_plugin(plugin_identifier)
    
    unless plugin
      Rails.logger.error "Plugin not found: #{plugin_identifier}"
      return
    end
    
    # Find the task
    task = Railspress::PluginSystem.instance_variable_get(:@scheduled_tasks)[plugin_identifier]
                             &.find { |t| t[:name] == task_name }
    
    unless task
      Rails.logger.error "Task not found: #{plugin_identifier}:#{task_name}"
      return
    end
    
    Rails.logger.info "Executing scheduled task: #{plugin_identifier}:#{task_name}"
    
    begin
      # Execute the task
      task[:block].call
      Rails.logger.info "Task completed successfully: #{plugin_identifier}:#{task_name}"
    rescue => e
      Rails.logger.error "Task failed: #{plugin_identifier}:#{task_name} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      raise e
    end
  end
end
