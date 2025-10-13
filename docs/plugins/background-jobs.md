# Plugin Background Jobs

Execute tasks asynchronously using RailsPress's background job system powered by Sidekiq.

## Quick Start

```ruby
class MyPlugin < Railspress::PluginBase
  plugin_name 'Email Sender'
  
  def activate
    super
    
    # Create job class
    create_job('SendWelcomeEmailJob') do
      def perform(user_id)
        user = User.find(user_id)
        UserMailer.welcome_email(user).deliver_now
      end
    end
    
    # Hook into user creation
    add_action('user_created', :send_welcome_email)
  end
  
  private
  
  def send_welcome_email(user_id)
    # Enqueue job
    enqueue_job(EmailSender::SendWelcomeEmailJob, user_id)
  end
end
```

## Creating Jobs

### Simple Job

```ruby
create_job('ProcessDataJob') do
  def perform(data_id)
    data = Data.find(data_id)
    # Process data
    data.update(processed: true)
  end
end
```

### Job with Multiple Arguments

```ruby
create_job('SendNotificationJob') do
  def perform(user_id, message, options = {})
    user = User.find(user_id)
    NotificationMailer.send_notification(user, message, options).deliver_now
  end
end
```

### Job with Error Handling

```ruby
create_job('RobustJob') do
  retry_on StandardError, wait: 5.seconds, attempts: 3
  
  def perform(item_id)
    item = Item.find(item_id)
    # Risky operation
    ExternalAPI.process(item)
  rescue => e
    Rails.logger.error "[Plugin] Job failed: #{e.message}"
    raise # Re-raise to trigger retry
  end
end
```

## Enqueuing Jobs

### Run Immediately

```ruby
# Enqueue single job
enqueue_job(MyJob, arg1, arg2)

# Enqueue multiple jobs
enqueue_batch([
  [SendEmailJob, user1.id],
  [SendEmailJob, user2.id],
  [ProcessJob, data.id]
])
```

### Schedule for Later

```ruby
# Run at specific time
schedule_job(MyJob, 1.hour.from_now, user_id)
schedule_job(CleanupJob, Date.tomorrow.noon)

# Run after delay
schedule_job_in(MyJob, 30.minutes, user_id)
schedule_job_in(ReminderJob, 1.day, reminder_id)
```

## Recurring Jobs (Cron)

Requires `sidekiq-cron` gem.

### Daily Job

```ruby
def activate
  super
  
  # Every day at 2 AM
  schedule_recurring_job(
    'daily_cleanup',
    '0 2 * * *',
    CleanupJob
  )
end

def deactivate
  super
  
  # Remove recurring job
  remove_recurring_job('daily_cleanup')
end
```

### Common Cron Patterns

```ruby
# Every hour
'0 * * * *'

# Every 30 minutes
'*/30 * * * *'

# Every day at midnight
'0 0 * * *'

# Every Monday at 9 AM
'0 9 * * 1'

# First day of month at noon
'0 12 1 * *'

# Every weekday at 8 AM
'0 8 * * 1-5'
```

### Multiple Recurring Jobs

```ruby
def activate
  super
  
  # Daily summary email
  schedule_recurring_job('daily_summary', '0 8 * * *', DailySummaryJob)
  
  # Weekly report
  schedule_recurring_job('weekly_report', '0 9 * * 1', WeeklyReportJob)
  
  # Hourly sync
  schedule_recurring_job('hourly_sync', '0 * * * *', SyncJob)
end

def deactivate
  super
  
  remove_recurring_job('daily_summary')
  remove_recurring_job('weekly_report')
  remove_recurring_job('hourly_sync')
end
```

## Job Queues

### Use Custom Queue

```ruby
class MyPlugin < Railspress::PluginBase
  def activate
    super
    
    # Set custom queue for this plugin
    use_queue(:critical) # or :default, :low_priority
  end
end
```

### Queue Priority

Available queues (in order of priority):
1. `:critical` - Highest priority
2. `:default` - Standard priority
3. `:low_priority` - Background tasks

## Complete Example

```ruby
class EmailMarketingPlugin < Railspress::PluginBase
  plugin_name 'Email Marketing'
  plugin_version '1.0.0'
  
  def activate
    super
    
    # Create job classes
    create_welcome_email_job
    create_campaign_job
    create_cleanup_job
    
    # Schedule recurring cleanup
    schedule_recurring_job('daily_cleanup', '0 3 * * *', EmailMarketingPlugin::CleanupJob)
    
    # Register hooks
    add_action('user_registered', :send_welcome_email)
    add_action('campaign_created', :schedule_campaign)
  end
  
  def deactivate
    super
    
    # Remove recurring jobs
    remove_recurring_job('daily_cleanup')
    
    # Clear pending jobs
    clear_plugin_jobs
  end
  
  private
  
  def create_welcome_email_job
    create_job('WelcomeEmailJob') do
      def perform(user_id)
        user = User.find(user_id)
        return unless user
        
        EmailMarketingMailer.welcome_email(user).deliver_now
      end
    end
  end
  
  def create_campaign_job
    create_job('CampaignJob') do
      retry_on StandardError, wait: 10.minutes, attempts: 3
      
      def perform(campaign_id)
        campaign = Campaign.find(campaign_id)
        
        campaign.subscribers.find_each do |subscriber|
          EmailMarketingMailer.campaign_email(subscriber, campaign).deliver_now
        end
        
        campaign.update(sent_at: Time.current, status: 'sent')
      end
    end
  end
  
  def create_cleanup_job
    create_job('CleanupJob') do
      def perform
        # Remove old campaign data
        Campaign.where('sent_at < ?', 90.days.ago).destroy_all
      end
    end
  end
  
  def send_welcome_email(user_id)
    # Send immediately
    enqueue_job(EmailMarketingPlugin::WelcomeEmailJob, user_id)
  end
  
  def schedule_campaign(campaign_id)
    campaign = Campaign.find(campaign_id)
    
    # Schedule for campaign's send time
    schedule_job(
      EmailMarketingPlugin::CampaignJob,
      campaign.scheduled_at,
      campaign.id
    )
  end
end
```

## Job Methods Reference

### create_job(name, &block)
Creates a job class for your plugin.

### enqueue_job(job_class, *args)
Runs job immediately (async).

### schedule_job(job_class, time, *args)
Runs job at specific time.

### schedule_job_in(job_class, delay, *args)
Runs job after delay.

### schedule_recurring_job(name, cron, job_class, *args)
Runs job on schedule (requires sidekiq-cron).

### remove_recurring_job(name)
Removes recurring job.

### recurring_jobs
Lists all recurring jobs for plugin.

### clear_plugin_jobs
Removes all pending jobs for plugin.

### use_queue(queue_name)
Sets custom queue for plugin jobs.

## Best Practices

### 1. Clean Up on Deactivation

```ruby
def deactivate
  super
  
  # Remove recurring jobs
  recurring_jobs.each do |job|
    Sidekiq::Cron::Job.destroy(job.name)
  end
  
  # Clear pending jobs
  clear_plugin_jobs
end
```

### 2. Use Retries for External APIs

```ruby
create_job('APIJob') do
  retry_on Net::HTTPError, wait: 30.seconds, attempts: 5
  retry_on Timeout::Error, wait: 1.minute, attempts: 3
  
  def perform(data_id)
    # Call external API
  end
end
```

### 3. Log Job Execution

```ruby
def perform(user_id)
  Rails.logger.info "[MyPlugin] Starting job for user #{user_id}"
  
  # Do work
  
  Rails.logger.info "[MyPlugin] Job completed successfully"
end
```

### 4. Handle Missing Records

```ruby
def perform(record_id)
  record = Record.find_by(id: record_id)
  return unless record # Silently skip if deleted
  
  # Process record
end
```

### 5. Use Batches for Large Datasets

```ruby
def perform
  User.find_in_batches(batch_size: 100) do |batch|
    batch.each do |user|
      # Process user
    end
  end
end
```

## Monitoring Jobs

### Check if Sidekiq is Running

```ruby
if sidekiq_available?
  # Sidekiq is available
else
  # Fallback to inline processing
end
```

### List Recurring Jobs

```ruby
# In Rails console
plugin = MyPlugin.instance
plugin.recurring_jobs.each do |job|
  puts "#{job.name}: #{job.cron}"
end
```

## Testing

```ruby
require 'test_helper'

class MyPluginJobsTest < ActiveJob::TestCase
  def setup
    @plugin = MyPlugin.new
    @plugin.activate
  end

  test "job is enqueued" do
    assert_enqueued_with(job: EmailSender::WelcomeEmailJob) do
      @plugin.send_welcome_email(users(:admin).id)
    end
  end

  test "job performs correctly" do
    perform_enqueued_jobs do
      @plugin.send_welcome_email(users(:admin).id)
    end
    
    # Assert email was sent
    assert_emails 1
  end

  test "recurring job is scheduled" do
    jobs = @plugin.recurring_jobs
    assert jobs.any? { |j| j.name.include?('daily_cleanup') }
  end
end
```

## Related

- [Plugin Architecture](./architecture.md)
- [Settings Schema](./settings-schema.md)
- [Sidekiq Guide](https://github.com/sidekiq/sidekiq/wiki)
- [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron)




