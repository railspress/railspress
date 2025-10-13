class PostByEmailWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :default, retry: 3
  
  def perform
    Rails.logger.info "Starting Post by Email check..."
    
    result = PostByEmailService.check_mail
    
    Rails.logger.info "Post by Email check completed: #{result[:new_posts]} new post(s), #{result[:checked]} email(s) checked"
  rescue => e
    Rails.logger.error "Post by Email worker failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # Re-raise to trigger Sidekiq retry
  end
end




