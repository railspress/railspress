class GdprService
  include Rails.application.routes.url_helpers
  
  class << self
    # Create a personal data export request
    def create_export_request(user, requested_by, options = {})
      # Check if there's already a pending request
      existing_request = PersonalDataExportRequest.where(user: user, status: ['pending', 'processing']).first
      if existing_request
        raise StandardError, 'An export request is already pending or processing for this user'
      end
      
      # Create the request
      export_request = PersonalDataExportRequest.create!(
        user: user,
        email: user.email,
        requested_by: requested_by.id,
        status: 'pending',
        tenant: user.tenant
      )
      
      # Queue the export job
      PersonalDataExportWorker.perform_async(export_request.id)
      
      # Log the action
      log_gdpr_action('export_requested', user, requested_by, {
        request_id: export_request.id,
        email: user.email
      })
      
      export_request
    end
    
    # Create a personal data erasure request
    def create_erasure_request(user, requested_by, reason = nil)
      # Check if there's already a pending request
      existing_request = PersonalDataErasureRequest.where(user: user, status: ['pending_confirmation', 'processing']).first
      if existing_request
        raise StandardError, 'An erasure request is already pending or processing for this user'
      end
      
      # Gather metadata about what will be erased
      metadata = gather_erasure_metadata(user)
      
      # Create the request
      erasure_request = PersonalDataErasureRequest.create!(
        user: user,
        email: user.email,
        requested_by: requested_by.id,
        status: 'pending_confirmation',
        reason: reason,
        metadata: metadata,
        tenant: user.tenant
      )
      
      # Log the action
      log_gdpr_action('erasure_requested', user, requested_by, {
        request_id: erasure_request.id,
        reason: reason,
        metadata: metadata
      })
      
      erasure_request
    end
    
    # Confirm an erasure request
    def confirm_erasure_request(erasure_request, confirmed_by)
      erasure_request.update!(
        status: 'processing',
        confirmed_at: Time.current,
        confirmed_by: confirmed_by.id
      )
      
      # Queue the erasure job
      PersonalDataErasureWorker.perform_async(erasure_request.id)
      
      # Log the action
      log_gdpr_action('erasure_confirmed', erasure_request.user, confirmed_by, {
        request_id: erasure_request.id,
        reason: erasure_request.reason
      })
      
      erasure_request
    end
    
    # Generate comprehensive data portability information
    def generate_portability_data(user)
      {
        user_profile: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          bio: user.bio,
          website: user.website,
          created_at: user.created_at,
          updated_at: user.updated_at,
          last_sign_in_at: user.last_sign_in_at,
          sign_in_count: user.sign_in_count
        },
        posts: user.posts.map do |post|
          {
            id: post.id,
            title: post.title,
            slug: post.slug,
            content: post.content.to_s,
            excerpt: post.excerpt,
            status: post.status,
            published_at: post.published_at,
            created_at: post.created_at,
            updated_at: post.updated_at,
            categories: post.categories.map(&:name),
            tags: post.tags.map(&:name)
          }
        end,
        pages: user.pages.map do |page|
          {
            id: page.id,
            title: page.title,
            slug: page.slug,
            content: page.content.to_s,
            status: page.status,
            published_at: page.published_at,
            created_at: page.created_at,
            updated_at: page.updated_at
          }
        end,
        comments: Comment.where(author_email: user.email).map do |comment|
          {
            id: comment.id,
            content: comment.content,
            author_name: comment.author_name,
            author_email: comment.author_email,
            status: comment.status,
            post_title: comment.commentable&.title,
            created_at: comment.created_at,
            updated_at: comment.updated_at
          }
        end,
        media: user.media.map do |medium|
          {
            id: medium.id,
            filename: medium.filename,
            content_type: medium.content_type,
            file_size: medium.file_size,
            alt_text: medium.alt_text,
            caption: medium.caption,
            created_at: medium.created_at
          }
        end,
        subscribers: Subscriber.where(email: user.email).map do |subscriber|
          {
            id: subscriber.id,
            email: subscriber.email,
            status: subscriber.status,
            subscribed_at: subscriber.created_at,
            confirmed_at: subscriber.confirmed_at,
            lists: subscriber.lists
          }
        end,
        api_tokens: user.api_tokens.map do |token|
          {
            id: token.id,
            name: token.name,
            last_used_at: token.last_used_at,
            created_at: token.created_at
          }
        end,
        meta_fields: user.meta_fields.map do |field|
          {
            key: field.key,
            value: field.value,
            created_at: field.created_at,
            updated_at: field.updated_at
          }
        end,
        analytics_data: {
          pageviews: Pageview.where(user_id: user.id).group(:path).count,
          total_pageviews: Pageview.where(user_id: user.id).count,
          last_pageview: Pageview.where(user_id: user.id).order(:created_at).last&.created_at
        },
        consent_records: get_user_consent_records(user),
        gdpr_requests: {
          export_requests: PersonalDataExportRequest.where(user: user).map do |req|
            {
              id: req.id,
              status: req.status,
              requested_at: req.created_at,
              completed_at: req.completed_at
            }
          end,
          erasure_requests: PersonalDataErasureRequest.where(user: user).map do |req|
            {
              id: req.id,
              status: req.status,
              reason: req.reason,
              requested_at: req.created_at,
              confirmed_at: req.confirmed_at,
              completed_at: req.completed_at
            }
          end
        },
        metadata: {
          total_posts: user.posts.count,
          total_pages: user.pages.count,
          total_comments: Comment.where(author_email: user.email).count,
          total_media: user.media.count,
          total_subscribers: Subscriber.where(email: user.email).count,
          export_date: Time.current
        }
      }
    end
    
    # Get GDPR compliance status for a user
    def get_user_gdpr_status(user)
      {
        user_id: user.id,
        email: user.email,
        compliance_status: {
          data_processing_consent: get_consent_status(user, 'data_processing'),
          marketing_consent: get_consent_status(user, 'marketing'),
          analytics_consent: get_consent_status(user, 'analytics'),
          cookie_consent: get_consent_status(user, 'cookies')
        },
        data_retention: {
          account_created: user.created_at,
          last_activity: user.last_sign_in_at || user.updated_at,
          data_age_days: (Time.current - user.created_at).to_i / 1.day
        },
        pending_requests: {
          export_requests: PersonalDataExportRequest.where(user: user, status: ['pending', 'processing']).count,
          erasure_requests: PersonalDataErasureRequest.where(user: user, status: ['pending_confirmation', 'processing']).count
        },
        data_categories: {
          profile_data: true,
          content_data: user.posts.exists? || user.pages.exists?,
          communication_data: Comment.where(author_email: user.email).exists?,
          analytics_data: Pageview.where(user_id: user.id).exists?,
          media_data: user.media.exists?,
          subscription_data: Subscriber.where(email: user.email).exists?
        },
        legal_basis: {
          consent: get_consent_status(user, 'data_processing') == 'granted',
          withhold_consent: get_consent_status(user, 'data_processing') == 'withdrawn',
          legitimate_interest: true # For analytics and security
        }
      }
    end
    
    # Record user consent
    def record_user_consent(user, consent_type, consent_data)
      consent_record = UserConsent.find_or_initialize_by(
        user: user,
        consent_type: consent_type
      )
      
      consent_record.assign_attributes(
        granted: consent_data[:granted] || false,
        consent_text: consent_data[:consent_text],
        ip_address: consent_data[:ip_address],
        user_agent: consent_data[:user_agent],
        granted_at: consent_data[:granted] ? Time.current : nil,
        withdrawn_at: consent_data[:granted] ? nil : Time.current
      )
      
      consent_record.save!
      
      # Log the action
      log_gdpr_action('consent_recorded', user, nil, {
        consent_type: consent_type,
        granted: consent_data[:granted],
        consent_text: consent_data[:consent_text]
      })
      
      consent_record
    end
    
    # Withdraw user consent
    def withdraw_user_consent(user, consent_type)
      consent_record = UserConsent.find_by(user: user, consent_type: consent_type)
      
      if consent_record
        consent_record.update!(
          granted: false,
          withdrawn_at: Time.current
        )
        
        # Log the action
        log_gdpr_action('consent_withdrawn', user, nil, {
          consent_type: consent_type
        })
        
        consent_record
      else
        raise StandardError, 'No consent record found for this user and consent type'
      end
    end
    
    # Get audit log for GDPR compliance
    def get_audit_log(page = 1, per_page = 50)
      offset = (page - 1) * per_page
      
      # This would typically come from a dedicated audit log table
      # For now, we'll simulate with existing data
      audit_entries = []
      
      # Export requests
      PersonalDataExportRequest.includes(:user).recent.limit(per_page / 2).each do |req|
        audit_entries << {
          id: req.id,
          action: 'data_export_requested',
          user_email: req.email,
          timestamp: req.created_at,
          details: {
            status: req.status,
            completed_at: req.completed_at
          }
        }
      end
      
      # Erasure requests
      PersonalDataErasureRequest.includes(:user).recent.limit(per_page / 2).each do |req|
        audit_entries << {
          id: req.id,
          action: 'data_erasure_requested',
          user_email: req.email,
          timestamp: req.created_at,
          details: {
            status: req.status,
            reason: req.reason,
            confirmed_at: req.confirmed_at,
            completed_at: req.completed_at
          }
        }
      end
      
      # Sort by timestamp and paginate
      audit_entries.sort_by { |entry| entry[:timestamp] }.reverse
                  .slice(offset, per_page)
    end
    
    private
    
    # Gather metadata about what will be erased
    def gather_erasure_metadata(user)
      {
        user_posts_count: user.posts.count,
        user_pages_count: user.pages.count,
        user_comments_count: Comment.where(author_email: user.email).count,
        user_media_count: user.media.count,
        user_subscribers_count: Subscriber.where(email: user.email).count,
        user_pageviews_count: Pageview.where(user_id: user.id).count,
        user_api_tokens_count: user.api_tokens.count,
        user_meta_fields_count: user.meta_fields.count,
        account_age_days: (Time.current - user.created_at).to_i / 1.day,
        last_activity: user.last_sign_in_at || user.updated_at
      }
    end
    
    # Get consent status for a user
    def get_consent_status(user, consent_type)
      consent_record = UserConsent.find_by(user: user, consent_type: consent_type)
      
      if consent_record
        consent_record.granted ? 'granted' : 'withdrawn'
      else
        'not_recorded'
      end
    end
    
    # Get user consent records
    def get_user_consent_records(user)
      UserConsent.where(user: user).map do |consent|
        {
          consent_type: consent.consent_type,
          granted: consent.granted,
          consent_text: consent.consent_text,
          granted_at: consent.granted_at,
          withdrawn_at: consent.withdrawn_at,
          ip_address: consent.ip_address,
          created_at: consent.created_at,
          updated_at: consent.updated_at
        }
      end
    end
    
    # Log GDPR actions for audit trail
    def log_gdpr_action(action, user, performed_by, details = {})
      # In a real implementation, this would write to a dedicated audit log table
      Rails.logger.info("GDPR Action: #{action} - User: #{user.email} - Performed by: #{performed_by&.email} - Details: #{details.to_json}")
      
      # You could also store this in a dedicated audit log model:
      # GdprAuditLog.create!(
      #   action: action,
      #   user: user,
      #   performed_by: performed_by,
      #   details: details,
      #   ip_address: RequestStore[:current_request]&.remote_ip,
      #   user_agent: RequestStore[:current_request]&.user_agent
      # )
    end
  end
end
