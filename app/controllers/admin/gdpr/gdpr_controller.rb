class Admin::Gdpr::GdprController < Admin::BaseController
  before_action :set_user, only: [:user_data, :export_user_data, :erase_user_data, :user_consent_history]
  before_action :set_export_request, only: [:download_export, :export_status]
  before_action :set_erasure_request, only: [:confirm_erasure, :erasure_status]
  
  # GET /admin/gdpr
  def index
    @users = User.includes(:personal_data_export_requests, :personal_data_erasure_requests)
                 .order(:email)
                 .page(params[:page])
                 .per(25)
    
    @stats = {
      total_users: User.count,
      pending_exports: PersonalDataExportRequest.where(status: ['pending', 'processing']).count,
      pending_erasures: PersonalDataErasureRequest.where(status: ['pending_confirmation', 'processing']).count,
      completed_exports: PersonalDataExportRequest.where(status: 'completed').count,
      completed_erasures: PersonalDataErasureRequest.where(status: 'completed').count
    }
    
    @recent_requests = {
      exports: PersonalDataExportRequest.includes(:user).recent.limit(10),
      erasures: PersonalDataErasureRequest.includes(:user).recent.limit(10)
    }
  end
  
  # GET /admin/gdpr/users
  def users
    @users = User.includes(:personal_data_export_requests, :personal_data_erasure_requests, :user_consents, :posts, :media)
                 .order(:email)
    
    if params[:search].present?
      @users = @users.where("email ILIKE ? OR name ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:filter].present?
      case params[:filter]
      when 'with_exports'
        @users = @users.joins(:personal_data_export_requests)
      when 'with_erasures'
        @users = @users.joins(:personal_data_erasure_requests)
      when 'with_consent'
        @users = @users.joins(:user_consents)
      end
    end
    
    @users = @users.page(params[:page]).per(50)
    
    # Preload comment counts for all users to avoid N+1 queries
    user_emails = @users.pluck(:email)
    @comment_counts = Comment.where(author_email: user_emails).group(:author_email).count
  end
  
  # GET /admin/gdpr/users/:id
  def user_data
    @export_requests = @user.personal_data_export_requests.recent
    @erasure_requests = @user.personal_data_erasure_requests.recent
    @consent_records = @user.user_consents.recent
    
    @data_summary = {
      posts: @user.posts.count,
      pages: @user.pages.count,
      comments: Comment.where(author_email: @user.email).count,
      media: @user.media.count,
      pageviews: Pageview.where(user_id: @user.id).count,
      api_tokens: @user.api_tokens.count,
      meta_fields: @user.meta_fields.count,
      consent_records: @user.user_consents.count
    }
    
    @gdpr_status = GdprService.get_user_gdpr_status(@user)
  end
  
  # POST /admin/gdpr/users/:id/export
  def export_user_data
    begin
      export_request = GdprService.create_export_request(@user, current_user)
      
      redirect_to admin_gdpr_user_data_path(@user), 
                  notice: "Data export request created successfully. Processing will begin shortly."
    rescue => e
      redirect_to admin_gdpr_user_data_path(@user), 
                  alert: "Failed to create export request: #{e.message}"
    end
  end
  
  # GET /admin/gdpr/exports/:id/download
  def download_export
    unless @export_request.completed?
      redirect_to admin_gdpr_user_data_path(@export_request.user), 
                  alert: 'Export is not ready yet. Please wait for processing to complete.'
      return
    end
    
    unless File.exist?(@export_request.file_path)
      redirect_to admin_gdpr_user_data_path(@export_request.user), 
                  alert: 'Export file not found. Please request a new export.'
      return
    end
    
    send_file @export_request.file_path,
              filename: "personal_data_#{@export_request.email.gsub('@', '_at_')}_#{Date.today}.json",
              type: 'application/json',
              disposition: 'attachment'
  end
  
  # POST /admin/gdpr/users/:id/erase
  def erase_user_data
    begin
      erasure_request = GdprService.create_erasure_request(@user, current_user, params[:reason])
      
      redirect_to admin_gdpr_user_data_path(@user), 
                  notice: "Data erasure request created. Confirmation required before processing."
    rescue => e
      redirect_to admin_gdpr_user_data_path(@user), 
                  alert: "Failed to create erasure request: #{e.message}"
    end
  end
  
  # POST /admin/gdpr/erasures/:id/confirm
  def confirm_erasure
    begin
      GdprService.confirm_erasure_request(@erasure_request, current_user)
      
      redirect_to admin_gdpr_user_data_path(@erasure_request.user), 
                  notice: "Data erasure confirmed and queued for processing."
    rescue => e
      redirect_to admin_gdpr_user_data_path(@erasure_request.user), 
                  alert: "Failed to confirm erasure: #{e.message}"
    end
  end
  
  # GET /admin/gdpr/users/:id/consent
  def user_consent_history
    @consent_records = @user.user_consents.recent
    @consent_types = UserConsent::CONSENT_TYPES
  end
  
  # POST /admin/gdpr/users/:id/consent
  def record_consent
    begin
      consent_data = {
        granted: params[:granted] == 'true',
        consent_text: params[:consent_text],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
      
      GdprService.record_user_consent(@user, params[:consent_type], consent_data)
      
      redirect_to admin_gdpr_user_consent_history_path(@user), 
                  notice: "Consent recorded successfully."
    rescue => e
      redirect_to admin_gdpr_user_consent_history_path(@user), 
                  alert: "Failed to record consent: #{e.message}"
    end
  end
  
  # DELETE /admin/gdpr/users/:id/consent/:consent_type
  def withdraw_consent
    begin
      GdprService.withdraw_user_consent(@user, params[:consent_type])
      
      redirect_to admin_gdpr_user_consent_history_path(@user), 
                  notice: "Consent withdrawn successfully."
    rescue => e
      redirect_to admin_gdpr_user_consent_history_path(@user), 
                  alert: "Failed to withdraw consent: #{e.message}"
    end
  end
  
  # GET /admin/gdpr/requests
  def requests
    @export_requests = PersonalDataExportRequest.includes(:user)
                                               .order(created_at: :desc)
                                               .page(params[:export_page])
                                               .per(25)
    
    @erasure_requests = PersonalDataErasureRequest.includes(:user)
                                                .order(created_at: :desc)
                                                .page(params[:erasure_page])
                                                .per(25)
    
    if params[:status].present?
      @export_requests = @export_requests.where(status: params[:status])
      @erasure_requests = @erasure_requests.where(status: params[:status])
    end
    
    if params[:user_search].present?
      user_ids = User.where("email ILIKE ?", "%#{params[:user_search]}%").pluck(:id)
      @export_requests = @export_requests.where(user_id: user_ids)
      @erasure_requests = @erasure_requests.where(user_id: user_ids)
    end
  end
  
  # GET /admin/gdpr/audit
  def audit
    @audit_entries = GdprService.get_audit_log(params[:page] || 1, 50)
    
    # Preload audit statistics to avoid queries in view
    @audit_stats = {
      total_exports: PersonalDataExportRequest.count,
      total_erasures: PersonalDataErasureRequest.count,
      total_consents: UserConsent.count,
      pending_requests: PersonalDataExportRequest.where(status: ['pending', 'processing']).count +
                       PersonalDataErasureRequest.where(status: ['pending_confirmation', 'processing']).count
    }
    
    if params[:user_search].present?
      # Filter audit entries by user email
      @audit_entries = @audit_entries.select { |entry| 
        entry[:user_email].downcase.include?(params[:user_search].downcase) 
      }
    end
    
    if params[:action_filter].present?
      @audit_entries = @audit_entries.select { |entry| 
        entry[:action].include?(params[:action_filter]) 
      }
    end
  end
  
  # GET /admin/gdpr/compliance
  def compliance
    @compliance_stats = {
      total_users: User.count,
      users_with_consent: User.joins(:user_consents).distinct.count,
      pending_requests: PersonalDataExportRequest.where(status: ['pending', 'processing']).count +
                       PersonalDataErasureRequest.where(status: ['pending_confirmation', 'processing']).count,
      completed_requests: PersonalDataExportRequest.where(status: 'completed').count +
                         PersonalDataErasureRequest.where(status: 'completed').count,
      consent_types: UserConsent.group(:consent_type).count,
      recent_activity: {
        exports_last_7_days: PersonalDataExportRequest.where('created_at > ?', 7.days.ago).count,
        erasures_last_7_days: PersonalDataErasureRequest.where('created_at > ?', 7.days.ago).count,
        consent_changes_last_7_days: UserConsent.where('granted_at > ?', 7.days.ago).count
      }
    }
    
    @gdpr_requirements = {
      data_export_implemented: true,
      data_erasure_implemented: true,
      consent_management_implemented: true,
      audit_trail_implemented: true,
      data_protection_by_design: true,
      user_rights_accessible: true
    }
  end
  
  # GET /admin/gdpr/settings
  def settings
    @gdpr_settings = {
      data_retention_days: SiteSetting.get('gdpr_data_retention_days', 365),
      export_auto_delete_days: SiteSetting.get('gdpr_export_auto_delete_days', 7),
      erasure_confirmation_required: SiteSetting.get('gdpr_erasure_confirmation_required', true),
      consent_required_for_processing: SiteSetting.get('gdpr_consent_required_for_processing', true),
      audit_log_retention_days: SiteSetting.get('gdpr_audit_log_retention_days', 2555), # 7 years
      anonymize_ip_addresses: SiteSetting.get('gdpr_anonymize_ip_addresses', true)
    }
  end
  
  # PATCH /admin/gdpr/settings
  def update_settings
    begin
      params[:gdpr_settings].each do |key, value|
        SiteSetting.set(key, value)
      end
      
      redirect_to admin_gdpr_settings_path, 
                  notice: "GDPR settings updated successfully."
    rescue => e
      redirect_to admin_gdpr_settings_path, 
                  alert: "Failed to update settings: #{e.message}"
    end
  end
  
  # POST /admin/gdpr/bulk_export
  def bulk_export
    user_ids = params[:user_ids] || []
    
    if user_ids.empty?
      redirect_to admin_gdpr_users_path, 
                  alert: "Please select users to export."
      return
    end
    
    users = User.where(id: user_ids)
    success_count = 0
    error_count = 0
    
    users.each do |user|
      begin
        GdprService.create_export_request(user, current_user)
        success_count += 1
      rescue => e
        error_count += 1
        Rails.logger.error("Bulk export failed for user #{user.id}: #{e.message}")
      end
    end
    
    if error_count > 0
      redirect_to admin_gdpr_users_path, 
                  notice: "Bulk export initiated. #{success_count} successful, #{error_count} failed."
    else
      redirect_to admin_gdpr_users_path, 
                  notice: "Bulk export initiated for #{success_count} users."
    end
  end
  
  # GET /admin/gdpr/export_template
  def export_template
    respond_to do |format|
      format.json do
        render json: {
          template: {
            request_info: {
              requested_at: Time.current.iso8601,
              email: "user@example.com",
              export_date: Time.current.iso8601
            },
            user_profile: {
              id: 1,
              email: "user@example.com",
              name: "User Name",
              role: "author",
              created_at: Time.current.iso8601,
              updated_at: Time.current.iso8601
            },
            posts: [],
            comments: [],
            media: [],
            subscribers: [],
            api_tokens: [],
            meta_fields: [],
            analytics_data: {},
            consent_records: [],
            gdpr_requests: {},
            metadata: {
              total_posts: 0,
              total_comments: 0,
              export_date: Time.current.iso8601
            }
          }
        }
      end
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id] || params[:user_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_gdpr_users_path, alert: 'User not found.'
  end
  
  def set_export_request
    @export_request = PersonalDataExportRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_gdpr_requests_path, alert: 'Export request not found.'
  end
  
  def set_erasure_request
    @erasure_request = PersonalDataErasureRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_gdpr_requests_path, alert: 'Erasure request not found.'
  end
end
