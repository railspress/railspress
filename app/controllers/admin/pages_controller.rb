class Admin::PagesController < Admin::BaseController
  before_action :set_page, only: %i[ show edit update destroy publish unpublish ]

  # GET /admin/pages or /admin/pages.json
  def index
    @pages = Page.not_trashed
    
    # Filter by status if specified
    if params[:status].present? && Page.statuses.keys.include?(params[:status])
      @pages = @pages.where(status: params[:status])
    end
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @pages = Page.trashed
    end
    
    @pages = @pages.includes(:user).order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.json { render json: pages_json }
    end
  end

  # GET /admin/pages/1 or /admin/pages/1.json
  def show
  end

  # GET /admin/pages/new
  def new
    @page = current_user.pages.build(status: :draft)
  end

  # GET /admin/pages/1/edit
  def edit
  end

  # POST /admin/pages or /admin/pages.json
  def create
    @page = current_user.pages.build(page_params)

    respond_to do |format|
      if @page.save
        format.html { redirect_to [:admin, @page], notice: "Page was successfully created." }
        format.json { render :show, status: :created, location: [:admin, @page] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/pages/1 or /admin/pages/1.json
  def update
    respond_to do |format|
      if @page.update(page_params)
        format.html { redirect_to [:admin, @page], notice: "Page was successfully updated." }
        format.json { render :show, status: :ok, location: [:admin, @page] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/pages/1 or /admin/pages/1.json
  def destroy
    @page.destroy!

    respond_to do |format|
      format.html { redirect_to admin_pages_path, notice: "Page was successfully deleted." }
      format.json { head :no_content }
    end
  end
  
  # PATCH /admin/pages/1/publish
  def publish
    @page.update(status: :published, published_at: Time.current)
    redirect_to admin_pages_path, notice: "Page was successfully published."
  end
  
  # PATCH /admin/pages/1/unpublish
  def unpublish
    @page.update(status: :draft)
    redirect_to admin_pages_path, notice: "Page was unpublished."
  end

  # POST /admin/pages/bulk_action
  def bulk_action
    action_type = params[:action_type]
    page_ids = params[:page_ids] || []
    
    pages = Page.where(id: page_ids)
    
    case action_type
    when 'publish'
      pages.update_all(status: :published, published_at: Time.current)
      message = "#{pages.count} pages published"
    when 'unpublish'
      pages.update_all(status: :draft)
      message = "#{pages.count} pages unpublished"
    when 'delete'
      pages.destroy_all
      message = "#{pages.count} pages deleted"
    else
      message = "Invalid action"
    end
    
    respond_to do |format|
      format.json { render json: { success: true, message: message } }
    end
  end

  private

  def set_page
    @page = Page.friendly.find(params[:id])
  end

  def page_params
    params.require(:page).permit(
      :title, :slug, :content, :status, :published_at,
      :parent_id, :order, :template, :meta_description, :meta_keywords,
      :password, :password_hint
    )
  end
  
  def pages_json
    @pages.map do |page|
      {
        id: page.id,
        title: page.title,
        slug: page.slug,
        status: page.status,
        author: page.user.email.split('@').first,
        created_at: page.created_at.strftime("%Y-%m-%d %H:%M"),
        published_at: page.published_at&.strftime("%Y-%m-%d %H:%M"),
        actions: view_context.link_to('Edit', edit_admin_page_path(page), class: 'text-indigo-400 hover:text-indigo-300')
      }
    end
  end
end
