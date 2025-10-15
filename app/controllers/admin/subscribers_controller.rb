class Admin::SubscribersController < Admin::BaseController
  before_action :set_subscriber, only: [:show, :edit, :update, :destroy, :confirm, :unsubscribe]
  
  # GET /admin/subscribers
  def index
    @subscribers = Subscriber.includes(:versions).recent
    
    # Filter by status
    @subscribers = @subscribers.where(status: params[:status]) if params[:status].present?
    
    # Filter by source
    @subscribers = @subscribers.by_source(params[:source]) if params[:source].present?
    
    # Filter by tag
    @subscribers = @subscribers.by_tag(params[:tag]) if params[:tag].present?
    
    # Filter by list
    @subscribers = @subscribers.by_list(params[:list]) if params[:list].present?
    
    # Search
    @subscribers = @subscribers.search(params[:q]) if params[:q].present?
    
    # Get stats
    @stats = Subscriber.stats
    
    # For Tabulator (AJAX)
    respond_to do |format|
      format.html
      format.json do
        render json: {
          data: @subscribers.limit(params[:size] || 20).offset(params[:page].to_i * (params[:size] || 20).to_i).map { |s| subscriber_json(s) },
          last_page: @subscribers.count / (params[:size] || 20).to_i
        }
      end
    end
  end
  
  # GET /admin/subscribers/:id
  def show
  end
  
  # GET /admin/subscribers/new
  def new
    @subscriber = Subscriber.new
  end
  
  # GET /admin/subscribers/:id/edit
  def edit
  end
  
  # POST /admin/subscribers
  def create
    @subscriber = Subscriber.new(subscriber_params)
    @subscriber.status = 'confirmed' # Manual adds are auto-confirmed
    @subscriber.confirmed_at = Time.current
    @subscriber.source = 'admin'
    
    if @subscriber.save
      redirect_to admin_subscribers_path, notice: 'Subscriber added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /admin/subscribers/:id
  def update
    if @subscriber.update(subscriber_params)
      redirect_to admin_subscribers_path, notice: 'Subscriber updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/subscribers/:id
  def destroy
    @subscriber.destroy
    redirect_to admin_subscribers_path, notice: 'Subscriber deleted successfully.'
  end
  
  # PATCH /admin/subscribers/:id/confirm
  def confirm
    @subscriber.confirm!
    redirect_to admin_subscribers_path, notice: 'Subscriber confirmed.'
  end
  
  # PATCH /admin/subscribers/:id/unsubscribe
  def unsubscribe
    @subscriber.unsubscribe!
    redirect_to admin_subscribers_path, notice: 'Subscriber unsubscribed.'
  end
  
  # POST /admin/subscribers/bulk_action
  def bulk_action
    subscriber_ids = params[:subscriber_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'confirm'
      Subscriber.where(id: subscriber_ids).each(&:confirm!)
      message = "#{subscriber_ids.count} subscribers confirmed."
    when 'unsubscribe'
      Subscriber.where(id: subscriber_ids).each(&:unsubscribe!)
      message = "#{subscriber_ids.count} subscribers unsubscribed."
    when 'delete'
      Subscriber.where(id: subscriber_ids).destroy_all
      message = "#{subscriber_ids.count} subscribers deleted."
    when 'add_tag'
      tag = params[:tag_value]
      Subscriber.where(id: subscriber_ids).each { |s| s.add_tag(tag) }
      message = "Tag '#{tag}' added to #{subscriber_ids.count} subscribers."
    when 'add_to_list'
      list = params[:list_value]
      Subscriber.where(id: subscriber_ids).each { |s| s.add_to_list(list) }
      message = "#{subscriber_ids.count} subscribers added to list '#{list}'."
    else
      message = "Invalid action."
    end
    
    redirect_to admin_subscribers_path, notice: message
  end
  
  # GET /admin/subscribers/import
  def import
  end
  
  # POST /admin/subscribers/do_import
  def do_import
    unless params[:file].present?
      redirect_to import_admin_subscribers_path, alert: 'Please select a file to import.'
      return
    end
    
    file = params[:file]
    
    begin
      result = Subscriber.import_from_csv(file.read)
      
      if result[:errors].empty?
        redirect_to admin_subscribers_path, notice: "Successfully imported #{result[:imported]} subscribers."
      else
        flash[:alert] = "Imported #{result[:imported]} of #{result[:total]} subscribers. #{result[:errors].count} errors occurred."
        redirect_to admin_subscribers_path
      end
    rescue => e
      redirect_to import_admin_subscribers_path, alert: "Import failed: #{e.message}"
    end
  end
  
  # GET /admin/subscribers/export
  def export
    csv_data = Subscriber.to_csv
    
    send_data csv_data,
              filename: "subscribers-#{Date.today}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end
  
  # GET /admin/subscribers/stats
  def stats
    render json: Subscriber.stats
  end
  
  private
  
  def set_subscriber
    @subscriber = Subscriber.find(params[:id])
  end
  
  def subscriber_params
    params.require(:subscriber).permit(
      :email,
      :name,
      :status,
      :source,
      :notes,
      tags: [],
      lists: [],
      metadata: {}
    )
  end
  
  def subscriber_json(subscriber)
    {
      id: subscriber.id,
      email: subscriber.email,
      name: subscriber.name,
      status: subscriber.status,
      source: subscriber.source,
      tags: subscriber.tags || [],
      lists: subscriber.lists || [],
      confirmed_at: subscriber.confirmed_at&.strftime('%Y-%m-%d %H:%M'),
      created_at: subscriber.created_at.strftime('%Y-%m-%d %H:%M'),
      actions: view_context.render(partial: 'admin/subscribers/actions', locals: { subscriber: subscriber })
    }
  end
end








