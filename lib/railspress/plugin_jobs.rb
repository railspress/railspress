module Railspress
  module PluginJobs
    # Base class for plugin background jobs
    class Base < ApplicationJob
      queue_as :default
      
      # Override in subclass
      def perform(*args)
        raise NotImplementedError, "Subclass must implement #perform"
      end
    end
    
    # Helper methods for plugins to create and schedule jobs
    module Helpers
      # Create a background job for the plugin
      # Example:
      #   create_job('SendEmailJob') do |job|
      #     def perform(user_id, message)
      #       user = User.find(user_id)
      #       PluginMailer.send_email(user, message).deliver_now
      #     end
      #   end
      def create_job(job_name, &block)
        job_class_name = "#{plugin_identifier.camelize}::#{job_name}"
        
        # Define job class dynamically
        job_class = Class.new(Railspress::PluginJobs::Base) do
          class_eval(&block) if block_given?
        end
        
        # Set constant
        plugin_module = plugin_identifier.camelize.constantize rescue Object.const_set(plugin_identifier.camelize, Module.new)
        plugin_module.const_set(job_name, job_class)
        
        job_class
      end
      
      # Enqueue a job to run immediately
      # Example:
      #   enqueue_job(SendEmailJob, user.id, 'Hello')
      def enqueue_job(job_class, *args)
        job_class.perform_later(*args)
        log("Enqueued job: #{job_class.name}")
      end
      
      # Schedule a job to run at specific time
      # Example:
      #   schedule_job(SendEmailJob, 1.hour.from_now, user.id, 'Reminder')
      def schedule_job(job_class, run_at, *args)
        job_class.set(wait_until: run_at).perform_later(*args)
        log("Scheduled job: #{job_class.name} at #{run_at}")
      end
      
      # Schedule a job to run after delay
      # Example:
      #   schedule_job_in(SendEmailJob, 30.minutes, user.id, 'Follow-up')
      def schedule_job_in(job_class, delay, *args)
        job_class.set(wait: delay).perform_later(*args)
        log("Scheduled job: #{job_class.name} in #{delay}")
      end
      
      # Schedule recurring job (using Sidekiq-cron)
      # Example:
      #   schedule_recurring_job('daily_cleanup', '0 2 * * *', CleanupJob)
      def schedule_recurring_job(job_name, cron_expression, job_class, *args)
        require 'sidekiq-cron'
        
        Sidekiq::Cron::Job.create(
          name: "#{plugin_identifier}_#{job_name}",
          cron: cron_expression,
          class: job_class.name,
          args: args.to_json
        )
        
        log("Scheduled recurring job: #{job_name} (#{cron_expression})")
      rescue LoadError
        log("Sidekiq-cron not available. Install it to use recurring jobs.", :warn)
      end
      
      # Remove recurring job
      # Example:
      #   remove_recurring_job('daily_cleanup')
      def remove_recurring_job(job_name)
        require 'sidekiq-cron'
        
        Sidekiq::Cron::Job.destroy("#{plugin_identifier}_#{job_name}")
        log("Removed recurring job: #{job_name}")
      rescue LoadError
        # Silently skip if sidekiq-cron not available
      end
      
      # Get all recurring jobs for this plugin
      def recurring_jobs
        require 'sidekiq-cron'
        
        prefix = "#{plugin_identifier}_"
        Sidekiq::Cron::Job.all.select { |job| job.name.start_with?(prefix) }
      rescue LoadError
        []
      end
      
      # Check if Sidekiq is available
      def sidekiq_available?
        defined?(Sidekiq)
      end
      
      # Get job queue name
      def job_queue
        :"#{plugin_identifier}_jobs"
      end
      
      # Set custom queue for plugin jobs
      # Example:
      #   use_queue(:critical) # or :default, :low_priority
      def use_queue(queue_name)
        @job_queue = queue_name
      end
      
      # Enqueue multiple jobs at once
      # Example:
      #   enqueue_batch([
      #     [SendEmailJob, user1.id],
      #     [SendEmailJob, user2.id],
      #     [ProcessDataJob, data.id]
      #   ])
      def enqueue_batch(jobs)
        jobs.each do |job_class, *args|
          enqueue_job(job_class, *args)
        end
      end
      
      # Check job status (if using Sidekiq Pro)
      def job_status(job_id)
        return unless sidekiq_available?
        
        # This requires Sidekiq Pro
        # Sidekiq::Status.get(job_id)
      end
      
      # Clear all jobs for this plugin
      def clear_plugin_jobs
        return unless sidekiq_available?
        
        # Remove from Redis queue
        Sidekiq::Queue.all.each do |queue|
          queue.each do |job|
            job.delete if job.klass.start_with?(plugin_identifier.camelize)
          end
        end
        
        log("Cleared all plugin jobs from queues")
      end
    end
  end
end






