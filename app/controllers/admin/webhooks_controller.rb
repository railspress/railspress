class Admin::WebhooksController < Admin::BaseController
  before_action :set_webhook, only: [:show, :edit, :update, :destroy, :test, :toggle_active]
  
  def index
    @webhooks = Webhook.order(created_at: :desc)
    @recent_deliveries = WebhookDelivery.includes(:webhook).recent.limit(20)
  end
  
  def show
    @deliveries = @webhook.webhook_deliveries.recent.page(params[:page]).per(20)
  end
  
  def new
    @webhook = Webhook.new
  end
  
  def create
    @webhook = Webhook.new(webhook_params)
    
    if @webhook.save
      redirect_to admin_webhook_path(@webhook), notice: 'Webhook created successfully.'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @webhook.update(webhook_params)
      redirect_to admin_webhook_path(@webhook), notice: 'Webhook updated successfully.'
    else
      render :edit
    end
  end
  
  def destroy
    @webhook.destroy
    redirect_to admin_webhooks_path, notice: 'Webhook deleted successfully.'
  end
  
  def toggle_active
    @webhook.update!(active: !@webhook.active?)
    
    status = @webhook.active? ? 'activated' : 'deactivated'
    redirect_to admin_webhooks_path, notice: "Webhook #{status}."
  end
  
  def test
    # Send a test webhook
    test_payload = {
      message: 'This is a test webhook from RailsPress',
      timestamp: Time.current.iso8601
    }
    
    delivery = @webhook.deliver('test.webhook', test_payload)
    
    redirect_to admin_webhook_path(@webhook), notice: "Test webhook queued for delivery. Check delivery status below."
  end
  
  private
  
  def set_webhook
    @webhook = Webhook.find(params[:id])
  end
  
  def webhook_params
    params.require(:webhook).permit(
      :name,
      :description,
      :url,
      :active,
      :retry_limit,
      :timeout,
      events: []
    )
  end
end






