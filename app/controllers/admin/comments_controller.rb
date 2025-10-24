class Admin::CommentsController < Admin::BaseController
  before_action :set_comment, only: %i[ show edit update destroy ]

  # GET /admin/comments or /admin/comments.json
  def index
    @comments = Comment.kept.includes(:commentable, :user).order(created_at: :desc)
    
    # Show trashed if explicitly requested
    if params[:show_trash] == 'true'
      @comments = Comment.trashed.includes(:commentable, :user).order(deleted_at: :desc)
    end
    
    respond_to do |format|
      format.html do
        @comments_data = comments_json
        @stats = {
          total: Comment.kept.count,
          approved: Comment.kept.where(status: 'approved').count,
          pending: Comment.kept.where(status: 'pending').count,
          spam: Comment.kept.where(status: 'spam').count
        }
        @bulk_actions = [
          { value: 'approve', label: 'Approve' },
          { value: 'unapprove', label: 'Unapprove' },
          { value: 'spam', label: 'Mark as Spam' },
          { value: 'trash', label: 'Move to Trash' },
          { value: 'untrash', label: 'Restore' }
        ]
        @status_options = [
          { value: 'approved', label: 'Approved' },
          { value: 'pending', label: 'Pending' },
          { value: 'spam', label: 'Spam' },
          { value: 'trash', label: 'Trash' }
        ]
        @columns = [
          {
            title: "",
            formatter: "rowSelection",
            titleFormatter: "rowSelection",
            width: "5%",
            headerSort: false,
            hozAlign: "center",
            headerHozAlign: "center"
          },
          {
            title: "Author",
            field: "author_name",
            width: "20%",
            formatter: "html"
          },
          {
            title: "Comment",
            field: "content",
            width: "35%",
            formatter: "html"
          },
          {
            title: "In Response To",
            field: "commentable_title",
            width: "20%",
            formatter: "html"
          },
          {
            title: "Date",
            field: "created_at",
            width: "10%",
            hozAlign: "center",
            headerHozAlign: "center",
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
            formatter: "html",
            hozAlign: "center",
            headerHozAlign: "center"
          }
        ]
      end
      format.json { render json: comments_json }
    end
  end

  # GET /admin/comments/1 or /admin/comments/1.json
  def show
  end


  # GET /admin/comments/1/edit
  def edit
  end

  # POST /admin/comments or /admin/comments.json
  def create
    @comment = Comment.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.html { redirect_to admin_comments_path, notice: "Comment was successfully created." }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { redirect_to admin_comments_path, alert: "Failed to create comment." }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/comments/1 or /admin/comments/1.json
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to [:admin, @comment], notice: "Comment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/comments/1 or /admin/comments/1.json
  def destroy
    if @comment.trashed?
      @comment.destroy_permanently! # Permanent delete
      notice = "Comment was permanently deleted."
    else
      @comment.trash!(current_user) # Soft delete
      notice = "Comment was moved to trash."
    end

    respond_to do |format|
      format.html { redirect_to admin_comments_path, notice: notice, status: :see_other }
      format.json { head :no_content }
    end
  end
  
  # POST /admin/comments/bulk_action
  def bulk_action
    action_type = params[:action_type]
    comment_ids = params[:ids] || []
    
    comments = Comment.where(id: comment_ids)
    
    case action_type
    when 'approve'
      comments.find_each(&:approve!)
      message = "#{comments.count} comments approved"
    when 'unapprove'
      comments.find_each(&:unapprove!)
      message = "#{comments.count} comments unapproved"
    when 'spam'
      comments.find_each { |comment| comment.update!(status: :spam) }
      message = "#{comments.count} comments marked as spam"
    when 'trash'
      comments.find_each { |comment| comment.trash!(current_user) }
      message = "#{comments.count} comments moved to trash"
    when 'untrash'
      comments.find_each(&:untrash!)
      message = "#{comments.count} comments restored from trash"
    else
      message = "Invalid action"
    end
    
    respond_to do |format|
      format.json { render json: { success: true, message: message } }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(
        :content, :author_name, :author_email, :author_url, :author_ip, :author_agent,
        :status, :comment_type, :comment_approved, :comment_parent_id, :user_id,
        :commentable_type, :commentable_id, :parent_id
      )
    end
    
    def comments_json
      @comments.map do |comment|
        {
          id: comment.id,
          author_name: format_author_name(comment),
          author_email: comment.author_email,
          content: format_content(comment.content),
          commentable_title: format_commentable_title(comment),
          created_at: comment.created_at.iso8601,
          actions: format_actions(comment),
          edit_url: edit_admin_comment_path(comment),
          show_url: admin_comment_path(comment),
          delete_url: nil
        }
      end
    end
    
    def format_actions(comment)
      # Comments table: edit, delete (no view since comments don't have slugs)
      helpers.format_table_actions(comment, [:edit, :delete])
    end
    
    def format_author_name(comment)
      edit_url = edit_admin_comment_path(comment)
      if comment.user.present?
        "<a href=\"#{edit_url}\" class=\"text-indigo-600 hover:text-indigo-900 font-medium\">#{comment.user.name}</a>"
      else
        "<a href=\"#{edit_url}\" class=\"text-indigo-600 hover:text-indigo-900 font-medium\">#{comment.author_name}</a>"
      end
    end
    
    def format_commentable_title(comment)
      return '<span class="text-gray-400">Unknown</span>' unless comment.commentable.present?
      
      title = comment.commentable.title
      
      # Link to the commentable's edit page
      if comment.commentable.is_a?(Post)
        url = edit_admin_post_path(comment.commentable)
        "<a href=\"#{url}\" class=\"text-indigo-600 hover:text-indigo-900\">#{title}</a>"
      elsif comment.commentable.is_a?(Page)
        url = edit_admin_page_path(comment.commentable)
        "<a href=\"#{url}\" class=\"text-indigo-600 hover:text-indigo-900\">#{title}</a>"
      else
        title
      end
    end
    
    def format_content(content)
      truncated = content.length > 100 ? content[0..100] + '...' : content
      "<div class='text-sm'>#{truncated}</div>"
    end
end
