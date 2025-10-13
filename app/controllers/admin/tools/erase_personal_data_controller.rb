class Admin::Tools::ErasePersonalDataController < Admin::BaseController
  # GET /admin/tools/erase_personal_data
  def index
    @erasure_requests = PersonalDataErasureRequest.order(created_at: :desc).limit(50) rescue []
  end
  
  # POST /admin/tools/erase_personal_data/request
  def request
    email = params[:email]
    reason = params[:reason]
    
    unless email.present?
      redirect_to admin_erase_personal_data_path, alert: 'Please provide an email address'
      return
    end
    
    user = User.find_by(email: email)
    
    unless user
      redirect_to admin_erase_personal_data_path, alert: 'No user found with that email address'
      return
    end
    
    # Prevent erasing admin users
    if user.administrator?
      redirect_to admin_erase_personal_data_path, 
                  alert: 'Cannot erase data for administrator accounts. Please change their role first.'
      return
    end
    
    # Create erasure request
    erasure_request = PersonalDataErasureRequest.create!(
      user_id: user.id,
      email: email,
      requested_by: current_user.id,
      status: 'pending_confirmation',
      reason: reason,
      token: SecureRandom.hex(32),
      metadata: {
        user_posts_count: user.posts.count,
        user_comments_count: Comment.where(email: email).count,
        user_media_count: Medium.where(user_id: user.id).count rescue 0
      }
    )
    
    redirect_to admin_erase_personal_data_path, 
                notice: "Erasure request created for #{email}. Awaiting final confirmation."
  rescue => e
    Rails.logger.error("Personal data erasure error: #{e.message}")
    redirect_to admin_erase_personal_data_path, alert: "Request failed: #{e.message}"
  end
  
  # POST /admin/tools/erase_personal_data/confirm/:token
  def confirm
    erasure_request = PersonalDataErasureRequest.find_by(token: params[:token])
    
    unless erasure_request
      redirect_to admin_erase_personal_data_path, alert: 'Erasure request not found'
      return
    end
    
    if erasure_request.status != 'pending_confirmation'
      redirect_to admin_erase_personal_data_path, alert: 'This request has already been processed'
      return
    end
    
    # Update status
    erasure_request.update!(
      status: 'processing',
      confirmed_at: Time.current,
      confirmed_by: current_user.id
    )
    
    # Queue the erasure job
    PersonalDataErasureWorker.perform_async(erasure_request.id)
    
    redirect_to admin_erase_personal_data_path, 
                notice: "Personal data erasure confirmed and queued for processing."
  rescue => e
    Rails.logger.error("Personal data erasure confirmation error: #{e.message}")
    redirect_to admin_erase_personal_data_path, alert: "Confirmation failed: #{e.message}"
  end
end





