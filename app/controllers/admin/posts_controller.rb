class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: %i[ show edit update destroy publish unpublish write restore ]
  layout :choose_layout

  # GET /admin/posts or /admin/posts.json
  def index
    @posts = Post.kept.includes(:user, :terms).order(created_at: :desc)
    
    # Filter by status if specified
    if params[:status].present? && Post.statuses.keys.include?(params[:status])
      @posts = @posts.where(status: params[:status])
    end
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @posts = Post.discarded.includes(:user, :terms).order(created_at: :desc)
    end
    
    respond_to do |format|
      format.html
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
    @tags = Term.for_taxonomy('post_tag').ordered
  end
  
  # GET /admin/posts/write (collection)
  def write_new
    @post = current_user.posts.build(status: :draft)
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('post_tag').ordered
    render :write, layout: 'editor_fullscreen'
  end
  
  # GET /admin/posts/:id/write (member)
  def write
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('post_tag').ordered
    render layout: 'editor_fullscreen'
  end

  # GET /admin/posts/1/edit
  def edit
    @categories = Term.for_taxonomy('category').ordered
    @tags = Term.for_taxonomy('post_tag').ordered
  end

  # POST /admin/posts or /admin/posts.json
  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to [:admin, @post], notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        @categories = Term.for_taxonomy('category').ordered
        @tags = Term.for_taxonomy('post_tag').ordered
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/posts/1 or /admin/posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to [:admin, @post], notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @post }
      else
        @categories = Term.for_taxonomy('category').ordered
        @tags = Term.for_taxonomy('post_tag').ordered
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/posts/1 or /admin/posts/1.json
  def destroy
    if @post.discarded?
      @post.destroy! # Permanent delete
      notice = "Post was permanently deleted."
    else
      @post.discard # Soft delete
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
    @post.undiscard
    redirect_to admin_posts_path, notice: "Post was restored from trash."
  end
  
  # POST /admin/posts/bulk_action
  def bulk_action
    action_type = params[:action_type]
    post_ids = params[:post_ids] || []
    
    posts = Post.where(id: post_ids)
    
    case action_type
    when 'publish'
      posts.update_all(status: :published, published_at: Time.current)
      message = "#{posts.count} posts published"
    when 'unpublish'
      posts.update_all(status: :draft)
      message = "#{posts.count} posts unpublished"
    when 'delete'
      posts.destroy_all
      message = "#{posts.count} posts deleted"
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
        :featured_image, :meta_description, :meta_keywords,
        :featured_image_file, :password, :password_hint,
        category_ids: [], tag_ids: []
      )
    end
    
    def posts_json
      @posts.map do |post|
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          status: post.status,
          author: post.author_name,
          categories: post.terms_for_taxonomy('category').pluck(:name).join(', '),
          tags: post.terms_for_taxonomy('post_tag').pluck(:name).join(', '),
          comments_count: post.comments.where(status: 'approved').count,
          created_at: post.created_at.strftime("%Y-%m-%d %H:%M"),
          published_at: post.published_at&.strftime("%Y-%m-%d %H:%M")
        }
      end
    end
    
    def choose_layout
      action_name == 'write' || action_name == 'write_new' ? 'editor_fullscreen' : 'admin'
    end
end
