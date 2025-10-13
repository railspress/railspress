class Admin::RedirectsController < Admin::BaseController
  before_action :set_redirect, only: [:edit, :update, :destroy, :toggle]
  
  # GET /admin/redirects
  def index
    @redirects = Redirect.includes(:versions)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(20)
    
    # Filter by status
    @redirects = @redirects.active if params[:status] == 'active'
    @redirects = @redirects.inactive if params[:status] == 'inactive'
    
    # Filter by type
    @redirects = @redirects.by_type(params[:type]) if params[:type].present?
    
    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @redirects = @redirects.where('from_path LIKE ? OR to_path LIKE ?', search_term, search_term)
    end
    
    # Stats
    @stats = {
      total: Redirect.count,
      active: Redirect.active.count,
      inactive: Redirect.inactive.count,
      total_hits: Redirect.sum(:hits_count)
    }
  end
  
  # GET /admin/redirects/new
  def new
    @redirect = Redirect.new
  end
  
  # GET /admin/redirects/:id/edit
  def edit
  end
  
  # POST /admin/redirects
  def create
    @redirect = Redirect.new(redirect_params)
    
    if @redirect.save
      redirect_to admin_redirects_path, notice: 'Redirect created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /admin/redirects/:id
  def update
    if @redirect.update(redirect_params)
      redirect_to admin_redirects_path, notice: 'Redirect updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /admin/redirects/:id
  def destroy
    @redirect.destroy
    redirect_to admin_redirects_path, notice: 'Redirect deleted successfully.'
  end
  
  # PATCH /admin/redirects/:id/toggle
  def toggle
    @redirect.update(active: !@redirect.active)
    redirect_to admin_redirects_path, notice: "Redirect #{@redirect.active? ? 'activated' : 'deactivated'}."
  end
  
  # POST /admin/redirects/bulk_action
  def bulk_action
    redirect_ids = params[:redirect_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'activate'
      Redirect.where(id: redirect_ids).update_all(active: true)
      message = "#{redirect_ids.count} redirects activated."
    when 'deactivate'
      Redirect.where(id: redirect_ids).update_all(active: false)
      message = "#{redirect_ids.count} redirects deactivated."
    when 'delete'
      Redirect.where(id: redirect_ids).destroy_all
      message = "#{redirect_ids.count} redirects deleted."
    else
      message = "Invalid action."
    end
    
    redirect_to admin_redirects_path, notice: message
  end
  
  # GET /admin/redirects/import
  def import
  end
  
  # POST /admin/redirects/do_import
  def do_import
    unless params[:file].present?
      redirect_to import_admin_redirects_path, alert: 'Please select a file to import.'
      return
    end
    
    file = params[:file]
    
    begin
      require 'csv'
      csv_data = CSV.parse(file.read, headers: true)
      
      data = csv_data.map do |row|
        {
          from_path: row['From Path'] || row['from_path'],
          to_path: row['To Path'] || row['to_path'],
          redirect_type: row['Type'] || row['type'] || 'permanent',
          notes: row['Notes'] || row['notes']
        }
      end
      
      result = Redirect.import_redirects(data)
      
      if result[:errors].empty?
        redirect_to admin_redirects_path, notice: "Successfully imported #{result[:imported]} redirects."
      else
        flash[:alert] = "Imported #{result[:imported]} redirects with #{result[:errors].count} errors."
        redirect_to admin_redirects_path
      end
    rescue => e
      redirect_to import_admin_redirects_path, alert: "Import failed: #{e.message}"
    end
  end
  
  # GET /admin/redirects/export
  def export
    csv_data = Redirect.to_csv
    
    send_data csv_data,
              filename: "redirects-#{Date.today}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end
  
  private
  
  def set_redirect
    @redirect = Redirect.find(params[:id])
  end
  
  def redirect_params
    params.require(:redirect).permit(
      :from_path,
      :to_path,
      :redirect_type,
      :status_code,
      :active,
      :notes
    )
  end
end






