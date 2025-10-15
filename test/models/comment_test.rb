require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @post = posts(:one)
    @comment = Comment.new(
      content: "This is a test comment",
      author_name: "Test Author",
      author_email: "test@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      author_ip: "127.0.0.1",
      author_agent: "Mozilla/5.0 (Test Browser)",
      tenant: @user.tenant
    )
  end

  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "should require content" do
    @comment.content = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:content], "can't be blank"
  end

  test "should require author name when no user" do
    @comment.user = nil
    @comment.author_name = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:author_name], "can't be blank"
  end

  test "should require author email when no user" do
    @comment.user = nil
    @comment.author_email = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:author_email], "can't be blank"
  end

  test "should validate email format when no user" do
    @comment.user = nil
    @comment.author_email = "invalid-email"
    assert_not @comment.valid?
    assert_includes @comment.errors[:author_email], "is invalid"
  end

  test "should require commentable" do
    @comment.commentable = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:commentable], "must exist"
  end

  test "should not require tenant due to optional" do
    @comment.tenant = nil
    assert @comment.valid?
  end

  test "should validate comment type" do
    # This will raise an error because enum validation happens before our validation
    assert_raises(ArgumentError) do
      @comment.comment_type = "invalid_type"
    end
  end

  test "should validate comment approved status" do
    @comment.comment_approved = "invalid"
    assert_not @comment.valid?
    assert_includes @comment.errors[:comment_approved], "is not included in the list"
  end

  test "should have default status" do
    comment = Comment.new
    assert_equal "pending", comment.status
  end

  test "should scope approved comments" do
    @comment.status = "approved"
    @comment.save!
    
    approved_comment = Comment.approved.first
    assert_equal @comment, approved_comment
  end

  test "should scope pending comments" do
    @comment.status = "pending"
    @comment.save!
    
    pending_comment = Comment.pending.first
    assert_equal @comment, pending_comment
  end

  test "should scope spam comments" do
    @comment.status = "spam"
    @comment.save!
    
    spam_comment = Comment.spam.first
    assert_equal @comment, spam_comment
  end

  test "should scope trash comments" do
    @comment.status = "trash"
    @comment.save!
    
    trash_comment = Comment.trash.first
    assert_equal @comment, trash_comment
  end

  test "should scope comments by type" do
    @comment.comment_type = "comment"
    @comment.save!
    
    comment_type = Comment.comments_only.first
    assert_equal @comment, comment_type
  end

  test "should scope recent comments" do
    @comment.save!
    
    recent_comment = Comment.recent.first
    assert_equal @comment, recent_comment
  end

  test "should belong to user" do
    assert_respond_to @comment, :user
  end

  test "should belong to commentable" do
    assert_respond_to @comment, :commentable
  end

  test "should belong to tenant" do
    assert_respond_to @comment, :tenant
  end

  test "should have parent comment" do
    parent_comment = Comment.create!(
      content: "Parent comment",
      author_name: "Parent Author",
      author_email: "parent@example.com",
      commentable: @post,
      user: @user,
      tenant: @user.tenant
    )
    
    @comment.comment_parent_id = parent_comment.id
    @comment.save!
    
    assert_equal parent_comment, @comment.comment_parent
  end

  test "should have child comments" do
    @comment.save!
    
    child_comment = Comment.create!(
      content: "Child comment",
      author_name: "Child Author",
      author_email: "child@example.com",
      commentable: @post,
      user: @user,
      comment_parent_id: @comment.id,
      tenant: @user.tenant
    )
    
    assert_includes @comment.comment_replies, child_comment
  end

  test "should be trashable" do
    @comment.save!
    assert_respond_to @comment, :trash!
    assert_respond_to @comment, :untrash!
    assert_respond_to @comment, :trashed?
  end

  test "should have browser info method" do
    @comment.author_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    assert_equal "Chrome", @comment.browser_info
  end

  test "should check if comment is reply" do
    assert_not @comment.is_reply?
    
    @comment.comment_parent_id = 1
    assert @comment.is_reply?
  end
end
