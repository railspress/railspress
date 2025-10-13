# SlickForms Submissions Controller
# Handles form submission management in the admin panel

class Admin::SlickForms::SubmissionsController < Admin::BaseController
  before_action :set_submission, only: [:show, :destroy]
  
  def index
    @submissions = get_recent_submissions(50)
    @stats = {
      total: get_submission_count,
      today: get_submissions_today_count,
      this_week: get_submissions_week_count
    }
    
    # Handle bulk actions
    if params[:bulk_action].present? && params[:submission_ids].present?
      handle_bulk_action
    end
  end
  
  def show
    @form = get_form_by_id(@submission[:slick_form_id])
  end
  
  def destroy
    if delete_submission(@submission[:id])
      redirect_to admin_slick_forms_submissions_path, notice: 'Submission was successfully deleted.'
    else
      redirect_to admin_slick_forms_submissions_path, alert: 'Failed to delete submission.'
    end
  end
  
  def export
    submissions = get_all_submissions
    csv_data = generate_csv(submissions)
    
    respond_to do |format|
      format.csv { send_data csv_data, filename: "slick_forms_submissions_#{Date.today}.csv" }
    end
  end
  
  def bulk_action
    case params[:bulk_action]
    when 'delete'
      bulk_delete_submissions(params[:submission_ids])
      redirect_to admin_slick_forms_submissions_path, notice: 'Selected submissions were deleted.'
    when 'mark_spam'
      bulk_mark_spam(params[:submission_ids])
      redirect_to admin_slick_forms_submissions_path, notice: 'Selected submissions were marked as spam.'
    when 'mark_ham'
      bulk_mark_ham(params[:submission_ids])
      redirect_to admin_slick_forms_submissions_path, notice: 'Selected submissions were marked as legitimate.'
    else
      redirect_to admin_slick_forms_submissions_path, alert: 'Invalid bulk action.'
    end
  end
  
  private
  
  def set_submission
    @submission = get_submission_by_id(params[:id])
    redirect_to admin_slick_forms_submissions_path, alert: 'Submission not found.' unless @submission
  end
  
  def handle_bulk_action
    case params[:bulk_action]
    when 'delete'
      bulk_delete_submissions(params[:submission_ids])
      flash[:notice] = 'Selected submissions were deleted.'
    when 'mark_spam'
      bulk_mark_spam(params[:submission_ids])
      flash[:notice] = 'Selected submissions were marked as spam.'
    when 'mark_ham'
      bulk_mark_ham(params[:submission_ids])
      flash[:notice] = 'Selected submissions were marked as legitimate.'
    end
  end
  
  # Database operations
  def get_recent_submissions(limit = 50)
    return [] unless table_exists?('slick_form_submissions')
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_form_submissions ORDER BY created_at DESC LIMIT #{limit}"
    ).to_a.map(&:symbolize_keys)
  end
  
  def get_all_submissions
    return [] unless table_exists?('slick_form_submissions')
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_form_submissions ORDER BY created_at DESC"
    ).to_a.map(&:symbolize_keys)
  end
  
  def get_submission_by_id(id)
    return nil unless table_exists?('slick_form_submissions')
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_form_submissions WHERE id = #{id}"
    ).first
    result&.symbolize_keys
  end
  
  def delete_submission(id)
    return false unless table_exists?('slick_form_submissions')
    
    ActiveRecord::Base.connection.execute(
      "DELETE FROM slick_form_submissions WHERE id = #{id}"
    )
    
    true
  end
  
  def bulk_delete_submissions(ids)
    return unless table_exists?('slick_form_submissions')
    
    ids = ids.reject(&:blank?)
    return if ids.empty?
    
    ActiveRecord::Base.connection.execute(
      "DELETE FROM slick_form_submissions WHERE id IN (#{ids.join(',')})"
    )
  end
  
  def bulk_mark_spam(ids)
    return unless table_exists?('slick_form_submissions')
    
    ids = ids.reject(&:blank?)
    return if ids.empty?
    
    ActiveRecord::Base.connection.execute(
      "UPDATE slick_form_submissions SET spam = 1 WHERE id IN (#{ids.join(',')})"
    )
  end
  
  def bulk_mark_ham(ids)
    return unless table_exists?('slick_form_submissions')
    
    ids = ids.reject(&:blank?)
    return if ids.empty?
    
    ActiveRecord::Base.connection.execute(
      "UPDATE slick_form_submissions SET spam = 0 WHERE id IN (#{ids.join(',')})"
    )
  end
  
  def get_submission_count
    return 0 unless table_exists?('slick_form_submissions')
    ActiveRecord::Base.connection.execute("SELECT COUNT(*) as count FROM slick_form_submissions WHERE spam = 0").first['count']
  end
  
  def get_submissions_today_count
    return 0 unless table_exists?('slick_form_submissions')
    today = Date.today.to_s
    ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) as count FROM slick_form_submissions WHERE DATE(created_at) = '#{today}' AND spam = 0"
    ).first['count']
  end
  
  def get_submissions_week_count
    return 0 unless table_exists?('slick_form_submissions')
    week_ago = 7.days.ago.to_s
    ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) as count FROM slick_form_submissions WHERE created_at >= '#{week_ago}' AND spam = 0"
    ).first['count']
  end
  
  def get_form_by_id(id)
    return nil unless table_exists?('slick_forms')
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM slick_forms WHERE id = #{id}"
    ).first
    result&.symbolize_keys
  end
  
  def generate_csv(submissions)
    require 'csv'
    
    CSV.generate do |csv|
      # Header
      csv << ['ID', 'Form ID', 'Form Name', 'Data', 'IP Address', 'User Agent', 'Spam', 'Created At']
      
      # Data rows
      submissions.each do |submission|
        form = get_form_by_id(submission[:slick_form_id])
        csv << [
          submission[:id],
          submission[:slick_form_id],
          form&.[](:name) || 'Unknown',
          submission[:data],
          submission[:ip_address],
          submission[:user_agent],
          submission[:spam] ? 'Yes' : 'No',
          submission[:created_at]
        ]
      end
    end
  end
  
  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end
end

