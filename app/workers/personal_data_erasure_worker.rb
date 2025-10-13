class PersonalDataErasureWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 1, queue: :critical
  
  def perform(request_id)
    request = PersonalDataErasureRequest.find(request_id)
    request.update(status: 'processing')
    
    user = User.find(request.user_id)
    email = request.email
    
    ActiveRecord::Base.transaction do
      # 1. Anonymize or delete comments
      Comment.where(email: email).update_all(
        author_name: 'Anonymous',
        email: "deleted_#{SecureRandom.hex(8)}@example.com",
        ip_address: '0.0.0.0',
        user_agent: nil
      )
      
      # 2. Delete or anonymize posts (depending on policy)
      # Option 1: Keep posts but anonymize author
      user.posts.update_all(user_id: nil)
      # Option 2: Delete all posts (uncomment if desired)
      # user.posts.destroy_all
      
      # 3. Delete subscribers
      Subscriber.where(email: email).destroy_all
      
      # 4. Anonymize pageviews
      Pageview.where(user_id: user.id).update_all(
        user_id: nil,
        ip_hash: Digest::SHA256.hexdigest("anonymized_#{SecureRandom.hex}"),
        session_id: nil
      )
      
      # 5. Delete email logs
      EmailLog.where(to: email).destroy_all rescue nil
      
      # 6. Delete custom field values
      CustomFieldValue.where(post_id: user.posts.pluck(:id)).destroy_all rescue nil
      
      # 7. Delete user media
      user.avatar.purge if user.avatar.attached? rescue nil
      
      # 8. Finally, delete the user account
      user.destroy!
      
      # Log the erasure
      Rails.logger.info("Personal data erased for user #{email} (Request ##{request.id})")
      
      request.update(
        status: 'completed',
        completed_at: Time.current,
        metadata: request.metadata.merge(
          erased_at: Time.current,
          erased_by: request.confirmed_by
        )
      )
    end
    
  rescue => e
    Rails.logger.error("Personal data erasure #{request_id} failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    request.update(
      status: 'failed',
      metadata: request.metadata.merge(error: e.message)
    )
  end
end






