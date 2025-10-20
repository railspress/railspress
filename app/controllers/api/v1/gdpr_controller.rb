module Api
  module V1
    class GdprController < BaseController
      before_action :authenticate_user!
      before_action :set_user, only: [:export_data, :request_erasure, :data_portability]
      before_action :validate_gdpr_request, only: [:export_data, :request_erasure]
      
      # GET /api/v1/gdpr/data-export/:user_id
      # Export personal data for a user (GDPR Article 20 - Right to Data Portability)
      def export_data
        begin
          export_request = GdprService.create_export_request(@user, current_user)
          
          render json: {
            success: true,
            message: 'Personal data export request created successfully',
            data: {
              request_id: export_request.id,
              token: export_request.token,
              status: export_request.status,
              requested_at: export_request.created_at,
              estimated_completion: 5.minutes.from_now,
              download_url: api_v1_gdpr_download_export_url(export_request.token)
            }
          }, status: :created
        rescue => e
          render json: {
            success: false,
            message: 'Failed to create export request',
            error: e.message
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/gdpr/data-export/download/:token
      # Download exported personal data
      def download_export
        export_request = PersonalDataExportRequest.find_by(token: params[:token])
        
        unless export_request
          render json: {
            success: false,
            message: 'Export request not found'
          }, status: :not_found
          return
        end
        
        unless export_request.completed?
          render json: {
            success: false,
            message: 'Export is not ready yet',
            data: {
              status: export_request.status,
              estimated_completion: export_request.created_at + 5.minutes
            }
          }, status: :accepted
          return
        end
        
        unless File.exist?(export_request.file_path)
          render json: {
            success: false,
            message: 'Export file not found'
          }, status: :not_found
          return
        end
        
        send_file export_request.file_path,
                  filename: "personal_data_#{export_request.email.gsub('@', '_at_')}_#{Date.today}.json",
                  type: 'application/json',
                  disposition: 'attachment'
      rescue => e
        render json: {
          success: false,
          message: 'Download failed',
          error: e.message
        }, status: :internal_server_error
      end
      
      # POST /api/v1/gdpr/data-erasure/:user_id
      # Request data erasure (GDPR Article 17 - Right to Erasure)
      def request_erasure
        begin
          erasure_request = GdprService.create_erasure_request(@user, current_user, params[:reason])
          
          render json: {
            success: true,
            message: 'Data erasure request created successfully',
            data: {
              request_id: erasure_request.id,
              token: erasure_request.token,
              status: erasure_request.status,
              requested_at: erasure_request.created_at,
              reason: erasure_request.reason,
              confirmation_url: api_v1_gdpr_confirm_erasure_url(erasure_request.token),
              metadata: erasure_request.metadata
            }
          }, status: :created
        rescue => e
          render json: {
            success: false,
            message: 'Failed to create erasure request',
            error: e.message
          }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/gdpr/data-erasure/confirm/:token
      # Confirm data erasure request
      def confirm_erasure
        erasure_request = PersonalDataErasureRequest.find_by(token: params[:token])
        
        unless erasure_request
          render json: {
            success: false,
            message: 'Erasure request not found'
          }, status: :not_found
          return
        end
        
        if erasure_request.status != 'pending_confirmation'
          render json: {
            success: false,
            message: 'This request has already been processed',
            data: { status: erasure_request.status }
          }, status: :unprocessable_entity
          return
        end
        
        begin
          GdprService.confirm_erasure_request(erasure_request, current_user)
          
          render json: {
            success: true,
            message: 'Data erasure confirmed and queued for processing',
            data: {
              request_id: erasure_request.id,
              status: erasure_request.status,
              confirmed_at: erasure_request.confirmed_at,
              estimated_completion: 10.minutes.from_now
            }
          }, status: :ok
        rescue => e
          render json: {
            success: false,
            message: 'Failed to confirm erasure request',
            error: e.message
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/gdpr/data-portability/:user_id
      # Get data portability information (GDPR Article 20)
      def data_portability
        begin
          portability_data = GdprService.generate_portability_data(@user)
          
          render json: {
            success: true,
            message: 'Data portability information retrieved successfully',
            data: portability_data
          }, status: :ok
        rescue => e
          render json: {
            success: false,
            message: 'Failed to retrieve portability data',
            error: e.message
          }, status: :internal_server_error
        end
      end
      
      # GET /api/v1/gdpr/requests
      # List all GDPR requests for the current user or admin
      def requests
        if current_user.administrator?
          export_requests = PersonalDataExportRequest.includes(:user).recent.limit(50)
          erasure_requests = PersonalDataErasureRequest.includes(:user).recent.limit(50)
        else
          export_requests = PersonalDataExportRequest.where(user: current_user).recent.limit(50)
          erasure_requests = PersonalDataErasureRequest.where(user: current_user).recent.limit(50)
        end
        
        render json: {
          success: true,
          data: {
            export_requests: export_requests.map do |req|
              {
                id: req.id,
                user_email: req.email,
                status: req.status,
                requested_at: req.created_at,
                completed_at: req.completed_at,
                download_url: req.completed? ? api_v1_gdpr_download_export_url(req.token) : nil
              }
            end,
            erasure_requests: erasure_requests.map do |req|
              {
                id: req.id,
                user_email: req.email,
                status: req.status,
                reason: req.reason,
                requested_at: req.created_at,
                confirmed_at: req.confirmed_at,
                completed_at: req.completed_at
              }
            end
          }
        }, status: :ok
      end
      
      # GET /api/v1/gdpr/status/:user_id
      # Get GDPR compliance status for a user
      def status
        begin
          status_data = GdprService.get_user_gdpr_status(@user)
          
          render json: {
            success: true,
            data: status_data
          }, status: :ok
        rescue => e
          render json: {
            success: false,
            message: 'Failed to retrieve GDPR status',
            error: e.message
          }, status: :internal_server_error
        end
      end
      
      # POST /api/v1/gdpr/consent/:user_id
      # Record user consent (GDPR Article 7)
      def record_consent
        begin
          consent_data = GdprService.record_user_consent(@user, params[:consent_type], params[:consent_data])
          
          render json: {
            success: true,
            message: 'Consent recorded successfully',
            data: consent_data
          }, status: :created
        rescue => e
          render json: {
            success: false,
            message: 'Failed to record consent',
            error: e.message
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/gdpr/consent/:user_id
      # Withdraw user consent
      def withdraw_consent
        begin
          GdprService.withdraw_user_consent(@user, params[:consent_type])
          
          render json: {
            success: true,
            message: 'Consent withdrawn successfully'
          }, status: :ok
        rescue => e
          render json: {
            success: false,
            message: 'Failed to withdraw consent',
            error: e.message
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/gdpr/audit-log
      # Get GDPR audit log (admin only)
      def audit_log
        unless current_user.administrator?
          render json: {
            success: false,
            message: 'Access denied'
          }, status: :forbidden
          return
        end
        
        begin
          audit_data = GdprService.get_audit_log(params[:page] || 1, params[:per_page] || 50)
          
          render json: {
            success: true,
            data: audit_data
          }, status: :ok
        rescue => e
          render json: {
            success: false,
            message: 'Failed to retrieve audit log',
            error: e.message
          }, status: :internal_server_error
        end
      end
      
      private
      
      def set_user
        @user = User.find(params[:user_id])
        
        # Users can only access their own data unless they're admin
        unless current_user.administrator? || @user == current_user
          render json: {
            success: false,
            message: 'Access denied'
          }, status: :forbidden
        end
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          message: 'User not found'
        }, status: :not_found
      end
      
      def validate_gdpr_request
        # Prevent admins from being erased
        if params[:action] == 'request_erasure' && @user.administrator?
          render json: {
            success: false,
            message: 'Cannot erase data for administrator accounts. Please change their role first.'
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
