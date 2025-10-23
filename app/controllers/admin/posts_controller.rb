class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: %i[ show edit update destroy publish unpublish write restore versions restore_version ]
  layout :choose_layout

  # GET /admin/posts or /admin/posts.json
  def index
    @posts = Post.kept.where.not(status: :auto_draft).includes(:user, :terms).order(created_at: :desc)
    
    # Filter by status if specified
    if params[:status].present? && Post.statuses.keys.include?(params[:status])
      @posts = @posts.where(status: params[:status])
    end
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @posts = Post.trashed.where.not(status: :auto_draft).includes(:user, :terms).order(deleted_at: :desc)
    end
    
    respond_to do |format|
      format.html do
        @posts_data = posts_json
        @stats = {
          total: Post.kept.where.not(status: :auto_draft).count,
          published: Post.published.count,
          draft: Post.where(status: 'draft').count,
          trash: Post.trashed.where.not(status: :auto_draft).count
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
            width: 300,
            formatter: "html"
          },
          {
            title: "Author",
            field: "author_name",
            width: 150
          },
          {
            title: "Status",
            field: "status",
            width: 100,
            formatter: "html"
          },
          {
            title: "Categories",
            field: "categories",
            width: 150,
            formatter: "html"
          },
          {
            title: "Tags",
            field: "tags",
            width: 150,
            formatter: "html"
          },
          {
            title: "Date",
            field: "created_at",
            width: 150,
            formatter: "datetime",
            formatterParams: {
              inputFormat: "YYYY-MM-DDTHH:mm:ss.SSSZ",
              outputFormat: "DD/MM/YYYY HH:mm"
            }
          },
          {
            title: "Actions",
            field: "actions",
            width: 120,
            headerSort: false,
            formatter: "html"
          }
        ]
      end
      format.json { render json: posts_json }
    end
  end

  # GET /admin/posts/1 or /admin/posts/1.json
  def show
  end

  # GET /admin/posts/new
  def new
    @post = current_user.posts.build(status: :draft)
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('tag').ordered
  end
  
  # GET /admin/posts/write (collection)
  def write_new
    # Get default comment status from site settings
    default_comment_status = SiteSetting.get('default_comment_status', 'closed')
    
    # Create auto-draft with UUID slug (SIMPLE!)
    @post = current_user.posts.create!(
      title: 'Untitled',
      slug: "untitled-#{SecureRandom.uuid[0..7]}", # Truncated UUID (8 chars)
      status: :auto_draft,
      comment_status: default_comment_status
    )
    
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('tag').ordered
    @channels = Channel.active.order(:name)
    @users = User.order(:name)
    @available_templates = get_available_templates
    @sidebar_order = current_user.sidebar_order
    render :write, layout: 'write_fullscreen'
  end
  
  # GET /admin/posts/:id/write (member)
  def write
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('tag').ordered
    @channels = Channel.active.order(:name)
    @users = User.order(:name)
    @available_templates = get_available_templates
    @sidebar_order = current_user.sidebar_order
    render layout: 'write_fullscreen'
  end

  # GET /admin/posts/1/edit
  def edit
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('tag').ordered
    @channels = Channel.active.order(:name)
    @users = User.order(:name)
    @available_templates = get_available_templates
    @sidebar_order = current_user.sidebar_order
    render layout: 'write_fullscreen'
  end

  # POST /admin/posts or /admin/posts.json
  def create
    @post = current_user.posts.build(post_params)
    
    # Handle unique slug generation for untitled posts or empty slugs
    if @post.slug.blank? || @post.slug == 'untitled'
      @post.slug = "untitled-#{SecureRandom.uuid[0..7]}"
    end

    respond_to do |format|
      if params[:autosave] == 'true'
        # Autosave - skip validations and set default values
        @post.title = 'Untitled' if @post.title.blank?
        if @post.save(validate: false)
          format.json { render json: { status: 'success', id: @post.id, edit_url: admin_post_path(@post), slug: @post.slug } }
        else
          format.json { render json: { status: 'error', errors: @post.errors }, status: :unprocessable_entity }
        end
      elsif @post.save
        format.html { redirect_to [:admin, @post], notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        @categories = Term.for_taxonomy('category').ordered
        @tags = Term.for_taxonomy('tag').ordered
        if params[:autosave] == 'true'
          format.json { render json: { status: 'error', errors: @post.errors }, status: :unprocessable_entity }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @post.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /admin/posts/1 or /admin/posts/1.json
  def update
    # Keep auto_draft posts as auto_draft during autosave
    if params[:autosave] == 'true' && @post.auto_draft_status?
      # Force status to remain auto_draft during autosave
      params[:post][:status] = 'auto_draft'
      # Ensure we have a title
      params[:post][:title] = 'Untitled' if params[:post][:title].blank?
    end
    
    # Promote auto_draft to draft on manual save
    if !params[:autosave] && @post.auto_draft_status?
      @post.status = :draft
      @post.title = 'Untitled' if @post.title.blank?
    end
    
    respond_to do |format|
      if @post.update(post_params)
        if params[:autosave] == 'true'
          format.json { render json: { status: 'success', updated_at: @post.updated_at, slug: @post.slug } }
        else
          format.html { redirect_to edit_admin_post_path(@post), notice: "Post was successfully updated.", status: :see_other }
          format.json { render :show, status: :ok, location: @post }
        end
      else
        @categories = Term.for_taxonomy('category').ordered
        @tags = Term.for_taxonomy('tag').ordered
        @channels = Channel.active.order(:name)
        @users = User.order(:name)
        @available_templates = get_available_templates
        @sidebar_order = current_user.sidebar_order
        if params[:autosave] == 'true'
          format.json { render json: { status: 'error', errors: @post.errors }, status: :unprocessable_entity }
        else
          format.html { render :edit, layout: 'write_fullscreen', status: :unprocessable_entity }
          format.json { render json: @post.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /admin/posts/1 or /admin/posts/1.json
  def destroy
    if @post.trashed?
      @post.destroy_permanently! # Permanent delete
      notice = "Post was permanently deleted."
    else
      @post.trash!(current_user) # Soft delete
      notice = "Post was moved to trash."
    end

    respond_to do |format|
      format.html { redirect_to admin_posts_path, notice: notice, status: :see_other }
      format.json { head :no_content }
    end
  end
  
  # PATCH /admin/posts/1/publish
  def publish
    @post.update(status: :published, published_at: Time.current)
    redirect_to [:admin, @post], notice: "Post was successfully published."
  end
  
  # PATCH /admin/posts/1/unpublish
  def unpublish
    @post.update(status: :draft)
    redirect_to [:admin, @post], notice: "Post was unpublished."
  end
  
  # PATCH /admin/posts/1/restore
  def restore
    @post.untrash!
    redirect_to admin_posts_path, notice: "Post was restored from trash."
  end
  
  # POST /admin/posts/bulk_action
  def bulk_action
    action_type = params[:action_type]
    post_ids = params[:ids] || []
    
    posts = Post.where(id: post_ids)
    
    case action_type
    when 'publish'
      posts.update_all(status: :published, published_at: Time.current)
      message = "#{posts.count} posts published"
    when 'unpublish'
      posts.update_all(status: :draft)
      message = "#{posts.count} posts unpublished"
    when 'trash'
      posts.find_each { |post| post.trash!(current_user) }
      message = "#{posts.count} posts moved to trash"
    when 'untrash'
      posts.find_each(&:untrash!)
      message = "#{posts.count} posts restored from trash"
    when 'delete'
      posts.find_each(&:destroy_permanently!)
      message = "#{posts.count} posts permanently deleted"
    else
      message = "Invalid action"
    end
    
    respond_to do |format|
      format.json { render json: { success: true, message: message } }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(
        :title, :slug, :content, :excerpt, :status, :published_at,
        :featured_image, :meta_title, :meta_description, :meta_keywords,
        :featured_image_file, :password, :password_hint, :user_id, :template, :comment_status,
        :tag_list,
        category_ids: [], tag_ids: [], channel_ids: []
      )
    end
    
    
    
    def posts_json
      @posts.map do |post|
        categories = post.terms_for_taxonomy('category').pluck(:name)
        tags = post.terms_for_taxonomy('post_tag').pluck(:name)
        
        {
          id: post.id,
          title: "<a href=\"#{edit_admin_post_path(post)}\" class=\"text-indigo-600 hover:text-indigo-900 font-medium\">#{post.title}</a>",
          slug: post.slug,
          status: format_status_badge(post.status),
          status_raw: post.status,  # Raw status for CSS classes
          author_name: post.user&.name || 'Unknown',
          categories: format_categories(categories),
          tags: format_tags(tags),
          comments_count: post.comments.where(status: 'approved').count,
          created_at: post.created_at.iso8601,
          published_at: post.published_at&.iso8601,
          actions: format_actions(post),
          edit_url: edit_admin_post_path(post),
          show_url: admin_post_path(post),
          delete_url: admin_post_path(post)
        }
      end
    end

    private

    def format_status_badge(status)
      status_map = {
        'published' => { class: 'bg-green-100 text-green-800', label: 'Published' },
        'draft' => { class: 'bg-yellow-100 text-yellow-800', label: 'Draft' },
        'pending' => { class: 'bg-blue-100 text-blue-800', label: 'Pending' },
        'trash' => { class: 'bg-red-100 text-red-800', label: 'Trash' }
      }
      
      status_info = status_map[status] || { class: 'bg-gray-100 text-gray-800', label: status }
      "<span class=\"px-2 py-1 text-xs font-medium rounded-full #{status_info[:class]}\">#{status_info[:label]}</span>"
    end

    def format_categories(categories)
      if categories.empty?
        '<span class="text-gray-400">Uncategorized</span>'
      else
        categories.map { |cat| "<span class=\"px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded mr-1\">#{cat}</span>" }.join('')
      end
    end

    def format_tags(tags)
      if tags.empty?
        ''
      else
        tags.map { |tag| "<span class=\"px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded mr-1\">#{tag}</span>" }.join('')
      end
    end

    def format_actions(post)
      actions = ''
      actions += "<a href=\"#{edit_admin_post_path(post)}\" class=\"text-indigo-600 hover:text-indigo-900 mr-2\" title=\"Edit\">✏️</a>"
      actions += "<a href=\"#{admin_post_path(post)}\" class=\"text-blue-600 hover:text-blue-900 mr-2\" title=\"View\">👁️</a>"
      actions += "<a href=\"#{admin_post_path(post)}\" class=\"text-red-600 hover:text-red-900\" title=\"Delete\" data-confirm=\"Are you sure?\">🗑️</a>"
      actions
    end
    
    def choose_layout
      action_name == 'write' || action_name == 'write_new' ? 'write_fullscreen' : 'admin'
    end

    # Version-related actions
    def versions
      @versions = @post.versions.includes(:user).order(created_at: :desc)
      
      respond_to do |format|
        format.html
        format.json { render json: @versions.map { |v| version_json(v) } }
      end
    end

    def restore_version
      version_id = params[:version_id]
      
      if @post.restore_to_version(version_id)
        redirect_to edit_admin_post_path(@post), notice: 'Version restored successfully!'
      else
        redirect_to versions_admin_post_path(@post), alert: 'Failed to restore version.'
      end
    end

    private

    def version_json(version)
      {
        id: version.id,
        created_at: version.created_at,
        user: version.whodunnit ? User.find_by(id: version.whodunnit)&.name : 'System',
        summary: @post.version_summary(version),
        changes: version.changeset.keys,
        event: version.event
      }
    end

    def get_available_templates
      # Simple fallback for now
      [['Default', 'post']]
    end
end
