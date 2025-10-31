class Admin::PagesController < Admin::BaseController
  before_action :set_page, only: %i[ show edit update destroy publish unpublish write preview ]
  layout :choose_layout

  # GET /admin/pages or /admin/pages.json
  def index
    @pages = Page.kept.where.not(status: :auto_draft)
    
    # Filter by status if specified
    if params[:status].present? && Page.statuses.keys.include?(params[:status])
      @pages = @pages.where(status: params[:status])
    end
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @pages = Page.trashed.where.not(status: :auto_draft).includes(:user).order(deleted_at: :desc)
    else
      @pages = @pages.includes(:user).order(created_at: :desc)
    end
    
    respond_to do |format|
      format.html do
        @pages_data = pages_json
        @stats = {
          total: Page.kept.where.not(status: :auto_draft).count,
          published: Page.published.count,
          draft: Page.where(status: 'draft').count,
          trash: Page.trashed.where.not(status: :auto_draft).count
        }
        @bulk_actions = [
          { value: 'trash', label: 'Move to Trash' },
          { value: 'untrash', label: 'Restore' },
          { value: 'delete', label: 'Delete Permanently' }
        ]
        @status_options = [
          { value: 'published', label: 'Published' },
          { value: 'draft', label: 'Draft' },
          { value: 'pending', label: 'Pending' }
        ]
        @columns = [
          {
            title: "",
            formatter: "rowSelection",
            titleFormatter: "rowSelection",
            width: 40,
            headerSort: false
          },
          {
            title: "Title",
            field: "title",
            width: "50%",
            formatter: "html"
          },
          {
            title: "Author",
            field: "author_name",
            width: "15%"
          },
          {
            title: "Status",
            field: "status",
            width: "15%",
            formatter: "html"
          },
          {
            title: "Date",
            field: "created_at",
            width: "10%",
            formatter: "datetime",
            formatterParams: {
              inputFormat: "YYYY-MM-DDTHH:mm:ss.SSSZ",
              outputFormat: "DD/MM/YYYY HH:mm"
            }
          },
          {
            title: "Actions",
            field: "actions",
            width: "10%",
            headerSort: false,
            formatter: "html"
          }
        ]
      end
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
    preload_editor_collections
    render :write, layout: 'write_fullscreen_page'
  end

  # GET /admin/pages/write (collection) – create draft and open fullscreen editor
  def write_new
    @page = current_user.pages.create!(
      title: 'Untitled',
      slug: "untitled-#{SecureRandom.uuid[0..7]}",
      status: :auto_draft
    )
    redirect_to edit_admin_page_path(@page.uuid)
  end

  # GET /admin/pages/:id/write (member) – open existing in fullscreen editor
  def write
    preload_editor_collections
    render layout: 'write_fullscreen_page'
  end

  # GET /admin/pages/:id/preview – redirect to public URL without exposing slug in admin layout
  def preview
    redirect_to page_path(@page.slug)
  end

  # POST /admin/pages or /admin/pages.json
  def create
    @page = current_user.pages.build(page_params)

    respond_to do |format|
      if params[:autosave] == 'true'
        # Autosave: be lenient and ensure a title
        @page.title = 'Untitled' if @page.title.blank?
        # Ensure slug for preview/edit links
        @page.slug = @page.slug.presence || "untitled-#{SecureRandom.uuid[0..7]}"
        if @page.save(validate: false)
          format.json { render json: { status: 'success', id: @page.id, edit_url: edit_admin_page_path(@page.uuid), slug: @page.slug } }
        else
          format.json { render json: { status: 'error', errors: @page.errors }, status: :unprocessable_entity }
        end
      elsif @page.save
        format.html { redirect_to [:admin, @page], notice: "Page was successfully created." }
        format.json { render :show, status: :created, location: [:admin, @page] }
      else
        if request.format.json? || params[:autosave] == 'true'
          format.json { render json: { status: 'error', errors: @page.errors }, status: :unprocessable_entity }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @page.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /admin/pages/1 or /admin/pages/1.json
  def update
    @page = Page.find_by!(uuid: params[:id])
    
    # Debug: Log meta fields being received
    if params[:page]
      Rails.logger.debug "=== PAGE UPDATE DEBUG ==="
      Rails.logger.debug "Meta Title: #{params[:page][:meta_title].inspect}"
      Rails.logger.debug "Meta Description: #{params[:page][:meta_description].inspect}"
      Rails.logger.debug "Meta Keywords: #{params[:page][:meta_keywords].inspect}"
      Rails.logger.debug "========================"
    end
    
    # Ensure auto_draft pages have a title during autosave
    if params[:autosave] == 'true' && @page.auto_draft_status?
      # Ensure we have a title
      params[:page][:title] = 'Untitled' if params[:page] && params[:page][:title].blank?
    end
    
    # Promote auto_draft to draft on manual save (when user clicks save button)
    if !params[:autosave] && @page.auto_draft_status?
      @page.status = :draft unless params[:page] && params[:page][:status].present?
      @page.title = 'Untitled' if @page.title.blank?
    end
    
    respond_to do |format|
      update_params = page_params
      Rails.logger.debug "=== UPDATE PARAMS AFTER PERMIT ==="
      Rails.logger.debug "Meta Title: #{update_params[:meta_title].inspect}"
      Rails.logger.debug "Meta Description: #{update_params[:meta_description].inspect}"
      Rails.logger.debug "Meta Keywords: #{update_params[:meta_keywords].inspect}"
      Rails.logger.debug "==================================="
      
      if @page.update(update_params)
        Rails.logger.debug "=== AFTER UPDATE ==="
        Rails.logger.debug "Meta Title: #{@page.meta_title.inspect}"
        Rails.logger.debug "Meta Description: #{@page.meta_description.inspect}"
        Rails.logger.debug "Meta Keywords: #{@page.meta_keywords.inspect}"
        Rails.logger.debug "===================="
        
        if params[:autosave] == 'true'
          format.json { 
            render json: { 
              status: 'success', 
              updated_at: @page.updated_at, 
              slug: @page.slug,
              id: @page.id,
              uuid: @page.uuid,
              edit_url: edit_admin_page_path(@page)
            } 
          }
        else
          format.html { redirect_to edit_admin_page_path(@page), notice: "Page was successfully updated.", status: :see_other }
          format.json { render :show, status: :ok, location: @page }
        end
      else
        @categories = Term.for_taxonomy('category').ordered
        @tags = Term.for_taxonomy('tag').ordered
        @channels = Channel.active.order(:name)
        @users = User.order(:name)
        @available_templates = get_available_templates
        @sidebar_order = current_user.sidebar_order
        if params[:autosave] == 'true'
          format.json { render json: { status: 'error', errors: @page.errors.full_messages }, status: :unprocessable_entity }
        else
          format.html { render :edit, layout: 'write_fullscreen', status: :unprocessable_entity }
          format.json { render json: @page.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /admin/pages/1 or /admin/pages/1.json
  def destroy
    if @page.trashed?
      @page.destroy_permanently! # Permanent delete
      notice = "Page was permanently deleted."
    else
      @page.trash!(current_user) # Soft delete
      notice = "Page was moved to trash."
    end

    respond_to do |format|
      format.html { redirect_to admin_pages_path, notice: notice, status: :see_other }
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
    identifier = params[:id]
    if identifier.present? && identifier.to_s.match?(/^[0-9a-fA-F-]{32,36}$/)
      @page = Page.find_by!(uuid: identifier)
    else
      @page = Page.friendly.find(identifier)
    end
  end

  def page_params
    params.require(:page).permit(
      :title, :slug, :content, :content_html, :status, :published_at,
      :parent_id, :order, :template, :meta_description, :meta_keywords,
      :password, :password_hint, :page_template_id, channel_ids: []
    )
  end

  def preload_editor_collections
    @channels = Channel.active.order(:name)
    @users = User.order(:name)
    @sidebar_order = current_user.sidebar_order if current_user.respond_to?(:sidebar_order)
  end

  def choose_layout
    action_name.in?(['write', 'write_new']) ? 'write_fullscreen_page' : 'admin'
  end
  
  def pages_json
    @pages.map do |page|
      {
        id: page.id,
        title: "<a href=\"#{edit_admin_page_path(page.uuid)}\" class=\"text-indigo-600 hover:text-indigo-900 font-medium\">#{page.title}</a>",
        slug: page.slug,
        status: format_status_badge(page.status),
        status_raw: page.status,
        author_name: page.user&.name || 'Unknown',
        created_at: page.created_at.iso8601,
        published_at: page.published_at&.iso8601,
        actions: format_actions(page),
        edit_url: edit_admin_page_path(page.uuid),
        show_url: admin_page_path(page)
      }
    end
  end

  private

  def format_status_badge(status)
    status_map = {
      'published' => { class: 'bg-green-100 text-green-800', label: 'Published' },
      'draft' => { class: 'bg-yellow-100 text-yellow-800', label: 'Draft' },
      'pending' => { class: 'bg-blue-100 text-blue-800', label: 'Pending' }
    }
    status_info = status_map[status] || { class: 'bg-gray-100 text-gray-800', label: status }
    "<span class=\"px-2 py-1 text-xs font-medium rounded-full #{status_info[:class]}\">#{status_info[:label]}</span>"
  end

  def format_actions(page)
    # Pages table: view, edit, delete
    helpers.format_table_actions(page, [:view, :edit, :delete])
  end
  
  def get_available_templates
    # Simple fallback for now
    [['Default', 'page']]
  end
end
