class Admin::WebhooksController < Admin::BaseController
  before_action :set_webhook, only: [:show, :edit, :update, :destroy, :test, :toggle_active]
  
  def index
    @webhooks = Webhook.order(created_at: :desc)
    @recent_deliveries = WebhookDelivery.includes(:webhook).recent.limit(20)
    
    # Prepare data for Tabulator
    @webhooks_data = @webhooks.map do |webhook|
      # Status HTML
      status_html = if webhook.active?
        '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"><svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 8 8"><circle cx="4" cy="4" r="3"/></svg>Active</span>'
      else
        '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300">Inactive</span>'
      end
      
      # Add unhealthy indicator if needed
      unless webhook.healthy?
        status_html += '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 ml-2">Unhealthy</span>'
      end
      
      # Actions HTML
      actions_html = %{
        <div class="flex space-x-2">
          <a href="/admin/webhooks/#{webhook.id}" class="text-indigo-600 hover:text-indigo-900">View</a>
          <a href="/admin/webhooks/#{webhook.id}/edit" class="text-indigo-600 hover:text-indigo-900">Edit</a>
          <a href="/admin/webhooks/#{webhook.id}/test" data-method="post" class="text-green-600 hover:text-green-900">Test</a>
          <a href="/admin/webhooks/#{webhook.id}/toggle_active" data-method="patch" class="text-yellow-600 hover:text-yellow-900">#{webhook.active? ? 'Disable' : 'Enable'}</a>
          <a href="/admin/webhooks/#{webhook.id}" data-method="delete" data-confirm="Are you sure?" class="text-red-600 hover:text-red-900">Delete</a>
        </div>
      }
      
      {
        id: webhook.id,
        name: webhook.name,
        url: webhook.url,
        events: webhook.events.join(', '),
        status: status_html,
        health: webhook.healthy? ? 'healthy' : 'unhealthy',
        total_deliveries: webhook.total_deliveries,
        failed_deliveries: webhook.failed_deliveries,
        success_rate: webhook.success_rate,
        created_at: webhook.created_at.iso8601,
        updated_at: webhook.updated_at.iso8601,
        actions: actions_html
      }
    end
    
    # Define columns for Tabulator
    @columns = [
      {
        title: "",
        field: "checkbox",
        formatter: "rowSelection",
        titleFormatter: "rowSelection",
        width: 40,
        hozAlign: "center",
        headerSort: false,
        frozen: true
      },
      {
        title: "Name & URL",
        field: "name",
        width: 300,
        formatter: "html",
        formatterParams: {
          template: "<div><strong>{{name}}</strong><br><small class='text-gray-500 font-mono'>{{url}}</small></div>"
        }
      },
      {
        title: "Events",
        field: "events",
        width: 200,
        formatter: "html",
        formatterParams: {
          template: "<span class='inline-flex px-2 py-1 text-xs font-medium rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200'>{{events}}</span>"
        }
      },
      {
        title: "Status",
        field: "status",
        width: 120,
        formatter: "html"
      },
      {
        title: "Stats",
        field: "total_deliveries",
        width: 120,
        formatter: "html",
        formatterParams: {
          template: "<div><strong>{{total_deliveries}}</strong> total<br><small class='text-gray-500'>{{failed_deliveries}} failed</small></div>"
        }
      },
      {
        title: "Success Rate",
        field: "success_rate",
        width: 100,
        formatter: "progress",
        formatterParams: {
          color: ["red", "orange", "green"],
          min: 0,
          max: 100
        }
      },
      {
        title: "Created",
        field: "created_at",
        width: 120,
        formatter: "datetime",
        formatterParams: {
          inputFormat: "YYYY-MM-DDTHH:mm:ss.SSSZ",
          outputFormat: "MMM DD, YYYY"
        }
      },
      {
        title: "Actions",
        field: "actions",
        width: 200,
        formatter: "html",
        headerSort: false
      }
    ]
    
    # Define bulk actions
    @bulk_actions = [
      { value: "activate", label: "Activate" },
      { value: "deactivate", label: "Deactivate" },
      { value: "delete", label: "Delete" }
    ]
    
    # Stats for the cards (using the format expected by the stats_cards partial)
    @stats = {
      total: @webhooks.count,
      active: @webhooks.where(active: true).count,
      deliveries: @webhooks.sum(:total_deliveries),
      failed: @webhooks.sum(:failed_deliveries)
    }
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
  
  def bulk_action
    webhook_ids = params[:webhook_ids]
    action = params[:bulk_action]
    
    return redirect_to admin_webhooks_path, alert: "No webhooks selected." if webhook_ids.blank?
    
    webhooks = Webhook.where(id: webhook_ids)
    
    case action
    when 'activate'
      webhooks.update_all(active: true)
      redirect_to admin_webhooks_path, notice: "#{webhooks.count} webhook(s) activated."
    when 'deactivate'
      webhooks.update_all(active: false)
      redirect_to admin_webhooks_path, notice: "#{webhooks.count} webhook(s) deactivated."
    when 'delete'
      webhooks.destroy_all
      redirect_to admin_webhooks_path, notice: "#{webhooks.count} webhook(s) deleted."
    else
      redirect_to admin_webhooks_path, alert: "Invalid bulk action."
    end
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








