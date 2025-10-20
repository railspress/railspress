class PersonalDataErasureWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 1, queue: :default
  
  def perform(request_id)
    request = PersonalDataErasureRequest.find(request_id)
    request.update(status: 'processing')
    
    user = User.find(request.user_id)
    
    begin
      # Create a backup before erasure (for audit purposes)
      create_erasure_backup(request, user)
      
      # Anonymize or delete personal data
      erase_user_data(user)
      
      # Update request status
      request.update!(
        status: 'completed',
        completed_at: Time.current,
        metadata: request.metadata.merge(
          erasure_completed_at: Time.current,
          erased_data_categories: get_erased_data_categories(user)
        )
      )
      
      # Log the completion
      Rails.logger.info("Personal data erasure completed for user #{user.email} (ID: #{user.id})")
      
    rescue => e
      Rails.logger.error("Personal data erasure failed for request #{request_id}: #{e.message}")
      request.update!(status: 'failed')
      raise e
    end
  end
  
  private
  
  def create_erasure_backup(request, user)
    # Create a minimal backup for audit purposes
    backup_data = {
      erasure_request_id: request.id,
      user_id: user.id,
      user_email: user.email,
      erasure_date: Time.current,
      reason: request.reason,
      metadata: request.metadata,
      data_categories_erased: get_data_categories_to_erase(user)
    }
    
    backup_file_path = Rails.root.join('tmp', "erasure_backup_#{request.id}.json")
    File.write(backup_file_path, JSON.pretty_generate(backup_data))
    
    # Store backup path in request metadata
    request.update!(
      metadata: request.metadata.merge(
        backup_file_path: backup_file_path.to_s
      )
    )
  end
  
  def erase_user_data(user)
    # 1. Anonymize user profile (keep account for system integrity)
    user.update!(
      email: "deleted_user_#{user.id}@deleted.local",
      name: "Deleted User",
      bio: nil,
      website: nil,
      phone: nil,
      location: nil,
      # Keep role and created_at for audit purposes
      # Keep tenant_id for system integrity
    )
    
    # 2. Delete user's posts (or anonymize if needed for system integrity)
    user.posts.each do |post|
      post.update!(
        title: "[Deleted Post]",
        content: "This post has been deleted due to data erasure request.",
        slug: "deleted-post-#{post.id}"
      )
    end
    
    # 3. Delete user's pages (or anonymize)
    user.pages.each do |page|
      page.update!(
        title: "[Deleted Page]",
        content: "This page has been deleted due to data erasure request.",
        slug: "deleted-page-#{page.id}"
      )
    end
    
    # 4. Delete user's media files
    user.media.each do |medium|
      # Delete the actual file
      medium.file.purge if medium.file.attached?
      # Delete the record
      medium.destroy!
    end
    
    # 5. Anonymize comments by email
    Comment.where(author_email: user.email).each do |comment|
      comment.update!(
        author_name: "Deleted User",
        author_email: "deleted@deleted.local",
        content: "[This comment has been deleted due to data erasure request.]"
      )
    end
    
    # 6. Delete subscriber records
    Subscriber.where(email: user.email).destroy_all
    
    # 7. Delete API tokens
    user.api_tokens.destroy_all
    
    # 8. Delete meta fields
    user.meta_fields.destroy_all
    
    # 9. Delete analytics data (pageviews)
    Pageview.where(user_id: user.id).destroy_all
    
    # 10. Delete consent records
    UserConsent.where(user: user).destroy_all
    
    # 11. Delete OAuth accounts
    user.oauth_accounts.destroy_all
    
    # 12. Delete AI usage records
    user.ai_usages.destroy_all
    
    # Note: We don't delete the user record itself to maintain referential integrity
    # The user account is anonymized but kept for audit purposes
  end
  
  def get_data_categories_to_erase(user)
    categories = []
    categories << 'profile_data' if user.persisted?
    categories << 'posts' if user.posts.exists?
    categories << 'pages' if user.pages.exists?
    categories << 'media' if user.media.exists?
    categories << 'comments' if Comment.where(author_email: user.email).exists?
    categories << 'subscribers' if Subscriber.where(email: user.email).exists?
    categories << 'api_tokens' if user.api_tokens.exists?
    categories << 'meta_fields' if user.meta_fields.exists?
    categories << 'analytics' if Pageview.where(user_id: user.id).exists?
    categories << 'consent_records' if UserConsent.where(user: user).exists?
    categories << 'oauth_accounts' if user.oauth_accounts.exists?
    categories << 'ai_usage' if user.ai_usages.exists?
    categories
  end
  
  def get_erased_data_categories(user)
    get_data_categories_to_erase(user)
  end
end