class Admin::EmailLogsController < Admin::BaseController
  include Pagy::Backend
  
  def index
    @pagy, @email_logs = pagy(EmailLog.recent, items: 50)
    @stats = EmailLog.stats
  end

  def show
    @email_log = EmailLog.find(params[:id])
  end

  def destroy
    @email_log = EmailLog.find(params[:id])
    @email_log.destroy
    redirect_to admin_email_logs_path, notice: 'Email log deleted successfully.'
  end

  def destroy_all
    EmailLog.delete_all
    redirect_to admin_email_logs_path, notice: 'All email logs cleared successfully.'
  end

  def stats
    render json: EmailLog.stats
  end
end

